//! # Runtime and Context Management
//!
//! This module provides the core runtime and context types for JavaScript execution.
//! It includes both synchronous and asynchronous variants with a unified interface.

use crate::api::error::{JsError, JsResult};
use crate::api::module::{
    DynamicModuleEntry, DynamicModuleLoader, DynamicModuleResolver, DynamicModuleStorage,
    GlobalAttachment, LoadedDynamicModules, ModuleBuilder, get_available_module_names,
};
use crate::api::source::{JsBuiltinOptions, JsEvalOptions, JsModule, get_raw_source_code};
use crate::api::value::{JsValue, install_value_intrinsics};
use flutter_rust_bridge::frb;
use rquickjs::loader::{BuiltinLoader, BuiltinResolver, FileResolver, NativeLoader, ScriptLoader};
use rquickjs::promise::MaybePromise;
use rquickjs::{CatchResultExt, FromJs, Module, Promise};
use std::sync::{Arc, RwLock};

/// Biggest `max_stack_size` for the async runtime: 3/4 of the dedicated JS
/// thread stack, leaving 1/4 as headroom. Also the default budget.
///
/// QuickJS's overflow check is a soft limit measured from a baseline on the
/// running thread; it only fires after JS grows this many bytes past it and
/// does not know the real native stack. If the budget reaches the thread
/// stack, JS overflows it and the process aborts instead of throwing. The
/// async runtime runs JS on fjs's own big threads (see [`crate::js_executor`]),
/// so this ceiling is generous. Deeper recursion needs a bigger thread stack,
/// not a bigger budget.
pub(crate) const MAX_SAFE_STACK_SIZE: usize = crate::js_executor::JS_THREAD_STACK_SIZE / 4 * 3;

/// Ceiling for the sync runtime, which runs JS on the caller's thread (fjs does
/// not control its stack). Kept conservative — assumes a 2 MB thread.
const SYNC_MAX_STACK_SIZE: usize = 2 * 1024 * 1024 / 4 * 3;

/// Clamps a requested stack budget to `ceiling`. `0` means "no limit" to
/// QuickJS, which on a fixed thread stack just means "crash", so it maps to the
/// ceiling too.
fn clamp_stack_size(limit: usize, ceiling: usize) -> usize {
    if limit == 0 || limit > ceiling {
        ceiling
    } else {
        limit
    }
}

/// Memory usage statistics for the JavaScript runtime.
///
/// This struct provides detailed information about memory allocation
/// and usage within the JavaScript runtime, useful for monitoring
/// and debugging memory-related issues.
///
/// ## Example
///
/// ```dart
/// final runtime = await JsAsyncRuntime.create(builtins: JsBuiltinOptions.all());
/// final engine = await JsEngine.create(builtins: JsBuiltinOptions.all());
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

type RuntimeResolverStack = (
    crate::api::module::ModuleResolver,
    BuiltinResolver,
    BuiltinResolver,
    DynamicModuleResolver,
    FileResolver,
);

type RuntimeLoaderStack = (
    rquickjs::loader::ModuleLoader,
    BuiltinLoader,
    BuiltinLoader,
    DynamicModuleLoader,
    NativeLoader,
    ScriptLoader,
);

fn make_loader_stack(
    module_resolver: crate::api::module::ModuleResolver,
    module_loader: rquickjs::loader::ModuleLoader,
    additional_resolver: BuiltinResolver,
    additional_loader: BuiltinLoader,
) -> (RuntimeResolverStack, RuntimeLoaderStack) {
    let resolver = (
        module_resolver,
        additional_resolver,
        BuiltinResolver::default(),
        DynamicModuleResolver::default(),
        FileResolver::default(),
    );
    let loader = (
        module_loader,
        additional_loader,
        BuiltinLoader::default(),
        DynamicModuleLoader::default(),
        NativeLoader::default(),
        ScriptLoader::default(),
    );
    (resolver, loader)
}

fn install_default_async_loaders(runtime: &rquickjs::AsyncRuntime) -> anyhow::Result<()> {
    let (module_resolver, module_loader, _) = ModuleBuilder::new().build();
    let (resolver, loader) = make_loader_stack(
        module_resolver,
        module_loader,
        BuiltinResolver::default(),
        BuiltinLoader::default(),
    );
    futures::executor::block_on(runtime.set_loader(resolver, loader));
    Ok(())
}

