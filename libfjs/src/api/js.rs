//! # JavaScript Runtime API
//!
//! This module provides the core JavaScript runtime functionality for Flutter integration.
//! It includes support for both synchronous and asynchronous JavaScript execution,
//! module management, and bidirectional communication between Dart and JavaScript.
//!
//! ## Key Components
//!
//! - **Runtime Management**: Configuration and lifecycle management of JavaScript runtimes
//! - **Context Management**: Execution contexts with isolation and state management
//! - **Module System**: Dynamic loading, resolution, and execution of JavaScript modules
//! - **Error Handling**: Comprehensive error types and propagation mechanisms
//! - **Bridge Communication**: Bidirectional communication between Dart and JavaScript
//!
//! ## Thread Safety
//!
//! All runtime types are designed to be thread-safe where appropriate. Async runtimes
//! can be shared across threads, while sync runtimes have more restrictive access patterns.

use crate::api::module::{
    DynamicModuleLoader, DynamicModuleResolver, GlobalAttachment, ModuleBuilder,
};
use crate::api::value::JsValue;
use anyhow::anyhow;
use flutter_rust_bridge::{frb, DartFnFuture};
use rquickjs::function::Args;
use rquickjs::loader::{BuiltinLoader, BuiltinResolver, FileResolver, NativeLoader, ScriptLoader};
use rquickjs::{async_with, CatchResultExt, FromJs, Module, Object, Promise};
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, RwLock};
use tokio::io::AsyncReadExt;
use tokio::sync::Mutex;

/// Maximum file size for JavaScript source files (10 MB)
///
/// This constant limits the maximum size of JavaScript files that can be loaded
/// to prevent memory exhaustion and potential DoS attacks.
const MAX_FILE_SIZE: u64 = 10 * 1024 * 1024; // 10 MB

/// Memory usage statistics for the JavaScript runtime.
///
/// This struct provides detailed information about memory consumption
/// within the QuickJS engine, including allocation counts, object counts,
/// and memory usage for different data types.
#[frb(opaque)]
#[derive(Clone)]
pub struct MemoryUsage(rquickjs::qjs::JSMemoryUsage);

/// Macro to generate getter methods for memory usage statistics.
///
/// This macro creates synchronized getter methods for all the fields
/// in the QuickJS JSMemoryUsage struct, making them accessible from Dart.
macro_rules! proxy_memory_usage_getter {
    ($($name:ident),+) => {
        impl MemoryUsage {
            $(
                /// Returns the memory usage statistic for the given field.
                #[frb(sync, getter)]
                pub fn $name(&self) -> i64 { self.0.$name }
            )+
        }
    };
}

// Generate getter methods for all memory usage fields
proxy_memory_usage_getter!(
    malloc_size,
    malloc_limit,
    memory_used_size,
    malloc_count,
    memory_used_count,
    atom_count,
    atom_size,
    str_count,
    str_size,
    obj_count,
    obj_size,
    prop_count,
    prop_size,
    shape_count,
    shape_size,
    js_func_count,
    js_func_size,
    js_func_code_size,
    js_func_pc2line_count,
    js_func_pc2line_size,
    c_func_count,
    array_count,
    fast_array_count,
    fast_array_elements,
    binary_object_count,
    binary_object_size
);

/// A synchronous JavaScript runtime.
///
/// This struct provides a synchronous JavaScript execution environment based on QuickJS.
/// It supports module loading, memory management, and garbage collection control.
/// Synchronous runtimes are suitable for simple scripts and non-blocking operations.
#[frb(opaque)]
#[derive(Clone)]
pub struct JsRuntime {
    rt: rquickjs::Runtime,
    global_attachment: Option<GlobalAttachment>,
}

impl JsRuntime {
    /// Creates a new JavaScript runtime with default configuration.
    ///
    /// # Returns
    ///
    /// Returns a new `JsRuntime` instance or an error if initialization fails.
    ///
    /// # Examples
    ///
    /// ```rust
    /// let runtime = JsRuntime::new()?;
    /// let context = JsContext::new(&runtime)?;
    /// ```
    #[frb(sync)]
    pub fn new() -> anyhow::Result<Self> {
        let runtime = rquickjs::Runtime::new()?;
        Ok(Self {
            rt: runtime,
            global_attachment: None,
        })
    }

    /// Creates a new JavaScript runtime with custom builtin modules and additional modules.
    ///
    /// # Parameters
    ///
    /// - `builtin`: Optional configuration for builtin Node.js modules
    /// - `additional`: Optional list of additional JavaScript modules to load
    ///
    /// # Returns
    ///
    /// Returns a new `JsRuntime` instance with the specified configuration.
    ///
    /// # Examples
    ///
    /// ```rust
    /// let builtin = JsBuiltinOptions::all();
    /// let additional = vec![JsModule::code("my-module", "export const value = 42;")];
    /// let runtime = JsAsyncRuntime::with_options(Some(builtin), Some(additional)).await?;
    /// ```
    pub async fn with_options(
        builtin: Option<JsBuiltinOptions>,
        additional: Option<Vec<JsModule>>,
    ) -> anyhow::Result<Self> {
        let runtime = rquickjs::Runtime::new()?;

        // Handle builtin module options
        let (module_resolver, module_loader, global_attachment) = if let Some(builtin_options) = builtin {
            let builder = builtin_options.to_module_builder();
            builder.build()
        } else {
            ModuleBuilder::new().build()
        };

        let mut builtin_resolver = BuiltinResolver::default();
        let mut builtin_loader = BuiltinLoader::default();

        // Handle additional JS modules
        if let Some(additional_modules) = additional {
            for module in additional_modules {
                let code = get_raw_source_code(module.source).await?;
                builtin_resolver = builtin_resolver.with_module(&module.name);
                builtin_loader = builtin_loader.with_module(&module.name, code);
            }
        }

        // Add dynamic module resolver and loader
        let dynamic_resolver = DynamicModuleResolver::default();
        let dynamic_loader = DynamicModuleLoader::default();

        let resolver = (
            module_resolver,
            builtin_resolver,
            dynamic_resolver,
            FileResolver::default(),
        );
        let loader = (
            module_loader,
            builtin_loader,
            dynamic_loader,
            NativeLoader::default(),
            ScriptLoader::default(),
        );
        runtime.set_loader(resolver, loader);
        Ok(Self {
            rt: runtime,
            global_attachment: Some(global_attachment),
        })
    }

    /// Sets the memory limit for the runtime.
    ///
    /// # Parameters
    ///
    /// - `limit`: Maximum memory limit in bytes
    #[frb(sync)]
    pub fn set_memory_limit(&self, limit: usize) {
        self.rt.set_memory_limit(limit);
    }

    /// Sets the maximum stack size for JavaScript execution.
    ///
    /// # Parameters
    ///
    /// - `limit`: Maximum stack size in bytes
    #[frb(sync)]
    pub fn set_max_stack_size(&self, limit: usize) {
        self.rt.set_max_stack_size(limit);
    }

    /// Sets the garbage collection threshold.
    ///
    /// # Parameters
    ///
    /// - `threshold`: GC threshold in bytes
    #[frb(sync)]
    pub fn set_gc_threshold(&self, threshold: usize) {
        self.rt.set_gc_threshold(threshold);
    }

    /// Forces garbage collection to run immediately.
    #[frb(sync)]
    pub fn run_gc(&self) {
        self.rt.run_gc();
    }

