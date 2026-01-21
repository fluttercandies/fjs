//! # Runtime and Context Management
//!
//! This module provides the core runtime and context types for JavaScript execution.
//! It includes both synchronous and asynchronous variants with a unified interface.

use crate::api::error::{JsError, JsResult};
use crate::api::module::{
    DynamicModuleLoader, DynamicModuleResolver, GlobalAttachment, ModuleBuilder,
};
use crate::api::source::{get_raw_source_code, JsBuiltinOptions, JsEvalOptions, JsModule};
use crate::api::value::JsValue;
use flutter_rust_bridge::frb;
use rquickjs::loader::{BuiltinLoader, BuiltinResolver, FileResolver, NativeLoader, ScriptLoader};
use rquickjs::{CatchResultExt, FromJs, Module, Promise};
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

/// Memory usage statistics for the JavaScript runtime.
///
/// This struct provides detailed information about memory allocation
/// and usage within the JavaScript runtime, useful for monitoring
/// and debugging memory-related issues.
///
/// ## Example
///
/// ```dart
/// final runtime = await JsAsyncRuntime.withOptions(builtin: JsBuiltinOptions.all());
/// final context = await JsAsyncContext.from(runtime: runtime);
/// final engine = JsEngine(context: context);
/// await engine.initWithoutBridge();
///
/// final memory = await runtime.memoryUsage();
/// print('Memory used: ${memory.totalMemory} bytes');
/// print('Allocations: ${memory.totalAllocations}');
/// ```
#[frb(opaque)]
#[derive(Clone)]
pub struct MemoryUsage(pub(crate) rquickjs::qjs::JSMemoryUsage);

macro_rules! proxy_memory_usage_getter {
    ($($name:ident),+) => {
        impl MemoryUsage {
            $(
                #[frb(sync, getter)]
                pub fn $name(&self) -> i64 { self.0.$name }
            )+
        }
    };
}

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

impl MemoryUsage {
    /// Returns total memory used in bytes.
    ///
    /// This represents the total amount of memory currently allocated
    /// by the JavaScript runtime.
    ///
    /// ## Returns
    ///
    /// Total memory usage in bytes
    #[frb(sync, getter)]
    pub fn total_memory(&self) -> i64 {
        self.0.memory_used_size
    }

    /// Returns total allocation count.
    ///
    /// This represents the total number of memory allocations
    /// performed by the JavaScript runtime.
    ///
    /// ## Returns
    ///
    /// Total number of allocations
    #[frb(sync, getter)]
    pub fn total_allocations(&self) -> i64 {
        self.0.malloc_count
    }

    /// Returns a human-readable summary of memory usage.
    ///
    /// Provides a formatted string containing key memory statistics
    /// including total memory, object count, function count, and string count.
    ///
    /// ## Returns
    ///
    /// A formatted string summarizing memory usage
    ///
    /// ## Example
    ///
    /// ```dart
    /// final memory = await runtime.memoryUsage();
    /// print(memory.summary());
    /// // Output: Memory: 123456 bytes, Objects: 42, Functions: 10, Strings: 25
    /// ```
    #[frb(sync)]
    pub fn summary(&self) -> String {
        format!(
            "Memory: {} bytes, Objects: {}, Functions: {}, Strings: {}",
            self.0.memory_used_size, self.0.obj_count, self.0.js_func_count, self.0.str_count
        )
    }
}

/// A synchronous JavaScript runtime.
///
/// `JsRuntime` provides a synchronous execution environment for JavaScript code.
/// It manages the underlying QuickJS runtime and handles module loading,
/// garbage collection, and memory management.
///
/// ## Example
///
/// ```dart
/// final runtime = JsRuntime();
/// final context = JsContext.from(runtime: runtime);
/// final result = context.eval(code: '1 + 1');
/// print(result.value); // 2
/// ```
#[frb(opaque)]
#[derive(Clone)]
pub struct JsRuntime {
    pub(crate) rt: rquickjs::Runtime,
    pub(crate) global_attachment: Option<GlobalAttachment>,
}

