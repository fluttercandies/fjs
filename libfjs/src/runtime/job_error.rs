pub(crate) use crate::runtime::error_sink::{format_caught_exception, format_value};

pub(crate) fn sync_job_context(context: rquickjs::Context) -> anyhow::Error {
    let message = context.with(|ctx| format_caught_exception(&ctx));
    anyhow::anyhow!("Job raised an exception: {message}")
}

pub(crate) async fn async_job_context(context: rquickjs::AsyncContext) -> anyhow::Error {
    let message = context
        .async_with(async |ctx| format_caught_exception(&ctx))
        .await;
    anyhow::anyhow!("Async job raised an exception: {message}")
}
