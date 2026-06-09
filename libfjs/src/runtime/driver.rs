use crate::runtime::executor;
use std::collections::VecDeque;
use std::future::Future;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use tokio::sync::Notify;

const MAX_ERRORS: usize = 32;

#[derive(Clone, Default)]
pub(crate) struct DriverController {
    inner: Arc<DriverState>,
}

#[derive(Default)]
struct DriverState {
    next_task_id: AtomicU64,
    lifecycle: Mutex<DriverLifecycle>,
    errors: Mutex<VecDeque<String>>,
    stop_finished: Notify,
}

#[derive(Default)]
enum DriverLifecycle {
    #[default]
    Idle,
    Running {
        task_id: u64,
        handle: tokio::task::JoinHandle<()>,
    },
    Stopping {
        task_id: u64,
    },
}

impl DriverController {
    pub(crate) fn start(&self, runtime: rquickjs::AsyncRuntime) {
        self.start_task(runtime.drive());
    }

    fn start_task<F>(&self, future: F)
    where
        F: Future<Output = ()> + Send + 'static,
    {
        let mut lifecycle = self.inner.lifecycle.lock().unwrap();
        if !matches!(*lifecycle, DriverLifecycle::Idle) {
            return;
        }

        let task_id = self.inner.next_task_id.fetch_add(1, Ordering::AcqRel);
        let state = self.inner.clone();
        let handle = executor::spawn_js(async move {
            let _guard = DriverTaskGuard {
                state: state.clone(),
                task_id,
            };
            future.await;
        });

        *lifecycle = DriverLifecycle::Running { task_id, handle };
    }

    pub(crate) async fn stop(&self) {
        match self.stop_action() {
            StopAction::Wait => self.wait_until_idle().await,
            StopAction::Done => {}
        }
    }

    fn stop_action(&self) -> StopAction {
        let mut lifecycle = self.inner.lifecycle.lock().unwrap();
        match std::mem::take(&mut *lifecycle) {
            DriverLifecycle::Running { task_id, handle } => {
                *lifecycle = DriverLifecycle::Stopping { task_id };
                self.spawn_abort_watcher(task_id, handle);
                StopAction::Wait
            }
            DriverLifecycle::Stopping { task_id } => {
                *lifecycle = DriverLifecycle::Stopping { task_id };
                StopAction::Wait
            }
            DriverLifecycle::Idle => StopAction::Done,
        }
    }

    fn spawn_abort_watcher(&self, task_id: u64, handle: tokio::task::JoinHandle<()>) {
        let state = self.inner.clone();
        // Keep teardown moving even if the caller cancels the stop() future.
        executor::spawn_js(async move {
            handle.abort();
            let _ = handle.await;
            state.mark_idle(task_id);
        });
    }

    async fn wait_until_idle(&self) {
        loop {
            let notified = self.inner.stop_finished.notified();
            if matches!(*self.inner.lifecycle.lock().unwrap(), DriverLifecycle::Idle) {
                return;
            }
            notified.await;
        }
    }

    pub(crate) fn running(&self) -> bool {
        matches!(
            *self.inner.lifecycle.lock().unwrap(),
            DriverLifecycle::Running { .. }
        )
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

enum StopAction {
    Wait,
    Done,
}

struct DriverTaskGuard {
    state: Arc<DriverState>,
    task_id: u64,
}

impl Drop for DriverTaskGuard {
    fn drop(&mut self) {
        self.state.mark_idle(self.task_id);
    }
}

impl DriverState {
    fn mark_idle(&self, task_id: u64) {
        let mut lifecycle = self.lifecycle.lock().unwrap();
        let matches_current_task = match &*lifecycle {
            DriverLifecycle::Running {
                task_id: current, ..
            }
            | DriverLifecycle::Stopping { task_id: current } => *current == task_id,
            DriverLifecycle::Idle => false,
        };

        if matches_current_task {
            *lifecycle = DriverLifecycle::Idle;
            self.stop_finished.notify_waiters();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::DriverController;
    use std::sync::Arc;
    use std::sync::atomic::{AtomicBool, Ordering};
    use std::time::Duration;
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

    #[tokio::test]
    async fn start_during_stop_does_not_restart_until_stop_finishes() {
        let driver = DriverController::default();
        let (started_tx, started_rx) = oneshot::channel::<()>();
        let (_tx, rx) = oneshot::channel::<()>();

        driver.start_task(async move {
            let _guard = SlowDropFlag;
            let _ = started_tx.send(());
            let _ = rx.await;
        });
        started_rx.await.unwrap();

        let stopping_driver = driver.clone();
        let stop_task = tokio::spawn(async move {
            stopping_driver.stop().await;
        });
        tokio::time::sleep(Duration::from_millis(10)).await;

        driver.start_task(async {});
        assert!(
            !driver.running(),
            "driver restarted while stop was still waiting for the old task"
        );

        stop_task.await.unwrap();
        assert!(!driver.running());
    }

    #[tokio::test]
    async fn overlapping_stops_keep_start_blocked_until_old_task_finishes() {
        let driver = DriverController::default();
        let (started_tx, started_rx) = oneshot::channel::<()>();
        let (_tx, rx) = oneshot::channel::<()>();

        driver.start_task(async move {
            let _guard = SlowDropFlag;
            let _ = started_tx.send(());
            let _ = rx.await;
        });
        started_rx.await.unwrap();

        let stopping_driver = driver.clone();
        let first_stop = tokio::spawn(async move {
            stopping_driver.stop().await;
        });
        tokio::time::sleep(Duration::from_millis(10)).await;

        let second_stop_driver = driver.clone();
        let second_stop = tokio::spawn(async move {
            second_stop_driver.stop().await;
        });
        tokio::time::sleep(Duration::from_millis(10)).await;

        driver.start_task(async {});

        assert!(
            !driver.running(),
            "driver restarted while an earlier stop was still awaiting the old task"
        );

        first_stop.await.unwrap();
        second_stop.await.unwrap();
        assert!(!driver.running());
    }

    #[tokio::test]
    async fn cancelled_stop_does_not_leave_driver_permanently_stopping() {
        let driver = DriverController::default();
        let (started_tx, started_rx) = oneshot::channel::<()>();
        let (_tx, rx) = oneshot::channel::<()>();

        driver.start_task(async move {
            let _guard = SlowDropFlag;
            let _ = started_tx.send(());
            let _ = rx.await;
        });
        started_rx.await.unwrap();

        let stopping_driver = driver.clone();
        let stop_task = tokio::spawn(async move {
            stopping_driver.stop().await;
        });
        tokio::time::sleep(Duration::from_millis(10)).await;

        stop_task.abort();
        let _ = stop_task.await;

        driver.start_task(async {
            std::future::pending::<()>().await;
        });
        assert!(
            !driver.running(),
            "driver restarted while a cancelled stop was still cleaning up the old task"
        );

        tokio::time::timeout(Duration::from_secs(2), driver.wait_until_idle())
            .await
            .expect("cancelled stop should eventually finish driver teardown");

        driver.start_task(async {
            std::future::pending::<()>().await;
        });

        assert!(
            driver.running(),
            "driver stayed permanently blocked after a cancelled stop"
        );
        driver.stop().await;
    }

    struct DriverDropFlag(Arc<AtomicBool>);

    impl Drop for DriverDropFlag {
        fn drop(&mut self) {
            self.0.store(true, Ordering::Release);
        }
    }

    struct SlowDropFlag;

    impl Drop for SlowDropFlag {
        fn drop(&mut self) {
            std::thread::sleep(Duration::from_millis(100));
        }
    }
}
