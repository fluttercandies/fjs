//! Tests for the production runtime execution architecture.

use crate::api::engine::JsEngine;
use crate::api::error::JsResult;
use crate::api::runtime::{JsAsyncContext, JsAsyncRuntime};
use crate::api::source::{JsBuiltinOptions, JsCode, JsModule};
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
        .await;
    assert!(matches!(scheduled, Ok(JsValue::String(ref value)) if value == "scheduled"));

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
async fn background_driver_wakes_for_timers_without_foreground_polling() {
    let engine = JsEngine::create(Some(JsBuiltinOptions::essential()), None, None)
        .await
        .unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .eval(
            JsCode::Code(
                r#"
                globalThis.__timerStart = Date.now();
                globalThis.__timerFiredAt = 0;
                setTimeout(() => {
                  globalThis.__timerFiredAt = Date.now();
                }, 50);
                'scheduled'
                "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    // No foreground traffic while the timer is pending: the driver must be
    // woken by the runtime schedular itself, well before the 1s fallback tick.
    tokio::time::sleep(Duration::from_millis(400)).await;

    let elapsed = engine
        .eval(
            JsCode::Code(
                "globalThis.__timerFiredAt > 0 \
                 ? globalThis.__timerFiredAt - globalThis.__timerStart : -1"
                    .to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    let ms = match elapsed {
        JsValue::Integer(ms) => ms as f64,
        JsValue::Float(ms) => ms,
        other => panic!("unexpected eval result: {other:?}"),
    };
    assert!(
        ms >= 0.0,
        "detached timer did not fire during the idle window"
    );
    assert!(
        ms < 350.0,
        "detached timer fired too late ({ms} ms); driver was likely only \
         woken by the fallback poll"
    );

    engine.close().await.unwrap();
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn explicit_job_error_contains_original_javascript_exception() {
    let runtime = JsAsyncRuntime::new().unwrap();
    runtime.stop_driver().await;
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
        let errors = engine.drain_unhandled_job_errors();
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
        let errors = engine.drain_unhandled_job_errors();
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
async fn timer_callback_error_does_not_break_later_timers() {
    let engine = JsEngine::create(Some(JsBuiltinOptions::essential()), None, None)
        .await
        .unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .eval(
            JsCode::Code(
                r#"
                setTimeout(() => {
                  throw new Error('fjs recoverable timer failure');
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
        let errors = engine.drain_unhandled_job_errors();
        if errors
            .iter()
            .any(|error| error.contains("fjs recoverable timer failure"))
        {
            break;
        }
        assert!(Instant::now() < deadline, "timer error was not queued");
        tokio::time::sleep(Duration::from_millis(20)).await;
    }

    engine
        .eval(
            JsCode::Code(
                r#"
                setTimeout(() => {
                  globalThis.__fjsTimerRecovered = true;
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
        let done = engine
            .eval(
                JsCode::Code("globalThis.__fjsTimerRecovered === true".to_string()),
                None,
            )
            .await
            .unwrap();
        if matches!(done, JsValue::Boolean(true)) {
            break;
        }
        assert!(
            Instant::now() < deadline,
            "runtime did not recover after timer callback error"
        );
        tokio::time::sleep(Duration::from_millis(20)).await;
    }

    engine.close().await.unwrap();
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn interval_callback_error_does_not_break_later_ticks() {
    let engine = JsEngine::create(Some(JsBuiltinOptions::essential()), None, None)
        .await
        .unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .eval(
            JsCode::Code(
                r#"
                globalThis.__fjsIntervalTicks = 0;
                const interval = setInterval(() => {
                  globalThis.__fjsIntervalTicks += 1;
                  if (globalThis.__fjsIntervalTicks === 1) {
                    throw new Error('fjs interval recoverable failure');
                  }
                  if (globalThis.__fjsIntervalTicks >= 3) {
                    clearInterval(interval);
                  }
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
        let errors = engine.drain_unhandled_job_errors();
        if errors
            .iter()
            .any(|error| error.contains("fjs interval recoverable failure"))
        {
            break;
        }
        assert!(Instant::now() < deadline, "interval error was not queued");
        tokio::time::sleep(Duration::from_millis(20)).await;
    }

    let deadline = Instant::now() + Duration::from_secs(2);
    loop {
        let ticks = engine
            .eval(
                JsCode::Code("globalThis.__fjsIntervalTicks".to_string()),
                None,
            )
            .await
            .unwrap();
        if matches!(ticks, JsValue::Integer(value) if value >= 3) {
            break;
        }
        assert!(
            Instant::now() < deadline,
            "interval did not continue after callback error"
        );
        tokio::time::sleep(Duration::from_millis(20)).await;
    }

    engine.close().await.unwrap();
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn engine_surfaces_unhandled_background_error_on_next_operation() {
    let engine = JsEngine::create(Some(JsBuiltinOptions::essential()), None, None)
        .await
        .unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .eval(
            JsCode::Code(
                r#"
                setTimeout(() => {
                  throw new Error('fjs automatic background error');
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
    let error = loop {
        match engine.eval(JsCode::Code("1 + 1".to_string()), None).await {
            Ok(_) => {
                assert!(
                    Instant::now() < deadline,
                    "background error was not surfaced automatically"
                );
                tokio::time::sleep(Duration::from_millis(20)).await;
            }
            Err(error) => break error.to_string(),
        }
    };

    assert!(error.contains("fjs automatic background error"));
    engine.close().await.unwrap();
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn detached_promise_error_caught_in_javascript_is_not_surfaced_to_dart() {
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .eval(
            JsCode::Code(
                r#"
                Promise.resolve()
                  .then(() => {
                    throw new Error('fjs handled detached failure');
                  })
                  .catch((error) => {
                    globalThis.__fjsHandledDetachedFailure = String(error);
                  });
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
        let result = engine
            .eval(
                JsCode::Code(
                    "globalThis.__fjsHandledDetachedFailure?.includes('fjs handled detached failure') === true"
                        .to_string(),
                ),
                None,
            )
            .await
            .unwrap();
        if matches!(result, JsValue::Boolean(true)) {
            break;
        }
        assert!(
            Instant::now() < deadline,
            "JavaScript .catch() did not observe detached failure"
        );
        tokio::time::sleep(Duration::from_millis(20)).await;
    }

    engine
        .eval(JsCode::Code("1 + 1".to_string()), None)
        .await
        .unwrap();
    engine.close().await.unwrap();
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn engine_close_surfaces_unhandled_background_error() {
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .runtime_for_test()
        .driver
        .push_error("fjs close background error".to_string());

    let error = engine.close().await.unwrap_err().to_string();
    assert!(error.contains("fjs close background error"));
    assert!(engine.closed());
    assert!(!engine.driver_running().await.unwrap());
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn engine_close_surfaces_background_timer_error_raised_during_teardown() {
    let engine = JsEngine::create(Some(JsBuiltinOptions::essential()), None, None)
        .await
        .unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .eval(
            JsCode::Code(
                r#"
                setTimeout(() => {
                  throw new Error('fjs close teardown timer failure');
                }, 10);
                'scheduled'
                "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    let error = engine.close().await.unwrap_err().to_string();
    assert!(error.contains("fjs close teardown timer failure"));
    assert!(engine.closed());
    assert!(!engine.driver_running().await.unwrap());
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn engine_direct_eval_error_is_not_replayed_as_background_error() {
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let error = engine
        .eval(
            JsCode::Code(
                r#"
                function recurse() {
                  return recurse() + 1;
                }
                recurse();
                "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap_err()
        .to_string();
    assert!(error.contains("Maximum call stack size exceeded"));

    engine.close().await.unwrap();
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn engine_foreground_error_does_not_acknowledge_detached_background_promise_error() {
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let error = engine
        .eval(
            JsCode::Code(
                r#"
                Promise.reject(new Error('fjs duplicate'));
                throw new Error('fjs duplicate');
                "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap_err()
        .to_string();
    assert!(error.contains("fjs duplicate"));

    let close_error = engine.close().await.unwrap_err().to_string();
    assert!(close_error.contains("fjs duplicate"));
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn engine_call_rejected_promise_error_is_not_replayed_as_background_error() {
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .evaluate_module(JsModule::code(
            "/foreground-call-error".to_string(),
            "export async function run() { throw new Error('fjs call foreground failure'); }"
                .to_string(),
        ))
        .await
        .unwrap();

    let error = engine
        .call(
            "/foreground-call-error".to_string(),
            "run".to_string(),
            None,
        )
        .await
        .unwrap_err()
        .to_string();
    assert!(error.contains("fjs call foreground failure"));

    engine.close().await.unwrap();
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn async_context_eval_function_rejected_promise_error_is_not_replayed_as_background_error() {
    let runtime = JsAsyncRuntime::create(
        None,
        Some(vec![JsModule::code(
            "/foreground-context-error".to_string(),
            "export async function run() { throw new Error('fjs context foreground failure'); }"
                .to_string(),
        )]),
    )
    .await
    .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    let result = context
        .eval_function(
            "/foreground-context-error".to_string(),
            "run".to_string(),
            None,
        )
        .await;
    let error = match result {
        JsResult::Err(error) => error.to_string(),
        JsResult::Ok(value) => panic!("expected foreground error, got {value:?}"),
    };
    assert!(error.contains("fjs context foreground failure"));

    let result = context.eval("1 + 1".to_string()).await;
    assert!(result.is_ok(), "foreground error was replayed: {result:?}");
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
async fn async_runtime_starts_background_driver_automatically() {
    let runtime = JsAsyncRuntime::create(Some(JsBuiltinOptions::essential()), None)
        .await
        .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    let scheduled = context
        .eval(
            r#"
            setTimeout(() => {
              globalThis.__fjsAutomaticDriverTimerDone = true;
            }, 10);
            "scheduled";
            "#
            .to_string(),
        )
        .await;
    assert!(matches!(scheduled, JsResult::Ok(JsValue::String(ref value)) if value == "scheduled"));

    let deadline = Instant::now() + Duration::from_secs(2);
    let mut fired = false;
    while Instant::now() < deadline {
        let result = context
            .eval("globalThis.__fjsAutomaticDriverTimerDone === true".to_string())
            .await;
        if matches!(result, JsResult::Ok(JsValue::Boolean(true))) {
            fired = true;
            break;
        }
        tokio::time::sleep(Duration::from_millis(20)).await;
    }

    runtime.idle().await;
    assert!(fired, "automatic background driver did not fire timer");
    runtime.stop_driver().await;
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn async_context_surfaces_unhandled_background_error_automatically() {
    let runtime = JsAsyncRuntime::create(Some(JsBuiltinOptions::essential()), None)
        .await
        .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    let scheduled = context
        .eval(
            r#"
            setTimeout(() => {
              throw new Error('fjs context background error');
            }, 10);
            "scheduled";
            "#
            .to_string(),
        )
        .await;
    assert!(matches!(scheduled, JsResult::Ok(JsValue::String(ref value)) if value == "scheduled"));

    let deadline = Instant::now() + Duration::from_secs(2);
    let error = loop {
        match context.eval("1 + 1".to_string()).await {
            JsResult::Ok(_) => {
                assert!(
                    Instant::now() < deadline,
                    "context background error was not surfaced automatically"
                );
                tokio::time::sleep(Duration::from_millis(20)).await;
            }
            JsResult::Err(error) => break error.to_string(),
        }
    };

    assert!(error.contains("fjs context background error"));
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
async fn runtime_driver_stop_returns_and_allows_restart() {
    let runtime = JsAsyncRuntime::create(Some(JsBuiltinOptions::essential()), None)
        .await
        .unwrap();

    runtime.start_driver().await;
    assert!(runtime.driver_running().await);

    tokio::time::timeout(Duration::from_secs(2), runtime.stop_driver())
        .await
        .expect("stop_driver should not hang");
    assert!(!runtime.driver_running().await);

    runtime.start_driver().await;
    assert!(runtime.driver_running().await);

    tokio::time::timeout(Duration::from_secs(2), runtime.stop_driver())
        .await
        .expect("restarted driver should stop cleanly");
    assert!(!runtime.driver_running().await);
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn restarted_runtime_driver_progresses_timer_scheduled_while_stopped() {
    let runtime = JsAsyncRuntime::create(Some(JsBuiltinOptions::essential()), None)
        .await
        .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    runtime.start_driver().await;
    runtime.stop_driver().await;

    let scheduled = context
        .eval(
            r#"
            setTimeout(() => {
              globalThis.__fjsRestartedDriverTimerDone = true;
            }, 10);
            "scheduled";
            "#
            .to_string(),
        )
        .await;
    assert!(matches!(scheduled, JsResult::Ok(JsValue::String(ref value)) if value == "scheduled"));

    runtime.start_driver().await;

    let deadline = Instant::now() + Duration::from_secs(2);
    loop {
        let result = context
            .eval("globalThis.__fjsRestartedDriverTimerDone === true".to_string())
            .await;
        if matches!(result, JsResult::Ok(JsValue::Boolean(true))) {
            break;
        }
        assert!(
            Instant::now() < deadline,
            "restarted background driver did not fire stopped timer"
        );
        tokio::time::sleep(Duration::from_millis(20)).await;
    }

    runtime.stop_driver().await;
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
