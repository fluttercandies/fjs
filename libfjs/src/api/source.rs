//! # JavaScript Source Code Types
//!
//! This module provides types for representing JavaScript source code,
//! modules, and evaluation options.

use flutter_rust_bridge::frb;

/// Maximum file size for JavaScript source files (10 MB)
pub const MAX_FILE_SIZE: u64 = 10 * 1024 * 1024;

/// Represents the source of JavaScript code.
///
/// This enum provides three ways to specify JavaScript source:
/// inline code as a string, a file path to load code from, or raw bytes.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Hash, Eq, PartialEq, Ord, PartialOrd)]
pub enum JsCode {
    /// Inline JavaScript code as a string
    Code(String),
    /// File path containing JavaScript code
    Path(String),
    /// Raw bytes containing JavaScript code (UTF-8 encoded)
    Bytes(Vec<u8>),
}

impl JsCode {
    /// Creates inline code source.
    #[frb(ignore)]
    pub fn code(code: String) -> Self {
        JsCode::Code(code)
    }

    /// Creates file path source.
    #[frb(ignore)]
    pub fn path(path: String) -> Self {
        JsCode::Path(path)
    }

    /// Creates bytes source.
    #[frb(ignore)]
    pub fn bytes(bytes: Vec<u8>) -> Self {
        JsCode::Bytes(bytes)
    }

    /// Returns the file path if this is a Path variant.
    #[frb(ignore)]
    pub fn as_path(&self) -> Option<&str> {
        match self {
            JsCode::Path(p) => Some(p),
            _ => None,
        }
    }

    /// Returns true if this is a Path variant.
    #[frb(sync)]
    pub fn is_path(&self) -> bool {
        matches!(self, JsCode::Path(_))
    }

    /// Returns true if this is a Code variant.
    #[frb(sync)]
    pub fn is_code(&self) -> bool {
        matches!(self, JsCode::Code(_))
    }

    /// Returns true if this is a Bytes variant.
    #[frb(sync)]
    pub fn is_bytes(&self) -> bool {
        matches!(self, JsCode::Bytes(_))
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

impl JsModule {
    /// Creates a new module with the given name and source.
    #[frb(sync)]
    pub fn new(name: String, source: JsCode) -> Self {
        JsModule { name, source }
    }

    /// Creates a module from inline code.
    #[frb(ignore)]
    pub fn code(module: String, code: String) -> Self {
        JsModule {
            name: module,
            source: JsCode::Code(code),
        }
    }

    /// Creates a module from a file path.
    #[frb(ignore)]
    pub fn path(module: String, path: String) -> Self {
        JsModule {
            name: module,
            source: JsCode::Path(path),
        }
    }

    /// Creates a module from raw bytes.
    #[frb(ignore)]
    pub fn bytes(module: String, bytes: Vec<u8>) -> Self {
        JsModule {
            name: module,
            source: JsCode::Bytes(bytes),
        }
    }

    /// Creates a module from inline code string.
    #[frb(sync, name = "fromCode")]
    pub fn from_code(module: String, code: String) -> Self {
        JsModule {
            name: module,
            source: JsCode::Code(code),
        }
    }

    /// Creates a module from a file path string.
    #[frb(sync, name = "fromPath")]
    pub fn from_path(module: String, path: String) -> Self {
        JsModule {
            name: module,
            source: JsCode::Path(path),
        }
    }

    /// Creates a module from raw bytes.
    #[frb(sync, name = "fromBytes")]
    pub fn from_bytes(module: String, bytes: Vec<u8>) -> Self {
        JsModule {
            name: module,
            source: JsCode::Bytes(bytes),
        }
    }
}

/// Options for JavaScript code evaluation.
///
/// This struct provides configuration options for how JavaScript
/// code should be executed and evaluated.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Default)]
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

    /// Creates options with default values (global scope, strict mode).
    #[frb(sync)]
    pub fn defaults() -> Self {
        JsEvalOptions {
            global: Some(true),
            strict: Some(true),
            backtrace_barrier: Some(false),
            promise: Some(false),
        }
    }

    /// Creates options with promise support enabled.
    #[frb(sync)]
    pub fn with_promise() -> Self {
        JsEvalOptions {
            global: Some(true),
            strict: Some(true),
            backtrace_barrier: Some(false),
            promise: Some(true),
        }
    }

    /// Creates options for module evaluation.
    #[frb(sync)]
    pub fn module() -> Self {
        JsEvalOptions {
            global: Some(false), // Module scope
            strict: Some(true),
            backtrace_barrier: Some(false),
            promise: Some(true),
        }
    }
}

impl From<JsEvalOptions> for rquickjs::context::EvalOptions {
    fn from(v: JsEvalOptions) -> Self {
        let mut opts = rquickjs::context::EvalOptions::default();
        opts.global = v.global.unwrap_or(true);
        opts.strict = v.strict.unwrap_or(true);
        opts.backtrace_barrier = v.backtrace_barrier.unwrap_or(false);
        opts.promise = v.promise.unwrap_or(false);
        opts
    }
}

/// Options for configuring builtin Node.js modules.
///
/// This struct provides fine-grained control over which Node.js
/// compatibility modules should be available in the runtime.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Default)]
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

