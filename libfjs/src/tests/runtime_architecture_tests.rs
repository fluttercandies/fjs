//! Tests for the production runtime execution architecture.

use crate::api::engine::JsEngine;
use crate::api::error::JsResult;
use crate::api::runtime::{JsAsyncContext, JsAsyncRuntime};
use crate::api::source::{JsBuiltinOptions, JsCode};
use crate::api::value::JsValue;
use rquickjs::CatchResultExt;
use std::sync::Arc;
use std::time::{Duration, Instant};

const DEEP_RECURSION_PROBE: &str = r#"
globalThis.__fjsDepthProbe = function(limit) {
  let depth = 0;
  function visit() {
    depth += 1;
    if (depth < limit) visit();
  }
  try {
    visit();
    return { ok: true, depth };
  } catch (error) {
    return { ok: false, name: error.name, message: String(error.message), depth };
  }
};
"#;

async fn install_depth_probe(context: &JsAsyncContext) {
    context
        .with_js(async |ctx| {
            ctx.eval::<(), _>(DEEP_RECURSION_PROBE).catch(&ctx).unwrap();
        })
        .await;
}

async fn probe_depth(context: &JsAsyncContext, limit: usize) -> (bool, i64, String) {
    context
        .with_js(async move |ctx| {
            let script = format!("globalThis.__fjsDepthProbe({limit})");
            let object: rquickjs::Object = ctx.eval(script).catch(&ctx).unwrap();
            let ok: bool = object.get("ok").unwrap();
            let depth: i64 = object.get("depth").unwrap();
            let name: String = object.get("name").unwrap_or_default();
            (ok, depth, name)
        })
        .await
}

async fn runtime_and_context_from_new() -> (JsAsyncRuntime, JsAsyncContext) {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    install_depth_probe(&context).await;
    (runtime, context)
}

