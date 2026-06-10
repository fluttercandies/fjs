use std::future::Future;
use std::sync::OnceLock;
use std::sync::mpsc;

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

pub(crate) fn block_on_js<F, R>(future: F) -> R
where
    F: Future<Output = R> + Send + 'static,
    R: Send + 'static,
{
    if std::thread::current().name() == Some("fjs-js") {
        return futures::executor::block_on(future);
    }

    let (tx, rx) = mpsc::sync_channel(1);
    runtime().spawn(async move {
        let _ = tx.send(future.await);
    });
    rx.recv()
        .expect("fjs JavaScript executor task terminated before sending a result")
}
