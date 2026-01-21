//! # JavaScript Engine
//!
//! This module provides the core engine implementation that manages
//! the JavaScript runtime lifecycle and bridge communication.
//!
//! ## Simplified API
//!
//! The engine provides direct async methods:
//! - `eval()` - Evaluate JavaScript code
//! - `declare_new_module()` - Register a module without executing
//! - `declare_new_modules()` - Register multiple modules
//! - `evaluate_module()` - Register and execute a module
//! - `call()` - Call a function in a module
//! - `clear_new_modules()` - Clear all dynamic modules
//! - `get_declared_modules()` - Get all module names
//! - `is_module_declared()` - Check if a module exists

use crate::api::error::{JsError, JsResult};
use crate::api::runtime::{call_module_method, result_from_promise, JsAsyncContext};
use crate::api::source::{get_raw_source_code, JsCode, JsEvalOptions, JsModule};
use crate::api::value::JsValue;
use anyhow::anyhow;
use flutter_rust_bridge::{frb, DartFnFuture};
use rquickjs::function::Args;
use rquickjs::{CatchResultExt, FromJs, Module, Object, Promise};
use std::collections::HashMap;
use std::sync::atomic::{AtomicU8, Ordering};
use std::sync::{Arc, RwLock};

/// Type alias for the bridge callback function.
pub type BridgeCallback = dyn Fn(JsValue) -> DartFnFuture<JsResult> + Sync + Send + 'static;

/// Engine state constants
const STATE_CREATED: u8 = 0;
const STATE_RUNNING: u8 = 1;
const STATE_DISPOSED: u8 = 2;

/// The JavaScript engine.
///
/// `JsEngine` provides a high-level API for executing JavaScript code,
/// managing modules, and communicating with Dart through a bridge callback.
///
/// ## Lifecycle
///
/// 1. Create an engine with `JsEngine.new(context)`
/// 2. Initialize it with `init(bridge)` or `initWithoutBridge()`
/// 3. Execute JavaScript using `eval()`, `evaluateModule()`, or `call()`
/// 4. Dispose when done with `dispose()`
///
/// ## Example
///
/// ```dart
/// final runtime = await JsAsyncRuntime.withOptions();
/// final context = await JsAsyncContext.from(runtime: runtime);
/// final engine = JsEngine(context: context);
/// await engine.initWithoutBridge();
/// final result = await engine.eval(source: JsCode.code('1 + 1'));
/// print(result.value); // 2
/// await engine.dispose();
/// ```
#[frb(opaque)]
pub struct JsEngine {
    context: JsAsyncContext,
    state: AtomicU8,
}

impl JsEngine {
    /// Creates a new JavaScript engine from an async context.
    ///
    /// The engine starts in a "created" state and must be initialized
    /// with `init()` or `initWithoutBridge()` before use.
    ///
    /// ## Parameters
    /// - `context`: The async JavaScript execution context
    ///
    /// ## Returns
    /// A new `JsEngine` instance
    ///
    /// ## Example
    /// ```dart
    /// final engine = JsEngine(context: context);
    /// ```
    #[frb(sync)]
    pub fn new(context: &JsAsyncContext) -> anyhow::Result<Self> {
        Ok(Self {
            context: context.clone(),
            state: AtomicU8::new(STATE_CREATED),
        })
    }

    /// Returns the underlying async context.
    ///
    /// This can be used to access lower-level context operations
    /// if needed.
    #[frb(sync, getter)]
    pub fn context(&self) -> JsAsyncContext {
        self.context.clone()
    }

    /// Returns whether the engine has been disposed.
    ///
    /// Once disposed, the engine cannot be used anymore.
    #[frb(sync, getter)]
    pub fn disposed(&self) -> bool {
        self.state.load(Ordering::Acquire) == STATE_DISPOSED
    }

    /// Returns whether the engine is running and ready for execution.
    ///
    /// The engine is running after `init()` or `initWithoutBridge()`
    /// has been called successfully.
    #[frb(sync, getter)]
    pub fn running(&self) -> bool {
        self.state.load(Ordering::Acquire) == STATE_RUNNING
    }

    /// Ensures the engine is in running state.
    fn ensure_running(&self) -> anyhow::Result<()> {
        match self.state.load(Ordering::Acquire) {
            STATE_DISPOSED => Err(anyhow!("Engine is disposed")),
            STATE_CREATED => Err(anyhow!("Engine is not initialized")),
            _ => Ok(()),
        }
    }

