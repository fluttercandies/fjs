use crate::api::runtime::{JsAsyncContext, JsAsyncRuntime};

pub(crate) async fn cleanup_async_engine_gracefully(
    context: &JsAsyncContext,
    runtime: &JsAsyncRuntime,
) {
    runtime.stop_driver().await;

    let _ = context
        .with_js(async |ctx| {
            let globals = ctx.globals();
            let _ = globals.remove("fjs");
            Ok::<(), anyhow::Error>(())
        })
        .await;

    if runtime.is_job_pending().await {
        runtime.idle().await;
    }
    runtime.run_gc().await;
}

pub(crate) async fn cleanup_async_engine_immediately(
    context: &JsAsyncContext,
    runtime: &JsAsyncRuntime,
) {
    runtime.request_shutdown();
    runtime.stop_driver().await;

    let _ = context
        .with_js(async |ctx| {
            let globals = ctx.globals();
            let _ = globals.remove("fjs");
            Ok::<(), anyhow::Error>(())
        })
        .await;
}
