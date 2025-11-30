//! # JavaScript Engine Core
//!
//! This module provides the core engine implementation that manages
//! the JavaScript runtime lifecycle, action processing, and bridge communication.

use crate::api::error::{JsError, JsResult};
use crate::api::runtime::{result_from_promise, JsAsyncContext};
use crate::api::source::{get_raw_source_code, JsCode, JsEvalOptions, JsModule};
use crate::api::value::JsValue;
use anyhow::anyhow;
use flutter_rust_bridge::{frb, DartFnFuture};
use rquickjs::function::Args;
use rquickjs::{async_with, CatchResultExt, FromJs, Module, Object, Promise};
use std::collections::HashMap;
use std::sync::atomic::{AtomicU8, Ordering};
use std::sync::{Arc, RwLock};
use tokio::sync::Mutex;

/// Engine state constants
const STATE_CREATED: u8 = 0;
const STATE_RUNNING: u8 = 1;
const STATE_DISPOSED: u8 = 2;

/// Represents an action that can be executed by the engine.
#[derive(Debug, Clone)]
pub enum JsAction {
    /// Evaluate JavaScript code.
    Eval {
        id: u32,
        source: JsCode,
        options: Option<JsEvalOptions>,
    },
    /// Declare a new module.
    DeclareNewModule { id: u32, module: JsModule },
    /// Declare multiple modules.
    DeclareNewModules { id: u32, modules: Vec<JsModule> },
    /// Clear all dynamic modules.
    ClearNewModules { id: u32 },
    /// Evaluate a module.
    EvaluateModule { id: u32, module: JsModule },
    /// Get all declared module names.
    GetDeclaredModules { id: u32 },
    /// Check if a module is declared.
    IsModuleDeclared { id: u32, module_name: String },
    /// Call a function in a module.
    CallFunction {
        id: u32,
        module: String,
        method: String,
        params: Option<Vec<JsValue>>,
    },
}

/// Result of a JavaScript action execution.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub struct JsActionResult {
    pub id: u32,
    pub result: JsResult,
}

/// Callback from the JavaScript engine to Dart.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub enum JsCallback {
    /// Engine has been initialized.
    Initialized,
    /// Action execution result.
    Handler(JsActionResult),
    /// Bridge call from JavaScript.
    Bridge(JsValue),
}

/// Result of handling a callback.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub enum JsCallbackResult {
    /// Initialization acknowledged.
    Initialized,
    /// Handler acknowledged.
    Handler,
    /// Bridge call result.
    Bridge(JsResult),
}

/// The core JavaScript engine.
#[frb(opaque)]
pub struct JsEngineCore {
    context: JsAsyncContext,
    sender: tokio::sync::mpsc::UnboundedSender<JsAction>,
    receiver: Arc<Mutex<tokio::sync::mpsc::UnboundedReceiver<JsAction>>>,
    state: AtomicU8,
}

impl JsEngineCore {
    /// Creates a new engine core.
    #[frb(sync)]
    pub fn new(context: &JsAsyncContext) -> anyhow::Result<Self> {
        let (sender, receiver) = tokio::sync::mpsc::unbounded_channel();
        Ok(Self {
            context: context.clone(),
            sender,
            receiver: Arc::new(Mutex::new(receiver)),
            state: AtomicU8::new(STATE_CREATED),
        })
    }

    /// Returns the context.
    #[frb(sync, getter)]
    pub fn context(&self) -> JsAsyncContext {
        self.context.clone()
    }

    /// Returns whether the engine is disposed.
    #[frb(sync, getter)]
    pub fn disposed(&self) -> bool {
        self.state.load(Ordering::Acquire) == STATE_DISPOSED
    }

    /// Returns whether the engine is running.
    #[frb(sync, getter)]
    pub fn running(&self) -> bool {
        self.state.load(Ordering::Acquire) == STATE_RUNNING
    }

