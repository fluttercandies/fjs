//! # Engine Tests
//!
//! Tests for the high-level JsEngine API including initialization,
//! evaluation, module management, and bridge communication.

use crate::api::bytecode::JsBytecode;
use crate::api::engine::JsEngine;
use crate::api::error::JsResult;
use crate::api::module::GlobalAttachment;
use crate::api::runtime::{JsAsyncContext, JsAsyncRuntime};
use crate::api::source::{
    JsBuiltinOptions, JsCode, JsModule, JsModuleBytecode, JsScriptBytecode, JsScriptBytecodeOptions,
};
use crate::api::value::JsValue;
use std::sync::atomic::AtomicBool;
use std::sync::{Arc, Condvar, Mutex, OnceLock};

fn failing_global_attachment(_ctx: &rquickjs::Ctx<'_>) -> rquickjs::Result<()> {
    Err(rquickjs::Error::new_from_js_message(
        "global attachment",
        "context",
        "forced failure for init rollback",
    ))
}

#[derive(Default)]
struct BlockingInitState {
    enabled: bool,
    started: bool,
    release: bool,
}

static BLOCKING_INIT_ATTACHMENT: OnceLock<(Mutex<BlockingInitState>, Condvar)> = OnceLock::new();

fn blocking_global_attachment(_ctx: &rquickjs::Ctx<'_>) -> rquickjs::Result<()> {
    let (lock, condvar) = BLOCKING_INIT_ATTACHMENT
        .get_or_init(|| (Mutex::new(BlockingInitState::default()), Condvar::new()));
    let mut state = lock.lock().unwrap();

    if !state.enabled {
        return Ok(());
    }

    state.started = true;
    condvar.notify_all();

    while !state.release {
        state = condvar.wait(state).unwrap();
    }

    state.enabled = false;
    Ok(())
}

fn prepare_blocking_init_attachment() {
    let (lock, _) = BLOCKING_INIT_ATTACHMENT
        .get_or_init(|| (Mutex::new(BlockingInitState::default()), Condvar::new()));
    let mut state = lock.lock().unwrap();
    *state = BlockingInitState {
        enabled: true,
        started: false,
        release: false,
    };
}

fn wait_for_blocking_init_start() {
    let (lock, condvar) = BLOCKING_INIT_ATTACHMENT
        .get_or_init(|| (Mutex::new(BlockingInitState::default()), Condvar::new()));
    let mut state = lock.lock().unwrap();
    while !state.started {
        state = condvar.wait(state).unwrap();
    }
}

fn release_blocking_init_attachment() {
    let (lock, condvar) = BLOCKING_INIT_ATTACHMENT
        .get_or_init(|| (Mutex::new(BlockingInitState::default()), Condvar::new()));
    let mut state = lock.lock().unwrap();
    state.release = true;
    condvar.notify_all();
}

// ============================================================================
// Engine Lifecycle Tests
// ============================================================================

#[tokio::test]
async fn test_engine_create() {
    let engine = JsEngine::create(None, None, None).await;
    assert!(engine.is_ok());
}

#[tokio::test]
async fn test_engine_create_owns_default_runtime_and_context() {
    let engine = JsEngine::create(None, None, None).await.unwrap();

    engine.init_without_bridge().await.unwrap();
    let result = engine
        .eval(JsCode::Code("1 + 1".to_string()), None)
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(2)));
}

#[tokio::test]
async fn test_engine_create_owns_configured_runtime_and_context() {
    let engine = JsEngine::create(Some(JsBuiltinOptions::essential()), None, None)
        .await
        .unwrap();

    engine.init_without_bridge().await.unwrap();
    let result = engine
        .eval(JsCode::Code("typeof setTimeout".to_string()), None)
        .await
        .unwrap();

    assert!(matches!(result, JsValue::String(ref value) if value == "function"));
}

#[tokio::test]
async fn test_engine_create_applies_runtime_options_before_init() {
    let engine = JsEngine::create(
        Some(JsBuiltinOptions::essential()),
        None,
        Some(crate::api::engine::JsEngineRuntimeOptions {
            memory_limit: Some(1024 * 1024),
            gc_threshold: Some(256 * 1024),
            max_stack_size: Some(128 * 1024),
            info: Some("engine-runtime".to_string()),
        }),
    )
    .await
    .unwrap();

    let usage = engine.memory_usage().await.unwrap();
    assert!(usage.total_memory() >= 0);
}

#[tokio::test]
async fn test_engine_initial_state() {
    let engine = JsEngine::create(None, None, None).await.unwrap();

    assert!(!engine.closed());
    assert!(!engine.running());
}

#[tokio::test]
async fn test_engine_runtime_proxy_methods_work_before_init() {
    let engine = JsEngine::create(None, None, None).await.unwrap();

    let pending = engine.is_job_pending().await.unwrap();
    let usage = engine.memory_usage().await.unwrap();
    engine.set_memory_limit(1024 * 1024).await.unwrap();
    engine.set_gc_threshold(256 * 1024).await.unwrap();
    engine.set_max_stack_size(128 * 1024).await.unwrap();
    engine.set_info("before-init".to_string()).await.unwrap();
    engine.run_gc().await.unwrap();
    engine.idle().await.unwrap();
    let progressed = engine.execute_pending_job().await.unwrap();

    assert!(!pending);
    assert!(usage.total_memory() >= 0);
    assert!(!progressed);
}