    /// Initializes the engine with a bridge callback for Dart-JS communication.
    ///
    /// The bridge callback is invoked when JavaScript calls `fjs.bridge_call(value)`.
    /// This enables bidirectional communication between Dart and JavaScript.
    ///
    /// ## Parameters
    /// - `bridge`: A callback function that receives a `JsValue` from JavaScript
    ///   and returns a `JsResult` back to JavaScript
    ///
    /// ## Throws
    /// - If the engine is already disposed
    /// - If the engine is already initialized
    ///
    /// ## Example
    /// ```dart
    /// await engine.init(bridge: (value) async {
    ///   print('Received from JS: \$value');
    ///   return JsResult.ok(JsValue.string('Response from Dart'));
    /// });
    /// ```
    pub async fn init(
        &self,
        bridge: impl Fn(JsValue) -> DartFnFuture<JsResult> + Sync + Send + 'static,
    ) -> anyhow::Result<()> {
        let current = self.state.load(Ordering::Acquire);
        if current == STATE_DISPOSED {
            return Err(anyhow!("Engine is disposed"));
        }
        if current == STATE_RUNNING {
            return Err(anyhow!("Engine is already initialized"));
        }

        // Transition to running state
        if self
            .state
            .compare_exchange(
                STATE_CREATED,
                STATE_RUNNING,
                Ordering::AcqRel,
                Ordering::Acquire,
            )
            .is_err()
        {
            return Err(anyhow!("Failed to initialize engine - invalid state"));
        }

        let bridge = Arc::new(bridge);

        self.context
            .ctx
            .async_with(async |ctx| {
                if let Some(attachment) = &self.context.global_attachment {
                    if let Err(e) = attachment.attach(&ctx) {
                        return Err(anyhow!("Failed to attach global context: {}", e));
                    }
                }
                if let Err(e) = register_fjs(ctx.clone(), bridge) {
                    return Err(anyhow!("Failed to register fjs bridge: {}", e));
                }
                Ok(())
            })
            .await
    }

    /// Initializes the engine without a bridge callback.
    ///
    /// Use this when you don't need Dart-JS communication via the bridge.
    /// JavaScript code can still run, but `fjs.bridge_call()` will not be available.
    ///
    /// ## Throws
    /// - If the engine is already disposed
    /// - If the engine is already initialized
    ///
    /// ## Example
    /// ```dart
    /// await engine.initWithoutBridge();
    /// ```
    pub async fn init_without_bridge(&self) -> anyhow::Result<()> {
        let current = self.state.load(Ordering::Acquire);
        if current == STATE_DISPOSED {
            return Err(anyhow!("Engine is disposed"));
        }
        if current == STATE_RUNNING {
            return Err(anyhow!("Engine is already initialized"));
        }

        // Transition to running state
        if self
            .state
            .compare_exchange(
                STATE_CREATED,
                STATE_RUNNING,
                Ordering::AcqRel,
                Ordering::Acquire,
            )
            .is_err()
        {
            return Err(anyhow!("Failed to initialize engine - invalid state"));
        }

        self.context
            .ctx
            .async_with(async |ctx| {
                if let Some(attachment) = &self.context.global_attachment {
                    if let Err(e) = attachment.attach(&ctx) {
                        return Err(anyhow!("Failed to attach global context: {}", e));
                    }
                }
                Ok(())
            })
            .await
    }

    /// Disposes the engine and releases resources.
    ///
    /// After disposal, the engine cannot be used anymore.
    /// Any pending operations will fail.
    ///
    /// ## Throws
    /// - If the engine is already disposed
    pub async fn dispose(&self) -> anyhow::Result<()> {
        let current = self.state.load(Ordering::Acquire);
        if current == STATE_DISPOSED {
            return Err(anyhow!("Engine is already disposed"));
        }
        self.state.store(STATE_DISPOSED, Ordering::Release);
        Ok(())
    }

    /// Evaluates JavaScript code and returns the result.
    ///
    /// Supports both synchronous and asynchronous JavaScript code.
    /// Top-level await is enabled by default.
    ///
    /// ## Parameters
    /// - `source`: The JavaScript code to evaluate (string, path, or bytes)
    /// - `options`: Optional evaluation settings (defaults to promise-enabled mode)
    ///
    /// ## Returns
    /// The result of the evaluation as a `JsValue`
    ///
    /// ## Throws
    /// - If the engine is not initialized
    /// - If the engine is disposed
    /// - If JavaScript execution fails
    ///
    /// ## Example
    /// ```dart
    /// // Simple expression
    /// final result = await engine.eval(source: JsCode.code('1 + 1'));
    /// print(result.value); // 2
    ///
    /// // Async code
    /// final asyncResult = await engine.eval(source: JsCode.code('''
    ///   await new Promise(resolve => setTimeout(() => resolve('done'), 100))
    /// '''));
    /// ```
    pub async fn eval(
        &self,
        source: JsCode,
        options: Option<JsEvalOptions>,
    ) -> anyhow::Result<JsValue> {
        self.ensure_running()?;

        let mut options = options.unwrap_or_default();
        options.promise = Some(true);

        let source_code = get_raw_source_code(source.clone())
            .await
            .map_err(|e| anyhow!("Failed to get source code: {}", e))?;

        let result = self
            .context
            .ctx
            .async_with(async |ctx| {
                let res = ctx.eval_with_options(source_code, options.into());
                result_from_promise(&ctx, res).await
            })
            .await;

        result.into_result()
    }

