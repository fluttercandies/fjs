//! # Runtime Tests
//!
//! Tests for the JavaScript runtime and context management.
//! Covers synchronous and asynchronous runtimes, memory management,
//! and basic evaluation.

use crate::api::runtime::{JsAsyncContext, JsAsyncRuntime, JsContext, JsRuntime};
use crate::api::source::{JsBuiltinOptions, JsEvalOptions, JsModule};
use crate::api::value::JsValue;

// ============================================================================
// Synchronous Runtime Tests
// ============================================================================

#[test]
fn test_runtime_new() {
    let runtime = JsRuntime::new();
    assert!(runtime.is_ok());
}

#[test]
fn test_runtime_memory_usage() {
    let runtime = JsRuntime::new().unwrap();
    let usage = runtime.memory_usage();
    assert!(usage.total_memory() >= 0);
    assert!(usage.total_allocations() >= 0);
}

#[test]
fn test_runtime_memory_usage_summary() {
    let runtime = JsRuntime::new().unwrap();
    let usage = runtime.memory_usage();
    let summary = usage.summary();
    assert!(summary.contains("Memory:"));
    assert!(summary.contains("Objects:"));
    assert!(summary.contains("Functions:"));
    assert!(summary.contains("Strings:"));
}

#[test]
fn test_runtime_set_memory_limit() {
    let runtime = JsRuntime::new().unwrap();
    runtime.set_memory_limit(16 * 1024 * 1024); // 16 MB
    // Should not panic
}

#[test]
fn test_runtime_set_max_stack_size() {
    let runtime = JsRuntime::new().unwrap();
    runtime.set_max_stack_size(1024 * 1024); // 1 MB
    // Should not panic
}

#[test]
fn test_runtime_set_gc_threshold() {
    let runtime = JsRuntime::new().unwrap();
    runtime.set_gc_threshold(256 * 1024); // 256 KB
    // Should not panic
}

#[test]
fn test_runtime_run_gc() {
    let runtime = JsRuntime::new().unwrap();
    runtime.run_gc();
    // Should not panic
}

#[test]
fn test_runtime_is_job_pending() {
    let runtime = JsRuntime::new().unwrap();
    assert!(!runtime.is_job_pending());
}

#[test]
fn test_runtime_execute_pending_job_no_jobs() {
    let runtime = JsRuntime::new().unwrap();
    let result = runtime.execute_pending_job();
    assert!(result.is_ok());
    assert!(!result.unwrap());
}

#[test]
fn test_runtime_set_dump_flags() {
    let runtime = JsRuntime::new().unwrap();
    runtime.set_dump_flags(0);
    // Should not panic
}

#[test]
fn test_runtime_set_info() {
    let runtime = JsRuntime::new().unwrap();
    let result = runtime.set_info("test runtime".to_string());
    assert!(result.is_ok());
}

// ============================================================================
// Synchronous Context Tests
// ============================================================================

#[test]
fn test_context_from_runtime() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime);
    assert!(context.is_ok());
}

#[test]
fn test_context_eval_simple() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();
    let result = context.eval("1 + 1".to_string());
    assert!(result.is_ok());
    match result {
        crate::api::error::JsResult::Ok(v) => {
            assert!(matches!(v, JsValue::Integer(2)));
        }
        _ => panic!("Expected Ok result"),
    }
}

#[test]
fn test_context_eval_string() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();
    let result = context.eval("'hello'".to_string());
    assert!(result.is_ok());
    match result {
        crate::api::error::JsResult::Ok(v) => {
            assert!(matches!(v, JsValue::String(s) if s == "hello"));
        }
        _ => panic!("Expected Ok result"),
    }
}

#[test]
fn test_context_eval_boolean() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();
    let result = context.eval("true".to_string());
    assert!(result.is_ok());
    match result {
        crate::api::error::JsResult::Ok(v) => {
            assert!(matches!(v, JsValue::Boolean(true)));
        }
        _ => panic!("Expected Ok result"),
    }
}

#[test]
fn test_context_eval_array() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();
    let result = context.eval("[1, 2, 3]".to_string());
    assert!(result.is_ok());
    match result {
        crate::api::error::JsResult::Ok(v) => {
            assert!(v.is_array());
        }
        _ => panic!("Expected Ok result"),
    }
}

