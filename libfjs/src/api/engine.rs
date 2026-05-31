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
//! - `declare_new_bytecode_module()` - Register precompiled module bytecode
//! - `evaluate_bytecode_module()` - Register and execute precompiled module bytecode
//! - `evaluate_script_bytecode()` - Execute precompiled classic script bytecode
//! - `call()` - Call a function in a module
//! - `clear_pending_modules()` - Clear dynamic modules that have not been loaded yet
//! - `get_declared_modules()` - Get all module names
//! - `get_available_modules()` - Get builtin and dynamic module names
//! - `is_module_declared()` - Check if a module exists
//! - `is_module_available()` - Check if a builtin or dynamic module exists

use crate::api::error::{JsError, JsResult};
use crate::api::module::{
    DynamicModuleEntry, DynamicModuleStorage, get_loaded_dynamic_module_names,
    is_dynamic_module_loaded, mark_dynamic_module_loaded,
};
use crate::api::runtime::{
    JsAsyncContext, JsAsyncRuntime, MemoryUsage, call_module_method, result_from_maybe_promise,
    result_from_promise,
};
use crate::api::source::{
    JsBuiltinOptions, JsCode, JsEvalOptions, JsModule, JsModuleBytecode, JsModuleBytecodeBundle,
    JsScriptBytecode, get_raw_source_code,
};
use crate::api::value::JsValue;
use crate::bytecode_support::{
    eval_script_bytecode, load_module_bytecode_checked, validate_module_bundle_impl,
    validate_module_bytecode_impl, validate_script_bytecode_impl,
};
use anyhow::anyhow;
use flutter_rust_bridge::{DartFnFuture, frb};
use rquickjs::{CatchResultExt, FromJs, Module, Object, Promise};
use std::collections::HashSet;
use std::sync::Arc;
use std::sync::atomic::{AtomicU8, Ordering};

/// Type alias for the bridge callback function.
pub type BridgeCallback = dyn Fn(JsValue) -> DartFnFuture<JsResult> + Sync + Send + 'static;

/// Runtime configuration applied when constructing a high-level `JsEngine`.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct JsEngineRuntimeOptions {
    pub memory_limit: Option<usize>,
    pub gc_threshold: Option<usize>,
    pub max_stack_size: Option<usize>,
    pub info: Option<String>,
}

/// Engine state constants
const STATE_CREATED: u8 = 0;
const STATE_INITIALIZING: u8 = 1;
const STATE_RUNNING: u8 = 2;
const STATE_CLOSED: u8 = 3;

/// The JavaScript engine.
///
/// `JsEngine` provides a high-level API for executing JavaScript code,
/// managing modules, and communicating with Dart through a bridge callback.
///
/// ## Lifecycle
///
/// 1. Create an engine with `JsEngine.create(...)`
/// 2. Initialize it with `init(bridge)` or `initWithoutBridge()`
/// 3. Execute JavaScript using `eval()`, `evaluateModule()`, or `call()`
/// 4. Close when done with `close()`
///
/// ## Example
///
/// ```dart
/// final engine = await JsEngine.create(
///   builtins: JsBuiltinOptions.essential(),
/// );
/// await engine.initWithoutBridge();
/// final result = await engine.eval(source: JsCode.code('1 + 1'));
/// print(result.value); // 2
/// await engine.close();
/// ```
#[frb(opaque)]
pub struct JsEngine {
    runtime: JsAsyncRuntime,
    context: JsAsyncContext,
    state: AtomicU8,
}

