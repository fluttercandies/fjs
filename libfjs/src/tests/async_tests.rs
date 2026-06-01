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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code("Promise.resolve(1).then(x => x + 1).then(x => x * 2)".to_string()),
            None,
        )
        .await
        .unwrap();
    assert!(matches!(result, JsValue::Integer(4)));
}

#[tokio::test]
async fn test_promise_catch() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code("Promise.reject('error').catch(e => 'caught: ' + e)".to_string()),
            None,
        )
        .await
        .unwrap();
    assert!(matches!(result, JsValue::String(s) if s == "caught: error"));
}

#[tokio::test]
async fn test_promise_finally() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    engine.close().await.unwrap();
    runtime.idle().await;
    runtime.run_gc().await;
    drop(engine);
    drop(context);
}

#[tokio::test]
async fn test_async_await_sequential() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(JsCode::Code("await Promise.resolve(42)".to_string()), None)
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(42)));
}

#[tokio::test]
async fn test_top_level_await_with_variable() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
        .call("async-utils".to_string(), "fetchData".to_string(), None)
        .await
        .unwrap();

    assert!(result.is_object());
}

#[tokio::test]
async fn test_async_module_chain() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let _context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();
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
        .call("chain-test".to_string(), "runChain".to_string(), None)
        .await
        .unwrap();

    assert!(matches!(result, JsValue::Integer(4))); // (1 + 1) * 2 = 4
}

// ============================================================================
// Bridge Async Tests
// ============================================================================

#[tokio::test]
async fn test_bridge_multiple_async_calls() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::create(None, None, None).await.unwrap();

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
    engine.close().await.unwrap();
    runtime.idle().await;
    runtime.run_gc().await;
    drop(engine);
    drop(context);
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

// ============================================================================
// Background Driver Tests
// ============================================================================

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn test_start_stop_drive_lifecycle() {
    let runtime = JsAsyncRuntime::new().unwrap();

    // No driver before it is started.
    assert!(runtime.driver.lock().unwrap().is_none());

    // Starting spawns a live background task.
    runtime.start_drive().await;
    let first_id = {
        let slot = runtime.driver.lock().unwrap();
        let handle = slot.as_ref().expect("driver task should be present");
        assert!(!handle.is_finished(), "driver task should be running");
        handle.id()
    };

    // Idempotent: a second start does not replace the running task.
    runtime.start_drive().await;
    let second_id = runtime.driver.lock().unwrap().as_ref().unwrap().id();
    assert_eq!(first_id, second_id, "start_drive should not re-spawn");

    // Stopping aborts the task and clears the slot.
    runtime.stop_drive().await;
    assert!(runtime.driver.lock().unwrap().is_none());

    // Stopping again is a harmless no-op.
    runtime.stop_drive().await;
    assert!(runtime.driver.lock().unwrap().is_none());

    // The runtime is still usable after stopping the driver.
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let _ = context.eval("globalThis.y = 7".to_string()).await;
    assert!(matches!(
        context.eval("y".to_string()).await,
        JsResult::Ok(JsValue::Integer(7))
    ));
}

/// The whole point of `start_drive`: a *detached* async job (one not awaited by
/// any live `eval`) must still resolve on its own. `eval`'s own await loop
/// (rquickjs `WithFuture`) already pumps work it is awaiting, so a timer inside
/// `await new Promise(...)` is not a real test of the driver. Here we schedule a
/// timer and return immediately, leaving it parked on the scheduler with nothing
/// awaiting it — exactly how the app's `fetch`/timers behave.
///
/// `is_job_pending()` is a pure state read; it never drives the scheduler, so it
/// cannot itself pump the timer.
#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn test_background_driver_pumps_detached_timer() {
    use crate::api::engine::JsEngine;
    use crate::api::source::{JsBuiltinOptions, JsCode};
    use std::time::Duration;

    let schedule = "setTimeout(() => { globalThis.__fired = true; }, 50); 'scheduled'";

    // Control: with NO driver, the detached timer can never run — nothing polls
    // the scheduler during the sleep — so it stays pending.
    let engine = JsEngine::create(Some(JsBuiltinOptions::essential()), None, None)
        .await
        .unwrap();
    engine.init_without_bridge().await.unwrap();
    engine
        .eval(JsCode::Code(schedule.to_string()), None)
        .await
        .unwrap();
    assert!(
        engine.is_job_pending().await.unwrap(),
        "timer should be queued right after scheduling"
    );
    tokio::time::sleep(Duration::from_millis(300)).await;
    assert!(
        engine.is_job_pending().await.unwrap(),
        "without a driver the detached timer must still be pending after 300ms"
    );
    engine.close().await.unwrap();

    // With the driver: the same detached timer resolves on its own.
    let engine = JsEngine::create(Some(JsBuiltinOptions::essential()), None, None)
        .await
        .unwrap();
    engine.init_without_bridge().await.unwrap();
    engine.start_drive().await.unwrap();
    engine
        .eval(JsCode::Code(schedule.to_string()), None)
        .await
        .unwrap();
    tokio::time::sleep(Duration::from_millis(300)).await;
    assert!(
        !engine.is_job_pending().await.unwrap(),
        "the background driver should have pumped the detached timer to completion"
    );
    engine.close().await.unwrap();
}