/// The default stack budget for every async runtime. `new()` and `create()` both
/// call this so they can't disagree — without it, `new()` keeps QuickJS's tiny
/// 256 KB default.
async fn apply_default_async_stack_budget(runtime: &rquickjs::AsyncRuntime) {
    runtime.set_max_stack_size(MAX_SAFE_STACK_SIZE).await;
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
    /// The runtime is created with no builtin modules. Use `create()`
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
        let (module_resolver, module_loader, _) = ModuleBuilder::new().build();
        let (resolver, loader) = make_loader_stack(
            module_resolver,
            module_loader,
            BuiltinResolver::default(),
            BuiltinLoader::default(),
        );
        runtime.set_loader(resolver, loader);
        Ok(Self {
            rt: runtime,
            global_attachment: None,
        })
    }

    /// Creates a new JavaScript runtime with custom builtin modules.
    ///
    /// This method creates a runtime with support for Node.js-compatible
    /// builtin modules and custom modules.
    ///
    /// ## Parameters
    /// - `builtins`: Optional builtin module configuration (e.g., console, fs, crypto)
    /// - `modules`: Optional list of additional modules to register
    ///
    /// ## Returns
    ///
    /// A new `JsRuntime` instance with configured modules
    ///
    /// ## Example
    ///
    /// ```dart
    /// final runtime = await JsRuntime.create(
    ///   builtins: JsBuiltinOptions.all(),
    ///   modules: [
    ///     JsModule.code(module: 'my-utils', code: 'export const foo = "bar";'),
    ///   ],
    /// );
    /// ```
    pub async fn create(
        builtins: Option<JsBuiltinOptions>,
        modules: Option<Vec<JsModule>>,
    ) -> anyhow::Result<Self> {
        let runtime = rquickjs::Runtime::new()?;
        let (
            module_resolver,
            module_loader,
            additional_resolver,
            additional_loader,
            global_attachment,
        ) = Self::build_loaders(builtins, modules).await?;

        let (resolver, loader) = make_loader_stack(
            module_resolver,
            module_loader,
            additional_resolver,
            additional_loader,
        );
        runtime.set_loader(resolver, loader);

        Ok(Self {
            rt: runtime,
            global_attachment: Some(global_attachment),
        })
    }

    async fn build_loaders(
        builtins: Option<JsBuiltinOptions>,
        modules: Option<Vec<JsModule>>,
    ) -> anyhow::Result<(
        crate::api::module::ModuleResolver,
        rquickjs::loader::ModuleLoader,
        BuiltinResolver,
        BuiltinLoader,
        GlobalAttachment,
    )> {
        let (module_resolver, module_loader, mut global_attachment) =
            if let Some(builtin_options) = builtins {
                builtin_options.to_module_builder().build()
            } else {
                ModuleBuilder::new().build()
            };

        let mut additional_resolver = BuiltinResolver::default();
        let mut additional_loader = BuiltinLoader::default();

        if let Some(named_modules) = modules {
            for module in named_modules {
                let code = get_raw_source_code(module.source).await?;
                additional_resolver = additional_resolver.with_module(&module.name);
                additional_loader = additional_loader.with_module(&module.name, code);
                global_attachment = global_attachment.add_name(module.name);
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
    /// - `limit`: Maximum stack size in bytes. Clamped to a safe ceiling below
    ///   the runtime thread stack so overflow throws instead of crashing; `0`
    ///   ("no limit") maps to that ceiling.
    #[frb(sync)]
    pub fn set_max_stack_size(&self, limit: usize) {
        self.rt
            .set_max_stack_size(clamp_stack_size(limit, SYNC_MAX_STACK_SIZE));
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

    /// Checks whether the QuickJS job queue is non-empty.
    ///
    /// In the synchronous runtime this only reflects QuickJS jobs, such as
    /// pending Promise reaction callbacks created by already-resolved promises.
    /// It does not wait for external async work.
    ///
    /// ## Returns
    ///
    /// `true` if at least one QuickJS job is queued, `false` otherwise
    ///
    /// ## Example
    ///
    /// ```dart
    /// if (runtime.isJobPending()) {
    ///   runtime.executePendingJob();
    /// }
    /// ```
    #[frb(sync)]
    pub fn is_job_pending(&self) -> bool {
        self.rt.is_job_pending()
    }

    /// Executes one pending QuickJS job.
    ///
    /// This is a low-level pump for synchronous runtimes. It is mainly useful
    /// when you want explicit control over when Promise callbacks are drained.
    ///
    /// ## Returns
    ///
    /// `true` if one job was executed, `false` if the queue was empty
    ///
    /// ## Throws
    ///
    /// If the job throws while running
    ///
    /// ## Example
    ///
    /// ```dart
    /// while (runtime.isJobPending()) {
    ///   runtime.executePendingJob();
    /// }
    /// ```
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
        context.with(|ctx| install_value_intrinsics(&ctx))?;
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
            return JsResult::Err(JsError::promise("Promise not supported in sync context"));
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
            return JsResult::Err(JsError::promise("Promise not supported in sync context"));
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

    /// Returns all modules currently available in this context.
    ///
    /// This includes builtin modules, statically configured modules,
    /// and any dynamically declared modules attached to the context.
    #[frb(sync)]
    pub fn get_available_modules(&self) -> anyhow::Result<Vec<String>> {
        self.ctx.with(|ctx| {
            if let Some(attachment) = &self.global_attachment {
                attachment
                    .attach(&ctx)
                    .map_err(|e| anyhow::anyhow!("Failed to attach global context: {e}"))?;
            }
            Ok(get_available_module_names(&ctx))
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
/// final runtime = await JsAsyncRuntime.create(builtins: JsBuiltinOptions.all());
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
    /// The runtime is created with no builtin modules. Use `create()`
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
        install_default_async_loaders(&runtime)?;
        // block_on because new() is sync — same as the loader install above.
        futures::executor::block_on(apply_default_async_stack_budget(&runtime));
        Ok(Self {
            rt: runtime,
            global_attachment: None,
        })
    }

    /// Creates a new async runtime with custom configuration.
    ///
    /// This method creates a runtime with support for Node.js-compatible
    /// builtin modules and custom modules.
    ///
    /// ## Parameters
    /// - `builtins`: Optional builtin module configuration (e.g., console, fs, crypto)
    /// - `modules`: Optional list of additional modules to register
    ///
    /// ## Returns
    ///
    /// A new `JsAsyncRuntime` instance with configured modules
    ///
    /// ## Example
    ///
    /// ```dart
    /// final runtime = await JsAsyncRuntime.create(
    ///   builtins: JsBuiltinOptions.all(),
    ///   modules: [
    ///     JsModule.code(module: 'my-utils', code: 'export const foo = "bar";'),
    ///   ],
    /// );
    /// ```
    pub async fn create(
        builtins: Option<JsBuiltinOptions>,
        modules: Option<Vec<JsModule>>,
    ) -> anyhow::Result<Self> {
        let runtime = rquickjs::AsyncRuntime::new()?;
        let (
            module_resolver,
            module_loader,
            additional_resolver,
            additional_loader,
            global_attachment,
        ) = JsRuntime::build_loaders(builtins, modules).await?;

        let (resolver, loader) = make_loader_stack(
            module_resolver,
            module_loader,
            additional_resolver,
            additional_loader,
        );
        runtime.set_loader(resolver, loader).await;
        apply_default_async_stack_budget(&runtime).await;

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
    /// - `limit`: Maximum stack size in bytes. Clamped to a safe ceiling below
    ///   the runtime thread stack so overflow throws instead of crashing; `0`
    ///   ("no limit") maps to that ceiling.
    pub async fn set_max_stack_size(&self, limit: usize) {
        self.rt
            .set_max_stack_size(clamp_stack_size(limit, MAX_SAFE_STACK_SIZE))
            .await;
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

    /// Checks whether the async runtime still has work to do.
    ///
    /// This reports both queued QuickJS jobs and background futures managed by
    /// the runtime scheduler, such as timers or other spawned async work.
    ///
    /// ## Returns
    ///
    /// `true` if the runtime still has queued jobs or scheduled async work,
    /// `false` otherwise
    ///
    /// ## Example
    ///
    /// ```dart
    /// if (await runtime.isJobPending()) {
    ///   await runtime.executePendingJob();
    /// }
    /// ```
    pub async fn is_job_pending(&self) -> bool {
        self.rt.is_job_pending().await
    }

    /// Advances the async runtime by one scheduler step.
    ///
    /// This may execute one queued QuickJS job or make progress on background
    /// runtime futures. A `false` return value only means this call did not make
    /// progress; it does not guarantee the runtime is fully drained. Use
    /// `idle()` when you explicitly want to run the runtime until quiescent.
    ///
    /// ## Returns
    ///
    /// `true` if this call executed a job or advanced pending async work,
    /// `false` if nothing progressed during this step
    ///
    /// ## Throws
    ///
    /// If a scheduled job throws while running
    ///
    /// ## Example
    ///
    /// ```dart
    /// while (await runtime.isJobPending()) {
    ///   final progressed = await runtime.executePendingJob();
    ///   if (!progressed) {
    ///     break;
    ///   }
    /// }
    /// ```
    pub async fn execute_pending_job(&self) -> anyhow::Result<bool> {
        let rt = self.rt.clone();
        crate::js_executor::run(async move { rt.execute_pending_job().await })
            .await
            .map_err(|e| anyhow::anyhow!(e))
    }

    /// Runs the async runtime until no queued jobs or spawned futures remain.
    ///
    /// This is a full drain operation. It may execute timers, promise callbacks,
    /// and other background work unrelated to the call site, so it should be used
    /// deliberately for teardown, tests, or explicit "drain everything" flows.
    ///
    /// QuickJS job errors raised during this drain are handled by the underlying
    /// runtime and are not surfaced through this method.
    ///
    /// ## Example
    ///
    /// ```dart
    /// await runtime.idle();
    /// ```
    pub async fn idle(&self) {
        let rt = self.rt.clone();
        crate::js_executor::run(async move { rt.idle().await }).await;
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
/// final runtime = await JsAsyncRuntime.create(builtins: JsBuiltinOptions.all());
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
    /// Runs `f` against this context on a dedicated big-stack JS thread.
    ///
    /// All user-facing JavaScript runs through here so it gets a browser-class
    /// native stack (see [`crate::js_executor`]) instead of flutter_rust_bridge's
    /// smaller worker stack, which deep JS (e.g. a recursive render) would
    /// overflow. (Context setup in `from` is shallow and runs inline.)
    pub(crate) async fn with_js<F, R>(&self, f: F) -> R
    where
        F: for<'js> AsyncFnOnce(rquickjs::Ctx<'js>) -> R + Send + 'static,
        R: Send + 'static,
    {
        let ctx = self.ctx.clone();
        crate::js_executor::run(async move { ctx.async_with(f).await }).await
    }

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
    /// final runtime = await JsAsyncRuntime.create(builtins: JsBuiltinOptions.all());
    /// final context = await JsAsyncContext.from(runtime: runtime);
    /// ```
    pub async fn from(runtime: &JsAsyncRuntime) -> anyhow::Result<Self> {
        let context = rquickjs::AsyncContext::full(&runtime.rt).await?;
        let dynamic_modules: DynamicModuleStorage =
            Arc::new(RwLock::new(std::collections::HashMap::<
                String,
                DynamicModuleEntry,
            >::new()));
        let loaded_dynamic_modules = LoadedDynamicModules::default();

        context
            .async_with(async |ctx| {
                ctx.store_userdata(dynamic_modules.clone())
                    .map_err(|e| anyhow::anyhow!("Failed to store dynamic modules: {:?}", e))?;
                ctx.store_userdata(loaded_dynamic_modules).map_err(|e| {
                    anyhow::anyhow!("Failed to store loaded dynamic modules: {:?}", e)
                })?;
                Ok::<(), anyhow::Error>(())
            })
            .await?;
        context
            .async_with(async |ctx| install_value_intrinsics(&ctx))
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
        self.eval_with_options(code, JsEvalOptions::with_promise())
            .await
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
        let attachment = self.global_attachment.clone();
        self.with_js(async move |ctx| {
            if let Some(attachment) = &attachment
                && let Err(e) = attachment.attach(&ctx)
            {
                return JsResult::Err(JsError::context(e.to_string()));
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
        self.eval_file_with_options(path, JsEvalOptions::with_promise())
            .await
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
        let attachment = self.global_attachment.clone();
        self.with_js(async move |ctx| {
            if let Some(attachment) = &attachment
                && let Err(e) = attachment.attach(&ctx)
            {
                return JsResult::Err(JsError::context(e.to_string()));
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
        let attachment = self.global_attachment.clone();
        self.with_js(async move |ctx| {
            if let Some(attachment) = &attachment
                && let Err(e) = attachment.attach(&ctx)
            {
                return JsResult::Err(JsError::context(format!(
                    "Failed to attach global context: {}",
                    e
                )));
            }
            call_module_method(&ctx, module, method, params).await
        })
        .await
    }

    /// Returns all modules currently available in this context.
    ///
    /// This includes builtin modules, statically configured modules,
    /// and any dynamically declared modules attached to the context.
    pub async fn get_available_modules(&self) -> anyhow::Result<Vec<String>> {
        let attachment = self.global_attachment.clone();
        self.with_js(async move |ctx| {
            if let Some(attachment) = &attachment {
                attachment
                    .attach(&ctx)
                    .map_err(|e| anyhow::anyhow!("Failed to attach global context: {e}"))?;
            }
            Ok(get_available_module_names(&ctx))
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
            ));
        }
    };

    let module_value = match promise.into_future::<rquickjs::Value>().await.catch(ctx) {
        Ok(v) => v,
        Err(e) => {
            return JsResult::Err(JsError::module(
                Some(module),
                None,
                format!("Failed to import: {}", e),
            ));
        }
    };

    let obj = match module_value.as_object() {
        Some(o) => o,
        None => {
            return JsResult::Err(JsError::module(
                Some(module),
                None,
                "Module is not an object",
            ));
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
                ));
            }
        },
        Ok(_) => {
            return JsResult::Err(JsError::module(
                Some(module),
                Some(method),
                "Method is not a function",
            ));
        }
        Err(e) => {
            return JsResult::Err(JsError::module(
                Some(module),
                Some(method),
                format!("Failed to get method: {}", e),
            ));
        }
    };

    let res = func.call::<_, MaybePromise>((rquickjs::function::Rest(params),));
    result_from_maybe_promise(ctx, res).await
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
        Ok(promise) => match promise.into_future::<rquickjs::Value>().await.catch(ctx) {
            Ok(value) => result_from_value(ctx, value).await,
            Err(e) => JsResult::Err(JsError::runtime(e.to_string())),
        },
        Err(e) => JsResult::Err(JsError::runtime(e.to_string())),
    }
}

pub(crate) async fn result_from_maybe_promise<'js>(
    ctx: &rquickjs::Ctx<'js>,
    res: rquickjs::Result<MaybePromise<'js>>,
) -> JsResult {
    match res.catch(ctx) {
        Ok(value) => match value.into_future::<rquickjs::Value>().await.catch(ctx) {
            Ok(value) => result_from_value(ctx, value).await,
            Err(e) => JsResult::Err(JsError::runtime(e.to_string())),
        },
        Err(e) => JsResult::Err(JsError::runtime(e.to_string())),
    }
}

fn unwrap_async_eval_value<'js>(value: &mut rquickjs::Value<'js>) -> rquickjs::Result<()> {
    let Some(obj) = value.as_object() else {
        return Ok(());
    };

    let mut keys = obj.keys::<String>();
    let first_key = keys.next().transpose()?;
    let second_key = keys.next().transpose()?;

    if matches!(first_key.as_deref(), Some("value")) && second_key.is_none() {
        *value = obj.get("value")?;
    }

    Ok(())
}

async fn result_from_value<'js>(
    ctx: &rquickjs::Ctx<'js>,
    mut value: rquickjs::Value<'js>,
) -> JsResult {
    if let Err(e) = unwrap_async_eval_value(&mut value) {
        return JsResult::Err(JsError::runtime(e.to_string()));
    }

    while let Some(promise) = value.as_promise().cloned() {
        value = match promise.into_future::<rquickjs::Value>().await.catch(ctx) {
            Ok(v) => v,
            Err(e) => return JsResult::Err(JsError::runtime(e.to_string())),
        };
        if let Err(e) = unwrap_async_eval_value(&mut value) {
            return JsResult::Err(JsError::runtime(e.to_string()));
        }
    }

    while ctx.execute_pending_job() {}

    match JsValue::from_js(ctx, value).catch(ctx) {
        Ok(v) => JsResult::Ok(v),
        Err(e) => JsResult::Err(JsError::runtime(e.to_string())),
    }
}

#[cfg(test)]
mod tests {
    use super::unwrap_async_eval_value;
    use crate::api::value::JsValue;
    use rquickjs::{Context, FromJs, Runtime};

    #[test]
    fn test_unwrap_async_eval_value_wrapper_object() {
        let runtime = Runtime::new().unwrap();
        let context = Context::full(&runtime).unwrap();

        context.with(|ctx| {
            let mut value: rquickjs::Value = ctx.eval("({ value: 42 })").unwrap();
            unwrap_async_eval_value(&mut value).unwrap();
            let js_value = JsValue::from_js(&ctx, value).unwrap();
            assert!(matches!(js_value, JsValue::Integer(42)));
        });
    }

    #[test]
    fn test_unwrap_async_eval_value_preserves_multi_key_object() {
        let runtime = Runtime::new().unwrap();
        let context = Context::full(&runtime).unwrap();

        context.with(|ctx| {
            let mut value: rquickjs::Value = ctx.eval("({ value: 42, extra: true })").unwrap();
            unwrap_async_eval_value(&mut value).unwrap();
            let js_value = JsValue::from_js(&ctx, value).unwrap();

            assert!(matches!(
                js_value,
                JsValue::Object(ref obj)
                    if matches!(obj.get("value"), Some(JsValue::Integer(42)))
                        && matches!(obj.get("extra"), Some(JsValue::Boolean(true)))
            ));
        });
    }
}