    /// Declares a new module without executing it.
    ///
    /// The module will be available for import in subsequent evaluations.
    /// Use this when you need to register a module for later use.
    ///
    /// ## Parameters
    /// - `module`: The module to declare (name and source code)
    ///
    /// ## Throws
    /// - If the engine is not initialized
    /// - If module storage is not available
    ///
    /// ## Example
    /// ```dart
    /// await engine.declareNewModule(module: JsModule.fromCode(
    ///   module: 'math-utils',
    ///   code: 'export function add(a, b) { return a + b; }',
    /// ));
    ///
    /// // Later, import and use it
    /// final result = await engine.eval(source: JsCode.code('''
    ///   const { add } = await import('math-utils');
    ///   add(1, 2)
    /// '''));
    /// ```
    pub async fn declare_new_module(&self, module: JsModule) -> anyhow::Result<()> {
        self.ensure_running()?;

        let source_code = get_raw_source_code(module.source.clone())
            .await
            .map_err(|e| anyhow!("Failed to get module source: {}", e))?;

        let module_name = module.name.clone();
        let result = self
            .context
            .ctx
            .async_with(async |ctx| {
                if let Some(storage) = ctx.userdata::<Arc<RwLock<HashMap<String, Vec<u8>>>>>() {
                    storage.write().unwrap().insert(module_name, source_code);
                    JsResult::Ok(JsValue::None)
                } else {
                    JsResult::Err(JsError::storage("Module storage not initialized"))
                }
            })
            .await;

        result.into_result().map(|_| ())
    }

    /// Declares multiple new modules without executing them.
    ///
    /// Convenience method for registering multiple modules at once.
    ///
    /// ## Parameters
    /// - `modules`: List of modules to declare
    ///
    /// ## Throws
    /// - If the engine is not initialized
    /// - If any module declaration fails
    ///
    /// ## Example
    /// ```dart
    /// await engine.declareNewModules(modules: [
    ///   JsModule.fromCode(module: 'utils', code: 'export const VERSION = "1.0"'),
    ///   JsModule.fromCode(module: 'helpers', code: 'export function log(x) { console.log(x); }'),
    /// ]);
    /// ```
    pub async fn declare_new_modules(&self, modules: Vec<JsModule>) -> anyhow::Result<()> {
        self.ensure_running()?;

        for module in modules {
            self.declare_new_module(module).await?;
        }
        Ok(())
    }

    /// Evaluates a module (registers and executes it).
    ///
    /// Unlike `declareNewModule`, this method also executes the module's
    /// top-level code and returns its default export or last expression value.
    ///
    /// ## Parameters
    /// - `module`: The module to evaluate (name and source code)
    ///
    /// ## Returns
    /// The result of module evaluation
    ///
    /// ## Throws
    /// - If the engine is not initialized
    /// - If module storage is not available
    /// - If module execution fails
    ///
    /// ## Example
    /// ```dart
    /// final result = await engine.evaluateModule(module: JsModule.fromCode(
    ///   module: 'init',
    ///   code: '''
    ///     console.log("Module initializing...");
    ///     export default { version: "1.0" };
    ///   ''',
    /// ));
    /// ```
    pub async fn evaluate_module(&self, module: JsModule) -> anyhow::Result<JsValue> {
        self.ensure_running()?;

        let source_code = get_raw_source_code(module.source.clone())
            .await
            .map_err(|e| anyhow!("Failed to get module source: {}", e))?;

        let module_name = module.name.clone();
        let result = self
            .context
            .ctx
            .async_with(async |ctx| {
                if let Some(storage) = ctx.userdata::<Arc<RwLock<HashMap<String, Vec<u8>>>>>() {
                    storage
                        .write()
                        .unwrap()
                        .insert(module_name.clone(), source_code.clone());
                    let res = Module::evaluate(ctx.clone(), module_name, source_code);
                    result_from_promise(&ctx, res).await
                } else {
                    JsResult::Err(JsError::storage("Module storage not initialized"))
                }
            })
            .await;

        result.into_result()
    }