    /// Returns the current memory usage statistics.
    ///
    /// # Returns
    ///
    /// Returns a `MemoryUsage` struct containing detailed memory statistics.
    #[frb(sync)]
    pub fn memory_usage(&self) -> MemoryUsage {
        let usage = self.rt.memory_usage();
        MemoryUsage(usage)
    }

    /// Checks if there are pending jobs to be executed.
    ///
    /// # Returns
    ///
    /// Returns `true` if there are pending jobs, `false` otherwise.
    #[frb(sync)]
    pub fn is_job_pending(&self) -> bool {
        self.rt.is_job_pending()
    }

    /// Executes a pending job if one is available.
    ///
    /// # Returns
    ///
    /// Returns `true` if a job was executed, `false` if no jobs were pending.
    ///
    /// # Errors
    ///
    /// Returns an error if job execution fails.
    #[frb(sync)]
    pub fn execute_pending_job(&self) -> anyhow::Result<bool> {
        self.rt.execute_pending_job().map_err(|e| anyhow!(e))
    }

    /// Sets dump flags for debugging and profiling.
    ///
    /// # Parameters
    ///
    /// - `flags`: Bitmask of dump flags
    #[frb(sync)]
    pub fn set_dump_flags(&self, flags: u64) {
        self.rt.set_dump_flags(flags);
    }

    /// Sets runtime information for debugging purposes.
    ///
    /// # Parameters
    ///
    /// - `info`: Information string to set
    ///
    /// # Errors
    ///
    /// Returns an error if setting the info fails.
    #[frb(sync)]
    pub fn set_info(&self, info: String) -> anyhow::Result<()> {
        self.rt.set_info(info)?;
        Ok(())
    }
}

/// A synchronous JavaScript execution context.
///
/// This struct provides a context for executing JavaScript code synchronously.
/// Each context has its own global object and state but shares the underlying runtime.
/// Contexts are thread-safe for read operations but require exclusive access for execution.
#[frb(opaque)]
#[derive(Clone)]
pub struct JsContext {
    ctx: rquickjs::Context,
    global_attachment: Option<GlobalAttachment>,
}

impl JsContext {
    /// Creates a new JavaScript context from a runtime.
    ///
    /// # Parameters
    ///
    /// - `rt`: The runtime to create the context from
    ///
    /// # Returns
    ///
    /// Returns a new `JsContext` instance or an error if creation fails.
    ///
    /// # Examples
    ///
    /// ```rust
    /// let runtime = JsRuntime::new()?;
    /// let context = JsContext::new(&runtime)?;
    /// let result = context.eval("2 + 2".to_string())?;
    /// ```
    #[frb(sync)]
    pub fn new(rt: &JsRuntime) -> anyhow::Result<Self> {
        let context = rquickjs::Context::full(&rt.rt)?;
        Ok(Self {
            ctx: context,
            global_attachment: rt.global_attachment.clone(),
        })
    }

    /// Evaluates JavaScript code with default options.
    ///
    /// # Parameters
    ///
    /// - `code`: The JavaScript code to execute
    ///
    /// # Returns
    ///
    /// Returns the execution result as a `JsResult`.
    ///
    /// # Examples
    ///
    /// ```rust
    /// let result = context.eval("Math.random()".to_string())?;
    /// ```
    #[frb(sync)]
    pub fn eval(&self, code: String) -> JsResult {
        self.eval_with_options(code, JsEvalOptions::default())
    }

    /// Evaluates JavaScript code with custom options.
    ///
    /// # Parameters
    ///
    /// - `code`: The JavaScript code to execute
    /// - `options`: Evaluation options
    ///
    /// # Returns
    ///
    /// Returns the execution result as a `JsResult`.
    ///
    /// # Notes
    ///
    /// Promise evaluation is not supported in synchronous contexts.
    /// Use `JsAsyncContext` for asynchronous operations.
    #[frb(sync)]
    pub fn eval_with_options(&self, code: String, options: JsEvalOptions) -> JsResult {
        if options.promise.unwrap_or(false) {
            return JsResult::Err(JsError::promise(
                "Promise not supported in sync context".to_string(),
            ));
        }
        self.ctx.with(|ctx| {
            if let Some(attachment) = &self.global_attachment {
                if let Err(e) = attachment.attach(&ctx) {
                    return JsResult::Err(JsError::context(format!(
                        "Failed to attach global context: {}",
                        e
                    )));
                }
            }
            let res = ctx.eval_with_options(code, options.into());
            JsResult::from_result(&ctx, res)
        })
    }

    /// Evaluates JavaScript code from a file with default options.
    ///
    /// # Parameters
    ///
    /// - `path`: Path to the JavaScript file
    ///
    /// # Returns
    ///
    /// Returns the execution result as a `JsResult`.
    ///
    /// # Errors
    ///
    /// Returns an error if the file cannot be read or execution fails.
    #[frb(sync)]
    pub fn eval_file(&self, path: String) -> JsResult {
        self.eval_file_with_options(path, JsEvalOptions::default())
    }

    /// Evaluates JavaScript code from a file with custom options.
    ///
    /// # Parameters
    ///
    /// - `path`: Path to the JavaScript file
    /// - `options`: Evaluation options
    ///
    /// # Returns
    ///
    /// Returns the execution result as a `JsResult`.
    ///
    /// # Notes
    ///
    /// Promise evaluation is not supported in synchronous contexts.
    #[frb(sync)]
    pub fn eval_file_with_options(&self, path: String, options: JsEvalOptions) -> JsResult {
        if options.promise.unwrap_or(false) {
            return JsResult::Err(JsError::promise(
                "Promise not supported in sync context".to_string(),
            ));
        }
        self.ctx.with(|ctx| {
            if let Some(attachment) = &self.global_attachment {
                if let Err(e) = attachment.attach(&ctx) {
                    return JsResult::Err(JsError::context(format!(
                        "Failed to attach global context: {}",
                        e
                    )));
                }
            }
            let res = ctx.eval_file_with_options(path, options.into());
            JsResult::from_result(&ctx, res)
        })
    }
}

/// An asynchronous JavaScript runtime.
///
/// This struct provides an asynchronous JavaScript execution environment based on QuickJS.
/// It supports all features of the synchronous runtime plus asynchronous operations,
/// promise handling, and concurrent execution.
#[frb(opaque)]
#[derive(Clone)]
pub struct JsAsyncRuntime {
    rt: rquickjs::AsyncRuntime,
    global_attachment: Option<GlobalAttachment>,
}

impl JsAsyncRuntime {
    /// Creates a new asynchronous JavaScript runtime with default configuration.
    ///
    /// # Returns
    ///
    /// Returns a new `JsAsyncRuntime` instance or an error if initialization fails.
    #[frb(sync)]
    pub fn new() -> anyhow::Result<Self> {
        let runtime = rquickjs::AsyncRuntime::new()?;
        Ok(Self {
            rt: runtime,
            global_attachment: None,
        })
    }