    /// Disposes the engine.
    pub async fn dispose(&self) -> anyhow::Result<()> {
        let current = self.state.load(Ordering::Acquire);
        if current == STATE_DISPOSED {
            return Err(anyhow!("Engine is already disposed"));
        }
        self.state.store(STATE_DISPOSED, Ordering::Release);
        Ok(())
    }

    /// Executes an action.
    pub async fn exec(&self, action: JsAction) -> anyhow::Result<()> {
        let state = self.state.load(Ordering::Acquire);
        if state == STATE_DISPOSED {
            return Err(anyhow!("Engine is disposed"));
        }
        if state != STATE_RUNNING {
            return Err(anyhow!("Engine is not running"));
        }
        self.sender
            .send(action)
            .map_err(|e| anyhow!("Failed to send action: {}", e))
    }

    /// Starts the engine event loop.
    pub async fn start(
        &self,
        bridge: impl Fn(JsCallback) -> DartFnFuture<JsCallbackResult> + Sync + Send + 'static,
    ) -> anyhow::Result<()> {
        let current = self.state.load(Ordering::Acquire);
        if current == STATE_DISPOSED {
            return Err(anyhow!("Engine is disposed"));
        }
        if current == STATE_RUNNING {
            return Err(anyhow!("Engine is already running"));
        }

        // Transition to running state
        if self
            .state
            .compare_exchange(STATE_CREATED, STATE_RUNNING, Ordering::AcqRel, Ordering::Acquire)
            .is_err()
        {
            return Err(anyhow!("Failed to start engine - invalid state"));
        }

        // State guard
        struct StateGuard<'a> {
            state: &'a AtomicU8,
        }
        impl<'a> Drop for StateGuard<'a> {
            fn drop(&mut self) {
                self.state.store(STATE_DISPOSED, Ordering::Release);
            }
        }
        let _guard = StateGuard { state: &self.state };

        let cb = Arc::new(bridge);