impl JsEngine {
    /// Creates a new JavaScript engine with custom runtime configuration.
    ///
    /// ## Parameters
    /// - `builtins`: Optional builtin module configuration
    /// - `modules`: Optional list of additional modules to register
    /// - `runtimeOptions`: Optional runtime-level limits and metadata applied
    ///   before the engine context is created
    pub async fn create(
        builtins: Option<JsBuiltinOptions>,
        modules: Option<Vec<JsModule>>,
        runtime_options: Option<JsEngineRuntimeOptions>,
    ) -> anyhow::Result<Self> {
        let runtime = JsAsyncRuntime::create(builtins, modules).await?;
        if let Some(options) = runtime_options {
            if let Some(limit) = options.memory_limit {
                runtime.set_memory_limit(limit).await;
            }
            if let Some(threshold) = options.gc_threshold {
                runtime.set_gc_threshold(threshold).await;
            }
            if let Some(limit) = options.max_stack_size {
                runtime.set_max_stack_size(limit).await;
            }
            if let Some(info) = options.info {
                runtime.set_info(info).await?;
            }
        }
        let context = JsAsyncContext::from(&runtime).await?;

        Ok(Self {
            runtime,
            context,
            state: AtomicU8::new(STATE_CREATED),
        })
    }

    #[cfg(test)]
    pub(crate) fn new_for_test(runtime: JsAsyncRuntime, context: JsAsyncContext) -> Self {
        Self {
            runtime,
            context,
            state: AtomicU8::new(STATE_CREATED),
        }
    }

    #[cfg(test)]
    pub(crate) fn runtime_for_test(&self) -> JsAsyncRuntime {
        self.runtime.clone()
    }

    /// Returns whether the engine has been closed.
    ///
    /// Once closed, the engine cannot be used anymore.
    #[frb(sync, getter)]
    pub fn closed(&self) -> bool {
        self.state.load(Ordering::Acquire) == STATE_CLOSED
    }

    /// Returns whether the engine is running and ready for execution.
    ///
    /// The engine is running after `init()` or `initWithoutBridge()`
    /// has been called successfully.
    #[frb(sync, getter)]
    pub fn running(&self) -> bool {
        self.state.load(Ordering::Acquire) == STATE_RUNNING
    }

    /// Ensures runtime-level controls can be used on this engine.
    fn ensure_runtime_accessible(&self) -> anyhow::Result<()> {
        match self.state.load(Ordering::Acquire) {
            STATE_CREATED | STATE_RUNNING => Ok(()),
            STATE_CLOSED => Err(anyhow!("Engine is closed")),
            STATE_INITIALIZING => Err(anyhow!("Engine is initializing")),
            _ => Err(anyhow!("Engine is in an invalid state")),
        }
    }

    /// Ensures the engine is in running state.
    fn ensure_running(&self) -> anyhow::Result<()> {
        match self.state.load(Ordering::Acquire) {
            STATE_RUNNING => Ok(()),
            STATE_CLOSED => Err(anyhow!("Engine is closed")),
            STATE_INITIALIZING => Err(anyhow!("Engine is initializing")),
            STATE_CREATED => Err(anyhow!("Engine is not initialized")),
            _ => Err(anyhow!("Engine is in an invalid state")),
        }
    }

    /// Transitions the engine into the initializing state.
    fn begin_init(&self) -> anyhow::Result<()> {
        let current = self.state.load(Ordering::Acquire);
        if current == STATE_CLOSED {
            return Err(anyhow!("Engine is closed"));
        }
        if current == STATE_INITIALIZING {
            return Err(anyhow!("Engine is initializing"));
        }
        if current == STATE_RUNNING {
            return Err(anyhow!("Engine is already initialized"));
        }

        self.state
            .compare_exchange(
                STATE_CREATED,
                STATE_INITIALIZING,
                Ordering::AcqRel,
                Ordering::Acquire,
            )
            .map_err(|_| anyhow!("Failed to initialize engine - invalid state"))?;
        Ok(())
    }

    /// Advances the engine-owned runtime by one scheduler step.
    pub async fn execute_pending_job(&self) -> anyhow::Result<bool> {
        self.ensure_runtime_accessible()?;
        self.runtime.execute_pending_job().await
    }

    /// Runs the engine-owned runtime until quiescent.
    pub async fn idle(&self) -> anyhow::Result<()> {
        self.ensure_runtime_accessible()?;
        self.runtime.idle().await;
        Ok(())
    }

