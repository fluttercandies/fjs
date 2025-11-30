//! # JavaScript Module System
//!
//! This module provides comprehensive support for JavaScript module loading,
//! resolution, and management within the FJS runtime. It implements both
//! static module registration and dynamic module loading capabilities.
//!
//! ## Features
//!
//! - **Dynamic Module Loading**: Load modules at runtime from files or inline code
//! - **Module Resolution**: Resolve module imports with custom resolvers
//! - **Global Attachments**: Initialize global objects and functions
//! - **Module Builders**: Fluent API for configuring runtime modules
//! - **Node.js Compatibility**: Support for standard Node.js modules
//!
//! ## Architecture
//!
//! The module system consists of several key components:
//!
//! - **Resolvers**: Handle module name resolution
//! - **Loaders**: Handle module content loading
//! - **Storage**: Manage dynamic module state
//! - **Builders**: Configure runtime module systems

use crate::api::source::JsBuiltinOptions;
use flutter_rust_bridge::frb;
use llrt_utils::module::ModuleInfo;
use rquickjs::loader::{Loader, ModuleLoader, Resolver};
use rquickjs::module::ModuleDef;
use rquickjs::{Ctx, JsLifetime, Module};
use std::collections::{HashMap, HashSet};
use std::marker::PhantomData;
use std::sync::{Arc, RwLock};

/// A resolver for dynamically loaded JavaScript modules.
///
/// This resolver handles the resolution of module names that have been
/// dynamically loaded at runtime. It works with the dynamic module storage
/// to provide access to modules that weren't available at compile time.
#[derive(Debug, Default)]
#[frb(ignore)]
pub struct DynamicModuleResolver {}

impl Resolver for DynamicModuleResolver {
    /// Resolves a dynamic module name.
    ///
    /// This method checks if the module exists in the dynamic module storage.
    /// If found, returns the module name; otherwise returns a resolving error.
    ///
    /// # Parameters
    ///
    /// - `ctx`: The JavaScript context
    /// - `base`: The base path for resolution
    /// - `name`: The module name to resolve
    ///
    /// # Returns
    ///
    /// Returns the resolved module name if found in storage.
    fn resolve<'js>(
        &mut self,
        ctx: &Ctx<'js>,
        base: &str,
        name: &str,
    ) -> rquickjs::Result<String> {
        if let Some(modules_storage) = ctx.userdata::<Arc<RwLock<HashMap<String, Vec<u8>>>>>() {
            let modules = modules_storage.read().unwrap();
            if modules.contains_key(name) {
                return Ok(name.to_string());
            }
        }
        // Not found in dynamic storage, let other resolvers try
        Err(rquickjs::Error::new_resolving(base, name))
    }
}

/// A loader for dynamically loaded JavaScript modules.
///
/// This loader handles the actual loading of module content from the
/// dynamic module storage. It retrieves source code that has been
/// previously stored during runtime.
#[derive(Debug, Default)]
#[frb(ignore)]
pub struct DynamicModuleLoader {}

impl Loader for DynamicModuleLoader {
    /// Loads a dynamic module from storage.
    ///
    /// This method retrieves the source code for a module from the
    /// dynamic module storage and creates a declared module instance.
    ///
    /// # Parameters
    ///
    /// - `ctx`: The JavaScript context
    /// - `name`: The module name to load
    ///
    /// # Returns
    ///
    /// Returns a declared module or an error if the module is not found.
    fn load<'js>(
        &mut self,
        ctx: &Ctx<'js>,
        name: &str,
    ) -> rquickjs::Result<Module<'js, rquickjs::module::Declared>> {
        if let Some(modules_storage) = ctx.userdata::<Arc<RwLock<HashMap<String, Vec<u8>>>>>() {
            let modules = modules_storage.read().unwrap();
            if let Some(source) = modules.get(name) {
                return Module::declare(ctx.clone(), name, source.clone());
            }
        }
        Err(rquickjs::Error::new_loading(name))
    }
}

/// Stores a set of module names for a specific JavaScript context.
///
/// This struct maintains a list of available module names within a
/// specific context lifecycle. It uses a phantom marker to ensure
/// lifetime safety.
#[frb(ignore)]
pub struct ModuleNames<'js> {
    /// The set of module names
    list: HashSet<String>,
    /// Phantom data for lifetime tracking
    _marker: PhantomData<&'js ()>,
}