#[test]
fn test_context_eval_object() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();
    let result = context.eval("({a: 1, b: 2})".to_string());
    assert!(result.is_ok());
    match result {
        crate::api::error::JsResult::Ok(v) => {
            assert!(v.is_object());
        }
        _ => panic!("Expected Ok result"),
    }
}

#[test]
fn test_context_eval_syntax_error() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();
    let result = context.eval("function {".to_string());
    assert!(result.is_err());
}

#[test]
fn test_context_eval_reference_error() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();
    let result = context.eval("undefinedVariable".to_string());
    assert!(result.is_err());
}

#[test]
fn test_context_eval_type_error() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();
    let result = context.eval("null.property".to_string());
    assert!(result.is_err());
}

#[test]
fn test_context_eval_with_options() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();
    let options = JsEvalOptions::defaults();
    let result = context.eval_with_options("42".to_string(), options);
    assert!(result.is_ok());
}

#[test]
fn test_context_eval_with_promise_option_fails() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();
    let options = JsEvalOptions::with_promise();
    let result = context.eval_with_options("42".to_string(), options);
    // Promise not supported in sync context
    assert!(result.is_err());
}

#[test]
fn test_context_eval_global_scope() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // Set a global variable
    let _ = context.eval("globalThis.testVar = 42".to_string());

    // Read it back
    let result = context.eval("testVar".to_string());
    assert!(result.is_ok());
    match result {
        crate::api::error::JsResult::Ok(v) => {
            assert!(matches!(v, JsValue::Integer(42)));
        }
        _ => panic!("Expected Ok result"),
    }
}

#[test]
fn test_context_eval_function_call() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval(
        r#"
        function add(a, b) { return a + b; }
        add(3, 4)
    "#
        .to_string(),
    );
    assert!(result.is_ok());
    match result {
        crate::api::error::JsResult::Ok(v) => {
            assert!(matches!(v, JsValue::Integer(7)));
        }
        _ => panic!("Expected Ok result"),
    }
}

#[test]
fn test_context_eval_multiline() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval(
        r#"
        let x = 1;
        let y = 2;
        let z = 3;
        x + y + z
    "#
        .to_string(),
    );
    assert!(result.is_ok());
    match result {
        crate::api::error::JsResult::Ok(v) => {
            assert!(matches!(v, JsValue::Integer(6)));
        }
        _ => panic!("Expected Ok result"),
    }
}

#[test]
fn test_context_eval_date_uses_captured_intrinsics() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval(
        r#"
        const OriginalDate = Date;
        const date = new OriginalDate(1609459200000);
        Date.prototype.getTime = () => 1;
        globalThis.Date = function FakeDate() {};
        Date.prototype = { getTime() { return 2; } };
        date
    "#
        .to_string(),
    );

    assert!(matches!(
        result,
        crate::api::error::JsResult::Ok(JsValue::Date(1609459200000))
    ));
}

// ============================================================================
// Asynchronous Runtime Tests (using tokio)
// ============================================================================

#[tokio::test]
async fn test_async_runtime_new() {
    let runtime = JsAsyncRuntime::new();
    assert!(runtime.is_ok());
}

#[tokio::test]
async fn test_async_runtime_with_options_none() {
    let runtime = JsAsyncRuntime::create(None, None).await;
    assert!(runtime.is_ok());
}

#[tokio::test]
async fn test_async_runtime_with_builtin_essential() {
    let builtin = JsBuiltinOptions::essential();
    let runtime = JsAsyncRuntime::create(Some(builtin), None).await;
    assert!(runtime.is_ok());
}

#[tokio::test]
async fn test_async_runtime_with_builtin_all() {
    let builtin = JsBuiltinOptions::all();
    let runtime = JsAsyncRuntime::create(Some(builtin), None).await;
    assert!(runtime.is_ok());
}

#[tokio::test]
async fn test_async_runtime_with_additional_modules() {
    use crate::api::source::JsCode;
    let module = JsModule::new(
        "test-module".to_string(),
        JsCode::Code("export const value = 42;".to_string()),
    );
    let runtime = JsAsyncRuntime::create(None, Some(vec![module])).await;
    assert!(runtime.is_ok());
}

#[tokio::test]
async fn test_async_runtime_memory_operations() {
    let runtime = JsAsyncRuntime::new().unwrap();

    runtime.set_memory_limit(16 * 1024 * 1024).await;
    runtime.set_max_stack_size(1024 * 1024).await;
    runtime.set_gc_threshold(256 * 1024).await;

    let usage = runtime.memory_usage().await;
    assert!(usage.total_memory() >= 0);

    runtime.run_gc().await;
    // Should not panic
}

