use crate::runtime::driver::DriverController;
use rquickjs::{CatchResultExt, CaughtError, Ctx, Exception, FromJs, JsLifetime, Value};
use std::sync::Once;

#[derive(Clone)]
pub(crate) struct RuntimeErrorSink {
    driver: DriverController,
}

impl RuntimeErrorSink {
    pub(crate) fn new(driver: DriverController) -> Self {
        Self { driver }
    }

    pub(crate) fn push(&self, error: String) {
        self.driver.push_error(error);
    }
}

unsafe impl<'js> JsLifetime<'js> for RuntimeErrorSink {
    type Changed<'to> = RuntimeErrorSink;
}

static INSTALL_SPAWN_ERROR_HANDLER: Once = Once::new();

pub(crate) fn install_llrt_spawn_error_handler() {
    INSTALL_SPAWN_ERROR_HANDLER.call_once(|| {
        llrt_context::set_spawn_error_handler(|ctx, error| {
            if let Some(sink) = ctx.userdata::<RuntimeErrorSink>() {
                sink.push(format_caught_error(ctx, error));
            }
        });
    });
}

pub(crate) fn format_caught_error<'js>(ctx: &Ctx<'js>, error: CaughtError<'js>) -> String {
    match error {
        CaughtError::Exception(exception) => exception.to_string(),
        CaughtError::Value(value) => format_value(ctx, value),
        CaughtError::Error(error) => error.to_string(),
    }
}

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