        async_with!(self.context.ctx => |ctx| {
            if let Some(attachment) = &self.context.global_attachment {
                if let Err(e) = attachment.attach(&ctx) {
                    return Err(anyhow!("Failed to attach global context: {}", e));
                }
            }
            if let Err(e) = register_fjs(ctx.clone(), cb.clone()) {
                return Err(anyhow!("Failed to register fjs bridge: {}", e));
            }

            cb(JsCallback::Initialized).await;

            loop {
                let mut receiver = self.receiver.lock().await;
                match receiver.recv().await {
                    None => return Ok(()),
                    Some(action) => {
                        drop(receiver);
                        let ctx_s = ctx.clone();
                        let cb_clone = cb.clone();
                        ctx.spawn(async move {
                            Self::handle_action(ctx_s, cb_clone, action).await;
                        });
                    }
                }
            }
        })
        .await
    }

    /// Handles a single action.
    async fn handle_action(
        ctx: rquickjs::Ctx<'_>,
        cb: Arc<dyn Fn(JsCallback) -> DartFnFuture<JsCallbackResult> + Sync + Send + 'static>,
        action: JsAction,
    ) {
        match action {
            JsAction::Eval { id, source, options } => {
                let mut options = options.unwrap_or_default();
                options.promise = Some(true);
                let res = match get_raw_source_code(source.clone()).await {
                    Err(e) => JsResult::Err(JsError::io(
                        source.as_path().map(|s| s.to_string()),
                        e.to_string(),
                    )),
                    Ok(source_code) => {
                        let res = ctx.eval_with_options(source_code, options.into());
                        result_from_promise(&ctx, res).await
                    }
                };
                cb(JsCallback::Handler(JsActionResult { id, result: res })).await;
            }

            JsAction::DeclareNewModule { id, module } => {
                let res = Self::declare_module(&ctx, module).await;
                cb(JsCallback::Handler(JsActionResult { id, result: res })).await;
            }

            JsAction::DeclareNewModules { id, modules } => {
                let mut last_result = JsResult::Ok(JsValue::None);
                for module in modules {
                    let res = Self::declare_module(&ctx, module).await;
                    if res.is_err() {
                        last_result = res;
                        break;
                    }
                }
                cb(JsCallback::Handler(JsActionResult {
                    id,
                    result: last_result,
                }))
                .await;
            }

            JsAction::EvaluateModule { id, module } => {
                let res = match get_raw_source_code(module.source.clone()).await {
                    Err(e) => JsResult::Err(JsError::io(
                        module.source.as_path().map(|s| s.to_string()),
                        e.to_string(),
                    )),
                    Ok(source_code) => {
                        if let Some(storage) =
                            ctx.userdata::<Arc<RwLock<HashMap<String, Vec<u8>>>>>()
                        {
                            storage
                                .write()
                                .unwrap()
                                .insert(module.name.clone(), source_code.clone());
                            let res = Module::evaluate(ctx.clone(), module.name, source_code);
                            result_from_promise(&ctx, res).await
                        } else {
                            JsResult::Err(JsError::storage("Module storage not initialized"))
                        }
                    }
                };
                cb(JsCallback::Handler(JsActionResult { id, result: res })).await;
            }

            JsAction::ClearNewModules { id } => {
                let res = if let Some(storage) =
                    ctx.userdata::<Arc<RwLock<HashMap<String, Vec<u8>>>>>()
                {
                    storage.write().unwrap().clear();
                    JsResult::Ok(JsValue::None)
                } else {
                    JsResult::Err(JsError::storage("Module storage not initialized"))
                };
                cb(JsCallback::Handler(JsActionResult { id, result: res })).await;
            }

            JsAction::GetDeclaredModules { id } => {
                let res = if let Some(storage) =
                    ctx.userdata::<Arc<RwLock<HashMap<String, Vec<u8>>>>>()
                {
                    let names: Vec<JsValue> = storage
                        .read()
                        .unwrap()
                        .keys()
                        .cloned()
                        .map(JsValue::String)
                        .collect();
                    JsResult::Ok(JsValue::Array(names))
                } else {
                    JsResult::Err(JsError::storage("Module storage not initialized"))
                };
                cb(JsCallback::Handler(JsActionResult { id, result: res })).await;
            }

            JsAction::IsModuleDeclared { id, module_name } => {
                let res = if let Some(storage) =
                    ctx.userdata::<Arc<RwLock<HashMap<String, Vec<u8>>>>>()
                {
                    let is_declared = storage.read().unwrap().contains_key(&module_name);
                    JsResult::Ok(JsValue::Boolean(is_declared))
                } else {
                    JsResult::Err(JsError::storage("Module storage not initialized"))
                };
                cb(JsCallback::Handler(JsActionResult { id, result: res })).await;
            }

            JsAction::CallFunction {
                id,
                module,
                method,
                params,
            } => {
                let params = params.unwrap_or_default();
                let res = match Module::import(&ctx, module.clone()).catch(&ctx) {
                    Ok(promise) => {
                        match promise.into_future::<rquickjs::Value>().await.catch(&ctx) {
                            Ok(v) if v.is_object() => {
                                if let Some(obj) = v.as_object() {
                                    let m: rquickjs::Result<rquickjs::Value> = obj.get(&method);
                                    match m.catch(&ctx) {
                                        Ok(m) if m.is_function() => {
                                            if let Some(func) = m.as_function() {
                                                let res = func
                                                    .call((rquickjs::function::Rest(params),));
                                                result_from_promise(&ctx, res).await
                                            } else {
                                                JsResult::Err(JsError::module(
                                                    Some(module),
                                                    Some(method),
                                                    "Method is not a function",
                                                ))
                                            }
                                        }
                                        Ok(_) => JsResult::Err(JsError::module(
                                            Some(module),
                                            Some(method),
                                            "Method is not a function",
                                        )),
                                        Err(e) => JsResult::Err(JsError::module(
                                            Some(module),
                                            Some(method),
                                            format!("Failed to get method: {}", e),
                                        )),
                                    }
                                } else {
                                    JsResult::Err(JsError::module(
                                        Some(module),
                                        None,
                                        "Module is not an object",
                                    ))
                                }
                            }
                            Ok(_) => JsResult::Err(JsError::module(
                                Some(module),
                                None,
                                "Module is not an object",
                            )),
                            Err(e) => JsResult::Err(JsError::module(
                                Some(module),
                                None,
                                format!("Failed to import: {}", e),
                            )),
                        }
                    }
                    Err(e) => JsResult::Err(JsError::module(
                        Some(module),
                        None,
                        format!("Failed to import: {}", e),
                    )),
                };
                cb(JsCallback::Handler(JsActionResult { id, result: res })).await;
            }
        }
    }

    async fn declare_module(ctx: &rquickjs::Ctx<'_>, module: JsModule) -> JsResult {
        match get_raw_source_code(module.source.clone()).await {
            Err(e) => JsResult::Err(JsError::io(
                module.source.as_path().map(|s| s.to_string()),
                e.to_string(),
            )),
            Ok(source_code) => {
                if let Some(storage) = ctx.userdata::<Arc<RwLock<HashMap<String, Vec<u8>>>>>() {
                    storage.write().unwrap().insert(module.name, source_code);
                    JsResult::Ok(JsValue::None)
                } else {
                    JsResult::Err(JsError::storage("Module storage not initialized"))
                }
            }
        }
    }
}