#[tokio::test]
async fn test_async_runtime_is_job_pending() {
    let runtime = JsAsyncRuntime::new().unwrap();
    assert!(!runtime.is_job_pending().await);
}

#[tokio::test]
async fn test_async_runtime_execute_pending_job() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let result = runtime.execute_pending_job().await;
    assert!(result.is_ok());
    assert!(!result.unwrap());
}

#[tokio::test]
async fn test_async_runtime_idle() {
    let runtime = JsAsyncRuntime::new().unwrap();
    runtime.idle().await;
    // Should not panic
}

#[tokio::test]
async fn test_async_context_eval_does_not_implicitly_idle_runtime() {
    let runtime = JsAsyncRuntime::create(Some(JsBuiltinOptions::essential()), None)
        .await
        .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    let result = context
        .eval(
            r#"
                setTimeout(() => {
                    globalThis.__fjs_timer_fired = true;
                }, 10);
                'scheduled'
            "#
            .to_string(),
        )
        .await;

    match result {
        crate::api::error::JsResult::Ok(JsValue::String(value)) => assert_eq!(value, "scheduled"),
        other => panic!("Expected string result, got {other:?}"),
    }

    assert!(runtime.is_job_pending().await);

    let before_idle = context
        .eval("globalThis.__fjs_timer_fired ?? false".to_string())
        .await;
    match before_idle {
        crate::api::error::JsResult::Ok(JsValue::Boolean(false)) => {}
        other => panic!("Expected timer to be pending before idle, got {other:?}"),
    }

    runtime.idle().await;

    let after_idle = context
        .eval("globalThis.__fjs_timer_fired".to_string())
        .await;
    match after_idle {
        crate::api::error::JsResult::Ok(JsValue::Boolean(true)) => {}
        other => panic!("Expected timer to fire after idle, got {other:?}"),
    }
}

#[tokio::test]
async fn test_async_runtime_set_info() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let result = runtime.set_info("test async runtime".to_string()).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_context_get_available_modules_includes_additional_modules() {
    let runtime = JsRuntime::create(
        Some(JsBuiltinOptions {
            path: Some(true),
            ..Default::default()
        }),
        Some(vec![JsModule::code(
            "test-extra".to_string(),
            "export const value = 1;".to_string(),
        )]),
    )
    .await
    .unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let modules = context.get_available_modules().unwrap();

    assert!(modules.contains(&"path".to_string()));
    assert!(modules.contains(&"test-extra".to_string()));
}

#[tokio::test]
async fn test_async_context_get_available_modules_includes_dynamic_modules() {
    let runtime = JsAsyncRuntime::create(
        Some(JsBuiltinOptions {
            dgram: Some(true),
            ..Default::default()
        }),
        Some(vec![JsModule::code(
            "test-extra".to_string(),
            "export const value = 1;".to_string(),
        )]),
    )
    .await
    .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    let mut modules = context.get_available_modules().await.unwrap();
    modules.sort();

    assert!(modules.contains(&"dgram".to_string()));
    assert!(modules.contains(&"test-extra".to_string()));
}

// ============================================================================
// Memory Usage Tests
// ============================================================================

#[test]
fn test_memory_usage_getters() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // Allocate some objects
    let _ =
        context.eval("let arr = []; for(let i = 0; i < 1000; i++) arr.push({x: i});".to_string());

    let usage = runtime.memory_usage();

    // All getters should work without panicking
    let _ = usage.malloc_size();
    let _ = usage.malloc_limit();
    let _ = usage.memory_used_size();
    let _ = usage.malloc_count();
    let _ = usage.memory_used_count();
    let _ = usage.atom_count();
    let _ = usage.atom_size();
    let _ = usage.str_count();
    let _ = usage.str_size();
    let _ = usage.obj_count();
    let _ = usage.obj_size();
    let _ = usage.prop_count();
    let _ = usage.prop_size();
    let _ = usage.shape_count();
    let _ = usage.shape_size();
    let _ = usage.js_func_count();
    let _ = usage.js_func_size();
    let _ = usage.js_func_code_size();
    let _ = usage.js_func_pc2line_count();
    let _ = usage.js_func_pc2line_size();
    let _ = usage.c_func_count();
    let _ = usage.array_count();
    let _ = usage.fast_array_count();
    let _ = usage.fast_array_elements();
    let _ = usage.binary_object_count();
    let _ = usage.binary_object_size();
    let _ = usage.total_memory();
    let _ = usage.total_allocations();
}

