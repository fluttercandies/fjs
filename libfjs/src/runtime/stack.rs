use crate::runtime::executor;

pub(crate) const ASYNC_MAX_STACK_SIZE: usize = executor::JS_THREAD_STACK_SIZE / 4 * 3;
pub(crate) const SYNC_MAX_STACK_SIZE: usize = 2 * 1024 * 1024 / 4 * 3;

fn clamp(limit: usize, ceiling: usize) -> usize {
    if limit == 0 || limit > ceiling {
        ceiling
    } else {
        limit
    }
}

pub(crate) fn clamp_async(limit: usize) -> usize {
    clamp(limit, ASYNC_MAX_STACK_SIZE)
}

pub(crate) fn clamp_sync(limit: usize) -> usize {
    clamp(limit, SYNC_MAX_STACK_SIZE)
}