/// Same idea as the timer test, but for `fetch` — the path that actually fails
/// in the app. A fetch's network I/O is driven by a connection task hyper
/// `tokio::spawn`s separately from the scheduler, so it exercises more of the
/// wake chain than a self-contained timer.
///
/// The app's symptom is specific: the request *egress* works, but the response
/// reaching JS (the `.then`) is what lags. So we test the full round trip into
/// JS by chaining a second fetch inside `.then`: server B only hears anything if
/// `fetch(A)`'s promise actually resolved in JS and ran the callback. All
/// observation is host-side (a server reading request bytes), so no `eval` can
/// mask a missing wake by pumping the scheduler itself.
#[tokio::test(flavor = "multi_thread", worker_threads = 4)]
async fn test_background_driver_pumps_detached_fetch() {
    use crate::api::engine::JsEngine;
    use crate::api::source::{JsBuiltinOptions, JsCode};
    use std::time::Duration;
    use tokio::io::{AsyncReadExt, AsyncWriteExt};

    // A local server that replies 200, and signals once it has read a request.
    async fn spawn_server() -> (String, tokio::sync::mpsc::Receiver<()>) {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        let (tx, rx) = tokio::sync::mpsc::channel(1);
        tokio::spawn(async move {
            loop {
                let Ok((mut sock, _)) = listener.accept().await else {
                    return;
                };
                let tx = tx.clone();
                tokio::spawn(async move {
                    let mut buf = [0u8; 1024];
                    if sock.read(&mut buf).await.unwrap_or(0) > 0 {
                        let _ = tx.send(()).await;
                        let _ = sock
                            .write_all(b"HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n")
                            .await;
                    }
                });
            }
        });
        (format!("http://{addr}/"), rx)
    }

    // fetch(A).then(() => fetch(B)) — B is reached only if A's response was
    // delivered back into JS and the .then ran. Detached: nothing awaits it.
    let schedule = |a: &str, b: &str| {
        format!("fetch('{a}').then(() => fetch('{b}')).catch(() => {{}}); 'scheduled'")
    };

    // Control: with NO driver nothing pumps, so A's request never even goes out.
    let (url_a, rx_a) = spawn_server().await;
    let (url_b, mut rx_b) = spawn_server().await;
    let engine = JsEngine::create(Some(JsBuiltinOptions::all()), None, None)
        .await
        .unwrap();
    engine.init_without_bridge().await.unwrap();
    engine
        .eval(JsCode::Code(schedule(&url_a, &url_b)), None)
        .await
        .unwrap();
    assert!(
        tokio::time::timeout(Duration::from_millis(800), rx_b.recv())
            .await
            .is_err(),
        "without a driver the chained fetch must never reach server B"
    );
    let _ = rx_a;
    engine.close().await.unwrap();

    // With the driver: A goes out, A's response reaches JS, .then runs, B is hit.
    let (url_a, mut rx_a) = spawn_server().await;
    let (url_b, mut rx_b) = spawn_server().await;
    let engine = JsEngine::create(Some(JsBuiltinOptions::all()), None, None)
        .await
        .unwrap();
    engine.init_without_bridge().await.unwrap();
    engine.start_drive().await.unwrap();
    engine
        .eval(JsCode::Code(schedule(&url_a, &url_b)), None)
        .await
        .unwrap();
    assert!(
        tokio::time::timeout(Duration::from_secs(3), rx_a.recv())
            .await
            .is_ok(),
        "the driver should have sent fetch A"
    );
    assert!(
        tokio::time::timeout(Duration::from_secs(3), rx_b.recv())
            .await
            .is_ok(),
        "fetch A's response should have reached JS and triggered fetch B"
    );
    engine.close().await.unwrap();
}