#[tokio::test]
async fn test_engine_init_without_bridge() {
    let engine = JsEngine::create(None, None, None).await.unwrap();

    let result = engine.init_without_bridge().await;
    assert!(result.is_ok());
    assert!(engine.running());
    assert!(!engine.closed());
}

#[tokio::test]
async fn test_engine_init_failure_rolls_back_state() {
    let runtime = JsAsyncRuntime {
        rt: rquickjs::AsyncRuntime::new().unwrap(),
        global_attachment: Some(
            GlobalAttachment::default().add_function(failing_global_attachment),
        ),
        driver: crate::runtime::driver::DriverController::default(),
        cleaned: Arc::new(AtomicBool::new(false)),
        runtime_lifetime: Arc::new(()),
    };
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new_for_test(runtime, context);

    let first_error = engine.init_without_bridge().await.unwrap_err();
    assert!(
        first_error
            .to_string()
            .contains("Failed to attach global context")
    );
    assert!(!engine.running());

    let second_error = engine.init_without_bridge().await.unwrap_err();
    assert!(
        second_error
            .to_string()
            .contains("Failed to attach global context")
    );
    assert!(!engine.running());
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn test_engine_runtime_proxy_methods_fail_while_initializing() {
    prepare_blocking_init_attachment();

    let runtime = JsAsyncRuntime {
        rt: rquickjs::AsyncRuntime::new().unwrap(),
        global_attachment: Some(
            GlobalAttachment::default().add_function(blocking_global_attachment),
        ),
        driver: crate::runtime::driver::DriverController::default(),
        cleaned: Arc::new(AtomicBool::new(false)),
        runtime_lifetime: Arc::new(()),
    };
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = std::sync::Arc::new(JsEngine::new_for_test(runtime, context));

    let init_engine = engine.clone();
    let init_task = tokio::spawn(async move { init_engine.init_without_bridge().await });

    tokio::task::spawn_blocking(wait_for_blocking_init_start)
        .await
        .unwrap();

    let usage_error = engine.memory_usage().await;
    assert!(matches!(usage_error, Err(ref error) if error.to_string().contains("initializing")));

    let limit_error = engine.set_memory_limit(1024).await.unwrap_err();
    assert!(limit_error.to_string().contains("initializing"));

    let close_error = engine.close().await.unwrap_err();
    assert!(close_error.to_string().contains("initializing"));

    release_blocking_init_attachment();
    init_task.await.unwrap().unwrap();
}

#[tokio::test]
async fn test_engine_init_with_bridge() {
    let engine = JsEngine::create(None, None, None).await.unwrap();

    let result = engine
        .init(|value| {
            Box::pin(async move {
                // Echo back the value
                JsResult::Ok(value)
            })
        })
        .await;

    assert!(result.is_ok());
    assert!(engine.running());
    engine.close().await.unwrap();
}

#[tokio::test]
async fn test_engine_double_init_fails() {
    let engine = JsEngine::create(None, None, None).await.unwrap();

    let result1 = engine.init_without_bridge().await;
    assert!(result1.is_ok());

    let result2 = engine.init_without_bridge().await;
    assert!(result2.is_err());
}

#[tokio::test]
async fn test_engine_close() {
    let engine = JsEngine::create(None, None, None).await.unwrap();

    engine.init_without_bridge().await.unwrap();
    let result = engine.close().await;

    assert!(result.is_ok());
    assert!(engine.closed());
    assert!(!engine.running());
}

#[tokio::test]
async fn test_engine_double_close_is_idempotent() {
    let engine = JsEngine::create(None, None, None).await.unwrap();

    engine.init_without_bridge().await.unwrap();
    engine.close().await.unwrap();

    let result = engine.close().await;
    assert!(result.is_ok());
    assert!(engine.closed());
    assert!(!engine.running());
}

#[tokio::test]
async fn test_engine_close_marks_engine_closed() {
    let engine = JsEngine::create(None, None, None).await.unwrap();

    engine.init_without_bridge().await.unwrap();
    engine.close().await.unwrap();

    assert!(engine.closed());
    assert!(!engine.running());
}

#[tokio::test]
async fn test_engine_close_drains_pending_runtime_work() {
    let engine = JsEngine::create(Some(JsBuiltinOptions::essential()), None, None)
        .await
        .unwrap();
    engine.init_without_bridge().await.unwrap();

    let scheduled = engine
        .eval(
            JsCode::Code(
                r#"
                    setTimeout(() => {
                        globalThis.__close_timer_fired = true;
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
    assert!(engine.is_job_pending().await.unwrap());

    engine.close().await.unwrap();

    assert!(!engine.runtime_for_test().is_job_pending().await);
}

#[tokio::test]
async fn test_engine_runtime_proxy_methods_fail_after_close() {
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.close().await.unwrap();

    assert!(engine.memory_usage().await.is_err());
    assert!(engine.set_memory_limit(1024).await.is_err());
    assert!(engine.run_gc().await.is_err());
}

// ============================================================================
// Engine Evaluation Tests
// ============================================================================

#[tokio::test]
async fn test_engine_eval_simple() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine.eval(JsCode::Code("1 + 1".to_string()), None).await;
    assert!(result.is_ok());
    let value = result.unwrap();
    assert!(matches!(value, JsValue::Integer(2)));
}

#[tokio::test]
async fn test_engine_eval_string() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(JsCode::Code("'hello world'".to_string()), None)
        .await;
    assert!(result.is_ok());
    let value = result.unwrap();
    assert!(matches!(value, JsValue::String(s) if s == "hello world"));
}

#[tokio::test]
async fn test_engine_eval_async() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(JsCode::Code("Promise.resolve(42)".to_string()), None)
        .await;
    assert!(result.is_ok());
    let value = result.unwrap();
    assert!(matches!(value, JsValue::Integer(42)));
}

#[tokio::test]
async fn test_engine_eval_does_not_implicitly_idle_runtime() {
    let engine = JsEngine::create(Some(JsBuiltinOptions::essential()), None, None)
        .await
        .unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                r#"
                    setTimeout(() => {
                        globalThis.__engine_timer_fired = true;
                    }, 10);
                    'scheduled'
                "#
                .to_string(),
            ),
            None,
        )
        .await;

    assert!(matches!(result, Ok(JsValue::String(ref value)) if value == "scheduled"));
    assert!(engine.is_job_pending().await.unwrap());

    let before_idle = engine
        .eval(
            JsCode::Code("globalThis.__engine_timer_fired ?? false".to_string()),
            None,
        )
        .await;
    assert!(matches!(before_idle, Ok(JsValue::Boolean(false))));

    engine.idle().await.unwrap();

    let after_idle = engine
        .eval(
            JsCode::Code("globalThis.__engine_timer_fired".to_string()),
            None,
        )
        .await;
    assert!(matches!(after_idle, Ok(JsValue::Boolean(true))));
}

