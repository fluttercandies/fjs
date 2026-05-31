//! # Stack-overflow safety
//!
//! QuickJS's overflow check is a soft limit: it only fires once JS has grown
//! `max_stack_size` bytes past a baseline captured on the running thread, and
//! it does not know the real native thread stack. So two things must hold:
//!
//! * eval and pumped jobs must run against a fresh per-thread baseline, or one
//!   path would overflow much earlier than the other;
//! * `max_stack_size` must stay below the thread stack, or JS overflows the
//!   native stack first and the process aborts instead of throwing.
//!
//! These tests pin down both: eval and jobs reach the same catchable depth, a
//! bigger budget reaches deeper, and an over-large budget is clamped so it
//! still throws instead of crashing a worker thread.
//!
//! A native stack overflow aborts the whole test binary, so a regression here
//! shows up as a process abort, not a normal assertion failure.

use crate::api::runtime::{JsAsyncContext, JsAsyncRuntime};

const PROBE_DEF: &str = r#"
globalThis.__probe = function () {
    let depth = 0;
    function r() { depth++; r(); }
    try { r(); } catch (e) {
        if (!(e instanceof RangeError)) throw e;
    }
    return depth;
};
"#;

/// Returns the recursion depth reached via (eval, pumped job) for a runtime.
///
/// The job is a queued microtask that `async_with` does not drain, so it only
/// runs when we pump it through the runtime's `execute_pending_job` — the real
/// job path.
async fn eval_and_job_depths(runtime: &JsAsyncRuntime, context: &JsAsyncContext) -> (i32, i32) {
    context
        .ctx
        .async_with(async |ctx| {
            ctx.eval::<(), _>(PROBE_DEF).unwrap();
        })
        .await;

    let eval_depth = context
        .ctx
        .async_with(async |ctx| ctx.eval::<i32, _>("__probe()").unwrap())
        .await;

    context
        .ctx
        .async_with(async |ctx| {
            ctx.eval::<(), _>(
                "globalThis.__jd = -1; \
                 Promise.resolve().then(() => { globalThis.__jd = __probe(); });",
            )
            .unwrap();
        })
        .await;

    while runtime.execute_pending_job().await.unwrap() {}

    let job_depth = context
        .ctx
        .async_with(async |ctx| ctx.eval::<i32, _>("globalThis.__jd").unwrap())
        .await;

    (eval_depth, job_depth)
}

async fn runtime_with_budget(budget: usize) -> (JsAsyncRuntime, JsAsyncContext) {
    let runtime = JsAsyncRuntime::new().unwrap();
    runtime.set_max_stack_size(budget).await;
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    (runtime, context)
}

/// Eval and a pumped job reach the same depth and both throw a catchable
/// error (rquickjs refreshes the stack baseline on each entry, including jobs).
#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn eval_and_job_reach_same_catchable_depth() {
    let (runtime, context) = runtime_with_budget(256 * 1024).await;
    let (eval_depth, job_depth) = eval_and_job_depths(&runtime, &context).await;

    assert!(
        eval_depth > 0 && job_depth > 0,
        "both paths must throw a catchable RangeError (no crash), got eval={eval_depth} job={job_depth}",
    );
    assert!(
        (eval_depth - job_depth).abs() <= 3,
        "eval and job should reach ~the same depth, got eval={eval_depth} job={job_depth}",
    );
}

/// A bigger budget (within the safe ceiling) reaches deeper on both paths.
#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn raising_budget_raises_depth_on_both_paths() {
    let (small_rt, small_ctx) = runtime_with_budget(128 * 1024).await;
    let small = eval_and_job_depths(&small_rt, &small_ctx).await;

    let (large_rt, large_ctx) = runtime_with_budget(512 * 1024).await;
    let large = eval_and_job_depths(&large_rt, &large_ctx).await;

    assert!(
        large.0 > small.0,
        "eval: larger budget should reach deeper ({} vs {})",
        large.0,
        small.0,
    );
    assert!(
        large.1 > small.1,
        "job: larger budget should reach deeper ({} vs {})",
        large.1,
        small.1,
    );
}

/// An over-large budget is clamped below the worker thread stack, so deep
/// recursion on a worker thread throws instead of aborting the process.
///
/// Without the clamp, the 64 MB budget lets JS blow past the worker's 2 MB
/// native stack and the test binary aborts.
#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn oversized_budget_is_clamped_and_stays_catchable() {
    let runtime = JsAsyncRuntime::new().unwrap();
    runtime.set_max_stack_size(64 * 1024 * 1024).await;
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    context
        .ctx
        .async_with(async |ctx| {
            ctx.eval::<(), _>(PROBE_DEF).unwrap();
        })
        .await;

    // Force the recursion onto a tokio worker thread, like flutter_rust_bridge
    // does, so it runs against the worker's native stack.
    let context = context.clone();
    let depth = tokio::spawn(async move {
        context
            .ctx
            .async_with(async |ctx| ctx.eval::<i32, _>("__probe()").unwrap())
            .await
    })
    .await
    .unwrap();

    assert!(
        depth > 0,
        "clamped budget must throw a catchable RangeError (no crash), got depth {depth}",
    );
}