    /// Returns whether the engine-owned runtime still has work pending.
    pub async fn is_job_pending(&self) -> anyhow::Result<bool> {
        self.ensure_runtime_accessible()?;
        Ok(self.runtime.is_job_pending().await)
    }

    /// Returns memory usage statistics for the engine-owned runtime.
    pub async fn memory_usage(&self) -> anyhow::Result<MemoryUsage> {
        self.ensure_runtime_accessible()?;
        Ok(self.runtime.memory_usage().await)
    }

    /// Forces a garbage collection pass on the engine-owned runtime.
    pub async fn run_gc(&self) -> anyhow::Result<()> {
        self.ensure_runtime_accessible()?;
        self.runtime.run_gc().await;
        Ok(())
    }

    /// Sets the garbage collection threshold on the engine-owned runtime.
    pub async fn set_gc_threshold(&self, threshold: usize) -> anyhow::Result<()> {
        self.ensure_runtime_accessible()?;
        self.runtime.set_gc_threshold(threshold).await;
        Ok(())
    }

    /// Sets runtime metadata on the engine-owned runtime.
    pub async fn set_info(&self, info: String) -> anyhow::Result<()> {
        self.ensure_runtime_accessible()?;
        self.runtime.set_info(info).await
    }

    /// Sets the max stack size on the engine-owned runtime.
    pub async fn set_max_stack_size(&self, limit: usize) -> anyhow::Result<()> {
        self.ensure_runtime_accessible()?;
        self.runtime.set_max_stack_size(limit).await;
        Ok(())
    }

    /// Sets the memory limit on the engine-owned runtime.
    pub async fn set_memory_limit(&self, limit: usize) -> anyhow::Result<()> {
        self.ensure_runtime_accessible()?;
        self.runtime.set_memory_limit(limit).await;
        Ok(())
    }

    /// Commits initialization after all setup steps succeed.
    fn finish_init(&self) -> anyhow::Result<()> {
        self.state
            .compare_exchange(
                STATE_INITIALIZING,
                STATE_RUNNING,
                Ordering::AcqRel,
                Ordering::Acquire,
            )
            .map_err(|_| anyhow!("Failed to finalize engine initialization"))?;
        Ok(())
    }

    /// Rolls back the init state when initialization fails.
    fn rollback_init(&self) {
        let _ = self.state.compare_exchange(
            STATE_INITIALIZING,
            STATE_CREATED,
            Ordering::AcqRel,
            Ordering::Acquire,
        );
    }