    /// Creates builtin options with no modules enabled.
    #[frb(sync)]
    pub fn none() -> Self {
        JsBuiltinOptions::default()
    }

    /// Creates builtin options with essential modules only.
    /// Includes: console, timers, buffer, util, json
    #[frb(sync)]
    pub fn essential() -> Self {
        JsBuiltinOptions {
            console: Some(true),
            timers: Some(true),
            buffer: Some(true),
            util: Some(true),
            json: Some(true),
            ..Default::default()
        }
    }

    /// Creates builtin options for web-like environment.
    /// Includes: console, timers, fetch, url, crypto, stream_web
    #[frb(sync)]
    pub fn web() -> Self {
        JsBuiltinOptions {
            console: Some(true),
            timers: Some(true),
            fetch: Some(true),
            url: Some(true),
            crypto: Some(true),
            stream_web: Some(true),
            navigator: Some(true),
            exceptions: Some(true),
            json: Some(true),
            ..Default::default()
        }
    }

    /// Creates builtin options for Node.js-like environment.
    /// Includes most modules except OS-specific ones.
    #[frb(sync)]
    pub fn node() -> Self {
        JsBuiltinOptions {
            abort: Some(true),
            assert: Some(true),
            async_hooks: Some(true),
            buffer: Some(true),
            console: Some(true),
            crypto: Some(true),
            dns: Some(true),
            events: Some(true),
            exceptions: Some(true),
            fs: Some(true),
            path: Some(true),
            perf_hooks: Some(true),
            process: Some(true),
            stream_web: Some(true),
            string_decoder: Some(true),
            timers: Some(true),
            url: Some(true),
            util: Some(true),
            json: Some(true),
            ..Default::default()
        }
    }
}

/// Retrieves the raw source code from a JsCode source.
#[frb(ignore)]
pub async fn get_raw_source_code(source: JsCode) -> anyhow::Result<Vec<u8>> {
    let code = match source {
        JsCode::Code(code) => code.into_bytes(),
        JsCode::Path(path) => {
            // Check file size before reading
            let metadata = tokio::fs::metadata(&path).await?;
            let file_size = metadata.len();

            if file_size > MAX_FILE_SIZE {
                return Err(anyhow::anyhow!(
                    "File size exceeds maximum allowed size: {} (size: {} bytes, max: {} bytes)",
                    path,
                    file_size,
                    MAX_FILE_SIZE
                ));
            }

            // Use tokio::fs::read directly for better efficiency
            tokio::fs::read(&path).await?
        }
        JsCode::Bytes(bytes) => bytes,
    };
    Ok(code)
}

/// Synchronously retrieves the raw source code from a JsCode source.
#[frb(ignore)]
pub fn get_raw_source_code_sync(source: JsCode) -> anyhow::Result<Vec<u8>> {
    let code = match source {
        JsCode::Code(code) => code.into_bytes(),
        JsCode::Path(path) => {
            // Check file size before reading
            let metadata = std::fs::metadata(&path)?;
            let file_size = metadata.len();

            if file_size > MAX_FILE_SIZE {
                return Err(anyhow::anyhow!(
                    "File size exceeds maximum allowed size: {} (size: {} bytes, max: {} bytes)",
                    path,
                    file_size,
                    MAX_FILE_SIZE
                ));
            }

            std::fs::read(&path)?
        }
        JsCode::Bytes(bytes) => bytes,
    };
    Ok(code)
}