/// Registers the fjs bridge object.
fn register_fjs<'js>(
    ctx: rquickjs::Ctx<'js>,
    bridge: Arc<dyn Fn(JsCallback) -> DartFnFuture<JsCallbackResult> + Sync + Send + 'static>,
) -> rquickjs::CaughtResult<'js, ()> {
    let fjs = Object::new(ctx.clone()).catch(&ctx)?;
    fjs.set("bridge_call", new_bridge_call(ctx.clone(), bridge)?)
        .catch(&ctx)?;
    ctx.globals().set("fjs", fjs).catch(&ctx)?;
    Ok(())
}

/// Creates the bridge_call function.
fn new_bridge_call<'js>(
    ctx: rquickjs::Ctx<'js>,
    bridge: Arc<dyn Fn(JsCallback) -> DartFnFuture<JsCallbackResult> + Sync + Send + 'static>,
) -> rquickjs::CaughtResult<'js, rquickjs::Function<'js>> {
    let ctx_for_catch = ctx.clone();
    rquickjs::Function::new(
        ctx.clone(),
        move |args: rquickjs::function::Rest<rquickjs::Value<'js>>| -> rquickjs::Result<Promise> {
            if args.0.len() > 1 {
                return Err(rquickjs::Error::TooManyArgs {
                    expected: 1,
                    given: args.len(),
                });
            }
            if args.0.is_empty() {
                return Err(rquickjs::Error::MissingArgs {
                    expected: 1,
                    given: 0,
                });
            }

            let arg = args
                .0
                .first()
                .ok_or_else(|| rquickjs::Error::MissingArgs {
                    expected: 1,
                    given: 0,
                })?;

            let js_value = JsValue::from_js(&ctx, arg.clone())?;
            let bridge_call = bridge.clone();
            let (promise, resolve, reject) = ctx.promise()?;
            let ctx_s = ctx.clone();

            ctx.spawn(async move {
                let res = bridge_call(JsCallback::Bridge(js_value)).await;
                if let JsCallbackResult::Bridge(res) = res {
                    match res {
                        JsResult::Ok(value) => {
                            let mut args = Args::new(ctx_s.clone(), 1);
                            if let Err(e) = args.push_arg(value) {
                                let mut reject_args = Args::new(ctx_s, 1);
                                let _ = reject_args.push_arg(format!("Internal error: {}", e));
                                let _ = reject.call_arg::<()>(reject_args);
                                return;
                            }
                            let _ = resolve.call_arg::<()>(args);
                        }
                        JsResult::Err(err) => {
                            let mut args = Args::new(ctx_s, 1);
                            if args.push_arg(err.to_string()).is_err() {
                                return;
                            }
                            let _ = reject.call_arg::<()>(args);
                        }
                    }
                }
            });
            Ok(promise)
        },
    )
    .catch(&ctx_for_catch)
}