unsafe impl<'js> JsLifetime<'js> for ModuleNames<'js> {
    /// Allows the module names to be tracked across different lifetimes.
    ///
    /// This implementation enables safe usage of module names across
    /// different JavaScript context lifetimes while maintaining type safety.
    type Changed<'to> = ModuleNames<'to>;
}

impl ModuleNames<'_> {
    /// Creates a new module names storage with the given set of names.
    ///
    /// # Parameters
    ///
    /// - `names`: The initial set of module names
    ///
    /// # Returns
    ///
    /// Returns a new `ModuleNames` instance.
    pub fn new(names: HashSet<String>) -> Self {
        Self {
            list: names,
            _marker: PhantomData,
        }
    }

    /// Returns a copy of the module names list.
    ///
    /// # Returns
    ///
    /// Returns a cloned `HashSet` containing all module names.
    #[allow(dead_code)]
    pub fn get_list(&self) -> HashSet<String> {
        self.list.clone()
    }
}

/// Manages global object attachments for JavaScript contexts.
///
/// This struct handles the attachment of global objects, functions,
/// and module names to JavaScript contexts. Each context will be
/// initialized independently when attach() is called.
#[frb(ignore)]
#[derive(Debug, Default, Clone)]
pub struct GlobalAttachment {
    /// Inner implementation with initialization data
    inner: Arc<GlobalAttachmentInner>,
}

/// Marker type to track if a context has been initialized with global attachments.
#[frb(ignore)]
struct GlobalAttachmentInitialized;

unsafe impl<'js> JsLifetime<'js> for GlobalAttachmentInitialized {
    type Changed<'to> = GlobalAttachmentInitialized;
}

/// Inner implementation of global attachment management.
///
/// This struct contains the actual data for global attachments,
/// including module names and initialization functions.
#[frb(ignore)]
#[derive(Debug, Default)]
struct GlobalAttachmentInner {
    /// Set of module names to attach
    names: HashSet<String>,
    /// List of initialization functions to call
    functions: Vec<fn(&Ctx<'_>) -> rquickjs::Result<()>>,
}

impl GlobalAttachment {
    /// Adds a global initialization function to the attachment.
    ///
    /// This function will be called when the attachment is applied to a context.
    /// It can be used to set up global objects, functions, or other runtime state.
    ///
    /// # Parameters
    ///
    /// - `init`: A function that takes a context and performs initialization
    ///
    /// # Returns
    ///
    /// Returns self for method chaining.
    ///
    /// # Panics
    ///
    /// This method will panic if called after the attachment has been shared.
    pub fn add_function(mut self, init: fn(&Ctx<'_>) -> rquickjs::Result<()>) -> Self {
        // Get mutable access to inner before it's shared
        let inner = Arc::get_mut(&mut self.inner)
            .expect("GlobalAttachment should not be shared during construction");
        inner.functions.push(init);
        self
    }

    /// Adds a module name to the attachment.
    ///
    /// This name will be registered as an available module when the attachment
    /// is applied to a context.
    ///
    /// # Parameters
    ///
    /// - `path`: The module name to add
    ///
    /// # Returns
    ///
    /// Returns self for method chaining.
    ///
    /// # Panics
    ///
    /// This method will panic if called after the attachment has been shared.
    pub fn add_name<P: Into<String>>(mut self, path: P) -> Self {
        let inner = Arc::get_mut(&mut self.inner)
            .expect("GlobalAttachment should not be shared during construction");
        inner.names.insert(path.into());
        self
    }

    /// Attaches the global state to a JavaScript context.
    ///
    /// This method applies all registered module names and initialization functions
    /// to the given context. It uses context-level userdata to ensure that each
    /// context is only initialized once.
    ///
    /// # Parameters
    ///
    /// - `ctx`: The JavaScript context to attach to
    ///
    /// # Returns
    ///
    /// Returns Ok if attachment succeeds, or an error if initialization fails.
    pub fn attach(&self, ctx: &Ctx<'_>) -> rquickjs::Result<()> {
        // Check if this context has already been initialized
        if ctx.userdata::<GlobalAttachmentInitialized>().is_some() {
            return Ok(());
        }

        // Mark this context as initialized
        let _ = ctx.store_userdata(GlobalAttachmentInitialized);

        if !self.inner.names.is_empty() {
            let _ = ctx.store_userdata(ModuleNames::new(self.inner.names.clone()));
        }
        for init in &self.inner.functions {
            init(ctx)?;
        }
        Ok(())
    }
}

/// A resolver for static module names.
///
/// This resolver handles the resolution of statically known module names
    /// that are registered at runtime configuration time.
#[frb(ignore)]
#[derive(Debug, Default)]
pub struct ModuleResolver {
    /// Set of registered module names
    modules: HashSet<String>,
}

impl ModuleResolver {
    /// Adds a module name to the resolver.
    ///
    /// # Parameters
    ///
    /// - `path`: The module name to add
    ///
    /// # Returns
    ///
    /// Returns self for method chaining.
    #[must_use]
    pub fn add_name<P: Into<String>>(mut self, path: P) -> Self {
        self.modules.insert(path.into());
        self
    }
}

impl Resolver for ModuleResolver {
    /// Resolves a module name if it's in the registered set.
    ///
    /// This method handles Node.js-style module names by stripping the "node:"
    /// prefix and checking if the resulting name is in the registered module set.
    ///
    /// # Parameters
    ///
    /// - `_`: The context (not used)
    /// - `base`: The base path for resolution
    /// - `name`: The module name to resolve
    ///
    /// # Returns
    ///
    /// Returns the resolved module name or an error if not found.
    fn resolve(&mut self, _: &Ctx<'_>, base: &str, name: &str) -> rquickjs::Result<String> {
        let name = name.trim_start_matches("node:");
        if self.modules.contains(name) {
            Ok(name.into())
        } else {
            Err(rquickjs::Error::new_resolving(base, name))
        }
    }
}

/// A builder for configuring JavaScript runtime module systems.
///
/// This struct provides a fluent API for configuring module resolvers,
/// loaders, and global attachments for JavaScript runtimes. It supports
/// both static module registration and dynamic module capabilities.
#[frb(ignore)]
pub struct ModuleBuilder {
    /// The module resolver to use
    module_resolver: ModuleResolver,
    /// The module loader to use
    module_loader: ModuleLoader,
    /// The global attachment configuration
    global_attachment: GlobalAttachment,
}

impl ModuleBuilder {
    /// Creates a new module builder with default configuration.
    ///
    /// # Returns
    ///
    /// Returns a new `ModuleBuilder` with empty resolver, loader, and attachment.
    pub fn new() -> Self {
        Self {
            module_resolver: ModuleResolver::default(),
            module_loader: ModuleLoader::default(),
            global_attachment: GlobalAttachment::default(),
        }
    }