    /// Creates a new asynchronous JavaScript runtime with custom configuration.
    ///
    /// # Parameters
    ///
    /// - `builtin`: Optional configuration for builtin Node.js modules
    /// - `additional`: Optional list of additional JavaScript modules to load
    ///
    /// # Returns
    ///
    /// Returns a new `JsAsyncRuntime` instance with the specified configuration.
    ///
    /// # Examples
    ///
    /// ```rust
    /// let builtin = JsBuiltinOptions::all();
    /// let additional = vec![JsModule::code("my-module", "export const value = 42;")];
    /// let runtime = JsAsyncRuntime::with_options(Some(builtin), Some(additional)).await?;
    /// ```
    pub async fn with_options(
        builtin: Option<JsBuiltinOptions>,
        additional: Option<Vec<JsModule>>,
    ) -> anyhow::Result<Self> {
        let runtime = rquickjs::AsyncRuntime::new()?;
        
        // Handle builtin module options
        let (module_resolver, module_loader, global_attachment) = if let Some(builtin_options) = builtin {
            let builder = builtin_options.to_module_builder();
            builder.build()
        } else {
            ModuleBuilder::new().build()
        };
        
        let mut builtin_resolver = BuiltinResolver::default();
        let mut builtin_loader = BuiltinLoader::default();

        // Handle additional JS modules
        if let Some(additional_modules) = additional {
            for module in additional_modules {
                let code = get_raw_source_code(module.source).await?;
                builtin_resolver = builtin_resolver.with_module(&module.name);
                builtin_loader = builtin_loader.with_module(&module.name, code);
            }
        }

        // Add dynamic module resolver and loader
        let dynamic_resolver = DynamicModuleResolver::default();
        let dynamic_loader = DynamicModuleLoader::default();

        let resolver = (
            module_resolver,
            builtin_resolver,
            dynamic_resolver,
            FileResolver::default(),
        );
        let loader = (
            module_loader,
            builtin_loader,
            dynamic_loader,
            NativeLoader::default(),
            ScriptLoader::default(),
        );
        runtime.set_loader(resolver, loader).await;
        Ok(Self {
            rt: runtime,
            global_attachment: Some(global_attachment),
        })
    }

    /// Sets the memory limit for the runtime asynchronously.
    ///
    /// # Parameters
    ///
    /// - `limit`: Maximum memory limit in bytes
    pub async fn set_memory_limit(&self, limit: usize) {
        self.rt.set_memory_limit(limit).await;
    }

    /// Sets the maximum stack size for JavaScript execution asynchronously.
    ///
    /// # Parameters
    ///
    /// - `limit`: Maximum stack size in bytes
    pub async fn set_max_stack_size(&self, limit: usize) {
        self.rt.set_max_stack_size(limit).await;
    }

    /// Sets the garbage collection threshold asynchronously.
    ///
    /// # Parameters
    ///
    /// - `threshold`: GC threshold in bytes
    pub async fn set_gc_threshold(&self, threshold: usize) {
        self.rt.set_gc_threshold(threshold).await;
    }

    /// Forces garbage collection to run immediately asynchronously.
    pub async fn run_gc(&self) {
        self.rt.run_gc().await;
    }

    /// Returns the current memory usage statistics asynchronously.
    ///
    /// # Returns
    ///
    /// Returns a `MemoryUsage` struct containing detailed memory statistics.
    pub async fn memory_usage(&self) -> MemoryUsage {
        let usage = self.rt.memory_usage().await;
        MemoryUsage(usage)
    }

    /// Checks if there are pending jobs to be executed asynchronously.
    ///
    /// # Returns
    ///
    /// Returns `true` if there are pending jobs, `false` otherwise.
    pub async fn is_job_pending(&self) -> bool {
        self.rt.is_job_pending().await
    }

    /// Executes a pending job if one is available asynchronously.
    ///
    /// # Returns
    ///
    /// Returns `true` if a job was executed, `false` if no jobs were pending.
    ///
    /// # Errors
    ///
    /// Returns an error if job execution fails.
    pub async fn execute_pending_job(&self) -> anyhow::Result<bool> {
        self.rt.execute_pending_job().await.map_err(|e| anyhow!(e))
    }

    /// Puts the runtime into idle state, waiting for events.
    ///
    /// This method should be called when the runtime is not actively executing
    /// JavaScript code but needs to remain responsive to events.
    pub async fn idle(&self) {
        self.rt.idle().await;
    }

    /// Sets runtime information for debugging purposes asynchronously.
    ///
    /// # Parameters
    ///
    /// - `info`: Information string to set
    ///
    /// # Errors
    ///
    /// Returns an error if setting the info fails.
    pub async fn set_info(&self, info: String) -> anyhow::Result<()> {
        self.rt.set_info(info).await?;
        Ok(())
    }
}

/// An asynchronous JavaScript execution context.
///
/// This struct provides a context for executing JavaScript code asynchronously.
/// It supports promise handling, top-level await, and concurrent execution.
/// Each context has its own global object and state but shares the underlying runtime.
#[frb(opaque)]
#[derive(Clone)]
pub struct JsAsyncContext {
    ctx: rquickjs::AsyncContext,
    global_attachment: Option<GlobalAttachment>,
}

impl JsAsyncContext {
    /// Creates a new asynchronous JavaScript context from a runtime.
    ///
    /// # Parameters
    ///
    /// - `rt`: The asynchronous runtime to create the context from
    ///
    /// # Returns
    ///
    /// Returns a new `JsAsyncContext` instance or an error if creation fails.
    ///
    /// # Examples
    ///
    /// ```rust
    /// let runtime = JsAsyncRuntime::new().await?;
    /// let context = JsAsyncContext::from(&runtime).await?;
    /// let result = context.eval("await Promise.resolve(42)".to_string()).await?;
    /// ```
    pub async fn from(rt: &JsAsyncRuntime) -> anyhow::Result<Self> {
        let context = rquickjs::AsyncContext::full(&rt.rt).await?;

        // Initialize dynamic module storage
        let dynamic_modules = Arc::new(RwLock::new(HashMap::<String, String>::new()));

        async_with!(context => |ctx| {
            // Add dynamic modules storage to context user data
            ctx.store_userdata(dynamic_modules.clone())
                .map_err(|e| anyhow!("Failed to store dynamic modules: {:?}", e))
        })
        .await?;

        Ok(Self {
            ctx: context,
            global_attachment: rt.global_attachment.clone(),
        })
    }

    /// Evaluates JavaScript code with default options asynchronously.
    ///
    /// # Parameters
    ///
    /// - `code`: The JavaScript code to execute
    ///
    /// # Returns
    ///
    /// Returns the execution result as a `JsResult`.
    ///
    /// # Examples
    ///
    /// ```rust
    /// let result = context.eval("Math.random()".to_string()).await?;
    /// let async_result = context.eval("await Promise.resolve(42)".to_string()).await?;
    /// ```
    pub async fn eval(&self, code: String) -> JsResult {
        self.eval_with_options(code, JsEvalOptions::default()).await
    }

    /// Evaluates JavaScript code with custom options asynchronously.
    ///
    /// # Parameters
    ///
    /// - `code`: The JavaScript code to execute
    /// - `options`: Evaluation options
    ///
    /// # Returns
    ///
    /// Returns the execution result as a `JsResult`.
    ///
    /// # Notes
    ///
    /// This method supports promise evaluation and top-level await.
    pub async fn eval_with_options(&self, code: String, options: JsEvalOptions) -> JsResult {
        async_with!(self.ctx => |ctx| {
            if let Some(attachment) = &self.global_attachment {
                if let Err(e) = attachment.clone().attach(&ctx) {
                    return JsResult::Err(JsError::context(e.to_string()));
                }
            }
            let mut options = options;
            options.promise = Some(true);
            let res = ctx.eval_with_options(code, options.into());
            JsResult::from_promise_result(&ctx, res).await
        })
        .await
    }

