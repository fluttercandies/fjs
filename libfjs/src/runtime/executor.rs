use std::future::Future;
use std::sync::OnceLock;

pub(crate) const JS_THREAD_STACK_SIZE: usize = 8 * 1024 * 1024;

static JS_RUNTIME: OnceLock<tokio::runtime::Runtime> = OnceLock::new();

fn runtime() -> &'static tokio::runtime::Runtime {
    JS_RUNTIME.get_or_init(|| {
        tokio::runtime::Builder::new_multi_thread()
            .enable_all()
            .thread_name("fjs-js")
            .thread_stack_size(JS_THREAD_STACK_SIZE)
            .worker_threads(2)
            .build()
            .expect("failed to build fjs JavaScript executor")
    })
}

pub(crate) async fn run_js<F, R>(future: F) -> R
where
    F: Future<Output = R> + Send + 'static,
    R: Send + 'static,
{
    runtime()
        .spawn(future)
        .await
        .expect("fjs JavaScript executor task panicked")
}

pub(crate) fn spawn_js<F>(future: F) -> tokio::task::JoinHandle<F::Output>
where
    F: Future + Send + 'static,
    F::Output: Send + 'static,
{
    runtime().spawn(future)
}
