use crate::runtime::executor;
use std::collections::VecDeque;
use std::future::Future;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};

const MAX_ERRORS: usize = 32;

#[derive(Clone, Default)]
pub(crate) struct DriverController {
    inner: Arc<DriverState>,
}

#[derive(Default)]
struct DriverState {
    running: AtomicBool,
    handle: Mutex<Option<tokio::task::JoinHandle<()>>>,
    errors: Mutex<VecDeque<String>>,
}

impl DriverController {
    pub(crate) fn start(&self, runtime: rquickjs::AsyncRuntime) {
        self.start_task(runtime.drive());
    }

    fn start_task<F>(&self, future: F)
    where
        F: Future<Output = ()> + Send + 'static,
    {
        let mut handle_slot = self.inner.handle.lock().unwrap();
        if handle_slot.is_some() {
            return;
        }

        let state = self.inner.clone();
        self.inner.running.store(true, Ordering::Release);
        let handle = executor::spawn_js(async move {
            future.await;
            state.running.store(false, Ordering::Release);
            let _ = state.handle.lock().unwrap().take();
        });

        *handle_slot = Some(handle);
    }

    pub(crate) async fn stop(&self) {
        let handle = self.inner.handle.lock().unwrap().take();
        self.inner.running.store(false, Ordering::Release);
        if let Some(handle) = handle {
            handle.abort();
            let _ = handle.await;
        }
    }

    pub(crate) fn running(&self) -> bool {
        self.inner.running.load(Ordering::Acquire)
    }

    pub(crate) fn push_error(&self, error: String) {
        let mut errors = self.inner.errors.lock().unwrap();
        if errors.len() == MAX_ERRORS {
            errors.pop_front();
        }
        errors.push_back(error);
    }

    pub(crate) fn drain_errors(&self) -> Vec<String> {
        self.inner.errors.lock().unwrap().drain(..).collect()
    }
}

#[cfg(test)]
mod tests {
    use super::DriverController;
    use std::sync::Arc;
    use std::sync::atomic::{AtomicBool, Ordering};
    use tokio::sync::oneshot;

    #[test]
    fn error_queue_keeps_newest_entries_when_full() {
        let driver = DriverController::default();

        for index in 0..40 {
            driver.push_error(format!("error {index}"));
        }

        let errors = driver.drain_errors();
        assert_eq!(errors.len(), 32);
        assert_eq!(errors.first().unwrap(), "error 8");
        assert_eq!(errors.last().unwrap(), "error 39");
        assert!(driver.drain_errors().is_empty());
    }

    #[tokio::test]
    async fn stop_waits_for_driver_task_to_finish_before_restart() {
        let driver = DriverController::default();
        let dropped = Arc::new(AtomicBool::new(false));
        let dropped_for_task = dropped.clone();
        let (started_tx, started_rx) = oneshot::channel::<()>();
        let (_tx, rx) = oneshot::channel::<()>();

        driver.start_task(async move {
            let _guard = DriverDropFlag(dropped_for_task);
            let _ = started_tx.send(());
            let _ = rx.await;
        });
        started_rx.await.unwrap();
        assert!(driver.running());

        driver.stop().await;
        assert!(dropped.load(Ordering::Acquire));
        assert!(!driver.running());
    }

    struct DriverDropFlag(Arc<AtomicBool>);

    impl Drop for DriverDropFlag {
        fn drop(&mut self) {
            self.0.store(true, Ordering::Release);
        }
    }
}