    /// Evaluates JavaScript code from a file with default options asynchronously.
    ///
    /// # Parameters
    ///
    /// - `path`: Path to the JavaScript file
    ///
    /// # Returns
    ///
    /// Returns the execution result as a `JsResult`.
    ///
    /// # Errors
    ///
    /// Returns an error if the file cannot be read or execution fails.
    pub async fn eval_file(&self, path: String) -> JsResult {
        self.eval_file_with_options(path, JsEvalOptions::default())
            .await
    }

    /// Evaluates JavaScript code from a file with custom options asynchronously.
    ///
    /// # Parameters
    ///
    /// - `path`: Path to the JavaScript file
    /// - `options`: Evaluation options
    ///
    /// # Returns
    ///
    /// Returns the execution result as a `JsResult`.
    pub async fn eval_file_with_options(&self, path: String, options: JsEvalOptions) -> JsResult {
        async_with!(self.ctx => |ctx| {
            if let Some(attachment) = &self.global_attachment {
                if let Err(e) = attachment.clone().attach(&ctx) {
                    return JsResult::Err(JsError::context(e.to_string()));
                }
            }
            let mut options = options;
            options.promise = Some(true);
            let res = ctx.eval_file_with_options(path, options.into());
            JsResult::from_promise_result(&ctx, res).await
        })
        .await
    }

    /// Evaluates a specific function from a module asynchronously.
    ///
    /// # Parameters
    ///
    /// - `module`: The name of the module containing the function
    /// - `method`: The name of the function to call
    /// - `params`: Optional parameters to pass to the function
    ///
    /// # Returns
    ///
    /// Returns the execution result as a `JsResult`.
    ///
    /// # Examples
    ///
    /// ```rust
    /// let result = context.eval_function(
    ///     "my-module".to_string(),
    ///     "myFunction".to_string(),
    ///     Some(vec![JsValue::integer(42)])
    /// ).await?;
    /// ```
    pub async fn eval_function(
        &self,
        module: String,
        method: String,
        params: Option<Vec<JsValue>>,
    ) -> JsResult {
        let params = params.unwrap_or_default();
        async_with!(self.ctx => |ctx| {
            if let Some(attachment) = &self.global_attachment {
                if let Err(e) = attachment.attach(&ctx) {
                    return JsResult::Err(JsError::context(format!("Failed to attach global context: {}", e)));
                }
            }
            match Module::import(&ctx, module.clone()).catch(&ctx) {
                Ok(promise) => {
                    match promise.into_future::<rquickjs::Value>().await.catch(&ctx) {
                        Ok(v) => {
                            if !v.is_object() {
                                return JsResult::Err(JsError::module(Some(module.clone()), None, "Is the module registered correctly?".to_string()));
                            }
                            let obj = match v.as_object() {
                                Some(o) => o,
                                None => return JsResult::Err(JsError::module(Some(module.clone()), None, "Is the module registered correctly?".to_string())),
                            };
                            let m: rquickjs::Result<rquickjs::Value> = obj.get(&method);
                            match m.catch(&ctx) {
                                Ok(m) => {
                                    if m.is_function() {
                                        let func = match m.as_function() {
                                            Some(f) => f,
                                            None => return JsResult::Err(JsError::module(Some(module.clone()), Some(method.clone()), "Method not found in the module".to_string())),
                                        };
                                        let res = func.call((rquickjs::function::Rest(params),));
                                        JsResult::from_promise_result(&ctx, res).await
                                    } else {
                                        JsResult::Err(JsError::module(Some(module.clone()), Some(method.clone()), "Method not found in the module".to_string()))
                                    }
                                }
                                Err(e) => {
                                    JsResult::Err(JsError::module(Some(module.clone()), Some(method.clone()), format!("Failed to get method: {}", e)))
                                }
                            }
                        }
                        Err(e) => {
                            JsResult::Err(JsError::module(Some(module.clone()), None, format!("Failed to import module: {}", e)))
                        }
                    }
                }
                Err(e) => JsResult::Err(JsError::module(Some(module.clone()), None, format!("Failed to import module: {}", e)))
            }
        })
            .await
    }
}

/// Represents an action that can be executed by the JavaScript engine.
///
/// This enum defines the various operations that can be performed
/// by the JavaScript engine, including code evaluation, module management,
/// and dynamic module operations.
#[derive(Debug, Clone)]
pub enum JsAction {
    /// Evaluate JavaScript code with optional evaluation options.
    Eval {
        /// Unique identifier for this action
        id: u32,
        /// The source code to evaluate (either inline code or file path)
        source: JsCode,
        /// Optional evaluation options
        options: Option<JsEvalOptions>,
    },
    /// Declare a new module in the dynamic module storage.
    DeclareNewModule {
        /// Unique identifier for this action
        id: u32,
        /// The module to declare
        module: JsModule,
    },
    /// Declare multiple new modules in the dynamic module storage.
    DeclareNewModules {
        /// Unique identifier for this action
        id: u32,
        /// List of modules to declare
        modules: Vec<JsModule>,
    },
    /// Clear all modules from the dynamic module storage.
    ClearNewModules {
        /// Unique identifier for this action
        id: u32,
    },
    /// Evaluate a module and return its result.
    EvaluateModule {
        /// Unique identifier for this action
        id: u32,
        /// The module to evaluate
        module: JsModule,
    },
}

/// Represents the result of a JavaScript action execution.
///
/// This struct contains the result of an action execution along with
/// the action's unique identifier for correlation purposes.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub struct JsActionResult {
    /// The unique identifier of the action that produced this result
    pub id: u32,
    /// The result of the action execution
    pub result: JsResult,
}

/// Represents a callback from the JavaScript engine to Dart.
///
/// This enum defines the various types of callbacks that can be sent
/// from the JavaScript engine to the Dart side for communication.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub enum JsCallback {
    /// Indicates that the engine has been initialized and is ready
    Initialized,
    /// Indicates the result of an action execution
    Handler(JsActionResult),
    /// Indicates a bridge call from JavaScript to Dart
    Bridge(JsValue),
}

/// Represents the result of handling a JavaScript callback.
///
/// This enum defines the possible responses when handling callbacks
/// from the JavaScript engine.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub enum JsCallbackResult {
    /// Indicates successful initialization handling
    Initialized,
    /// Indicates successful action handling
    Handler,
    /// Indicates the result of a bridge call
    Bridge(JsResult),
}

/// Core JavaScript engine implementation.
///
/// This struct provides the core functionality for executing JavaScript
/// actions, managing state, and handling communication between Dart and JavaScript.
/// It operates asynchronously and supports concurrent execution of actions.
#[frb(opaque)]
pub struct JsEngineCore {
    /// The asynchronous context for JavaScript execution
    context: JsAsyncContext,
    /// Channel for sending actions to the engine
    sender: tokio::sync::mpsc::UnboundedSender<JsAction>,
    /// Channel for receiving actions (wrapped in Arc<Mutex<>> for thread safety)
    receiver: Arc<Mutex<tokio::sync::mpsc::UnboundedReceiver<JsAction>>>,
    /// Atomic flag indicating if the engine has been disposed
    disposed: AtomicBool,
    /// Atomic flag indicating if the engine is currently running
    running: AtomicBool,
}

