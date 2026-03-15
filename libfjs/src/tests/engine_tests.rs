//! # Engine Tests
//!
//! Tests for the high-level JsEngine API including initialization,
//! evaluation, module management, and bridge communication.

use crate::api::engine::JsEngine;
use crate::api::error::JsResult;
use crate::api::module::GlobalAttachment;
use crate::api::runtime::{JsAsyncContext, JsAsyncRuntime};
use crate::api::source::{JsBuiltinOptions, JsCode, JsModule};
use crate::api::value::JsValue;

fn failing_global_attachment(_ctx: &rquickjs::Ctx<'_>) -> rquickjs::Result<()> {
    Err(rquickjs::Error::new_from_js_message(
        "global attachment",
        "context",
        "forced failure for init rollback",
    ))
}

// ============================================================================
// Engine Lifecycle Tests
// ============================================================================

#[tokio::test]
async fn test_engine_new() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context);
    assert!(engine.is_ok());
}

#[tokio::test]
async fn test_engine_initial_state() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();

    assert!(!engine.disposed());
    assert!(!engine.running());
}

#[tokio::test]
async fn test_engine_init_without_bridge() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();

    let result = engine.init_without_bridge().await;
    assert!(result.is_ok());
    assert!(engine.running());
    assert!(!engine.disposed());
}

#[tokio::test]
async fn test_engine_init_failure_rolls_back_state() {
    let runtime = JsAsyncRuntime {
        rt: rquickjs::AsyncRuntime::new().unwrap(),
        global_attachment: Some(
            GlobalAttachment::default().add_function(failing_global_attachment),
        ),
    };
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();

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

#[tokio::test]
async fn test_engine_init_with_bridge() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();

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
    engine.dispose().await.unwrap();
}

#[tokio::test]
async fn test_engine_double_init_fails() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();

    let result1 = engine.init_without_bridge().await;
    assert!(result1.is_ok());

    let result2 = engine.init_without_bridge().await;
    assert!(result2.is_err());
}

#[tokio::test]
async fn test_engine_dispose() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();

    engine.init_without_bridge().await.unwrap();
    let result = engine.dispose().await;

    assert!(result.is_ok());
    assert!(engine.disposed());
    assert!(!engine.running());
}

#[tokio::test]
async fn test_engine_double_dispose_fails() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();

    engine.init_without_bridge().await.unwrap();
    engine.dispose().await.unwrap();

    let result = engine.dispose().await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_engine_context_getter() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();

    let _ = engine.context();
    // Should not panic
}

// ============================================================================
// Engine Evaluation Tests
// ============================================================================

#[tokio::test]
async fn test_engine_eval_simple() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine.eval(JsCode::Code("1 + 1".to_string()), None).await;
    assert!(result.is_ok());
    let value = result.unwrap();
    assert!(matches!(value, JsValue::Integer(2)));
}

#[tokio::test]
async fn test_engine_eval_string() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let runtime = JsAsyncRuntime::with_options(Some(JsBuiltinOptions::essential()), None)
        .await
        .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    assert!(runtime.is_job_pending().await);

    let before_idle = engine
        .eval(
            JsCode::Code("globalThis.__engine_timer_fired ?? false".to_string()),
            None,
        )
        .await;
    assert!(matches!(before_idle, Ok(JsValue::Boolean(false))));

    runtime.idle().await;

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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();

    let result = engine.eval(JsCode::Code("1 + 1".to_string()), None).await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_engine_eval_after_dispose_fails() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();

    engine.init_without_bridge().await.unwrap();
    engine.dispose().await.unwrap();

    let result = engine.eval(JsCode::Code("1 + 1".to_string()), None).await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_engine_eval_syntax_error() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(JsCode::Code("function {".to_string()), None)
        .await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_engine_eval_runtime_error() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(JsCode::Code("undefinedVariable".to_string()), None)
        .await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_engine_eval_throw_error() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let modules = vec![
        JsModule::code("module1".to_string(), "export const a = 1;".to_string()),
        JsModule::code("module2".to_string(), "export const b = 2;".to_string()),
    ];

    let result = engine.declare_new_modules(modules).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_engine_evaluate_module() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let module = JsModule::code(
        "eval-module".to_string(),
        "export const value = 42; export default value;".to_string(),
    );

    let result = engine.evaluate_module(module).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_engine_dynamic_module_relative_import() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let runtime = JsAsyncRuntime::with_options(
        Some(JsBuiltinOptions {
            path: Some(true),
            https: Some(true),
            ..Default::default()
        }),
        Some(vec![JsModule::code(
            "static-extra".to_string(),
            "export const value = 1;".to_string(),
        )]),
    )
    .await
    .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let runtime = JsAsyncRuntime::with_options(
        Some(JsBuiltinOptions {
            dgram: Some(true),
            ..Default::default()
        }),
        None,
    )
    .await
    .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .call("nonexistent".to_string(), "func".to_string(), None)
        .await;

    assert!(result.is_err());
}

#[tokio::test]
async fn test_engine_call_nonexistent_function() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();

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
    engine.dispose().await.unwrap();
}

#[tokio::test]
async fn test_engine_bridge_call_with_object() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();

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
    engine.dispose().await.unwrap();
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
    let runtime = JsAsyncRuntime::with_options(Some(builtin), None)
        .await
        .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let runtime = JsAsyncRuntime::with_options(Some(builtin), None)
        .await
        .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let runtime = JsAsyncRuntime::with_options(Some(builtin), None)
        .await
        .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let runtime = JsAsyncRuntime::with_options(Some(builtin), None)
        .await
        .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let runtime = JsAsyncRuntime::with_options(Some(builtin), None)
        .await
        .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
    let runtime = JsAsyncRuntime::with_options(Some(builtin), None)
        .await
        .unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
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