    /// Clears all dynamically declared modules.
    ///
    /// Removes all modules that were registered via `declareNewModule` or `declareNewModules`.
    /// Built-in modules are not affected.
    ///
    /// ## Throws
    /// - If the engine is not initialized
    /// - If module storage is not available
    ///
    /// ## Example
    /// ```dart
    /// await engine.clearNewModules();
    /// ```
    pub async fn clear_new_modules(&self) -> anyhow::Result<()> {
        self.ensure_running()?;

        let result = self
            .context
            .ctx
            .async_with(async |ctx| {
                if let Some(storage) = ctx.userdata::<Arc<RwLock<HashMap<String, Vec<u8>>>>>() {
                    storage.write().unwrap().clear();
                    JsResult::Ok(JsValue::None)
                } else {
                    JsResult::Err(JsError::storage("Module storage not initialized"))
                }
            })
            .await;

        result.into_result().map(|_| ())
    }

    /// Gets all declared module names.
    ///
    /// Returns a list of all dynamically registered module names.
    ///
    /// ## Returns
    /// List of module names as strings
    ///
    /// ## Throws
    /// - If the engine is not initialized
    /// - If module storage is not available
    ///
    /// ## Example
    /// ```dart
    /// final modules = await engine.getDeclaredModules();
    /// print('Declared modules: $modules');
    /// ```
    pub async fn get_declared_modules(&self) -> anyhow::Result<Vec<String>> {
        self.ensure_running()?;

        self.context
            .ctx
            .async_with(async |ctx| {
                if let Some(storage) = ctx.userdata::<Arc<RwLock<HashMap<String, Vec<u8>>>>>() {
                    Ok(storage.read().unwrap().keys().cloned().collect())
                } else {
                    Err(anyhow!("Module storage not initialized"))
                }
            })
            .await
    }

    /// Checks if a module is declared.
    ///
    /// ## Parameters
    /// - `moduleName`: The name of the module to check
    ///
    /// ## Returns
    /// `true` if the module exists, `false` otherwise
    ///
    /// ## Throws
    /// - If the engine is not initialized
    /// - If module storage is not available
    ///
    /// ## Example
    /// ```dart
    /// if (await engine.isModuleDeclared(moduleName: 'my-module')) {
    ///   print('Module exists!');
    /// }
    /// ```
    pub async fn is_module_declared(&self, module_name: String) -> anyhow::Result<bool> {
        self.ensure_running()?;

        self.context
            .ctx
            .async_with(async |ctx| {
                if let Some(storage) = ctx.userdata::<Arc<RwLock<HashMap<String, Vec<u8>>>>>() {
                    Ok(storage.read().unwrap().contains_key(&module_name))
                } else {
                    Err(anyhow!("Module storage not initialized"))
                }
            })
            .await
    }

    /// Calls a function in a module.
    ///
    /// Imports the specified module and invokes one of its exported functions.
    ///
    /// ## Parameters
    /// - `module`: The module name to import
    /// - `method`: The function name to call (must be exported from the module)
    /// - `params`: Optional parameters to pass to the function
    ///
    /// ## Returns
    /// The result of the function call as a `JsValue`
    ///
    /// ## Throws
    /// - If the engine is not initialized
    /// - If the module cannot be imported
    /// - If the function does not exist
    /// - If the function call fails
    ///
    /// ## Example
    /// ```dart
    /// // Call a function with parameters
    /// final result = await engine.call(
    ///   module: 'math-utils',
    ///   method: 'add',
    ///   params: [JsValue.integer(1), JsValue.integer(2)],
    /// );
    /// print(result.value); // 3
    ///
    /// // Call a function without parameters
    /// final version = await engine.call(
    ///   module: 'config',
    ///   method: 'getVersion',
    /// );
    /// ```
    pub async fn call(
        &self,
        module: String,
        method: String,
        params: Option<Vec<JsValue>>,
    ) -> anyhow::Result<JsValue> {
        self.ensure_running()?;

        let params = params.unwrap_or_default();
        let result = self
            .context
            .ctx
            .async_with(async |ctx| {
                call_module_method(&ctx, module, method, params).await
            })
            .await;

        result.into_result()
    }
}

/// Registers the fjs bridge object.
fn register_fjs<'js>(
    ctx: rquickjs::Ctx<'js>,
    bridge: Arc<BridgeCallback>,
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
    bridge: Arc<BridgeCallback>,
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

            let arg = args.0.first().ok_or_else(|| rquickjs::Error::MissingArgs {
                expected: 1,
                given: 0,
            })?;

            let js_value = JsValue::from_js(&ctx, arg.clone())?;
            let bridge_ref = bridge.clone();
            let (promise, resolve, reject) = ctx.promise()?;
            let ctx_s = ctx.clone();

            ctx.spawn(async move {
                let res = bridge_ref(js_value).await;
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
            });
            Ok(promise)
        },
    )
    .catch(&ctx_for_catch)
}
