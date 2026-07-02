use crate::api::error::JsError;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use tokio::sync::Notify;

#[derive(Clone, Default)]
pub(crate) struct RuntimeShutdown {
    inner: Arc<RuntimeShutdownState>,
}

#[derive(Default)]
struct RuntimeShutdownState {
    requested: AtomicBool,
    notify: Notify,
}

impl RuntimeShutdown {
    pub(crate) fn request(&self) {
        if !self.inner.requested.swap(true, Ordering::AcqRel) {
            self.inner.notify.notify_waiters();
        }
    }

    pub(crate) fn requested(&self) -> bool {
        self.inner.requested.load(Ordering::Acquire)
    }

    pub(crate) fn error(&self) -> JsError {
        JsError::cancelled("JavaScript engine was closed")
    }

    pub(crate) async fn cancelled(&self) {
        loop {
            if self.requested() {
                return;
            }
            let notified = self.inner.notify.notified();
            if self.requested() {
                return;
            }
            notified.await;
        }
    }
}