impl JsEngineCore {
    /// Creates a new JavaScript engine core with the given context.
    ///
    /// # Parameters
    ///
    /// - `context`: The asynchronous context to use for JavaScript execution
    ///
    /// # Returns
    ///
    /// Returns a new `JsEngineCore` instance or an error if creation fails.
    #[frb(sync)]
    pub fn new(context: &JsAsyncContext) -> anyhow::Result<Self> {
        let (sender, receiver) = tokio::sync::mpsc::unbounded_channel();
        Ok(Self {
            context: context.clone(),
            sender,
            receiver: Arc::new(Mutex::new(receiver)),
            disposed: AtomicBool::new(false),
            running: AtomicBool::new(false),
        })
    }

    /// Returns the asynchronous context used by this engine.
    ///
    /// # Returns
    ///
    /// Returns the `JsAsyncContext` instance.
    #[frb(sync, getter)]
    pub fn context(&self) -> JsAsyncContext {
        self.context.clone()
    }

    /// Checks if the engine has been disposed.
    ///
    /// # Returns
    ///
    /// Returns `true` if the engine is disposed, `false` otherwise.
    #[frb(sync, getter)]
    pub fn disposed(&self) -> bool {
        self.disposed.load(Ordering::Acquire)
    }

    /// Checks if the engine is currently running.
    ///
    /// # Returns
    ///
    /// Returns `true` if the engine is running, `false` otherwise.
    #[frb(sync, getter)]
    pub fn running(&self) -> bool {
        self.running.load(Ordering::Acquire)
    }

    /// Disposes the engine and cleans up resources.
    ///
    /// This method marks the engine as disposed and prevents further operations.
    /// The actual cleanup happens when all references are dropped.
    ///
    /// # Errors
    ///
    /// Returns an error if the engine is already disposed.
    pub async fn dispose(&self) -> anyhow::Result<()> {
        if self.disposed.load(Ordering::Acquire) {
            return Err(anyhow!("Engine is disposed"));
        }

        // Mark as disposed
        self.disposed.store(true, Ordering::Release);
        Ok(())
    }

    /// Executes an action on the engine.
    ///
    /// # Parameters
    ///
    /// - `action`: The action to execute
    ///
    /// # Errors
    ///
    /// Returns an error if the engine is disposed or if sending the action fails.
    pub async fn exec(&self, action: JsAction) -> anyhow::Result<()> {
        if self.disposed.load(Ordering::Acquire) {
            return Err(anyhow!("Engine is disposed"));
        }
        self.sender
            .send(action)
            .map_err(|e| anyhow!("Failed to send action: {}", e))?;
        Ok(())
    }

    /// Starts the engine event loop with a bridge callback.
    ///
    /// # Parameters
    ///
    /// - `bridge`: Callback function for handling communication between JavaScript and Dart
    ///
    /// # Errors
    ///
    /// Returns an error if the engine is already disposed or already running.
    ///
    /// # Examples
    ///
    /// ```rust
    /// engine.start(|callback| {
    ///     match callback {
    ///         JsCallback::Initialized => {
    ///             println!("Engine initialized");
    ///             JsCallbackResult::Initialized
    ///         }
    ///         JsCallback::Handler(result) => {
    ///             println!("Action completed: {:?}", result);
    ///             JsCallbackResult::Handler
    ///         }
    ///         JsCallback::Bridge(value) => {
    ///             println!("Bridge call: {:?}", value);
    ///             JsCallbackResult::Bridge(JsResult::Ok(value))
    ///         }
    ///     }
    /// }).await?;
    /// ```
    pub async fn start(
        &self,
        bridge: impl Fn(JsCallback) -> DartFnFuture<JsCallbackResult> + Sync + Send + 'static,
    ) -> anyhow::Result<()> {
        if self.disposed.load(Ordering::Acquire) {
            return Err(anyhow!("Engine is disposed"));
        }
        if self.running.load(Ordering::Acquire) {
            return Err(anyhow!("Engine is already running"));
        }

        // Set running flag - use a guard to ensure it's reset on early return
        self.running.store(true, Ordering::Release);

        // Guard to ensure flags are properly reset
        struct StateGuard<'a> {
            running: &'a AtomicBool,
            disposed: &'a AtomicBool,
        }

        impl<'a> Drop for StateGuard<'a> {
            fn drop(&mut self) {
                self.running.store(false, Ordering::Release);
                self.disposed.store(true, Ordering::Release);
            }
        }

        let _guard = StateGuard {
            running: &self.running,
            disposed: &self.disposed,
        };

        let cb = Arc::new(bridge);

        let result = async_with!(self.context.ctx => |ctx| {
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
                    None => {
                        // Channel closed, exit loop
                        return Ok(());
                    },
                    Some(ev) => {
                        drop(receiver);

                        let ctx_s = ctx.clone();
                        let cb_clone = cb.clone();

                        ctx.spawn(async move {
                            Self::handle_action(ctx_s, cb_clone, ev).await;
                        });
                    }
                }
            }
        })
        .await;

        result
    }

    /// Handles a single action from the event loop.
    ///
    /// This method processes individual actions and executes them
    /// in the JavaScript context, then sends the results back via the bridge.
    async fn handle_action(
        ctx: rquickjs::Ctx<'_>,
        cb: Arc<dyn Fn(JsCallback) -> DartFnFuture<JsCallbackResult> + Sync + Send + 'static>,
        action: JsAction,
    ) {
        match action {
            JsAction::Eval {
                id,
                source,
                options,
            } => {
                let mut options = options.unwrap_or_default();
                options.promise = Some(true);
                let res = match get_raw_source_code(source.clone()).await {
                    Err(e) => JsResult::Err(JsError::io(
                        match &source {
                            JsCode::Path(p) => Some(p.clone()),
                            JsCode::Code(_) => None,
                        },
                        e.to_string(),
                    )),
                    Ok(source_code) => {
                        let res = ctx.eval_with_options(source_code, options.into());
                        JsResult::from_promise_result(&ctx, res).await
                    }
                };
                let res = JsActionResult { id, result: res };
                cb(JsCallback::Handler(res)).await;
            }
            JsAction::DeclareNewModule {
                id,
                module: JsModule { name, source },
            } => {
                let res = match get_raw_source_code(source.clone()).await {
                    Err(e) => JsResult::Err(JsError::io(
                        match &source {
                            JsCode::Path(p) => Some(p.clone()),
                            JsCode::Code(_) => None,
                        },
                        e.to_string(),
                    )),
                    Ok(source_code) => {
                        if let Some(modules_storage) =
                            ctx.userdata::<Arc<RwLock<HashMap<String, String>>>>()
                        {
                            modules_storage
                                .write()
                                .unwrap()
                                .insert(name.clone(), source_code.clone());
                            JsResult::Ok(JsValue::None)
                        } else {
                            JsResult::Err(JsError::storage(
                                "Dynamic modules storage not initialized".to_string(),
                            ))
                        }
                    }
                };
                let res = JsActionResult { id, result: res };
                cb(JsCallback::Handler(res)).await;
            }
            JsAction::EvaluateModule {
                id,
                module: JsModule { name, source },
            } => {
                let res = match get_raw_source_code(source.clone()).await {
                    Err(e) => JsResult::Err(JsError::io(
                        match &source {
                            JsCode::Path(p) => Some(p.clone()),
                            JsCode::Code(_) => None,
                        },
                        e.to_string(),
                    )),
                    Ok(source_code) => {
                        // Ensure module is stored in dynamic module storage
                        if let Some(modules_storage) =
                            ctx.userdata::<Arc<RwLock<HashMap<String, String>>>>()
                        {
                            modules_storage
                                .write()
                                .unwrap()
                                .insert(name.clone(), source_code.clone());

                            // Evaluate module
                            let res = Module::evaluate(ctx.clone(), name.clone(), source_code);
                            JsResult::from_promise_result(&ctx, res).await
                        } else {
                            JsResult::Err(JsError::storage(
                                "Dynamic modules storage not initialized".to_string(),
                            ))
                        }
                    }
                };
                let res = JsActionResult { id, result: res };
                cb(JsCallback::Handler(res)).await;
            }
            JsAction::ClearNewModules { id } => {
                let res = if let Some(modules_storage) =
                    ctx.userdata::<Arc<RwLock<HashMap<String, String>>>>()
                {
                    modules_storage.write().unwrap().clear();
                    JsResult::Ok(JsValue::None)
                } else {
                    JsResult::Err(JsError::storage(
                        "Dynamic modules storage not initialized".to_string(),
                    ))
                };
                let res = JsActionResult { id, result: res };
                cb(JsCallback::Handler(res)).await;
            }
            JsAction::DeclareNewModules { id, modules } => {
                let mut last_result = JsResult::Ok(JsValue::None);
                for module in modules {
                    let res = match get_raw_source_code(module.source.clone()).await {
                        Err(e) => JsResult::Err(JsError::io(
                            match &module.source {
                                JsCode::Path(p) => Some(p.clone()),
                                JsCode::Code(_) => None,
                            },
                            e.to_string(),
                        )),
                        Ok(source_code) => {
                            if let Some(modules_storage) =
                                ctx.userdata::<Arc<RwLock<HashMap<String, String>>>>()
                            {
                                modules_storage
                                    .write()
                                    .unwrap()
                                    .insert(module.name.clone(), source_code.clone());
                                JsResult::Ok(JsValue::None)
                            } else {
                                JsResult::Err(JsError::storage(
                                    "Dynamic modules storage not initialized".to_string(),
                                ))
                            }
                        }
                    };
                    if let JsResult::Err(_) = &res {
                        last_result = res;
                        break;
                    }
                }
                let res = JsActionResult {
                    id,
                    result: last_result,
                };
                cb(JsCallback::Handler(res)).await;
            }
        }
    }
}