async fn runtime_and_context_from_create() -> (JsAsyncRuntime, JsAsyncContext) {
    let runtime = JsAsyncRuntime::create(None, None).await.unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    install_depth_probe(&context).await;
    (runtime, context)
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn async_runtime_constructors_apply_same_generous_stack_default() {
    let (_new_runtime, new_context) = runtime_and_context_from_new().await;
    let (_created_runtime, created_context) = runtime_and_context_from_create().await;

    let new_result = probe_depth(&new_context, 500).await;
    let created_result = probe_depth(&created_context, 500).await;

    assert!(
        new_result.0,
        "new() runtime should reach depth 500 by default, got {new_result:?}"
    );
    assert!(
        created_result.0,
        "create() runtime should reach depth 500 by default, got {created_result:?}"
    );
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn async_stack_limit_zero_is_clamped_to_catchable_range_error() {
    let (runtime, context) = runtime_and_context_from_new().await;
    runtime.set_max_stack_size(0).await;

    let result = probe_depth(&context, 100_000).await;

    assert!(!result.0, "oversized recursion should not complete");
    assert_eq!(result.2, "RangeError");
    assert!(result.1 > 0, "RangeError should happen after entering JS");
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn async_eval_runs_on_fjs_js_thread() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    let thread_name = context
        .with_js(async |ctx| {
            let globals = ctx.globals();
            let current_thread_name = rquickjs::Function::new(ctx.clone(), || {
                std::thread::current()
                    .name()
                    .unwrap_or("unnamed")
                    .to_string()
            })
            .catch(&ctx)
            .unwrap();
            globals
                .set("currentThreadName", current_thread_name)
                .catch(&ctx)
                .unwrap();
            ctx.eval::<String, _>("currentThreadName()")
                .catch(&ctx)
                .unwrap()
        })
        .await;

    assert_eq!(thread_name, "fjs-js");
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn execute_pending_job_runs_on_fjs_js_thread() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    context
        .with_js(async |ctx| {
            let globals = ctx.globals();
            let current_thread_name = rquickjs::Function::new(
                ctx.clone(),
                || std::thread::current().name().unwrap_or("unnamed").to_string(),
            )
            .catch(&ctx)
            .unwrap();
            globals
                .set("currentThreadName", current_thread_name)
                .catch(&ctx)
                .unwrap();
            ctx.eval::<(), _>(
                "Promise.resolve().then(() => { globalThis.__jobThreadName = currentThreadName(); });",
            )
            .catch(&ctx)
            .unwrap();
        })
        .await;

    while runtime.execute_pending_job().await.unwrap() {}

    let thread_name = context
        .with_js(async |ctx| {
            ctx.eval::<String, _>("globalThis.__jobThreadName")
                .catch(&ctx)
                .unwrap()
        })
        .await;

    assert_eq!(thread_name, "fjs-js");
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn engine_background_driver_progresses_detached_timers_without_manual_pump() {
    let engine = JsEngine::create(Some(JsBuiltinOptions::essential()), None, None)
        .await
        .unwrap();
    engine.init_without_bridge().await.unwrap();

    let scheduled = engine
        .eval(
            JsCode::Code(
                r#"
                setTimeout(() => {
                  globalThis.__driverTimerDone = true;
                }, 10);
                'scheduled'
                "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();
    assert!(matches!(scheduled, JsValue::String(ref value) if value == "scheduled"));

    let deadline = Instant::now() + Duration::from_secs(2);
    loop {
        let done = engine
            .eval(
                JsCode::Code("globalThis.__driverTimerDone === true".to_string()),
                None,
            )
            .await
            .unwrap();
        if matches!(done, JsValue::Boolean(true)) {
            break;
        }
        assert!(Instant::now() < deadline, "background timer did not fire");
        tokio::time::sleep(Duration::from_millis(20)).await;
    }

    engine.close().await.unwrap();
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn explicit_job_error_contains_original_javascript_exception() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    context
        .with_js(async |ctx| {
            let failing_job: rquickjs::Function = ctx
                .eval("() => { throw new Error('fjs explicit job failure'); }")
                .catch(&ctx)
                .unwrap();
            failing_job.defer(()).catch(&ctx).unwrap();
        })
        .await;

    let mut error = None;
    for _ in 0..16 {
        match runtime.execute_pending_job().await {
            Ok(true) => continue,
            Ok(false) => tokio::task::yield_now().await,
            Err(err) => {
                error = Some(err.to_string());
                break;
            }
        }
    }

    let error = error.expect("expected explicit job error");
    assert!(error.contains("fjs explicit job failure"), "{error}");
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn background_driver_errors_are_drainable() {
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .eval(
            JsCode::Code(
                r#"
                globalThis.__backgroundBoom = () => {
                  throw new Error('fjs background job failure');
                };
                Promise.resolve().then(() => globalThis.__backgroundBoom());
                'scheduled'
                "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    let deadline = Instant::now() + Duration::from_secs(2);
    loop {
        let errors = engine.drain_unhandled_job_errors().await.unwrap();
        if errors
            .iter()
            .any(|error| error.contains("fjs background job failure"))
        {
            break;
        }
        assert!(Instant::now() < deadline, "background error was not queued");
        tokio::time::sleep(Duration::from_millis(20)).await;
    }

    engine.close().await.unwrap();
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn background_driver_timer_callback_errors_are_drainable() {
    let engine = JsEngine::create(Some(JsBuiltinOptions::essential()), None, None)
        .await
        .unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .eval(
            JsCode::Code(
                r#"
                setTimeout(() => {
                  throw new Error('fjs timer callback failure');
                }, 10);
                'scheduled'
                "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    let deadline = Instant::now() + Duration::from_secs(2);
    loop {
        let errors = engine.drain_unhandled_job_errors().await.unwrap();
        if errors
            .iter()
            .any(|error| error.contains("fjs timer callback failure"))
        {
            break;
        }
        assert!(Instant::now() < deadline, "timer error was not queued");
        tokio::time::sleep(Duration::from_millis(20)).await;
    }

    engine.close().await.unwrap();
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn background_driver_raw_quickjs_job_errors_are_drainable() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    context
        .with_js(async |ctx| {
            let failing_job: rquickjs::Function = ctx
                .eval("() => { throw new Error('fjs raw background job failure'); }")
                .catch(&ctx)
                .unwrap();
            failing_job.defer(()).catch(&ctx).unwrap();
        })
        .await;

    runtime.start_driver().await;

    let deadline = Instant::now() + Duration::from_secs(2);
    loop {
        let errors = runtime.drain_unhandled_job_errors().await;
        if errors
            .iter()
            .any(|error| error.contains("fjs raw background job failure"))
        {
            break;
        }
        assert!(
            Instant::now() < deadline,
            "raw QuickJS job error was not queued"
        );
        tokio::time::sleep(Duration::from_millis(20)).await;
    }

    runtime.stop_driver().await;
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn dropping_pumped_runtime_and_context_without_close_does_not_abort() {
    let runtime = JsAsyncRuntime::create(Some(JsBuiltinOptions::essential()), None)
        .await
        .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    let scheduled = context
        .eval(
            r#"
            setTimeout(() => {
              globalThis.__fjsDropTimerDone = true;
            }, 10);
            "scheduled";
            "#
            .to_string(),
        )
        .await;
    assert!(scheduled.is_ok());

    runtime.stop_driver().await;

    let deadline = Instant::now() + Duration::from_secs(2);
    loop {
        runtime.execute_pending_job().await.unwrap();
        let result = context
            .eval("globalThis.__fjsDropTimerDone === true".to_string())
            .await;
        if matches!(result, JsResult::Ok(JsValue::Boolean(true))) {
            break;
        }
        assert!(Instant::now() < deadline, "manual pump timer did not fire");
        tokio::time::sleep(Duration::from_millis(20)).await;
    }

    drop(context);
    drop(runtime);
    tokio::task::yield_now().await;
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn background_driver_does_not_keep_runtime_alive_after_drop() {
    let runtime = JsAsyncRuntime::new().unwrap();
    runtime.start_driver().await;
    let driver = runtime.driver.clone();
    assert!(driver.running());

    drop(runtime);

    let deadline = Instant::now() + Duration::from_secs(2);
    while driver.running() {
        assert!(
            Instant::now() < deadline,
            "driver kept the async runtime alive after all host references were dropped"
        );
        tokio::time::sleep(Duration::from_millis(20)).await;
    }
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn engine_close_is_idempotent_and_stops_driver() {
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();
    assert!(engine.driver_running().await.unwrap());

    engine.close().await.unwrap();
    assert!(!engine.driver_running().await.unwrap());

    engine.close().await.unwrap();
    assert!(!engine.driver_running().await.unwrap());
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn dropping_initialized_bridge_engine_without_close_does_not_abort() {
    let engine = Arc::new(JsEngine::create(None, None, None).await.unwrap());
    engine
        .init(|value| Box::pin(async move { JsResult::Ok(value) }))
        .await
        .unwrap();

    drop(engine);

    tokio::task::yield_now().await;
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn dropping_essential_bridge_engine_with_loaded_module_without_close_does_not_abort() {
    let engine = Arc::new(
        JsEngine::create(
            Some(JsBuiltinOptions::essential()),
            Some(vec![crate::api::source::JsModule::code(
                "drop-fixture".to_string(),
                "export const value = 42;".to_string(),
            )]),
            None,
        )
        .await
        .unwrap(),
    );
    engine
        .init(|value| Box::pin(async move { JsResult::Ok(value) }))
        .await
        .unwrap();

    engine
        .evaluate_module(crate::api::source::JsModule::code(
            "/drop-test".to_string(),
            "import { value } from 'drop-fixture'; export async function run() { return await fjs.bridge_call(value); }".to_string(),
        ))
        .await
        .unwrap();

    let value = engine
        .call("/drop-test".to_string(), "run".to_string(), None)
        .await
        .unwrap();
    assert!(matches!(value, JsValue::Integer(42)));

    drop(engine);

    tokio::task::yield_now().await;
}