impl JsRuntime {
    /// Creates a new JavaScript runtime with default configuration.
    ///
    /// The runtime is created with no builtin modules. Use `withOptions()`
    /// to create a runtime with custom builtin modules.
    ///
    /// ## Returns
    ///
    /// A new `JsRuntime` instance
    ///
    /// ## Example
    ///
    /// ```dart
    /// final runtime = JsRuntime();
    /// ```
    #[frb(sync)]
    pub fn new() -> anyhow::Result<Self> {
        let runtime = rquickjs::Runtime::new()?;
        Ok(Self {
            rt: runtime,
            global_attachment: None,
        })
    }

    /// Creates a new JavaScript runtime with custom builtin modules.
    ///
    /// This method creates a runtime with support for Node.js-compatible
    /// builtin modules and additional custom modules.
    ///
    /// ## Parameters
    /// - `builtin`: Optional builtin module configuration (e.g., console, fs, crypto)
    /// - `additional`: Optional list of additional modules to register
    ///
    /// ## Returns
    ///
    /// A new `JsRuntime` instance with configured modules
    ///
    /// ## Example
    ///
    /// ```dart
    /// final runtime = await JsRuntime.withOptions(
    ///   builtin: JsBuiltinOptions.all(),
    ///   additional: [
    ///     JsModule.fromCode(module: 'my-utils', code: 'export const foo = "bar";'),
    ///   ],
    /// );
    /// ```
    pub async fn with_options(
        builtin: Option<JsBuiltinOptions>,
        additional: Option<Vec<JsModule>>,
    ) -> anyhow::Result<Self> {
        let runtime = rquickjs::Runtime::new()?;
        let (
            module_resolver,
            module_loader,
            additional_resolver,
            additional_loader,
            global_attachment,
        ) = Self::build_loaders(builtin, additional).await?;

        let dynamic_resolver = DynamicModuleResolver::default();
        let dynamic_loader = DynamicModuleLoader::default();

        let resolver = (
            module_resolver,
            additional_resolver,
            BuiltinResolver::default(),
            dynamic_resolver,
            FileResolver::default(),
        );
        let loader = (
            module_loader,
            additional_loader,
            BuiltinLoader::default(),
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

    async fn build_loaders(
        builtin: Option<JsBuiltinOptions>,
        additional: Option<Vec<JsModule>>,
    ) -> anyhow::Result<(
        crate::api::module::ModuleResolver,
        rquickjs::loader::ModuleLoader,
        BuiltinResolver,
        BuiltinLoader,
        GlobalAttachment,
    )> {
        let (module_resolver, module_loader, global_attachment) =
            if let Some(builtin_options) = builtin {
                builtin_options.to_module_builder().build()
            } else {
                ModuleBuilder::new().build()
            };

        let mut additional_resolver = BuiltinResolver::default();
        let mut additional_loader = BuiltinLoader::default();

        if let Some(additional_modules) = additional {
            for module in additional_modules {
                let code = get_raw_source_code(module.source).await?;
                additional_resolver = additional_resolver.with_module(&module.name);
                additional_loader = additional_loader.with_module(&module.name, code);
            }
        }

        Ok((
            module_resolver,
            module_loader,
            additional_resolver,
            additional_loader,
            global_attachment,
        ))
    }

    /// Sets the memory limit for the runtime.
    ///
    /// Once the memory limit is reached, JavaScript execution will fail
    /// with a memory limit error.
    ///
    /// ## Parameters
    ///
    /// - `limit`: Maximum memory in bytes
    ///
    /// ## Example
    ///
    /// ```dart
    /// runtime.setMemoryLimit(limit: 16 * 1024 * 1024); // 16 MB
    /// ```
    #[frb(sync)]
    pub fn set_memory_limit(&self, limit: usize) {
        self.rt.set_memory_limit(limit);
    }

    /// Sets the maximum stack size.
    ///
    /// Limits the maximum depth of the JavaScript call stack to prevent
    /// stack overflow errors.
    ///
    /// ## Parameters
    ///
    /// - `limit`: Maximum stack size in bytes
    #[frb(sync)]
    pub fn set_max_stack_size(&self, limit: usize) {
        self.rt.set_max_stack_size(limit);
    }

    /// Sets the garbage collection threshold.
    ///
    /// Configures when the runtime should trigger automatic garbage collection.
    ///
    /// ## Parameters
    ///
    /// - `threshold`: Memory threshold in bytes
    #[frb(sync)]
    pub fn set_gc_threshold(&self, threshold: usize) {
        self.rt.set_gc_threshold(threshold);
    }

    /// Forces garbage collection.
    ///
    /// Manually triggers garbage collection to free unused memory.
    /// This can be useful for memory management but should not be called
    /// excessively as it may impact performance.
    ///
    /// ## Example
    ///
    /// ```dart
    /// runtime.runGc();
    /// ```
    #[frb(sync)]
    pub fn run_gc(&self) {
        self.rt.run_gc();
    }

    /// Returns memory usage statistics.
    ///
    /// Provides detailed information about current memory allocation
    /// and usage patterns.
    ///
    /// ## Returns
    ///
    /// A `MemoryUsage` struct containing memory statistics
    ///
    /// ## Example
    ///
    /// ```dart
    /// final usage = runtime.memoryUsage();
    /// print('Total: ${usage.totalMemory} bytes');
    /// ```
    #[frb(sync)]
    pub fn memory_usage(&self) -> MemoryUsage {
        MemoryUsage(self.rt.memory_usage())
    }

    /// Checks if there are pending jobs.
    ///
    /// Jobs are asynchronous tasks that need to be executed, such as
    /// promise callbacks or timer callbacks.
    ///
    /// ## Returns
    ///
    /// `true` if there are pending jobs, `false` otherwise
    #[frb(sync)]
    pub fn is_job_pending(&self) -> bool {
        self.rt.is_job_pending()
    }

    /// Executes a pending job.
    ///
    /// Runs one pending job if any are available. This method should be
    /// called repeatedly to process all pending asynchronous work.
    ///
    /// ## Returns
    ///
    /// `true` if a job was executed, `false` if no jobs were pending
    ///
    /// ## Throws
    ///
    /// If job execution fails
    #[frb(sync)]
    pub fn execute_pending_job(&self) -> anyhow::Result<bool> {
        self.rt
            .execute_pending_job()
            .map_err(|e| anyhow::anyhow!(e))
    }

    /// Sets dump flags for debugging.
    ///
    /// Configures debug output flags for the QuickJS engine.
    /// Useful for development and troubleshooting.
    ///
    /// ## Parameters
    ///
    /// - `flags`: Debug flags to set
    #[frb(sync)]
    pub fn set_dump_flags(&self, flags: u64) {
        self.rt.set_dump_flags(flags);
    }

    /// Sets runtime info string.
    ///
    /// Sets informational metadata about the runtime instance.
    ///
    /// ## Parameters
    ///
    /// - `info`: Info string to set
    ///
    /// ## Throws
    ///
    /// If setting the info fails
    #[frb(sync)]
    pub fn set_info(&self, info: String) -> anyhow::Result<()> {
        self.rt.set_info(info)?;
        Ok(())
    }
}

/// A synchronous JavaScript execution context.
///
/// `JsContext` provides a synchronous execution environment for JavaScript code.
/// Contexts are created from runtimes and maintain their own global state
/// while sharing the underlying runtime.
///
/// ## Note
///
/// Synchronous contexts do not support Promise/async operations.
/// Use `JsAsyncContext` for asynchronous code execution.
///
/// ## Example
///
/// ```dart
/// final runtime = JsRuntime();
/// final context = JsContext.from(runtime: runtime);
/// final result = context.eval(code: 'Math.sqrt(16)');
/// print(result.value); // 4
/// ```
#[frb(opaque)]
#[derive(Clone)]
pub struct JsContext {
    pub(crate) ctx: rquickjs::Context,
    pub(crate) global_attachment: Option<GlobalAttachment>,
}

impl JsContext {
    /// Creates a new context from a runtime.
    ///
    /// The context will inherit the runtime's module configuration
    /// and global attachments.
    ///
    /// ## Parameters
    ///
    /// - `runtime`: The runtime to create the context from
    ///
    /// ## Returns
    ///
    /// A new `JsContext` instance
    ///
    /// ## Throws
    ///
    /// If context creation fails
    ///
    /// ## Example
    ///
    /// ```dart
    /// final runtime = JsRuntime();
    /// final context = JsContext.from(runtime: runtime);
    /// ```
    #[frb(sync)]
    pub fn from(runtime: &JsRuntime) -> anyhow::Result<Self> {
        let context = rquickjs::Context::full(&runtime.rt)?;
        Ok(Self {
            ctx: context,
            global_attachment: runtime.global_attachment.clone(),
        })
    }

    /// Evaluates JavaScript code.
    ///
    /// Evaluates the given code string with default options.
    /// Promise/async operations are not supported in sync context.
    ///
    /// ## Parameters
    ///
    /// - `code`: JavaScript code to evaluate
    ///
    /// ## Returns
    ///
    /// The result of evaluation as a `JsValue`
    ///
    /// ## Example
    ///
    /// ```dart
    /// final result = context.eval(code: '2 + 2');
    /// print(result.value); // 4
    /// ```
    #[frb(sync)]
    pub fn eval(&self, code: String) -> JsResult {
        self.eval_with_options(code, JsEvalOptions::defaults())
    }

    /// Evaluates JavaScript code with options.
    ///
    /// Provides fine-grained control over evaluation settings.
    /// Promise/async operations are not supported in sync context.
    ///
    /// ## Parameters
    ///
    /// - `code`: JavaScript code to evaluate
    /// - `options`: Evaluation options
    ///
    /// ## Returns
    ///
    /// The result of evaluation as a `JsValue`
    ///
    /// ## Throws
    ///
    /// - If promise option is enabled (not supported in sync context)
    /// - If code evaluation fails
    #[frb(sync)]
    pub fn eval_with_options(&self, code: String, options: JsEvalOptions) -> JsResult {
        if options.promise.unwrap_or(false) {
            return JsResult::Err(JsError::promise(
                "Promise not supported in sync context",
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
            result_from_sync(&ctx, res)
        })
    }

    /// Evaluates JavaScript code from a file.
    ///
    /// Reads and executes JavaScript code from the specified file path.
    ///
    /// ## Parameters
    ///
    /// - `path`: Path to the JavaScript file
    ///
    /// ## Returns
    ///
    /// The result of evaluation as a `JsValue`
    ///
    /// ## Throws
    ///
    /// - If promise option is enabled (not supported in sync context)
    /// - If file cannot be read
    /// - If code evaluation fails
    ///
    /// ## Example
    ///
    /// ```dart
    /// final result = context.evalFile(path: '/path/to/script.js');
    /// ```
    #[frb(sync)]
    pub fn eval_file(&self, path: String) -> JsResult {
        self.eval_file_with_options(path, JsEvalOptions::defaults())
    }

    /// Evaluates JavaScript code from a file with options.
    ///
    /// Reads and executes JavaScript code from the specified file path
    /// with custom evaluation options.
    ///
    /// ## Parameters
    ///
    /// - `path`: Path to the JavaScript file
    /// - `options`: Evaluation options
    ///
    /// ## Returns
    ///
    /// The result of evaluation as a `JsValue`
    ///
    /// ## Throws
    ///
    /// - If promise option is enabled (not supported in sync context)
    /// - If file cannot be read
    /// - If code evaluation fails
    #[frb(sync)]
    pub fn eval_file_with_options(&self, path: String, options: JsEvalOptions) -> JsResult {
        if options.promise.unwrap_or(false) {
            return JsResult::Err(JsError::promise(
                "Promise not supported in sync context",
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
            result_from_sync(&ctx, res)
        })
    }
}

/// An asynchronous JavaScript runtime.
///
/// `JsAsyncRuntime` provides an asynchronous execution environment for JavaScript code.
/// It supports Promise/async operations and is recommended for most use cases.
///
/// ## Example
///
/// ```dart
/// final runtime = await JsAsyncRuntime.withOptions(builtin: JsBuiltinOptions.all());
/// final context = await JsAsyncContext.from(runtime: runtime);
/// ```
#[frb(opaque)]
#[derive(Clone)]
pub struct JsAsyncRuntime {
    pub(crate) rt: rquickjs::AsyncRuntime,
    pub(crate) global_attachment: Option<GlobalAttachment>,
}

impl JsAsyncRuntime {
    /// Creates a new async runtime with default configuration.
    ///
    /// The runtime is created with no builtin modules. Use `withOptions()`
    /// to create a runtime with custom builtin modules.
    ///
    /// ## Returns
    ///
    /// A new `JsAsyncRuntime` instance
    ///
    /// ## Example
    ///
    /// ```dart
    /// final runtime = JsAsyncRuntime();
    /// ```
    #[frb(sync)]
    pub fn new() -> anyhow::Result<Self> {
        let runtime = rquickjs::AsyncRuntime::new()?;
        Ok(Self {
            rt: runtime,
            global_attachment: None,
        })
    }

    /// Creates a new async runtime with custom configuration.
    ///
    /// This method creates a runtime with support for Node.js-compatible
    /// builtin modules and additional custom modules.
    ///
    /// ## Parameters
    /// - `builtin`: Optional builtin module configuration (e.g., console, fs, crypto)
    /// - `additional`: Optional list of additional modules to register
    ///
    /// ## Returns
    ///
    /// A new `JsAsyncRuntime` instance with configured modules
    ///
    /// ## Example
    ///
    /// ```dart
    /// final runtime = await JsAsyncRuntime.withOptions(
    ///   builtin: JsBuiltinOptions.all(),
    ///   additional: [
    ///     JsModule.fromCode(module: 'my-utils', code: 'export const foo = "bar";'),
    ///   ],
    /// );
    /// ```
    pub async fn with_options(
        builtin: Option<JsBuiltinOptions>,
        additional: Option<Vec<JsModule>>,
    ) -> anyhow::Result<Self> {
        let runtime = rquickjs::AsyncRuntime::new()?;
        let (
            module_resolver,
            module_loader,
            additional_resolver,
            additional_loader,
            global_attachment,
        ) = JsRuntime::build_loaders(builtin, additional).await?;

        let dynamic_resolver = DynamicModuleResolver::default();
        let dynamic_loader = DynamicModuleLoader::default();

        let resolver = (
            module_resolver,
            additional_resolver,
            BuiltinResolver::default(),
            dynamic_resolver,
            FileResolver::default(),
        );
        let loader = (
            module_loader,
            additional_loader,
            BuiltinLoader::default(),
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

    /// Sets the memory limit.
    ///
    /// Once the memory limit is reached, JavaScript execution will fail
    /// with a memory limit error.
    ///
    /// ## Parameters
    ///
    /// - `limit`: Maximum memory in bytes
    ///
    /// ## Example
    ///
    /// ```dart
    /// await runtime.setMemoryLimit(limit: 16 * 1024 * 1024); // 16 MB
    /// ```
    pub async fn set_memory_limit(&self, limit: usize) {
        self.rt.set_memory_limit(limit).await;
    }

    /// Sets the maximum stack size.
    ///
    /// Limits the maximum depth of the JavaScript call stack to prevent
    /// stack overflow errors.
    ///
    /// ## Parameters
    ///
    /// - `limit`: Maximum stack size in bytes
    pub async fn set_max_stack_size(&self, limit: usize) {
        self.rt.set_max_stack_size(limit).await;
    }

    /// Sets the garbage collection threshold.
    ///
    /// Configures when the runtime should trigger automatic garbage collection.
    ///
    /// ## Parameters
    ///
    /// - `threshold`: Memory threshold in bytes
    pub async fn set_gc_threshold(&self, threshold: usize) {
        self.rt.set_gc_threshold(threshold).await;
    }

    /// Forces garbage collection.
    ///
    /// Manually triggers garbage collection to free unused memory.
    /// This can be useful for memory management but should not be called
    /// excessively as it may impact performance.
    ///
    /// ## Example
    ///
    /// ```dart
    /// await runtime.runGc();
    /// ```
    pub async fn run_gc(&self) {
        self.rt.run_gc().await;
    }

    /// Returns memory usage statistics.
    ///
    /// Provides detailed information about current memory allocation
    /// and usage patterns.
    ///
    /// ## Returns
    ///
    /// A `MemoryUsage` struct containing memory statistics
    ///
    /// ## Example
    ///
    /// ```dart
    /// final usage = await runtime.memoryUsage();
    /// print('Total: ${usage.totalMemory} bytes');
    /// ```
    pub async fn memory_usage(&self) -> MemoryUsage {
        MemoryUsage(self.rt.memory_usage().await)
    }

    /// Checks if there are pending jobs.
    ///
    /// Jobs are asynchronous tasks that need to be executed, such as
    /// promise callbacks or timer callbacks.
    ///
    /// ## Returns
    ///
    /// `true` if there are pending jobs, `false` otherwise
    pub async fn is_job_pending(&self) -> bool {
        self.rt.is_job_pending().await
    }

    /// Executes a pending job.
    ///
    /// Runs one pending job if any are available. This method should be
    /// called repeatedly to process all pending asynchronous work.
    ///
    /// ## Returns
    ///
    /// `true` if a job was executed, `false` if no jobs were pending
    ///
    /// ## Throws
    ///
    /// If job execution fails
    pub async fn execute_pending_job(&self) -> anyhow::Result<bool> {
        self.rt
            .execute_pending_job()
            .await
            .map_err(|e| anyhow::anyhow!(e))
    }

    /// Puts the runtime into idle state.
    ///
    /// Signals that the runtime is idle and may be used for background
    /// processing or resource cleanup.
    pub async fn idle(&self) {
        self.rt.idle().await;
    }

    /// Sets runtime info string.
    ///
    /// Sets informational metadata about the runtime instance.
    ///
    /// ## Parameters
    ///
    /// - `info`: Info string to set
    ///
    /// ## Throws
    ///
    /// If setting the info fails
    pub async fn set_info(&self, info: String) -> anyhow::Result<()> {
        self.rt.set_info(info).await?;
        Ok(())
    }
}

/// An asynchronous JavaScript execution context.
///
/// `JsAsyncContext` provides an asynchronous execution environment for JavaScript code.
/// It supports Promise/async operations and is the recommended context type for
/// most applications.
///
/// ## Example
///
/// ```dart
/// final runtime = await JsAsyncRuntime.withOptions(builtin: JsBuiltinOptions.all());
/// final context = await JsAsyncContext.from(runtime: runtime);
/// final result = await context.eval(code: 'await Promise.resolve(42)');
/// print(result.value); // 42
/// ```
#[frb(opaque)]
#[derive(Clone)]
pub struct JsAsyncContext {
    pub(crate) ctx: rquickjs::AsyncContext,
    pub(crate) global_attachment: Option<GlobalAttachment>,
}

impl JsAsyncContext {
    /// Creates a new async context from a runtime.
    ///
    /// The context will inherit the runtime's module configuration
    /// and global attachments, and will be initialized with support
    /// for dynamic module loading.
    ///
    /// ## Parameters
    ///
    /// - `runtime`: The runtime to create the context from
    ///
    /// ## Returns
    ///
    /// A new `JsAsyncContext` instance
    ///
    /// ## Throws
    ///
    /// If context creation or initialization fails
    ///
    /// ## Example
    ///
    /// ```dart
    /// final runtime = await JsAsyncRuntime.withOptions(builtin: JsBuiltinOptions.all());
    /// final context = await JsAsyncContext.from(runtime: runtime);
    /// ```
    pub async fn from(runtime: &JsAsyncRuntime) -> anyhow::Result<Self> {
        let context = rquickjs::AsyncContext::full(&runtime.rt).await?;
        let dynamic_modules = Arc::new(RwLock::new(HashMap::<String, Vec<u8>>::new()));

        context.async_with(async |ctx| {
            ctx.store_userdata(dynamic_modules.clone())
                .map_err(|e| anyhow::anyhow!("Failed to store dynamic modules: {:?}", e))
        })
        .await?;

        Ok(Self {
            ctx: context,
            global_attachment: runtime.global_attachment.clone(),
        })
    }

    /// Evaluates JavaScript code.
    ///
    /// Evaluates the given code string with promise support enabled.
    /// Top-level await is supported.
    ///
    /// ## Parameters
    ///
    /// - `code`: JavaScript code to evaluate
    ///
    /// ## Returns
    ///
    /// The result of evaluation as a `JsValue`
    ///
    /// ## Example
    ///
    /// ```dart
    /// final result = await context.eval(code: 'await Promise.resolve(42)');
    /// print(result.value); // 42
    /// ```
    pub async fn eval(&self, code: String) -> JsResult {
        self.eval_with_options(code, JsEvalOptions::with_promise()).await
    }

    /// Evaluates JavaScript code with options.
    ///
    /// Provides fine-grained control over evaluation settings.
    /// Promise support is automatically enabled.
    ///
    /// ## Parameters
    ///
    /// - `code`: JavaScript code to evaluate
    /// - `options`: Evaluation options
    ///
    /// ## Returns
    ///
    /// The result of evaluation as a `JsValue`
    ///
    /// ## Throws
    ///
    /// - If code evaluation fails
    /// - If global attachment fails
    pub async fn eval_with_options(&self, code: String, options: JsEvalOptions) -> JsResult {
        self.ctx.async_with(async |ctx| {
            if let Some(attachment) = &self.global_attachment {
                if let Err(e) = attachment.clone().attach(&ctx) {
                    return JsResult::Err(JsError::context(e.to_string()));
                }
            }
            let mut options = options;
            options.promise = Some(true);
            let res = ctx.eval_with_options(code, options.into());
            result_from_promise(&ctx, res).await
        })
        .await
    }

    /// Evaluates JavaScript code from a file.
    ///
    /// Reads and executes JavaScript code from the specified file path.
    /// Promise support is automatically enabled.
    ///
    /// ## Parameters
    ///
    /// - `path`: Path to the JavaScript file
    ///
    /// ## Returns
    ///
    /// The result of evaluation as a `JsValue`
    ///
    /// ## Throws
    ///
    /// - If file cannot be read
    /// - If code evaluation fails
    ///
    /// ## Example
    ///
    /// ```dart
    /// final result = await context.evalFile(path: '/path/to/script.js');
    /// ```
    pub async fn eval_file(&self, path: String) -> JsResult {
        self.eval_file_with_options(path, JsEvalOptions::with_promise()).await
    }

    /// Evaluates JavaScript code from a file with options.
    ///
    /// Reads and executes JavaScript code from the specified file path
    /// with custom evaluation options.
    ///
    /// ## Parameters
    ///
    /// - `path`: Path to the JavaScript file
    /// - `options`: Evaluation options
    ///
    /// ## Returns
    ///
    /// The result of evaluation as a `JsValue`
    ///
    /// ## Throws
    ///
    /// - If file cannot be read
    /// - If code evaluation fails
    pub async fn eval_file_with_options(&self, path: String, options: JsEvalOptions) -> JsResult {
        self.ctx.async_with(async |ctx| {
            if let Some(attachment) = &self.global_attachment {
                if let Err(e) = attachment.clone().attach(&ctx) {
                    return JsResult::Err(JsError::context(e.to_string()));
                }
            }
            let mut options = options;
            options.promise = Some(true);
            let res = ctx.eval_file_with_options(path, options.into());
            result_from_promise(&ctx, res).await
        })
        .await
    }

    /// Evaluates a function from a module.
    ///
    /// Imports the specified module and invokes one of its exported functions.
    ///
    /// ## Parameters
    /// - `module`: The module name to import
    /// - `method`: The function name to call (must be exported from the module)
    /// - `params`: Optional parameters to pass to the function
    ///
    /// ## Returns
    ///
    /// The result of the function call as a `JsValue`
    ///
    /// ## Throws
    ///
    /// - If the module cannot be imported
    /// - If the function does not exist
    /// - If the function call fails
    ///
    /// ## Example
    ///
    /// ```dart
    /// // Call a function with parameters
    /// final result = await context.evalFunction(
    ///   module: 'math-utils',
    ///   method: 'add',
    ///   params: [JsValue.integer(1), JsValue.integer(2)],
    /// );
    /// print(result.value); // 3
    /// ```
    pub async fn eval_function(
        &self,
        module: String,
        method: String,
        params: Option<Vec<JsValue>>,
    ) -> JsResult {
        let params = params.unwrap_or_default();
        self.ctx.async_with(async |ctx| {
            if let Some(attachment) = &self.global_attachment {
                if let Err(e) = attachment.attach(&ctx) {
                    return JsResult::Err(JsError::context(format!(
                        "Failed to attach global context: {}",
                        e
                    )));
                }
            }
            call_module_method(&ctx, module, method, params).await
        })
        .await
    }
}

/// Calls a method on a module.
pub(crate) async fn call_module_method<'js>(
    ctx: &rquickjs::Ctx<'js>,
    module: String,
    method: String,
    params: Vec<JsValue>,
) -> JsResult {
    let promise = match Module::import(ctx, module.clone()).catch(ctx) {
        Ok(p) => p,
        Err(e) => {
            return JsResult::Err(JsError::module(
                Some(module),
                None,
                format!("Failed to import: {}", e),
            ))
        }
    };

    let module_value = match promise.into_future::<rquickjs::Value>().await.catch(ctx) {
        Ok(v) => v,
        Err(e) => {
            return JsResult::Err(JsError::module(
                Some(module),
                None,
                format!("Failed to import: {}", e),
            ))
        }
    };

    let obj = match module_value.as_object() {
        Some(o) => o,
        None => {
            return JsResult::Err(JsError::module(
                Some(module),
                None,
                "Module is not an object",
            ))
        }
    };

    let func_value: rquickjs::Result<rquickjs::Value> = obj.get(&method);
    let func = match func_value.catch(ctx) {
        Ok(v) if v.is_function() => match v.as_function() {
            Some(f) => f.clone(),
            None => {
                return JsResult::Err(JsError::module(
                    Some(module),
                    Some(method),
                    "Method is not a function",
                ))
            }
        },
        Ok(_) => {
            return JsResult::Err(JsError::module(
                Some(module),
                Some(method),
                "Method is not a function",
            ))
        }
        Err(e) => {
            return JsResult::Err(JsError::module(
                Some(module),
                Some(method),
                format!("Failed to get method: {}", e),
            ))
        }
    };

    let res = func.call((rquickjs::function::Rest(params),));
    result_from_promise(ctx, res).await
}

/// Helper function to convert sync result.
fn result_from_sync<'js>(
    ctx: &rquickjs::Ctx<'js>,
    res: rquickjs::Result<rquickjs::Value<'js>>,
) -> JsResult {
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

/// Helper function to convert promise result.
pub(crate) async fn result_from_promise<'js>(
    ctx: &rquickjs::Ctx<'js>,
    res: rquickjs::Result<Promise<'js>>,
) -> JsResult {
    match res.catch(ctx) {
        Ok(promise) => {
            let mut value = match promise.into_future::<rquickjs::Value>().await.catch(ctx) {
                Ok(v) => v,
                Err(e) => return JsResult::Err(JsError::runtime(e.to_string())),
            };

            // JS_EVAL_FLAG_ASYNC wraps result in {value: xxx}
            // Detect wrapper: object with exactly one property named "value"
            if let Some(obj) = value.as_object() {
                if let Ok(keys) = obj.keys::<String>().collect::<Result<Vec<_>, _>>() {
                    if keys.len() == 1 && keys[0] == "value" {
                        // This is the QuickJS wrapper, extract the inner value
                        if let Ok(inner) = obj.get::<_, rquickjs::Value>("value") {
                            value = inner;
                        }
                    }
                }
            }

            // Handle nested promises
            while value.is_promise() {
                value = match value.as_promise().unwrap().clone().into_future::<rquickjs::Value>().await.catch(ctx) {
                    Ok(v) => v,
                    Err(e) => return JsResult::Err(JsError::runtime(e.to_string())),
                };
                // Unwrap wrapper again if needed
                if let Some(obj) = value.as_object() {
                    if let Ok(keys) = obj.keys::<String>().collect::<Result<Vec<_>, _>>() {
                        if keys.len() == 1 && keys[0] == "value" {
                            if let Ok(inner) = obj.get::<_, rquickjs::Value>("value") {
                                value = inner;
                            }
                        }
                    }
                }
            }

            match JsValue::from_js(ctx, value).catch(ctx) {
                Ok(v) => JsResult::Ok(v),
                Err(e) => JsResult::Err(JsError::runtime(e.to_string())),
            }
        }
        Err(e) => JsResult::Err(JsError::runtime(e.to_string())),
    }
}