#[tokio::test]
async fn test_engine_eval_before_init_fails() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();

    let result = engine.eval(JsCode::Code("1 + 1".to_string()), None).await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_engine_eval_after_close_fails() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();

    engine.init_without_bridge().await.unwrap();
    engine.close().await.unwrap();

    let result = engine.eval(JsCode::Code("1 + 1".to_string()), None).await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_engine_eval_syntax_error() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(JsCode::Code("function {".to_string()), None)
        .await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_engine_eval_runtime_error() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(JsCode::Code("undefinedVariable".to_string()), None)
        .await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_engine_eval_throw_error() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code("throw new Error('test error')".to_string()),
            None,
        )
        .await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_engine_eval_rejected_promise() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code("Promise.reject(new Error('rejected'))".to_string()),
            None,
        )
        .await;
    assert!(result.is_err());
}

// ============================================================================
// Engine Module Tests
// ============================================================================

#[tokio::test]
async fn test_engine_declare_new_module() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let module = JsModule::code(
        "test-module".to_string(),
        "export const value = 42;".to_string(),
    );

    let result = engine.declare_new_module(module).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_engine_declare_new_modules() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let modules = vec![
        JsModule::code("module1".to_string(), "export const a = 1;".to_string()),
        JsModule::code("module2".to_string(), "export const b = 2;".to_string()),
    ];

    let result = engine.declare_new_modules(modules).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_engine_declare_new_modules_rejects_duplicate_names() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let error = engine
        .declare_new_modules(vec![
            JsModule::code("dup".to_string(), "export const a = 1;".to_string()),
            JsModule::code("dup".to_string(), "export const b = 2;".to_string()),
        ])
        .await
        .unwrap_err();

    assert!(
        error
            .to_string()
            .contains("Duplicate module name in request")
    );
}

#[tokio::test]
async fn test_engine_evaluate_module() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let module = JsModule::code(
        "eval-module".to_string(),
        "export const value = 42; export default value;".to_string(),
    );

    let result = engine.evaluate_module(module).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_engine_compile_module_bytecode_roundtrip_declare_and_import() {
    let bytecode = JsBytecode::compile(
        JsModule::code(
            "bytecode-module".to_string(),
            "export function add(a, b) { return a + b; }".to_string(),
        ),
        None,
    )
    .await
    .unwrap();
    assert_eq!(bytecode.name, "bytecode-module");
    assert!(!bytecode.bytes.is_empty());

    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    engine.declare_new_bytecode_module(bytecode).await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                "const { add } = await import('bytecode-module'); add(20, 22)".to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(42)));
}

#[tokio::test]
async fn test_compile_module_bytecode_reports_quickjs_syntax_error() {
    let error = JsBytecode::compile(
        JsModule::code(
            "invalid-module-bytecode.js".to_string(),
            "export const = ;".to_string(),
        ),
        None,
    )
    .await
    .unwrap_err()
    .to_string();

    assert!(
        error.contains("Failed to compile module 'invalid-module-bytecode.js'"),
        "{error}"
    );
    assert!(error.contains("variable name expected"), "{error}");
    assert!(
        !error.contains("Exception generated by QuickJS")
            && !error.contains("Exception generated by quickjs"),
        "{error}"
    );
}