/// Retrieves the raw source code from a JsCode source.
///
/// This function resolves either inline code or file content
/// and returns the JavaScript source code as a string.
///
/// # Parameters
///
/// - `source`: The source to resolve (either inline code or file path)
///
/// # Returns
///
/// Returns the JavaScript source code as a string.
///
/// # Errors
///
/// Returns an error if:
/// - The file cannot be read
/// - The file size exceeds the maximum allowed size
async fn get_raw_source_code(source: JsCode) -> anyhow::Result<String> {
    let code = match source {
        JsCode::Code(code) => code,
        JsCode::Path(path) => {
            // Check file size before reading
            let metadata = tokio::fs::metadata(&path).await?;
            let file_size = metadata.len();

            if file_size > MAX_FILE_SIZE {
                return Err(anyhow!(
                    "File size exceeds maximum allowed size: {} (size: {} bytes, max: {} bytes)",
                    path,
                    file_size,
                    MAX_FILE_SIZE
                ));
            }

            let mut f = tokio::fs::File::open(&path).await?;
            let mut codes = String::with_capacity(file_size as usize);
            f.read_to_string(&mut codes).await?;
            codes
        }
    };
    Ok(code)
}

/// Represents the result of a JavaScript operation.
///
/// This enum provides a type-safe way to handle success and error cases
/// from JavaScript execution, with support for various error types.
#[frb(dart_metadata = ("freezed"), dart_code = "
  bool get isOk => this is JsResult_Ok;
  bool get isErr => this is JsResult_Err;
  JsValue get ok => (this as JsResult_Ok).field0;
  JsError get err => (this as JsResult_Err).field0;
")]
#[derive(Debug, Clone)]
pub enum JsResult {
    /// Successful execution result
    Ok(JsValue),
    /// Error during execution
    Err(JsError),
}

/// Represents various types of JavaScript errors.
///
/// This enum provides detailed error information for different
/// categories of errors that can occur during JavaScript execution.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub enum JsError {
    /// Promise-related errors (async operation failures)
    Promise(String),
    /// Module-related errors (import/export failures)
    Module {
        /// Optional module name where the error occurred
        module: Option<String>,
        /// Optional method name where the error occurred
        method: Option<String>,
        /// Error message
        message: String,
    },
    /// Context attachment errors (global object setup failures)
    Context(String),
    /// Storage initialization errors (dynamic module storage failures)
    Storage(String),
    /// File I/O errors (file reading failures)
    Io {
        /// Optional file path where the error occurred
        path: Option<String>,
        /// Error message
        message: String,
    },
    /// JavaScript runtime errors from QuickJS engine
    Runtime(String),
    /// Generic catch-all errors
    Generic(String),
    /// Engine lifecycle errors
    Engine(String),
    /// Bridge communication errors
    Bridge(String),
}

impl JsError {
    /// Creates a new promise error.
    #[frb(ignore)]
    fn promise(msg: String) -> Self {
        JsError::Promise(msg)
    }

    /// Creates a new module error.
    #[frb(ignore)]
    fn module(module: Option<String>, method: Option<String>, message: String) -> Self {
        JsError::Module {
            module,
            method,
            message,
        }
    }

    /// Creates a new context error.
    #[frb(ignore)]
    fn context(msg: String) -> Self {
        JsError::Context(msg)
    }

    /// Creates a new storage error.
    #[frb(ignore)]
    fn storage(msg: String) -> Self {
        JsError::Storage(msg)
    }

    /// Creates a new I/O error.
    #[frb(ignore)]
    fn io(path: Option<String>, message: String) -> Self {
        JsError::Io { path, message }
    }

    /// Creates a new runtime error.
    #[frb(ignore)]
    fn runtime(msg: String) -> Self {
        JsError::Runtime(msg)
    }

    /// Creates a new generic error.
    #[frb(ignore)]
    fn generic(msg: String) -> Self {
        JsError::Generic(msg)
    }

    /// Converts the error to a string representation.
    ///
    /// This method provides a human-readable description of the error,
    /// including contextual information when available.
    ///
    /// # Returns
    ///
    /// Returns a string describing the error.
    #[frb(sync)]
    pub fn to_string(&self) -> String {
        match self {
            JsError::Promise(msg) => format!("Promise error: {}", msg),
            JsError::Module {
                module,
                method,
                message,
            } => {
                let mut parts = Vec::new();
                if let Some(m) = module {
                    parts.push(format!("module: {}", m));
                }
                if let Some(m) = method {
                    parts.push(format!("method: {}", m));
                }
                parts.push(format!("error: {}", message));
                format!("Module error - {}", parts.join(", "))
            }
            JsError::Context(msg) => format!("Context error: {}", msg),
            JsError::Storage(msg) => format!("Storage error: {}", msg),
            JsError::Io { path, message } => {
                if let Some(p) = path {
                    format!("IO error at {}: {}", p, message)
                } else {
                    format!("IO error: {}", message)
                }
            }
            JsError::Runtime(msg) => format!("Runtime error: {}", msg),
            JsError::Generic(msg) => msg.clone(),
            JsError::Engine(msg) => format!("Engine error: {}", msg),
            JsError::Bridge(msg) => format!("Bridge error: {}", msg),
        }
    }
}