    /// Marks the engine as closed and returns the previous stable state.
    fn begin_close(&self) -> anyhow::Result<u8> {
        loop {
            let current = self.state.load(Ordering::Acquire);
            match current {
                STATE_CLOSED => return Err(anyhow!("Engine is already closed")),
                STATE_INITIALIZING => return Err(anyhow!("Engine is initializing")),
                STATE_CREATED | STATE_RUNNING => {
                    if self
                        .state
                        .compare_exchange(
                            current,
                            STATE_CLOSED,
                            Ordering::AcqRel,
                            Ordering::Acquire,
                        )
                        .is_ok()
                    {
                        return Ok(current);
                    }
                }
                _ => return Err(anyhow!("Engine is in an invalid state")),
            }
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
    /// - If the engine is already closed
    /// - If the engine is already initialized
    /// - If initialization is already in progress
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
        let attachment = self.context.global_attachment.clone();

        let init_result = self
            .context
            .with_js(async move |ctx| {
                if let Some(attachment) = &attachment
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

        init_result?;
        if let Err(error) = self.finish_init() {
            self.rollback_init();
            return Err(error);
        }
        Ok(())
    }

    /// Initializes the engine without a bridge callback.
    ///
    /// Use this when you don't need Dart-JS communication via the bridge.
    /// JavaScript code can still run, but `fjs.bridge_call()` will not be available.
    ///
    /// ## Throws
    /// - If the engine is already closed
    /// - If the engine is already initialized
    /// - If initialization is already in progress
    ///
    /// ## Example
    /// ```dart
    /// await engine.initWithoutBridge();
    /// ```
    pub async fn init_without_bridge(&self) -> anyhow::Result<()> {
        self.begin_init()?;

        let attachment = self.context.global_attachment.clone();
        let init_result = self
            .context
            .with_js(async move |ctx| {
                if let Some(attachment) = &attachment
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

        init_result?;
        if let Err(error) = self.finish_init() {
            self.rollback_init();
            return Err(error);
        }
        Ok(())
    }

    /// Closes the engine and releases resources.
    ///
    /// After close, the engine wrapper cannot be used anymore.
    /// This detaches the `fjs` bridge object, drains pending runtime work,
    /// and triggers a garbage collection pass, but it does not directly
    /// release the underlying runtime or context objects.
    ///
    /// Pending timers, Promise callbacks, and other runtime tasks may run during
    /// this drain step. Errors raised by those drained jobs are handled by the
    /// underlying runtime and are not surfaced through this method.
    ///
    /// ## Throws
    /// - If the engine is already closed
    /// - If initialization is still in progress
    ///
    /// ## Example
    /// ```dart
    /// await engine.close();
    /// ```
    pub async fn close(&self) -> anyhow::Result<()> {
        let previous_state = self.begin_close()?;

        if previous_state == STATE_CREATED || previous_state == STATE_RUNNING {
            let _ = self
                .context
                .with_js(async |ctx| {
                    let globals = ctx.globals();
                    let _ = globals.remove("fjs");
                    Ok::<(), anyhow::Error>(())
                })
                .await;

            if self.runtime.is_job_pending().await {
                self.runtime.idle().await;
            }
            self.runtime.run_gc().await;
        }

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
    /// - If the engine is closed
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
            .with_js(async move |ctx| {
                let res = ctx.eval_with_options(source_code, options.into());
                result_from_promise(&ctx, res).await
            })
            .await;

        result.into_result()
    }

    /// Declares a new bytecode-backed module without executing it.
    ///
    /// The bytecode must have been compiled for the same QuickJS version embedded by FJS and
    /// should only come from trusted sources.
    ///
    /// After declaration, the module can be imported by later evaluations or
    /// `call()` invocations. Once a dynamic module has been loaded in this
    /// context it cannot be replaced without creating a new context.
    ///
    /// ## Example
    /// ```dart
    /// final bytecode = await JsBytecode.compile(
    ///   module: JsModule.code(
    ///     module: 'feature/config',
    ///     code: 'export const version = "2.2.0";',
    ///   ),
    /// );
    ///
    /// await engine.declareNewBytecodeModule(module: bytecode);
    /// ```
    pub async fn declare_new_bytecode_module(
        &self,
        module: JsModuleBytecode,
    ) -> anyhow::Result<()> {
        self.ensure_running()?;
        validate_module_bytecode_impl(&module.name, &module.bytes)?;

        let result = self
            .context
            .with_js(async move |ctx| {
                if is_dynamic_module_loaded(&ctx, &module.name) {
                    return JsResult::Err(JsError::module(
                        Some(module.name),
                        None,
                        "Module has already been loaded in this context and cannot be redefined; create a new context to replace it",
                    ));
                }
                if let Some(storage) = ctx.userdata::<DynamicModuleStorage>() {
                    storage
                        .write()
                        .unwrap()
                        .insert(module.name, DynamicModuleEntry::Bytecode(module.bytes));
                    JsResult::Ok(JsValue::None)
                } else {
                    JsResult::Err(JsError::storage("Module storage not initialized"))
                }
            })
            .await;

        result.into_result().map(|_| ())
    }

    /// Declares multiple bytecode-backed modules without executing them.
    ///
    /// This is the bytecode counterpart to `declareNewModules(...)` and is useful
    /// when a feature depends on several precompiled modules.
    ///
    /// ## Example
    /// ```dart
    /// await engine.declareNewBytecodeModules(modules: [
    ///   coreBytecode,
    ///   helpersBytecode,
    /// ]);
    /// ```
    pub async fn declare_new_bytecode_modules(
        &self,
        modules: Vec<JsModuleBytecode>,
    ) -> anyhow::Result<()> {
        self.ensure_running()?;
        if let Some(duplicate) =
            first_duplicate_name(modules.iter().map(|module| module.name.as_str()))
        {
            return Err(anyhow!("Duplicate module name in request: '{}'", duplicate));
        }
        for module in &modules {
            validate_module_bytecode_impl(&module.name, &module.bytes)?;
        }

        let result = self
            .context
            .with_js(async move |ctx| {
                let conflicts: Vec<_> = modules
                    .iter()
                    .filter(|module| is_dynamic_module_loaded(&ctx, &module.name))
                    .map(|module| module.name.clone())
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
                if let Some(storage) = ctx.userdata::<DynamicModuleStorage>() {
                    let mut storage = storage.write().unwrap();
                    for module in modules {
                        storage.insert(module.name, DynamicModuleEntry::Bytecode(module.bytes));
                    }
                    JsResult::Ok(JsValue::None)
                } else {
                    JsResult::Err(JsError::storage("Module storage not initialized"))
                }
            })
            .await;

        result.into_result().map(|_| ())
    }

    /// Declares a bundle of bytecode-backed modules without executing them.
    ///
    /// The optional bundle entry is ignored during declaration. Use
    /// `evaluateBytecodeBundle(...)` when the entry module should also be
    /// executed.
    ///
    /// ## Example
    /// ```dart
    /// await engine.declareNewBytecodeBundle(bundle: pluginBundle);
    /// ```
    pub async fn declare_new_bytecode_bundle(
        &self,
        bundle: JsModuleBytecodeBundle,
    ) -> anyhow::Result<()> {
        self.ensure_running()?;
        validate_module_bundle_impl(&bundle)?;
        self.declare_new_bytecode_modules(bundle.modules).await
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
    /// await engine.declareNewModule(module: JsModule.code(
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
            .with_js(async move |ctx| {
                if is_dynamic_module_loaded(&ctx, &module_name) {
                    return JsResult::Err(JsError::module(
                        Some(module_name),
                        None,
                        "Module has already been loaded in this context and cannot be redefined; create a new context to replace it",
                    ));
                }
                if let Some(storage) = ctx.userdata::<DynamicModuleStorage>() {
                    storage
                        .write()
                        .unwrap()
                        .insert(module_name, DynamicModuleEntry::Source(source_code));
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
    ///   JsModule.code(module: 'utils', code: 'export const VERSION = "1.0"'),
    ///   JsModule.code(module: 'helpers', code: 'export function log(x) { console.log(x); }'),
    /// ]);
    /// ```
    pub async fn declare_new_modules(&self, modules: Vec<JsModule>) -> anyhow::Result<()> {
        self.ensure_running()?;
        if let Some(duplicate) =
            first_duplicate_name(modules.iter().map(|module| module.name.as_str()))
        {
            return Err(anyhow!("Duplicate module name in request: '{}'", duplicate));
        }

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
            .with_js(async move |ctx| {
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
                if let Some(storage) = ctx.userdata::<DynamicModuleStorage>() {
                    let mut storage = storage.write().unwrap();
                    storage.extend(
                        resolved_modules
                            .into_iter()
                            .map(|(name, source)| (name, DynamicModuleEntry::Source(source))),
                    );
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
    /// top-level code and registers it in the current context.
    ///
    /// QuickJS module evaluation usually completes with `undefined`. Import the module
    /// afterwards if you need its exports.
    ///
    /// ## Parameters
    /// - `module`: The module to evaluate (name and source code)
    ///
    /// ## Returns
    /// The completion value of module evaluation, which is usually `undefined`
    ///
    /// ## Throws
    /// - If the engine is not initialized
    /// - If module storage is not available
    /// - If module execution fails
    /// - If the module name has already been loaded in this context
    ///
    /// ## Example
    /// ```dart
    /// await engine.evaluateModule(module: JsModule.code(
    ///   module: 'init',
    ///   code: '''
    ///     console.log("Module initializing...");
    ///     export default { version: "1.0" };
    ///   ''',
    /// ));
    ///
    /// final loaded = await engine.eval(source: JsCode.code('''
    ///   const { default: info } = await import('init');
    ///   info.version
    /// '''));
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
            .with_js(async move |ctx| {
                if is_dynamic_module_loaded(&ctx, &module_name) {
                    return JsResult::Err(JsError::module(
                        Some(module_name),
                        None,
                        "Module has already been loaded in this context and cannot be redefined; create a new context to replace it",
                    ));
                }
                if let Some(storage) = ctx.userdata::<DynamicModuleStorage>() {
                    storage
                        .write()
                        .unwrap()
                        .insert(module_name.clone(), DynamicModuleEntry::Source(source_code.clone()));
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

    /// Evaluates a bytecode-backed module (registers and executes it).
    ///
    /// The bytecode must have been compiled for the same embedded QuickJS version and should
    /// only be loaded from trusted sources. As with source modules, the completion value is
    /// usually `undefined`; import the module afterwards to read its exports.
    ///
    /// ## Example
    /// ```dart
    /// final bytecode = await JsBytecode.compile(
    ///   module: JsModule.code(
    ///     module: 'feature/init',
    ///     code: 'export default { ready: true };',
    ///   ),
    /// );
    ///
    /// await engine.evaluateBytecodeModule(module: bytecode);
    ///
    /// final result = await engine.eval(source: JsCode.code('''
    ///   const { default: init } = await import('feature/init');
    ///   init.ready
    /// '''));
    /// ```
    pub async fn evaluate_bytecode_module(
        &self,
        module: JsModuleBytecode,
    ) -> anyhow::Result<JsValue> {
        self.ensure_running()?;
        validate_module_bytecode_impl(&module.name, &module.bytes)?;

        let module_name = module.name;
        let bytecode = module.bytes;

        let result = self
            .context
            .with_js(async move |ctx| {
                if is_dynamic_module_loaded(&ctx, &module_name) {
                    return JsResult::Err(JsError::module(
                        Some(module_name),
                        None,
                        "Module has already been loaded in this context and cannot be redefined; create a new context to replace it",
                    ));
                }

                let res = load_module_bytecode_checked(ctx.clone(), &module_name, &bytecode)
                    .and_then(|module| {
                    let embedded_name: String = module.name()?;
                    if embedded_name != module_name {
                        return Err(rquickjs::Error::new_loading_message(
                            module_name.clone(),
                            format!(
                                "Bytecode module name mismatch: expected '{}', found '{}'",
                                module_name, embedded_name
                            ),
                        ));
                    }
                    let (_module, promise) = module.eval()?;
                    Ok(promise)
                });

                if let Some(storage) = ctx.userdata::<DynamicModuleStorage>() {
                    match res {
                        Ok(promise) => {
                            storage.write().unwrap().insert(
                                module_name.clone(),
                                DynamicModuleEntry::Bytecode(bytecode),
                            );
                            mark_dynamic_module_loaded(&ctx, &module_name);
                            result_from_promise(&ctx, Ok(promise)).await
                        }
                        Err(err) => result_from_promise(&ctx, Err(err)).await,
                    }
                } else {
                    JsResult::Err(JsError::storage("Module storage not initialized"))
                }
            })
            .await;

        result.into_result()
    }

    /// Declares a bytecode bundle and evaluates its entry module.
    ///
    /// The bundle entry must be present in `bundle.modules`. The return value is the module
    /// evaluation completion value, so import the entry afterwards if you need exported data.
    ///
    /// ## Example
    /// ```dart
    /// await engine.evaluateBytecodeBundle(bundle: pluginBundle);
    ///
    /// final result = await engine.eval(source: JsCode.code('''
    ///   const { default: plugin } = await import('plugins/main');
    ///   plugin.name
    /// '''));
    /// ```
    pub async fn evaluate_bytecode_bundle(
        &self,
        bundle: JsModuleBytecodeBundle,
    ) -> anyhow::Result<JsValue> {
        self.ensure_running()?;
        validate_module_bundle_impl(&bundle)?;

        let Some(entry) = bundle.entry.clone() else {
            return Err(anyhow!(
                "Bytecode bundle has no entry module; declare it or provide an entry to evaluate"
            ));
        };

        let mut entry_module = None;
        let mut dependencies = Vec::new();
        for module in bundle.modules {
            if module.name == entry {
                entry_module = Some(module);
            } else {
                dependencies.push(module);
            }
        }

        let Some(entry_module) = entry_module else {
            return Err(anyhow!(
                "Bytecode bundle entry '{}' is not present in the bundle",
                entry
            ));
        };

        if !dependencies.is_empty() {
            self.declare_new_bytecode_modules(dependencies).await?;
        }
        self.evaluate_bytecode_module(entry_module).await
    }

    /// Evaluates classic script bytecode in the current global context.
    ///
    /// This is the non-module counterpart to `evaluateBytecodeModule()`.
    ///
    /// Script bytecode may mutate global state and returns the script completion value,
    /// or the resolved value when compiled with top-level await support.
    ///
    /// ## Example
    /// ```dart
    /// final script = await JsBytecode.compileScript(
    ///   name: 'bootstrap.js',
    ///   source: JsCode.code('globalThis.appVersion = "2.2.0";'),
    /// );
    ///
    /// await engine.evaluateScriptBytecode(script: script);
    /// final version = await engine.eval(source: JsCode.code('globalThis.appVersion'));
    /// ```
    pub async fn evaluate_script_bytecode(
        &self,
        script: JsScriptBytecode,
    ) -> anyhow::Result<JsValue> {
        self.ensure_running()?;
        validate_script_bytecode_impl(&script.name, &script.bytes)?;

        let script_name = script.name;
        let bytecode = script.bytes;
        let result = self
            .context
            .with_js(async move |ctx| {
                let res = eval_script_bytecode(&ctx, &script_name, &bytecode);
                result_from_maybe_promise(&ctx, res).await
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
            .with_js(async move |ctx| {
                if let Some(storage) = ctx.userdata::<DynamicModuleStorage>() {
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
            .with_js(async move |ctx| {
                if let Some(storage) = ctx.userdata::<DynamicModuleStorage>() {
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
    /// Returns builtin modules, statically configured modules,
    /// and dynamically declared modules in a sorted list.
    ///
    /// ## Returns
    /// A sorted list of module specifiers that can currently be imported
    ///
    /// ## Throws
    /// - If the engine is not initialized
    /// - If collecting module names fails
    ///
    /// ## Example
    /// ```dart
    /// final modules = await engine.getAvailableModules();
    /// print(modules);
    /// ```
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
            .with_js(async move |ctx| {
                if let Some(storage) = ctx.userdata::<DynamicModuleStorage>() {
                    Ok(storage.read().unwrap().contains_key(&module_name))
                } else {
                    Err(anyhow!("Module storage not initialized"))
                }
            })
            .await
    }

    /// Checks if a module is available to the engine.
    ///
    /// This includes builtin modules, statically configured modules,
    /// and dynamically declared modules.
    ///
    /// ## Parameters
    /// - `moduleName`: The module name to check
    ///
    /// ## Returns
    /// `true` if the module can currently be imported, `false` otherwise
    ///
    /// ## Throws
    /// - If the engine is not initialized
    /// - If collecting module names fails
    ///
    /// ## Example
    /// ```dart
    /// final available = await engine.isModuleAvailable(moduleName: 'path');
    /// print(available);
    /// ```
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
            .with_js(async move |ctx| call_module_method(&ctx, module, method, params).await)
            .await;

        result.into_result()
    }
}

fn first_duplicate_name<'a>(names: impl IntoIterator<Item = &'a str>) -> Option<String> {
    let mut seen = HashSet::new();
    for name in names {
        if !seen.insert(name) {
            return Some(name.to_string());
        }
    }
    None
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