#[tokio::test]
async fn test_compile_module_bundle_reports_quickjs_syntax_error() {
    let error = JsBytecode::compile_module_bundle(
        vec![JsModule::code(
            "bundle/invalid.js".to_string(),
            "export function broken( {".to_string(),
        )],
        None,
        None,
    )
    .await
    .unwrap_err()
    .to_string();

    assert!(
        error.contains("Failed to compile bundle module 'bundle/invalid.js'"),
        "{error}"
    );
    assert!(error.contains("invalid property name"), "{error}");
    assert!(
        !error.contains("Exception generated by QuickJS")
            && !error.contains("Exception generated by quickjs"),
        "{error}"
    );
}

#[tokio::test]
async fn test_engine_compile_module_bytecode_is_side_effect_free() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let module_name = "isolated-bytecode-module".to_string();
    let bytecode = JsBytecode::compile(
        JsModule::code(module_name.clone(), "export default 99;".to_string()),
        None,
    )
    .await
    .unwrap();

    assert_eq!(bytecode.name, module_name);

    let declared = engine
        .is_module_declared("isolated-bytecode-module".to_string())
        .await
        .unwrap();
    assert!(!declared);

    let import_result = engine
        .eval(
            JsCode::Code("await import('isolated-bytecode-module')".to_string()),
            None,
        )
        .await;
    assert!(import_result.is_err());
}

#[tokio::test]
async fn test_engine_dynamic_module_loader_reports_quickjs_syntax_error() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .declare_new_module(JsModule::code(
            "dynamic-invalid.js".to_string(),
            "export const = ;".to_string(),
        ))
        .await
        .unwrap();

    let error = engine
        .eval(
            JsCode::Code("await import('dynamic-invalid.js')".to_string()),
            None,
        )
        .await
        .unwrap_err()
        .to_string();

    assert!(error.contains("variable name expected"), "{error}");
    assert!(
        !error.contains("Exception generated by QuickJS")
            && !error.contains("Exception generated by quickjs"),
        "{error}"
    );
}

#[tokio::test]
async fn test_engine_evaluate_bytecode_module_roundtrip() {
    let bytecode = JsBytecode::compile(
        JsModule::code(
            "bytecode-evaluated".to_string(),
            "export const value = 7; export default value;".to_string(),
        ),
        None,
    )
    .await
    .unwrap();

    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let evaluation = engine
        .evaluate_bytecode_module(bytecode.clone())
        .await
        .unwrap();
    assert!(matches!(evaluation, JsValue::None));

    let imported = engine
        .eval(
            JsCode::Code(
                "const { default: value } = await import('bytecode-evaluated'); value".to_string(),
            ),
            None,
        )
        .await
        .unwrap();
    assert!(matches!(imported, JsValue::Integer(7)));

    let redeclare = engine.declare_new_bytecode_module(bytecode).await;
    assert!(redeclare.is_err());
    assert!(
        redeclare
            .unwrap_err()
            .to_string()
            .contains("cannot be redefined")
    );
}

#[tokio::test]
async fn test_engine_bytecode_module_name_mismatch_fails_on_declare() {
    let bytecode = JsBytecode::compile(
        JsModule::code(
            "embedded-bytecode-name".to_string(),
            "export default 1;".to_string(),
        ),
        None,
    )
    .await
    .unwrap();

    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let error = engine
        .declare_new_bytecode_module(JsModuleBytecode::new(
            "declared-bytecode-name".to_string(),
            bytecode.bytes,
        ))
        .await
        .unwrap_err();
    assert!(error.to_string().contains("Bytecode module name mismatch"));
}

#[tokio::test]
async fn test_engine_invalid_bytecode_fails_on_declare() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let error = engine
        .declare_new_bytecode_module(JsModuleBytecode::new(
            "invalid-bytecode.js".to_string(),
            vec![0, 1, 2, 3, 4],
        ))
        .await
        .unwrap_err();
    assert!(
        error
            .to_string()
            .contains("Failed to read bytecode module 'invalid-bytecode.js'")
    );
}

#[tokio::test]
async fn test_engine_bytecode_modules_support_relative_imports() {
    let dep = JsBytecode::compile(
        JsModule::code(
            "pkg/dep.js".to_string(),
            "export const value = 42;".to_string(),
        ),
        None,
    )
    .await
    .unwrap();
    let main = JsBytecode::compile(
        JsModule::code(
            "pkg/main.js".to_string(),
            "import { value } from './dep.js'; export default value;".to_string(),
        ),
        None,
    )
    .await
    .unwrap();

    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .declare_new_bytecode_modules(vec![dep, main])
        .await
        .unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                "const { default: value } = await import('pkg/main.js'); value".to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(42)));
}

#[tokio::test]
async fn test_engine_declare_new_bytecode_modules_rejects_duplicate_names() {
    let first = JsBytecode::compile(
        JsModule::code(
            "dup-bytecode".to_string(),
            "export const a = 1;".to_string(),
        ),
        None,
    )
    .await
    .unwrap();
    let second = JsBytecode::compile(
        JsModule::code(
            "dup-bytecode".to_string(),
            "export const b = 2;".to_string(),
        ),
        None,
    )
    .await
    .unwrap();

    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let error = engine
        .declare_new_bytecode_modules(vec![first, second])
        .await
        .unwrap_err();

    assert!(
        error
            .to_string()
            .contains("Duplicate module name in request")
    );
}