impl JsResult {
    /// Creates a new result from a promise execution result.
    ///
    /// This method handles the conversion from QuickJS promise results
    /// to the FJS result type, including error handling.
    async fn from_promise_result<'js>(
        ctx: &rquickjs::Ctx<'js>,
        res: rquickjs::Result<Promise<'js>>,
    ) -> Self {
        match res.catch(ctx) {
            Ok(promise) => match promise.into_future::<rquickjs::Value>().await.catch(ctx) {
                Ok(v) => match JsValue::from_js(ctx, v).catch(ctx) {
                    Ok(v) => JsResult::Ok(v),
                    Err(e) => JsResult::Err(JsError::runtime(e.to_string())),
                },
                Err(e) => JsResult::Err(JsError::runtime(e.to_string())),
            },
            Err(e) => JsResult::Err(JsError::runtime(e.to_string())),
        }
    }

    /// Creates a new result from a synchronous execution result.
    ///
    /// This method handles the conversion from QuickJS value results
    /// to the FJS result type, including error handling.
    fn from_result<'js>(
        ctx: &rquickjs::Ctx<'js>,
        res: rquickjs::Result<rquickjs::Value<'js>>,
    ) -> Self {
        res.catch(ctx)
            .map(|v| JsValue::from_js(ctx, v))
            .map_or_else(
                |e| JsResult::Err(JsError::runtime(e.to_string())),
                |v| match v {
                    Ok(v) => JsResult::Ok(v),
                    Err(e) => JsResult::Err(JsError::runtime(e.to_string())),
                },
            )
    }
}

/// Options for JavaScript code evaluation.
///
/// This struct provides configuration options for how JavaScript
/// code should be executed and evaluated.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub struct JsEvalOptions {
    /// Whether the code should be evaluated in global scope.
    pub global: Option<bool>,
    /// Whether strict mode should be enforced.
    pub strict: Option<bool>,
    /// Whether to create a backtrace barrier for error reporting.
    pub backtrace_barrier: Option<bool>,
    /// Whether to enable top-level await support.
    pub promise: Option<bool>,
}

impl JsEvalOptions {
    /// Creates new evaluation options with the specified parameters.
    ///
    /// # Parameters
    ///
    /// - `global`: Whether to evaluate in global scope
    /// - `strict`: Whether to enforce strict mode
    /// - `backtrace_barrier`: Whether to create backtrace barriers
    /// - `promise`: Whether to enable promise support
    ///
    /// # Returns
    ///
    /// Returns a new `JsEvalOptions` instance.
    #[frb(sync)]
    pub fn new(
        global: Option<bool>,
        strict: Option<bool>,
        backtrace_barrier: Option<bool>,
        promise: Option<bool>,
    ) -> Self {
        JsEvalOptions {
            global,
            strict,
            backtrace_barrier,
            promise,
        }
    }
}

impl From<JsEvalOptions> for rquickjs::context::EvalOptions {
    /// Converts FJS evaluation options to QuickJS evaluation options.
    fn from(v: JsEvalOptions) -> Self {
        let mut opts = rquickjs::context::EvalOptions::default();
        opts.global = v.global.unwrap_or(true);
        opts.strict = v.strict.unwrap_or(true);
        opts.backtrace_barrier = v.backtrace_barrier.unwrap_or(false);
        opts.promise = v.promise.unwrap_or(false);
        opts
    }
}

impl Default for JsEvalOptions {
    /// Returns default evaluation options.
    ///
    /// Default options enable global scope and strict mode,
    /// but disable backtrace barriers and promise support.
    #[frb(ignore)]
    fn default() -> Self {
        JsEvalOptions {
            global: Some(true),
            strict: Some(true),
            backtrace_barrier: Some(false),
            promise: Some(false),
        }
    }
}

/// Options for configuring builtin Node.js modules.
///
/// This struct provides fine-grained control over which Node.js
/// compatibility modules should be available in the runtime.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub struct JsBuiltinOptions {
    /// Enable abort functionality
    pub abort: Option<bool>,
    /// Enable assert module
    pub assert: Option<bool>,
    /// Enable async_hooks module
    pub async_hooks: Option<bool>,
    /// Enable buffer module
    pub buffer: Option<bool>,
    /// Enable child_process module
    pub child_process: Option<bool>,
    /// Enable console module
    pub console: Option<bool>,
    /// Enable crypto module
    pub crypto: Option<bool>,
    /// Enable dns module
    pub dns: Option<bool>,
    /// Enable events module
    pub events: Option<bool>,
    /// Enable exceptions module
    pub exceptions: Option<bool>,
    /// Enable fetch functionality
    pub fetch: Option<bool>,
    /// Enable fs module
    pub fs: Option<bool>,
    /// Enable navigator object
    pub navigator: Option<bool>,
    /// Enable net module
    pub net: Option<bool>,
    /// Enable os module
    pub os: Option<bool>,
    /// Enable path module
    pub path: Option<bool>,
    /// Enable perf_hooks module
    pub perf_hooks: Option<bool>,
    /// Enable process module
    pub process: Option<bool>,
    /// Enable stream_web module
    pub stream_web: Option<bool>,
    /// Enable string_decoder module
    pub string_decoder: Option<bool>,
    /// Enable timers module
    pub timers: Option<bool>,
    /// Enable tty module
    pub tty: Option<bool>,
    /// Enable url module
    pub url: Option<bool>,
    /// Enable util module
    pub util: Option<bool>,
    /// Enable zlib module
    pub zlib: Option<bool>,
    /// Enable JSON utilities
    pub json: Option<bool>,
}

impl JsBuiltinOptions {
    /// Creates builtin options with all modules enabled.
    ///
    /// # Returns
    ///
    /// Returns a `JsBuiltinOptions` instance with all available modules enabled.
    #[frb(sync)]
    pub fn all() -> Self {
        JsBuiltinOptions {
            abort: Some(true),
            assert: Some(true),
            async_hooks: Some(true),
            buffer: Some(true),
            child_process: Some(true),
            console: Some(true),
            crypto: Some(true),
            dns: Some(true),
            events: Some(true),
            exceptions: Some(true),
            fetch: Some(true),
            fs: Some(true),
            navigator: Some(true),
            net: Some(true),
            os: Some(true),
            path: Some(true),
            perf_hooks: Some(true),
            process: Some(true),
            stream_web: Some(true),
            string_decoder: Some(true),
            timers: Some(true),
            tty: Some(true),
            url: Some(true),
            util: Some(true),
            zlib: Some(true),
            json: Some(true),
        }
    }
}

impl Default for JsBuiltinOptions {
    /// Returns default builtin options (all modules disabled).
    ///
    /// Default options have all modules set to `None`, meaning they
    /// will not be included unless explicitly enabled.
    #[frb(ignore)]
    fn default() -> Self {
        JsBuiltinOptions {
            abort: None,
            assert: None,
            async_hooks: None,
            buffer: None,
            child_process: None,
            console: None,
            crypto: None,
            dns: None,
            events: None,
            exceptions: None,
            fetch: None,
            fs: None,
            navigator: None,
            net: None,
            os: None,
            path: None,
            perf_hooks: None,
            process: None,
            stream_web: None,
            string_decoder: None,
            timers: None,
            tty: None,
            url: None,
            util: None,
            zlib: None,
            json: None,
        }
    }
}

