use rquickjs::{CatchResultExt, Ctx, Exception, FromJs, Value};

pub(crate) fn format_caught_exception<'js>(ctx: &Ctx<'js>) -> String {
    format_value(ctx, ctx.catch())
}

pub(crate) fn format_value<'js>(ctx: &Ctx<'js>, value: Value<'js>) -> String {
    if let Some(exception) = value.clone().into_object().and_then(Exception::from_object) {
        return exception.to_string();
    }

    if let Ok(message) = String::from_js(ctx, value.clone()).catch(ctx) {
        return message;
    }

    format!("{value:?}")
}

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