#[tokio::test]
async fn test_engine_declare_and_evaluate_bytecode_bundle() {
    let bundle = JsBytecode::compile_module_bundle(
        vec![
            JsModule::code(
                "bundle/dep.js".to_string(),
                "export const value = 21;".to_string(),
            ),
            JsModule::code(
                "bundle/main.js".to_string(),
                "import { value } from './dep.js'; export default value * 2;".to_string(),
            ),
        ],
        Some("bundle/main.js".to_string()),
        None,
    )
    .await
    .unwrap();

    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine.evaluate_bytecode_bundle(bundle).await.unwrap();
    assert!(matches!(result, JsValue::None));

    let imported = engine
        .eval(
            JsCode::Code(
                "const { default: value } = await import('bundle/main.js'); value".to_string(),
            ),
            None,
        )
        .await
        .unwrap();
    assert!(matches!(imported, JsValue::Integer(42)));
}

#[tokio::test]
async fn test_engine_compile_bytecode_bundle_rejects_missing_relative_dependency() {
    let error = JsBytecode::compile_module_bundle(
        vec![JsModule::code(
            "bundle/main.js".to_string(),
            "import { value } from './missing.js'; export default value;".to_string(),
        )],
        Some("bundle/main.js".to_string()),
        None,
    )
    .await
    .unwrap_err();

    assert!(
        error
            .to_string()
            .contains("relative bundle dependency not found")
    );
}

#[tokio::test]
async fn test_engine_evaluate_script_bytecode_roundtrip() {
    let script = JsBytecode::compile_script(
        "script-bytecode.js".to_string(),
        JsCode::Code(
            "globalThis.__fjs_script_value = 41 + 1; globalThis.__fjs_script_value".to_string(),
        ),
        None,
    )
    .await
    .unwrap();

    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine.evaluate_script_bytecode(script).await.unwrap();
    assert!(matches!(result, JsValue::Integer(42)));

    let reread = engine
        .eval(
            JsCode::Code("globalThis.__fjs_script_value".to_string()),
            None,
        )
        .await
        .unwrap();
    assert!(matches!(reread, JsValue::Integer(42)));
}

#[tokio::test]
async fn test_engine_evaluate_async_script_bytecode_roundtrip() {
    let script = JsBytecode::compile_script(
        "async-script-bytecode.js".to_string(),
        JsCode::Code("await Promise.resolve(42)".to_string()),
        Some(JsScriptBytecodeOptions {
            promise: Some(true),
            ..Default::default()
        }),
    )
    .await
    .unwrap();

    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine.evaluate_script_bytecode(script).await.unwrap();
    assert!(matches!(result, JsValue::Integer(42)));
}

#[tokio::test]
async fn test_compile_script_bytecode_accepts_source_with_null_bytes() {
    let mut source = b"const text = 'a".to_vec();
    source.push(0);
    source.extend_from_slice(b"b'; text.length");

    let script = JsBytecode::compile_script(
        "script-null-byte.js".to_string(),
        JsCode::Bytes(source),
        None,
    )
    .await
    .unwrap();

    JsBytecode::validate_script(script.clone()).await.unwrap();

    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine.evaluate_script_bytecode(script).await.unwrap();
    assert!(matches!(result, JsValue::Integer(3)));
}

#[tokio::test]
async fn test_validate_module_bytecode_accepts_matching_name() {
    let bytecode = JsBytecode::compile(
        JsModule::code("validated.js".to_string(), "export default 1;".to_string()),
        None,
    )
    .await
    .unwrap();

    JsBytecode::validate(bytecode).await.unwrap();
}

#[test]
fn test_validate_module_bytecode_sync_accepts_matching_name() {
    let bytecode = JsBytecode::compile_sync(
        JsModule::code(
            "validated-sync.js".to_string(),
            "export default 1;".to_string(),
        ),
        None,
    )
    .unwrap();

    JsBytecode::validate_sync(bytecode).unwrap();
}

#[tokio::test]
async fn test_validate_script_bytecode_accepts_matching_payload() {
    let script = JsBytecode::compile_script(
        "validated-script.js".to_string(),
        JsCode::Code("1 + 1".to_string()),
        None,
    )
    .await
    .unwrap();

    JsBytecode::validate_script(script).await.unwrap();
}

#[test]
fn test_validate_script_bytecode_sync_accepts_matching_payload() {
    let script = JsBytecode::compile_script_sync(
        "validated-script-sync.js".to_string(),
        JsCode::Code("1 + 1".to_string()),
        None,
    )
    .unwrap();

    JsBytecode::validate_script_sync(script).unwrap();
}

#[tokio::test]
async fn test_validate_bytecode_bundle_rejects_missing_entry() {
    let dep = JsBytecode::compile(
        JsModule::code(
            "bundle/dep.js".to_string(),
            "export const value = 1;".to_string(),
        ),
        None,
    )
    .await
    .unwrap();

    let bundle = crate::api::source::JsModuleBytecodeBundle::new(
        Some("bundle/main.js".to_string()),
        vec![dep],
    );

    let error = JsBytecode::validate_bundle(bundle).await.unwrap_err();
    assert!(
        error
            .to_string()
            .contains("Bundle entry 'bundle/main.js' is not present")
    );
}