impl JsBuiltinOptions {
    /// Converts builtin options to a module builder.
    ///
    /// This method creates a `ModuleBuilder` with the selected
    /// builtin modules enabled according to the options.
    #[frb(ignore)]
    fn to_module_builder(&self) -> ModuleBuilder {
        let mut builder = ModuleBuilder::new();

        if self.abort.unwrap_or(false) {
            builder = builder.with_global(llrt_abort::init);
        }
        if self.assert.unwrap_or(false) {
            builder = builder.with_module(llrt_assert::AssertModule);
        }
        if self.async_hooks.unwrap_or(false) {
            builder = builder
                .with_global(llrt_async_hooks::init)
                .with_module(llrt_async_hooks::AsyncHooksModule);
        }
        if self.buffer.unwrap_or(false) {
            builder = builder
                .with_global(llrt_buffer::init)
                .with_module(llrt_buffer::BufferModule);
        }

        if self.child_process.unwrap_or(false) {
            builder = builder.with_module(llrt_child_process::ChildProcessModule);
        }

        if self.console.unwrap_or(false) {
            builder = builder
                .with_global(llrt_console::init)
                .with_module(llrt_console::ConsoleModule);
        }

        #[cfg(not(target_os = "android"))]
        if self.crypto.unwrap_or(false) {
            builder = builder
                .with_global(llrt_crypto::init)
                .with_module(llrt_crypto::CryptoModule);
        }

        if self.dns.unwrap_or(false) {
            builder = builder.with_module(llrt_dns::DnsModule);
        }

        if self.events.unwrap_or(false) {
            builder = builder
                .with_global(llrt_events::init)
                .with_module(llrt_events::EventsModule);
        }

        if self.exceptions.unwrap_or(false) {
            builder = builder.with_global(llrt_exceptions::init);
        }

        if self.fetch.unwrap_or(false) {
            builder = builder.with_global(llrt_fetch::init);
        }

        if self.fs.unwrap_or(false) {
            builder = builder
                .with_module(llrt_fs::FsPromisesModule)
                .with_module(llrt_fs::FsModule);
        }

        if self.navigator.unwrap_or(false) {
            builder = builder.with_global(llrt_navigator::init);
        }

        if self.net.unwrap_or(false) {
            builder = builder.with_module(llrt_net::NetModule);
        }

        if self.os.unwrap_or(false) {
            builder = builder.with_module(llrt_os::OsModule);
        }

        if self.path.unwrap_or(false) {
            builder = builder.with_module(llrt_path::PathModule);
        }

        if self.perf_hooks.unwrap_or(false) {
            builder = builder
                .with_global(llrt_perf_hooks::init)
                .with_module(llrt_perf_hooks::PerfHooksModule);
        }

        if self.process.unwrap_or(false) {
            builder = builder
                .with_global(llrt_process::init)
                .with_module(llrt_process::ProcessModule);
        }

        if self.stream_web.unwrap_or(false) {
            builder = builder
                .with_global(llrt_stream_web::init)
                .with_module(llrt_stream_web::StreamWebModule);
        }

        if self.string_decoder.unwrap_or(false) {
            builder = builder.with_module(llrt_string_decoder::StringDecoderModule);
        }

        if self.timers.unwrap_or(false) {
            builder = builder
                .with_global(llrt_timers::init)
                .with_module(llrt_timers::TimersModule);
        }

        if self.tty.unwrap_or(false) {
            builder = builder.with_module(llrt_tty::TtyModule);
        }

        if self.url.unwrap_or(false) {
            builder = builder
                .with_global(llrt_url::init)
                .with_module(llrt_url::UrlModule);
        }

        if self.util.unwrap_or(false) {
            builder = builder
                .with_global(llrt_util::init)
                .with_module(llrt_util::UtilModule);
        }

        if self.zlib.unwrap_or(false) {
            builder = builder.with_module(llrt_zlib::ZlibModule);
        }

        if self.json.unwrap_or(false) {
            builder = builder.with_global(llrt_json::redefine_static_methods);
        }

        builder
    }
}

/// Represents a JavaScript module.
///
/// This struct defines a module with a name and source code,
/// which can be loaded and executed in the JavaScript runtime.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Hash, Eq, PartialEq, Ord, PartialOrd)]
pub struct JsModule {
    /// The module name (used for imports and identification)
    pub name: String,
    /// The source code for the module
    pub source: JsCode,
}

/// Represents the source of JavaScript code.
///
/// This enum provides two ways to specify JavaScript source:
/// inline code as a string, or a file path to load code from.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Hash, Eq, PartialEq, Ord, PartialOrd)]
pub enum JsCode {
    /// Inline JavaScript code
    Code(String),
    /// File path containing JavaScript code
    Path(String),
}

impl JsModule {
    /// Creates a new module with the given name and source.
    ///
    /// # Parameters
    ///
    /// - `name`: The module name
    /// - `source`: The module source code
    ///
    /// # Returns
    ///
    /// Returns a new `JsModule` instance.
    #[frb(sync)]
    pub fn new(name: String, source: JsCode) -> Self {
        JsModule { name, source }
    }

    /// Creates a module from inline code.
    ///
    /// # Parameters
    ///
    /// - `module`: The module name
    /// - `code`: The inline JavaScript code
    ///
    /// # Returns
    ///
    /// Returns a new `JsModule` instance.
    ///
    /// # Examples
    ///
    /// ```rust
    /// let module = JsModule::code(
    ///     "my-module".to_string(),
    ///     "export const value = 42;".to_string()
    /// );
    /// ```
    #[frb(sync)]
    pub fn code(module: String, code: String) -> Self {
        JsModule {
            name: module,
            source: JsCode::Code(code),
        }
    }

    /// Creates a module from a file path.
    ///
    /// # Parameters
    ///
    /// - `module`: The module name
    /// - `path`: The file path containing JavaScript code
    ///
    /// # Returns
    ///
    /// Returns a new `JsModule` instance.
    ///
    /// # Examples
    ///
    /// ```rust
    /// let module = JsModule::path(
    ///     "my-module".to_string(),
    ///     "/path/to/module.js".to_string()
    /// );
    /// ```
    #[frb(sync)]
    pub fn path(module: String, path: String) -> Self {
        JsModule {
            name: module,
            source: JsCode::Path(path),
        }
    }
}

/// Registers the FJS bridge object in the JavaScript global scope.
///
/// This function creates a global `fjs` object that provides
/// a bridge function for communication from JavaScript to Dart.
///
/// # Parameters
///
/// - `ctx`: The JavaScript context
/// - `bridge`: The bridge callback function
///
/// # Returns
    ///
/// Returns an error if registration fails.
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

/// Creates a new bridge call function for JavaScript-to-Dart communication.
///
/// This function creates a JavaScript function that can be called from
/// JavaScript to communicate with Dart via the bridge.
///
/// # Parameters
///
/// - `ctx`: The JavaScript context
/// - `bridge`: The bridge callback function
///
/// # Returns
    ///
/// Returns a new JavaScript function or an error if creation fails.
fn new_bridge_call<'js>(
    ctx: rquickjs::Ctx<'js>,
    bridge: Arc<dyn Fn(JsCallback) -> DartFnFuture<JsCallbackResult> + Sync + Send + 'static>,
) -> rquickjs::CaughtResult<'js, rquickjs::Function<'js>> {
    let ctx_clone = ctx.clone();
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
                            if let Err(_) = args.push_arg(err.to_string()) {
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
    .catch(&ctx_clone)
}
