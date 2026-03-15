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
//! - `clear_pending_modules()` - Clear dynamic modules that have not been loaded yet
//! - `get_declared_modules()` - Get all module names
//! - `get_available_modules()` - Get builtin and dynamic module names
//! - `is_module_declared()` - Check if a module exists
//! - `is_module_available()` - Check if a builtin or dynamic module exists

use crate::api::error::{JsError, JsResult};
use crate::api::module::{
    get_loaded_dynamic_module_names, is_dynamic_module_loaded, mark_dynamic_module_loaded,
};
use crate::api::runtime::{JsAsyncContext, call_module_method, result_from_promise};
use crate::api::source::{JsCode, JsEvalOptions, JsModule, get_raw_source_code};
use crate::api::value::JsValue;
use anyhow::anyhow;
use flutter_rust_bridge::{DartFnFuture, frb};
use rquickjs::{CatchResultExt, FromJs, Module, Object, Promise};
use std::collections::{HashMap, HashSet};
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

    /// Transitions the engine into the initializing/running state.
    fn begin_init(&self) -> anyhow::Result<()> {
        let current = self.state.load(Ordering::Acquire);
        if current == STATE_DISPOSED {
            return Err(anyhow!("Engine is disposed"));
        }
        if current == STATE_RUNNING {
            return Err(anyhow!("Engine is already initialized"));
        }

        self.state
            .compare_exchange(
                STATE_CREATED,
                STATE_RUNNING,
                Ordering::AcqRel,
                Ordering::Acquire,
            )
            .map_err(|_| anyhow!("Failed to initialize engine - invalid state"))?;
        Ok(())
    }

    /// Rolls back the init state when initialization fails.
    fn rollback_init(&self) {
        let _ = self.state.compare_exchange(
            STATE_RUNNING,
            STATE_CREATED,
            Ordering::AcqRel,
            Ordering::Acquire,
        );
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
        self.begin_init()?;

        let bridge = Arc::new(bridge);

        let init_result = self
            .context
            .ctx
            .async_with(async |ctx| {
                if let Some(attachment) = &self.context.global_attachment
                    && let Err(e) = attachment.attach(&ctx)
                {
                    return Err(anyhow!("Failed to attach global context: {}", e));
                }
                if let Err(e) = register_fjs(ctx.clone(), bridge) {
                    return Err(anyhow!("Failed to register fjs bridge: {}", e));
                }
                Ok(())
            })
            .await;

        if init_result.is_err() {
            self.rollback_init();
        }

        init_result
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
        self.begin_init()?;

        let init_result = self
            .context
            .ctx
            .async_with(async |ctx| {
                if let Some(attachment) = &self.context.global_attachment
                    && let Err(e) = attachment.attach(&ctx)
                {
                    return Err(anyhow!("Failed to attach global context: {}", e));
                }
                Ok(())
            })
            .await;

        if init_result.is_err() {
            self.rollback_init();
        }

        init_result
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

        if current == STATE_RUNNING {
            let _ = self
                .context
                .ctx
                .async_with(async |ctx| {
                    let globals = ctx.globals();
                    let _ = globals.remove("fjs");
                    Ok::<(), anyhow::Error>(())
                })
                .await;

            if self.context.ctx.runtime().is_job_pending().await {
                self.context.ctx.runtime().idle().await;
            }
            self.context.ctx.runtime().run_gc().await;
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

        let source_code = get_raw_source_code(source)
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
    /// Once a dynamic module has been loaded into this context, it cannot
    /// be replaced without recreating the context.
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

        let JsModule {
            name: module_name,
            source,
        } = module;
        let source_code = get_raw_source_code(source)
            .await
            .map_err(|e| anyhow!("Failed to get module source: {}", e))?;

        let result = self
            .context
            .ctx
            .async_with(async |ctx| {
                if is_dynamic_module_loaded(&ctx, &module_name) {
                    return JsResult::Err(JsError::module(
                        Some(module_name),
                        None,
                        "Module has already been loaded in this context and cannot be redefined; create a new context to replace it",
                    ));
                }
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
    /// Loaded dynamic modules cannot be redefined; recreating the context is
    /// required to replace them.
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

        let mut resolved_modules = Vec::with_capacity(modules.len());
        for module in modules {
            let JsModule { name, source } = module;
            let source_code = get_raw_source_code(source)
                .await
                .map_err(|e| anyhow!("Failed to get module source: {}", e))?;
            resolved_modules.push((name, source_code));
        }

        let result = self
            .context
            .ctx
            .async_with(async |ctx| {
                let conflicts: Vec<_> = resolved_modules
                    .iter()
                    .filter(|(name, _)| is_dynamic_module_loaded(&ctx, name))
                    .map(|(name, _)| name.clone())
                    .collect();
                if !conflicts.is_empty() {
                    return JsResult::Err(JsError::module(
                        Some(conflicts[0].clone()),
                        None,
                        format!(
                            "Loaded dynamic modules cannot be redefined in this context: {}",
                            conflicts.join(", ")
                        ),
                    ));
                }
                if let Some(storage) = ctx.userdata::<Arc<RwLock<HashMap<String, Vec<u8>>>>>() {
                    let mut storage = storage.write().unwrap();
                    storage.extend(resolved_modules);
                    JsResult::Ok(JsValue::None)
                } else {
                    JsResult::Err(JsError::storage("Module storage not initialized"))
                }
            })
            .await;

        result.into_result().map(|_| ())
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
    /// - If the module name has already been loaded in this context
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

        let JsModule {
            name: module_name,
            source,
        } = module;
        let source_code = get_raw_source_code(source)
            .await
            .map_err(|e| anyhow!("Failed to get module source: {}", e))?;

        let result = self
            .context
            .ctx
            .async_with(async |ctx| {
                if is_dynamic_module_loaded(&ctx, &module_name) {
                    return JsResult::Err(JsError::module(
                        Some(module_name),
                        None,
                        "Module has already been loaded in this context and cannot be redefined; create a new context to replace it",
                    ));
                }
                if let Some(storage) = ctx.userdata::<Arc<RwLock<HashMap<String, Vec<u8>>>>>() {
                    storage
                        .write()
                        .unwrap()
                        .insert(module_name.clone(), source_code.clone());
                    let res = Module::evaluate(ctx.clone(), module_name.clone(), source_code);
                    if res.is_ok() {
                        mark_dynamic_module_loaded(&ctx, &module_name);
                    }
                    result_from_promise(&ctx, res).await
                } else {
                    JsResult::Err(JsError::storage("Module storage not initialized"))
                }
            })
            .await;

        result.into_result()
    }

    /// Clears dynamic modules that have not been loaded into the QuickJS module cache.
    ///
    /// Dynamic modules become immutable for the lifetime of the context once they are loaded.
    /// This method only removes still-pending module registrations. Built-in modules and already
    /// loaded dynamic modules are not affected.
    ///
    /// ## Throws
    /// - If the engine is not initialized
    /// - If module storage is not available
    ///
    /// ## Example
    /// ```dart
    /// await engine.clearPendingModules();
    /// ```
    pub async fn clear_pending_modules(&self) -> anyhow::Result<()> {
        self.ensure_running()?;

        let result = self
            .context
            .ctx
            .async_with(async |ctx| {
                if let Some(storage) = ctx.userdata::<Arc<RwLock<HashMap<String, Vec<u8>>>>>() {
                    let loaded: HashSet<_> =
                        get_loaded_dynamic_module_names(&ctx).into_iter().collect();
                    storage
                        .write()
                        .unwrap()
                        .retain(|name, _| loaded.contains(name));
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
                    let mut modules: Vec<_> = storage.read().unwrap().keys().cloned().collect();
                    modules.sort();
                    Ok(modules)
                } else {
                    Err(anyhow!("Module storage not initialized"))
                }
            })
            .await
    }

    /// Gets all modules available to this engine.
    ///
    /// Returns builtin modules, statically configured extra modules,
    /// and dynamically declared modules in a sorted list.
    pub async fn get_available_modules(&self) -> anyhow::Result<Vec<String>> {
        self.ensure_running()?;
        self.context.get_available_modules().await
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

    /// Checks if a module is available to the engine.
    ///
    /// This includes builtin modules, statically configured extra modules,
    /// and dynamically declared modules.
    pub async fn is_module_available(&self, module_name: String) -> anyhow::Result<bool> {
        self.ensure_running()?;
        Ok(self
            .get_available_modules()
            .await?
            .iter()
            .any(|name| name == &module_name))
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
            .async_with(async |ctx| call_module_method(&ctx, module, method, params).await)
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
        move |args: rquickjs::function::Rest<rquickjs::Value<'js>>| -> rquickjs::Result<Promise<'js>> {
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

            let arg = args.0.first().ok_or(rquickjs::Error::MissingArgs {
                expected: 1,
                given: 0,
            })?;

            let js_value = JsValue::from_js(&ctx, arg.clone())?;
            let bridge_ref = bridge.clone();

            Promise::wrap_future(&ctx, async move {
                match bridge_ref(js_value).await {
                    JsResult::Ok(value) => Ok::<JsValue, rquickjs::Error>(value),
                    JsResult::Err(err) => Err(rquickjs::Error::new_from_js_message(
                        "bridge",
                        "JsValue",
                        err.to_string(),
                    )),
                }
            })
        },
    )
    .catch(&ctx_for_catch)
}