#[tokio::test]
async fn test_validate_module_bytecode_rejects_name_mismatch() {
    let bytecode = JsBytecode::compile(
        JsModule::code("embedded.js".to_string(), "export default 1;".to_string()),
        None,
    )
    .await
    .unwrap();

    let error = JsBytecode::validate(JsModuleBytecode::new(
        "declared.js".to_string(),
        bytecode.bytes,
    ))
    .await
    .unwrap_err();
    assert!(error.to_string().contains("Bytecode module name mismatch"));
}

#[test]
fn test_validate_module_bytecode_sync_rejects_name_mismatch() {
    let bytecode = JsBytecode::compile_sync(
        JsModule::code(
            "embedded-sync.js".to_string(),
            "export default 1;".to_string(),
        ),
        None,
    )
    .unwrap();

    let error = JsBytecode::validate_sync(JsModuleBytecode::new(
        "declared-sync.js".to_string(),
        bytecode.bytes,
    ))
    .unwrap_err();
    assert!(error.to_string().contains("Bytecode module name mismatch"));
}

#[tokio::test]
async fn test_module_validation_rejects_script_bytecode() {
    let script = JsBytecode::compile_script(
        "not-a-module.js".to_string(),
        JsCode::Code("1 + 1".to_string()),
        None,
    )
    .await
    .unwrap();

    let error = JsBytecode::validate(JsModuleBytecode::new(
        "not-a-module.js".to_string(),
        script.bytes,
    ))
    .await
    .unwrap_err();
    assert!(error.to_string().contains("does not contain an ES module"));
}

#[tokio::test]
async fn test_script_validation_rejects_module_bytecode() {
    let module = JsBytecode::compile(
        JsModule::code(
            "actually-a-module.js".to_string(),
            "export default 1;".to_string(),
        ),
        None,
    )
    .await
    .unwrap();

    let error = JsBytecode::validate_script(JsScriptBytecode::new(
        "actually-a-module.js".to_string(),
        module.bytes,
    ))
    .await
    .unwrap_err();
    assert!(error.to_string().contains("contains an ES module"));
}

#[tokio::test]
async fn test_engine_declare_new_bytecode_module_rejects_script_bytecode() {
    let script = JsBytecode::compile_script(
        "script-in-module-slot.js".to_string(),
        JsCode::Code("1 + 1".to_string()),
        None,
    )
    .await
    .unwrap();

    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let error = engine
        .declare_new_bytecode_module(JsModuleBytecode::new(
            "script-in-module-slot.js".to_string(),
            script.bytes,
        ))
        .await
        .unwrap_err();

    assert!(error.to_string().contains("does not contain an ES module"));
}

#[tokio::test]
async fn test_engine_dynamic_module_relative_import() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .declare_new_modules(vec![
            JsModule::code(
                "pkg/dep.js".to_string(),
                "export const value = 42;".to_string(),
            ),
            JsModule::code(
                "pkg/main.js".to_string(),
                "import { value } from './dep.js'; export default value;".to_string(),
            ),
        ])
        .await
        .unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                "const { default: value } = await import('pkg/main.js'); value".to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(42)));
}

#[tokio::test]
async fn test_engine_dynamic_module_parent_relative_import() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .declare_new_modules(vec![
            JsModule::code(
                "pkg/dep.js".to_string(),
                "export const value = 7;".to_string(),
            ),
            JsModule::code(
                "pkg/nested/main.js".to_string(),
                "import { value } from '../dep.js'; export default value;".to_string(),
            ),
        ])
        .await
        .unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                "const { default: value } = await import('pkg/nested/main.js'); value".to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(7)));
}

#[tokio::test]
async fn test_engine_is_module_declared() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let module = JsModule::code(
        "check-module".to_string(),
        "export const x = 1;".to_string(),
    );
    engine.declare_new_module(module).await.unwrap();

    let exists = engine
        .is_module_declared("check-module".to_string())
        .await
        .unwrap();
    assert!(exists);

    let not_exists = engine
        .is_module_declared("non-existent".to_string())
        .await
        .unwrap();
    assert!(!not_exists);
}

#[tokio::test]
async fn test_engine_get_declared_modules() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let modules = vec![
        JsModule::code("mod-a".to_string(), "export const a = 1;".to_string()),
        JsModule::code("mod-b".to_string(), "export const b = 2;".to_string()),
    ];
    engine.declare_new_modules(modules).await.unwrap();

    let declared = engine.get_declared_modules().await.unwrap();
    assert_eq!(declared.len(), 2);
    assert_eq!(declared, vec!["mod-a".to_string(), "mod-b".to_string()]);
    assert!(declared.contains(&"mod-a".to_string()));
    assert!(declared.contains(&"mod-b".to_string()));
}

