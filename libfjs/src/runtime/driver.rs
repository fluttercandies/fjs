use crate::runtime::executor;
use std::collections::VecDeque;
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
        let mut handle_slot = self.inner.handle.lock().unwrap();
        if handle_slot.is_some() {
            return;
        }

        let state = self.inner.clone();
        let drive = runtime.drive();
        self.inner.running.store(true, Ordering::Release);
        let handle = executor::spawn_js(async move {
            drive.await;
            state.running.store(false, Ordering::Release);
            let _ = state.handle.lock().unwrap().take();
        });

        *handle_slot = Some(handle);
    }

    pub(crate) fn stop(&self) {
        let mut handle_slot = self.inner.handle.lock().unwrap();
        if let Some(handle) = handle_slot.take() {
            handle.abort();
        }
        self.inner.running.store(false, Ordering::Release);
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
}
