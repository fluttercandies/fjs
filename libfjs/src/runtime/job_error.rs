pub(crate) use crate::runtime::error_sink::format_value;

use crate::api::error::JsError;

pub(crate) fn sync_job_context(context: rquickjs::Context) -> JsError {
    context.with(|ctx| JsError::from_pending_exception(&ctx))
}

pub(crate) async fn async_job_context(context: rquickjs::AsyncContext) -> JsError {
    context
        .async_with(async |ctx| JsError::from_pending_exception(&ctx))
        .await
}