#[test]
fn test_memory_usage_clone() {
    let runtime = JsRuntime::new().unwrap();
    let usage = runtime.memory_usage();
    let cloned = usage.clone();
    assert_eq!(usage.total_memory(), cloned.total_memory());
}

// ============================================================================
// Eval Options Tests
// ============================================================================

#[test]
fn test_eval_options_defaults() {
    let options = JsEvalOptions::defaults();
    assert_eq!(options.global, Some(true));
    assert_eq!(options.strict, Some(true));
    assert_eq!(options.backtrace_barrier, Some(false));
    assert_eq!(options.promise, Some(false));
}

#[test]
fn test_eval_options_with_promise() {
    let options = JsEvalOptions::with_promise();
    assert_eq!(options.global, Some(true));
    assert_eq!(options.strict, Some(true));
    assert_eq!(options.promise, Some(true));
}

#[test]
fn test_eval_options_module() {
    let options = JsEvalOptions::module();
    assert_eq!(options.global, Some(false));
    assert_eq!(options.strict, Some(true));
    assert_eq!(options.promise, Some(true));
}

#[test]
fn test_eval_options_new() {
    let options = JsEvalOptions::new(Some(false), Some(false), Some(true), Some(true));
    assert_eq!(options.global, Some(false));
    assert_eq!(options.strict, Some(false));
    assert_eq!(options.backtrace_barrier, Some(true));
    assert_eq!(options.promise, Some(true));
}

// ============================================================================
// Builtin Options Tests
// ============================================================================

#[test]
fn test_builtin_options_all() {
    let options = JsBuiltinOptions::all();
    assert_eq!(options.console, Some(true));
    assert_eq!(options.timers, Some(true));
    assert_eq!(options.buffer, Some(true));
    assert_eq!(options.crypto, Some(true));
    assert_eq!(options.dgram, Some(true));
    assert_eq!(options.fs, Some(true));
    assert_eq!(options.https, Some(true));
    assert_eq!(options.intl, Some(true));
    assert_eq!(options.temporal, Some(true));
    assert_eq!(options.path, Some(true));
    assert_eq!(options.url, Some(true));
}

#[test]
fn test_builtin_options_none() {
    let options = JsBuiltinOptions::none();
    assert_eq!(options.console, None);
    assert_eq!(options.timers, None);
    assert_eq!(options.buffer, None);
    assert_eq!(options.dgram, None);
    assert_eq!(options.intl, None);
    assert_eq!(options.temporal, None);
}

#[test]
fn test_builtin_options_essential() {
    let options = JsBuiltinOptions::essential();
    assert_eq!(options.console, Some(true));
    assert_eq!(options.timers, Some(true));
    assert_eq!(options.buffer, Some(true));
    assert_eq!(options.util, Some(true));
    assert_eq!(options.json, Some(true));
    // Others should be None
    assert_eq!(options.crypto, None);
    assert_eq!(options.fs, None);
}

#[test]
fn test_builtin_options_web() {
    let options = JsBuiltinOptions::web();
    assert_eq!(options.console, Some(true));
    assert_eq!(options.timers, Some(true));
    assert_eq!(options.fetch, Some(true));
    assert_eq!(options.url, Some(true));
    assert_eq!(options.crypto, Some(true));
    assert_eq!(options.intl, Some(true));
    assert_eq!(options.stream_web, Some(true));
    assert_eq!(options.navigator, Some(true));
    // Node.js specific should be None
    assert_eq!(options.fs, None);
    assert_eq!(options.child_process, None);
}

#[test]
fn test_builtin_options_node() {
    let options = JsBuiltinOptions::node();
    assert_eq!(options.console, Some(true));
    assert_eq!(options.dgram, Some(true));
    assert_eq!(options.fs, Some(true));
    assert_eq!(options.https, Some(true));
    assert_eq!(options.intl, Some(true));
    assert_eq!(options.path, Some(true));
    assert_eq!(options.process, Some(true));
    assert_eq!(options.events, Some(true));
    // OS-specific might not be enabled
    assert_eq!(options.net, None);
    assert_eq!(options.tty, None);
}
