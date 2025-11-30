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
use rquickjs::{async_with, CatchResultExt, FromJs, Module, Promise};
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

/// Memory usage statistics for the JavaScript runtime.
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
    #[frb(sync, getter)]
    pub fn total_memory(&self) -> i64 {
        self.0.memory_used_size
    }

    /// Returns total allocation count.
    #[frb(sync, getter)]
    pub fn total_allocations(&self) -> i64 {
        self.0.malloc_count
    }

    /// Returns a human-readable summary of memory usage.
    #[frb(sync)]
    pub fn summary(&self) -> String {
        format!(
            "Memory: {} bytes, Objects: {}, Functions: {}, Strings: {}",
            self.0.memory_used_size, self.0.obj_count, self.0.js_func_count, self.0.str_count
        )
    }
}

/// A synchronous JavaScript runtime.
#[frb(opaque)]
#[derive(Clone)]
pub struct JsRuntime {
    pub(crate) rt: rquickjs::Runtime,
    pub(crate) global_attachment: Option<GlobalAttachment>,
}

impl JsRuntime {
    /// Creates a new JavaScript runtime with default configuration.
    #[frb(sync)]
    pub fn new() -> anyhow::Result<Self> {
        let runtime = rquickjs::Runtime::new()?;
        Ok(Self {
            rt: runtime,
            global_attachment: None,
        })
    }

    /// Creates a new JavaScript runtime with custom builtin modules.
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
    #[frb(sync)]
    pub fn set_memory_limit(&self, limit: usize) {
        self.rt.set_memory_limit(limit);
    }

    /// Sets the maximum stack size.
    #[frb(sync)]
    pub fn set_max_stack_size(&self, limit: usize) {
        self.rt.set_max_stack_size(limit);
    }

    /// Sets the garbage collection threshold.
    #[frb(sync)]
    pub fn set_gc_threshold(&self, threshold: usize) {
        self.rt.set_gc_threshold(threshold);
    }

    /// Forces garbage collection.
    #[frb(sync)]
    pub fn run_gc(&self) {
        self.rt.run_gc();
    }

    /// Returns memory usage statistics.
    #[frb(sync)]
    pub fn memory_usage(&self) -> MemoryUsage {
        MemoryUsage(self.rt.memory_usage())
    }

    /// Checks if there are pending jobs.
    #[frb(sync)]
    pub fn is_job_pending(&self) -> bool {
        self.rt.is_job_pending()
    }

    /// Executes a pending job.
    #[frb(sync)]
    pub fn execute_pending_job(&self) -> anyhow::Result<bool> {
        self.rt
            .execute_pending_job()
            .map_err(|e| anyhow::anyhow!(e))
    }

    /// Sets dump flags for debugging.
    #[frb(sync)]
    pub fn set_dump_flags(&self, flags: u64) {
        self.rt.set_dump_flags(flags);
    }

    /// Sets runtime info string.
    #[frb(sync)]
    pub fn set_info(&self, info: String) -> anyhow::Result<()> {
        self.rt.set_info(info)?;
        Ok(())
    }
}

/// A synchronous JavaScript execution context.
#[frb(opaque)]
#[derive(Clone)]
pub struct JsContext {
    pub(crate) ctx: rquickjs::Context,
    pub(crate) global_attachment: Option<GlobalAttachment>,
}

impl JsContext {
    /// Creates a new context from a runtime.
    #[frb(sync)]
    pub fn new(rt: &JsRuntime) -> anyhow::Result<Self> {
        let context = rquickjs::Context::full(&rt.rt)?;
        Ok(Self {
            ctx: context,
            global_attachment: rt.global_attachment.clone(),
        })
    }

    /// Evaluates JavaScript code.
    #[frb(sync)]
    pub fn eval(&self, code: String) -> JsResult {
        self.eval_with_options(code, JsEvalOptions::defaults())
    }

    /// Evaluates JavaScript code with options.
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
    #[frb(sync)]
    pub fn eval_file(&self, path: String) -> JsResult {
        self.eval_file_with_options(path, JsEvalOptions::defaults())
    }

    /// Evaluates JavaScript code from a file with options.
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
#[frb(opaque)]
#[derive(Clone)]
pub struct JsAsyncRuntime {
    pub(crate) rt: rquickjs::AsyncRuntime,
    pub(crate) global_attachment: Option<GlobalAttachment>,
}

impl JsAsyncRuntime {
    /// Creates a new async runtime with default configuration.
    #[frb(sync)]
    pub fn new() -> anyhow::Result<Self> {
        let runtime = rquickjs::AsyncRuntime::new()?;
        Ok(Self {
            rt: runtime,
            global_attachment: None,
        })
    }

    /// Creates a new async runtime with custom configuration.
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
    pub async fn set_memory_limit(&self, limit: usize) {
        self.rt.set_memory_limit(limit).await;
    }

    /// Sets the maximum stack size.
    pub async fn set_max_stack_size(&self, limit: usize) {
        self.rt.set_max_stack_size(limit).await;
    }

