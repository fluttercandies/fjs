//! Dedicated runtime that runs all JavaScript on big-stack threads.
//!
//! flutter_rust_bridge runs Rust on tokio workers whose stack defaults to 2 MB
//! and which fjs cannot resize. That is far below a browser's ~8 MB JS stack,
//! so deep-but-normal JS (e.g. a recursive UI render) can overflow the native
//! stack and abort the whole process instead of throwing. To behave like a
//! browser, fjs runs every JS entry on its own runtime whose threads have an
//! 8 MB stack. QuickJS refreshes its overflow baseline on each entry, so
//! spreading JS across these threads stays correct.
//!
//! The runtime is process-global and lives for the whole app, so it is never
//! dropped in an async context (which would panic).

use std::future::Future;
use std::sync::OnceLock;
use tokio::runtime::Runtime;
use tokio::task::JoinHandle;

/// Native stack of the dedicated JS threads. Browser-class, so deep UI trees
/// render; [`crate::api::runtime::MAX_SAFE_STACK_SIZE`] keeps the JS budget a
/// safe fraction below it.
pub(crate) const JS_THREAD_STACK_SIZE: usize = 8 * 1024 * 1024;

/// Number of JS worker threads. JS is serialized per runtime by QuickJS's lock,
/// so a small pool is plenty; it mainly lets timers/fetch and separate engines
/// make progress in parallel.
const JS_WORKER_THREADS: usize = 4;

fn executor() -> &'static Runtime {
    static EXECUTOR: OnceLock<Runtime> = OnceLock::new();
    EXECUTOR.get_or_init(|| {
        tokio::runtime::Builder::new_multi_thread()
            .worker_threads(JS_WORKER_THREADS)
            .thread_stack_size(JS_THREAD_STACK_SIZE)
            .thread_name("fjs-js")
            .enable_all()
            .build()
            .expect("failed to build fjs JS runtime")
    })
}

/// Spawns a JS task on the dedicated runtime.
pub(crate) fn spawn<F>(future: F) -> JoinHandle<F::Output>
where
    F: Future + Send + 'static,
    F::Output: Send + 'static,
{
    executor().spawn(future)
}

/// Runs `future` on the dedicated runtime and awaits it, so the JS executes on
/// a big-stack thread no matter which runtime called us.
pub(crate) async fn run<F>(future: F) -> F::Output
where
    F: Future + Send + 'static,
    F::Output: Send + 'static,
{
    spawn(future).await.expect("fjs JS task panicked")
}
