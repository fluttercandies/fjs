//! # Async Tests
//!
//! Comprehensive tests for asynchronous JavaScript execution,
//! including Promise handling, async/await, and concurrent operations.

use crate::api::engine::JsEngine;
use crate::api::error::JsResult;
use crate::api::runtime::{JsAsyncContext, JsAsyncRuntime};
use crate::api::source::{JsCode, JsModule};
use crate::api::value::JsValue;

// ============================================================================
// Basic Promise Tests
// ============================================================================

#[tokio::test]
async fn test_promise_resolve_primitive() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    // Integer
    let result = engine
        .eval(JsCode::Code("Promise.resolve(42)".to_string()), None)
        .await
        .unwrap();
    assert!(matches!(result, JsValue::Integer(42)));

    // String
    let result = engine
        .eval(JsCode::Code("Promise.resolve('hello')".to_string()), None)
        .await
        .unwrap();
    assert!(matches!(result, JsValue::String(s) if s == "hello"));

    // Boolean
    let result = engine
        .eval(JsCode::Code("Promise.resolve(true)".to_string()), None)
        .await
        .unwrap();
    assert!(matches!(result, JsValue::Boolean(true)));

    // Null
    let result = engine
        .eval(JsCode::Code("Promise.resolve(null)".to_string()), None)
        .await
        .unwrap();
    assert!(result.is_none());
}

#[tokio::test]
async fn test_promise_resolve_complex() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    // Array
    let result = engine
        .eval(JsCode::Code("Promise.resolve([1, 2, 3])".to_string()), None)
        .await
        .unwrap();
    assert!(result.is_array());

    // Object
    let result = engine
        .eval(
            JsCode::Code("Promise.resolve({a: 1, b: 2})".to_string()),
            None,
        )
        .await
        .unwrap();
    assert!(result.is_object());
}

#[tokio::test]
async fn test_promise_reject_error() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code("Promise.reject(new Error('test error'))".to_string()),
            None,
        )
        .await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_promise_reject_value() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(JsCode::Code("Promise.reject('rejected')".to_string()), None)
        .await;
    assert!(result.is_err());
}

// ============================================================================
// Promise Chain Tests
// ============================================================================

#[tokio::test]
async fn test_promise_then_chain() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                "Promise.resolve(1).then(x => x + 1).then(x => x * 2)".to_string(),
            ),
            None,
        )
        .await
        .unwrap();
    assert!(matches!(result, JsValue::Integer(4)));
}

#[tokio::test]
async fn test_promise_catch() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                "Promise.reject('error').catch(e => 'caught: ' + e)".to_string(),
            ),
            None,
        )
        .await
        .unwrap();
    assert!(matches!(result, JsValue::String(s) if s == "caught: error"));
}

#[tokio::test]
async fn test_promise_finally() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                r#"
                let finallyCalled = false;
                await Promise.resolve(42).finally(() => { finallyCalled = true; });
                finallyCalled
            "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();
    assert!(matches!(result, JsValue::Boolean(true)));
}

#[tokio::test]
async fn test_promise_error_propagation() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    // Error in middle of chain should skip subsequent then handlers
    let result = engine
        .eval(
            JsCode::Code(
                r#"
                Promise.resolve(1)
                    .then(() => { throw new Error('mid-chain'); })
                    .then(() => 'should not reach')
                    .catch(e => 'caught')
            "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();
    assert!(matches!(result, JsValue::String(s) if s == "caught"));
}

// ============================================================================
// Promise Static Methods Tests
// ============================================================================

#[tokio::test]
async fn test_promise_all_success() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                "Promise.all([Promise.resolve(1), Promise.resolve(2), Promise.resolve(3)])"
                    .to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(result.is_array());
    if let JsValue::Array(arr) = result {
        assert_eq!(arr.len(), 3);
    }
}

#[tokio::test]
async fn test_promise_all_failure() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                "Promise.all([Promise.resolve(1), Promise.reject('fail'), Promise.resolve(3)])"
                    .to_string(),
            ),
            None,
        )
        .await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_promise_all_empty() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(JsCode::Code("Promise.all([])".to_string()), None)
        .await
        .unwrap();

    assert!(result.is_array());
    if let JsValue::Array(arr) = result {
        assert!(arr.is_empty());
    }
}

#[tokio::test]
async fn test_promise_race() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                "Promise.race([Promise.resolve('first'), Promise.resolve('second')])".to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    // Should resolve to first
    assert!(matches!(result, JsValue::String(s) if s == "first"));
}

#[tokio::test]
async fn test_promise_allsettled() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                "Promise.allSettled([Promise.resolve(1), Promise.reject('fail')])".to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(result.is_array());
    if let JsValue::Array(arr) = result {
        assert_eq!(arr.len(), 2);
    }
}

#[tokio::test]
async fn test_promise_any_success() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                "Promise.any([Promise.reject('fail'), Promise.resolve('success')])".to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::String(s) if s == "success"));
}

// ============================================================================
// Async/Await Tests
// ============================================================================

#[tokio::test]
async fn test_async_function_basic() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                r#"
                async function test() {
                    return 42;
                }
                test()
            "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(42)));
}

#[tokio::test]
async fn test_async_await_sequential() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                r#"
                async function test() {
                    const a = await Promise.resolve(1);
                    const b = await Promise.resolve(2);
                    const c = await Promise.resolve(3);
                    return a + b + c;
                }
                test()
            "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(6)));
}

#[tokio::test]
async fn test_async_await_parallel() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                r#"
                async function test() {
                    const [a, b, c] = await Promise.all([
                        Promise.resolve(1),
                        Promise.resolve(2),
                        Promise.resolve(3)
                    ]);
                    return a + b + c;
                }
                test()
            "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(6)));
}