    /// Sets the garbage collection threshold.
    pub async fn set_gc_threshold(&self, threshold: usize) {
        self.rt.set_gc_threshold(threshold).await;
    }

    /// Forces garbage collection.
    pub async fn run_gc(&self) {
        self.rt.run_gc().await;
    }

    /// Returns memory usage statistics.
    pub async fn memory_usage(&self) -> MemoryUsage {
        MemoryUsage(self.rt.memory_usage().await)
    }

    /// Checks if there are pending jobs.
    pub async fn is_job_pending(&self) -> bool {
        self.rt.is_job_pending().await
    }

    /// Executes a pending job.
    pub async fn execute_pending_job(&self) -> anyhow::Result<bool> {
        self.rt
            .execute_pending_job()
            .await
            .map_err(|e| anyhow::anyhow!(e))
    }

    /// Puts the runtime into idle state.
    pub async fn idle(&self) {
        self.rt.idle().await;
    }

    /// Sets runtime info string.
    pub async fn set_info(&self, info: String) -> anyhow::Result<()> {
        self.rt.set_info(info).await?;
        Ok(())
    }
}

/// An asynchronous JavaScript execution context.
#[frb(opaque)]
#[derive(Clone)]
pub struct JsAsyncContext {
    pub(crate) ctx: rquickjs::AsyncContext,
    pub(crate) global_attachment: Option<GlobalAttachment>,
}

impl JsAsyncContext {
    /// Creates a new async context from a runtime.
    pub async fn from(rt: &JsAsyncRuntime) -> anyhow::Result<Self> {
        let context = rquickjs::AsyncContext::full(&rt.rt).await?;
        let dynamic_modules = Arc::new(RwLock::new(HashMap::<String, Vec<u8>>::new()));

        async_with!(context => |ctx| {
            ctx.store_userdata(dynamic_modules.clone())
                .map_err(|e| anyhow::anyhow!("Failed to store dynamic modules: {:?}", e))
        })
        .await?;

        Ok(Self {
            ctx: context,
            global_attachment: rt.global_attachment.clone(),
        })
    }

    /// Evaluates JavaScript code.
    pub async fn eval(&self, code: String) -> JsResult {
        self.eval_with_options(code, JsEvalOptions::with_promise()).await
    }

    /// Evaluates JavaScript code with options.
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
            result_from_promise(&ctx, res).await
        })
        .await
    }

    /// Evaluates JavaScript code from a file.
    pub async fn eval_file(&self, path: String) -> JsResult {
        self.eval_file_with_options(path, JsEvalOptions::with_promise()).await
    }

    /// Evaluates JavaScript code from a file with options.
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
            result_from_promise(&ctx, res).await
        })
        .await
    }

    /// Evaluates a function from a module.
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
                    return JsResult::Err(JsError::context(format!(
                        "Failed to attach global context: {}",
                        e
                    )));
                }
            }

            match Module::import(&ctx, module.clone()).catch(&ctx) {
                Ok(promise) => {
                    match promise.into_future::<rquickjs::Value>().await.catch(&ctx) {
                        Ok(v) => {
                            if !v.is_object() {
                                return JsResult::Err(JsError::module(
                                    Some(module),
                                    None,
                                    "Module is not an object",
                                ));
                            }
                            let obj = match v.as_object() {
                                Some(o) => o,
                                None => {
                                    return JsResult::Err(JsError::module(
                                        Some(module),
                                        None,
                                        "Module is not an object",
                                    ))
                                }
                            };
                            let m: rquickjs::Result<rquickjs::Value> = obj.get(&method);
                            match m.catch(&ctx) {
                                Ok(m) => {
                                    if m.is_function() {
                                        let func = match m.as_function() {
                                            Some(f) => f,
                                            None => {
                                                return JsResult::Err(JsError::module(
                                                    Some(module),
                                                    Some(method),
                                                    "Method not found",
                                                ))
                                            }
                                        };
                                        let res =
                                            func.call((rquickjs::function::Rest(params),));
                                        result_from_promise(&ctx, res).await
                                    } else {
                                        JsResult::Err(JsError::module(
                                            Some(module),
                                            Some(method),
                                            "Method not found",
                                        ))
                                    }
                                }
                                Err(e) => JsResult::Err(JsError::module(
                                    Some(module),
                                    Some(method),
                                    format!("Failed to get method: {}", e),
                                )),
                            }
                        }
                        Err(e) => JsResult::Err(JsError::module(
                            Some(module),
                            None,
                            format!("Failed to import module: {}", e),
                        )),
                    }
                }
                Err(e) => JsResult::Err(JsError::module(
                    Some(module),
                    None,
                    format!("Failed to import module: {}", e),
                )),
            }
        })
        .await
    }
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
            Ok(v) => match JsValue::from_js(ctx, v).catch(ctx) {
                Ok(v) => JsResult::Ok(v),
                Err(e) => JsResult::Err(JsError::runtime(e.to_string())),
            },
            Err(e) => JsResult::Err(JsError::runtime(e.to_string())),
        },
        Err(e) => JsResult::Err(JsError::runtime(e.to_string())),
    }
}