    /// Adds a module to the builder configuration.
    ///
    /// This method registers a module with the resolver, loader, and global attachment.
    /// The module will be available for import and loading in the JavaScript runtime.
    ///
    /// # Parameters
    ///
    /// - `module`: The module definition and information
    ///
    /// # Returns
    ///
    /// Returns self for method chaining.
    pub fn with_module<M: ModuleDef, I: Into<ModuleInfo<M>>>(mut self, module: I) -> Self {
        let module_info: ModuleInfo<M> = module.into();

        self.module_resolver = self.module_resolver.add_name(module_info.name);
        self.module_loader = self
            .module_loader
            .with_module(module_info.name, module_info.module);
        self.global_attachment = self.global_attachment.add_name(module_info.name);
        self
    }

    /// Adds a global initialization function to the builder.
    ///
    /// This function will be called when the module system is initialized
    /// and can be used to set up global objects, functions, or other state.
    ///
    /// # Parameters
    ///
    /// - `init`: The initialization function
    ///
    /// # Returns
    ///
    /// Returns self for method chaining.
    pub fn with_global(mut self, init: fn(&Ctx<'_>) -> rquickjs::Result<()>) -> Self {
        self.global_attachment = self.global_attachment.add_function(init);
        self
    }

    /// Builds the module system configuration.
    ///
    /// This method finalizes the configuration and returns the components
    /// needed to set up a JavaScript runtime with the configured modules.
    ///
    /// # Returns
    ///
    /// Returns a tuple containing the resolver, loader, and global attachment.
    pub fn build(self) -> (ModuleResolver, ModuleLoader, GlobalAttachment) {
        (
            self.module_resolver,
            self.module_loader,
            self.global_attachment,
        )
    }
}

impl JsBuiltinOptions {
    /// Converts builtin options to a module builder.
    #[frb(ignore)]
    pub fn to_module_builder(&self) -> ModuleBuilder {
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
        #[cfg(not(target_os = "ios"))]
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