#[tokio::test]
async fn test_async_try_catch() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                r#"
                async function test() {
                    try {
                        await Promise.reject(new Error('test error'));
                        return 'not reached';
                    } catch (e) {
                        return 'caught';
                    }
                }
                test()
            "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::String(s) if s == "caught"));
}

#[tokio::test]
async fn test_async_arrow_function() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                r#"
                const test = async () => {
                    const x = await Promise.resolve(10);
                    return x * 2;
                };
                test()
            "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(20)));
}

#[tokio::test]
async fn test_nested_async_functions() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                r#"
                async function outer() {
                    async function inner(x) {
                        return await Promise.resolve(x * 2);
                    }
                    const a = await inner(5);
                    const b = await inner(10);
                    return a + b;
                }
                outer()
            "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(30)));
}

// ============================================================================
// Top-Level Await Tests
// ============================================================================

#[tokio::test]
async fn test_top_level_await() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code("await Promise.resolve(42)".to_string()),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(42)));
}

#[tokio::test]
async fn test_top_level_await_with_variable() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                r#"
                const data = await Promise.resolve({ value: 42 });
                data.value
            "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(42)));
}

// ============================================================================
// Async Module Tests
// ============================================================================

#[tokio::test]
async fn test_async_module_function() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let module = JsModule::code(
        "async-utils".to_string(),
        r#"
        export async function fetchData() {
            return await Promise.resolve({ status: 'ok', data: [1, 2, 3] });
        }

        export async function processData(data) {
            const result = await Promise.resolve(data.map(x => x * 2));
            return result;
        }
    "#
        .to_string(),
    );
    engine.declare_new_module(module).await.unwrap();

    let result = engine
        .call(
            "async-utils".to_string(),
            "fetchData".to_string(),
            None,
        )
        .await
        .unwrap();

    assert!(result.is_object());
}

#[tokio::test]
async fn test_async_module_chain() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let module = JsModule::code(
        "chain-test".to_string(),
        r#"
        async function step1() {
            return await Promise.resolve(1);
        }

        async function step2(x) {
            return await Promise.resolve(x + 1);
        }

        async function step3(x) {
            return await Promise.resolve(x * 2);
        }

        export async function runChain() {
            let result = await step1();
            result = await step2(result);
            result = await step3(result);
            return result;
        }
    "#
        .to_string(),
    );
    engine.declare_new_module(module).await.unwrap();

    let result = engine
        .call(
            "chain-test".to_string(),
            "runChain".to_string(),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(4))); // (1 + 1) * 2 = 4
}

// ============================================================================
// Bridge Async Tests
// ============================================================================

#[tokio::test]
async fn test_bridge_async_call() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();

    engine
        .init(|value| {
            Box::pin(async move {
                // Simulate async processing
                match value {
                    JsValue::Integer(n) => JsResult::Ok(JsValue::Integer(n * 2)),
                    _ => JsResult::Ok(value),
                }
            })
        })
        .await
        .unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                r#"
                async function test() {
                    const result = await fjs.bridge_call(21);
                    return result;
                }
                test()
            "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(42)));
}

#[tokio::test]
async fn test_bridge_multiple_async_calls() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();

    engine
        .init(|value| {
            Box::pin(async move {
                match value {
                    JsValue::Integer(n) => JsResult::Ok(JsValue::Integer(n + 1)),
                    _ => JsResult::Ok(value),
                }
            })
        })
        .await
        .unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                r#"
                async function test() {
                    const a = await fjs.bridge_call(1);
                    const b = await fjs.bridge_call(a);
                    const c = await fjs.bridge_call(b);
                    return c;
                }
                test()
            "#
                .to_string(),
            ),
            None,
        )
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(4))); // 1 + 1 + 1 + 1 = 4
}

// ============================================================================
// Runtime Async Operations Tests
// ============================================================================

#[tokio::test]
async fn test_runtime_async_memory_operations() {
    let runtime = JsAsyncRuntime::new().unwrap();

    // Async memory operations
    runtime.set_memory_limit(32 * 1024 * 1024).await;
    runtime.set_max_stack_size(1024 * 1024).await;
    runtime.set_gc_threshold(1024 * 1024).await;

    let usage = runtime.memory_usage().await;
    assert!(usage.total_memory() >= 0);

    runtime.run_gc().await;
    // Should not panic
}

#[tokio::test]
async fn test_runtime_async_job_execution() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    // Evaluate code that creates pending jobs
    let result = context.eval("Promise.resolve(42)".to_string()).await;
    assert!(result.is_ok());

    // Process any pending jobs
    while runtime.is_job_pending().await {
        let _ = runtime.execute_pending_job().await;
    }
}

#[tokio::test]
async fn test_runtime_idle() {
    let runtime = JsAsyncRuntime::new().unwrap();

    runtime.idle().await;
    // Should not panic
}

// ============================================================================
// Context Async Evaluation Tests
// ============================================================================

#[tokio::test]
async fn test_context_async_eval_multiple() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    // Multiple evaluations should work
    let r1 = context.eval("1 + 1".to_string()).await;
    assert!(r1.is_ok());

    let r2 = context.eval("2 + 2".to_string()).await;
    assert!(r2.is_ok());

    let r3 = context.eval("3 + 3".to_string()).await;
    assert!(r3.is_ok());
}

#[tokio::test]
async fn test_context_async_eval_state_persistence() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    // Set a variable
    let _ = context.eval("globalThis.x = 42".to_string()).await;

    // Read it back
    let result = context.eval("x".to_string()).await;
    match result {
        JsResult::Ok(JsValue::Integer(42)) => {}
        _ => panic!("Expected 42"),
    }
}