#[tokio::test]
async fn test_engine_get_available_modules() {
    let engine = JsEngine::create(
        Some(JsBuiltinOptions {
            path: Some(true),
            https: Some(true),
            ..Default::default()
        }),
        Some(vec![JsModule::code(
            "static-extra".to_string(),
            "export const value = 1;".to_string(),
        )]),
        None,
    )
    .await
    .unwrap();
    engine.init_without_bridge().await.unwrap();
    engine
        .declare_new_module(JsModule::code(
            "dynamic-extra".to_string(),
            "export const value = 2;".to_string(),
        ))
        .await
        .unwrap();

    let modules = engine.get_available_modules().await.unwrap();

    assert!(modules.contains(&"dynamic-extra".to_string()));
    assert!(modules.contains(&"https".to_string()));
    assert!(modules.contains(&"path".to_string()));
    assert!(modules.contains(&"static-extra".to_string()));
}

#[tokio::test]
async fn test_engine_is_module_available() {
    let engine = JsEngine::create(
        Some(JsBuiltinOptions {
            dgram: Some(true),
            ..Default::default()
        }),
        None,
        None,
    )
    .await
    .unwrap();
    engine.init_without_bridge().await.unwrap();
    engine
        .declare_new_module(JsModule::code(
            "dynamic-extra".to_string(),
            "export const value = 2;".to_string(),
        ))
        .await
        .unwrap();

    assert!(
        engine
            .is_module_available("dgram".to_string())
            .await
            .unwrap()
    );
    assert!(
        engine
            .is_module_available("dynamic-extra".to_string())
            .await
            .unwrap()
    );
    assert!(
        !engine
            .is_module_available("missing".to_string())
            .await
            .unwrap()
    );
}

#[tokio::test]
async fn test_engine_clear_pending_modules() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let module = JsModule::code(
        "clear-module".to_string(),
        "export const x = 1;".to_string(),
    );
    engine.declare_new_module(module).await.unwrap();

    let before = engine.get_declared_modules().await.unwrap();
    assert!(!before.is_empty());

    engine.clear_pending_modules().await.unwrap();

    let after = engine.get_declared_modules().await.unwrap();
    assert!(after.is_empty());

    let result = engine
        .eval(
            JsCode::Code("await import('clear-module')".to_string()),
            None,
        )
        .await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_engine_clear_pending_modules_keeps_loaded_modules() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .declare_new_modules(vec![
            JsModule::code(
                "loaded-module".to_string(),
                "export function value() { return 1; }".to_string(),
            ),
            JsModule::code(
                "pending-module".to_string(),
                "export const value = 2;".to_string(),
            ),
        ])
        .await
        .unwrap();

    let result = engine
        .call("loaded-module".to_string(), "value".to_string(), None)
        .await
        .unwrap();
    assert!(matches!(result, JsValue::Integer(1)));

    engine.clear_pending_modules().await.unwrap();

    let declared = engine.get_declared_modules().await.unwrap();
    assert_eq!(declared, vec!["loaded-module".to_string()]);

    let pending_exists = engine
        .is_module_declared("pending-module".to_string())
        .await
        .unwrap();
    assert!(!pending_exists);

    let loaded_available = engine
        .is_module_available("loaded-module".to_string())
        .await
        .unwrap();
    assert!(loaded_available);

    let pending_import = engine
        .eval(
            JsCode::Code("await import('pending-module')".to_string()),
            None,
        )
        .await;
    assert!(pending_import.is_err());
}

#[tokio::test]
async fn test_engine_redeclare_loaded_module_fails() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    engine
        .declare_new_module(JsModule::code(
            "sticky-module".to_string(),
            "export function value() { return 1; }".to_string(),
        ))
        .await
        .unwrap();

    let first = engine
        .call("sticky-module".to_string(), "value".to_string(), None)
        .await
        .unwrap();
    assert!(matches!(first, JsValue::Integer(1)));

    let redeclare = engine
        .declare_new_module(JsModule::code(
            "sticky-module".to_string(),
            "export function value() { return 2; }".to_string(),
        ))
        .await;
    assert!(redeclare.is_err());
    assert!(
        redeclare
            .unwrap_err()
            .to_string()
            .contains("cannot be redefined")
    );

    let second = engine
        .call("sticky-module".to_string(), "value".to_string(), None)
        .await
        .unwrap();
    assert!(matches!(second, JsValue::Integer(1)));
}

#[tokio::test]
async fn test_engine_evaluate_module_marks_module_as_loaded() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .evaluate_module(JsModule::code(
            "evaluated-module".to_string(),
            "export default 1;".to_string(),
        ))
        .await
        .unwrap();
    assert!(matches!(result, JsValue::None));

    let redeclare = engine
        .declare_new_module(JsModule::code(
            "evaluated-module".to_string(),
            "export default 2;".to_string(),
        ))
        .await;
    assert!(redeclare.is_err());
    assert!(
        redeclare
            .unwrap_err()
            .to_string()
            .contains("cannot be redefined")
    );
}

#[tokio::test]
async fn test_engine_call_module_function() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let module = JsModule::code(
        "math-utils".to_string(),
        "export function add(a, b) { return a + b; }".to_string(),
    );
    engine.declare_new_module(module).await.unwrap();

    let result = engine
        .call(
            "math-utils".to_string(),
            "add".to_string(),
            Some(vec![JsValue::Integer(3), JsValue::Integer(4)]),
        )
        .await;

    assert!(result.is_ok());
    let value = result.unwrap();
    assert!(matches!(value, JsValue::Integer(7)));
}

