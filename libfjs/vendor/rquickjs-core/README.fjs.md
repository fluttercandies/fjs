# fjs rquickjs-core patch

This directory vendors `rquickjs-core` 0.12.0 from
`DelSkayn/rquickjs@144ad6472cd85b472b816c8fe5a166e74059cff5`.

fjs patches only the async runtime driver error path. Upstream `DriveFuture`
keeps spawned futures and QuickJS jobs moving without polling, but its
`JS_ExecutePendingJob` error branch was a TODO and dropped the JavaScript
exception. fjs adds an async runtime job error handler so background jobs can
keep using the event-driven driver while surfacing the real `ctx.catch()` value
to `JsAsyncRuntime.drain_unhandled_job_errors()`.

When upgrading rquickjs, remove this vendor directory only after confirming that
the upstream driver exposes equivalent background job error handling.