#[tokio::test]
async fn test_engine_call_async_function() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let module = JsModule::code(
        "async-utils".to_string(),
        "export async function asyncAdd(a, b) { return a + b; }".to_string(),
    );
    engine.declare_new_module(module).await.unwrap();

    let result = engine
        .call(
            "async-utils".to_string(),
            "asyncAdd".to_string(),
            Some(vec![JsValue::Integer(10), JsValue::Integer(20)]),
        )
        .await;

    assert!(result.is_ok());
    let value = result.unwrap();
    assert!(matches!(value, JsValue::Integer(30)));
}

#[tokio::test]
async fn test_engine_call_nonexistent_module() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .call("nonexistent".to_string(), "func".to_string(), None)
        .await;

    assert!(result.is_err());
}

#[tokio::test]
async fn test_engine_call_nonexistent_function() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let module = JsModule::code(
        "has-func".to_string(),
        "export function exists() { return 1; }".to_string(),
    );
    engine.declare_new_module(module).await.unwrap();

    let result = engine
        .call("has-func".to_string(), "notExists".to_string(), None)
        .await;

    assert!(result.is_err());
}

// ============================================================================
// Engine Bridge Tests
// ============================================================================

#[tokio::test]
async fn test_engine_bridge_call() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();

    engine
        .init(|value| {
            Box::pin(async move {
                // Double the integer if passed
                match value {
                    JsValue::Integer(n) => JsResult::Ok(JsValue::Integer(n * 2)),
                    _ => JsResult::Ok(value),
                }
            })
        })
        .await
        .unwrap();

    let result = engine
        .eval(JsCode::Code("fjs.bridge_call(21)".to_string()), None)
        .await;

    assert!(result.is_ok());
    let value = result.unwrap();
    assert!(matches!(value, JsValue::Integer(42)));
    engine.close().await.unwrap();
}

#[tokio::test]
async fn test_engine_bridge_call_with_object() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();

    engine
        .init(|value| {
            Box::pin(async move {
                // Return the value as-is
                JsResult::Ok(value)
            })
        })
        .await
        .unwrap();

    let result = engine
        .eval(
            JsCode::Code("fjs.bridge_call({name: 'test', value: 42})".to_string()),
            None,
        )
        .await;

    assert!(result.is_ok());
    let value = result.unwrap();
    assert!(value.is_object());
    engine.close().await.unwrap();
}

// ============================================================================
// Engine with Builtins Tests
// ============================================================================

#[tokio::test]
async fn test_engine_with_console_builtin() {
    let builtin = JsBuiltinOptions {
        console: Some(true),
        ..Default::default()
    };
    let engine = JsEngine::create(Some(builtin), None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    // Console should be available
    let result = engine
        .eval(
            JsCode::Code("typeof console.log === 'function'".to_string()),
            None,
        )
        .await;
    assert!(result.is_ok());
    let value = result.unwrap();
    assert!(matches!(value, JsValue::Boolean(true)));
}

#[tokio::test]
async fn test_engine_with_buffer_builtin() {
    let builtin = JsBuiltinOptions {
        buffer: Some(true),
        ..Default::default()
    };
    let engine = JsEngine::create(Some(builtin), None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    // Buffer should be available globally
    let result = engine
        .eval(
            JsCode::Code("typeof Buffer !== 'undefined'".to_string()),
            None,
        )
        .await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_engine_with_url_builtin() {
    let builtin = JsBuiltinOptions {
        url: Some(true),
        ..Default::default()
    };
    let engine = JsEngine::create(Some(builtin), None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    // URL should be available
    let result = engine
        .eval(
            JsCode::Code("new URL('https://example.com').hostname".to_string()),
            None,
        )
        .await;
    assert!(result.is_ok());
    let value = result.unwrap();
    assert!(matches!(value, JsValue::String(s) if s == "example.com"));
}

#[tokio::test]
async fn test_engine_with_path_builtin() {
    let builtin = JsBuiltinOptions {
        path: Some(true),
        ..Default::default()
    };
    let engine = JsEngine::create(Some(builtin), None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    // Path module should be importable
    let result = engine
        .eval(
            JsCode::Code(
                r#"
                const { default: path } = await import('path');
                path.join('a', 'b', 'c')
            "#
                .to_string(),
            ),
            None,
        )
        .await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_engine_with_crypto_builtin() {
    let builtin = JsBuiltinOptions {
        crypto: Some(true),
        ..Default::default()
    };
    let engine = JsEngine::create(Some(builtin), None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    // Crypto should be available
    let result = engine
        .eval(
            JsCode::Code("typeof crypto !== 'undefined'".to_string()),
            None,
        )
        .await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_engine_with_events_builtin() {
    let builtin = JsBuiltinOptions {
        events: Some(true),
        ..Default::default()
    };
    let engine = JsEngine::create(Some(builtin), None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    // EventEmitter should be available
    let result = engine
        .eval(
            JsCode::Code(
                r#"
                const { EventEmitter } = await import('events');
                typeof EventEmitter === 'function'
            "#
                .to_string(),
            ),
            None,
        )
        .await;
    assert!(result.is_ok());
}
