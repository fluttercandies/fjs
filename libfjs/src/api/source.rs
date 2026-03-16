//! # JavaScript Source Code Types
//!
//! This module provides types for representing JavaScript source code,
//! modules, and evaluation options.

use flutter_rust_bridge::frb;
use rquickjs::{WriteOptions, WriteOptionsEndianness};

/// Maximum file size for JavaScript source files (10 MB).
///
/// This limit prevents loading excessively large files that could
/// cause memory issues or performance problems.
pub const MAX_FILE_SIZE: u64 = 10 * 1024 * 1024;

/// Represents the source of JavaScript code.
///
/// This enum provides three ways to specify JavaScript source:
/// inline code as a string, a file path to load code from, or raw UTF-8 bytes.
///
/// `JsCode::Bytes` is still source text. QuickJS bytecode uses `JsModuleBytecode`.
///
/// ## Example
///
/// ```dart
/// // Inline code
/// final code1 = JsCode.code('console.log("Hello");');
///
/// // From file
/// final code2 = JsCode.path('/path/to/script.js');
///
/// // From bytes
/// final code3 = JsCode.bytes(utf8.encode('print("Hi");'));
/// ```
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Hash, Eq, PartialEq, Ord, PartialOrd)]
pub enum JsCode {
    /// Inline JavaScript code as a string
    Code(String),
    /// File path containing JavaScript code
    Path(String),
    /// Raw UTF-8 bytes containing JavaScript source code
    Bytes(Vec<u8>),
}

impl JsCode {
    /// Creates inline code source.
    ///
    /// ## Parameters
    ///
    /// - `code`: The JavaScript code as a string
    ///
    /// ## Returns
    ///
    /// A `JsCode::Code` instance
    #[frb(ignore)]
    pub fn code(code: String) -> Self {
        JsCode::Code(code)
    }

    /// Creates file path source.
    ///
    /// ## Parameters
    ///
    /// - `path`: The path to the JavaScript file
    ///
    /// ## Returns
    ///
    /// A `JsCode::Path` instance
    #[frb(ignore)]
    pub fn path(path: String) -> Self {
        JsCode::Path(path)
    }

    /// Creates bytes source from UTF-8 JavaScript source text.
    ///
    /// ## Parameters
    ///
    /// - `bytes`: The JavaScript code as UTF-8 encoded bytes
    ///
    /// ## Returns
    ///
    /// A `JsCode::Bytes` instance
    #[frb(ignore)]
    pub fn bytes(bytes: Vec<u8>) -> Self {
        JsCode::Bytes(bytes)
    }

    /// Returns the file path if this is a Path variant.
    ///
    /// ## Returns
    ///
    /// `Some(path)` if this is a Path variant, `None` otherwise
    #[frb(ignore)]
    pub fn as_path(&self) -> Option<&str> {
        match self {
            JsCode::Path(p) => Some(p),
            _ => None,
        }
    }

    /// Returns true if this is a Path variant.
    ///
    /// ## Returns
    ///
    /// `true` if this is a Path variant, `false` otherwise
    #[frb(sync)]
    pub fn is_path(&self) -> bool {
        matches!(self, JsCode::Path(_))
    }

    /// Returns true if this is a Code variant.
    ///
    /// ## Returns
    ///
    /// `true` if this is a Code variant, `false` otherwise
    #[frb(sync)]
    pub fn is_code(&self) -> bool {
        matches!(self, JsCode::Code(_))
    }

    /// Returns true if this is a Bytes variant.
    ///
    /// ## Returns
    ///
    /// `true` if this is a Bytes variant, `false` otherwise
    #[frb(sync)]
    pub fn is_bytes(&self) -> bool {
        matches!(self, JsCode::Bytes(_))
    }
}

/// Represents a JavaScript module.
///
/// This struct defines a module with a name and source code,
/// which can be loaded and executed in the JavaScript runtime.
///
/// `JsModule::bytes()` stores UTF-8 source bytes. Pre-compiled QuickJS bytecode
/// uses `JsModuleBytecode`.
///
/// ## Example
///
/// ```dart
/// // Create a module from inline code
/// final module = JsModule.code(
///   module: 'my-utils',
///   code: 'export const add = (a, b) => a + b;',
/// );
///
/// // Create a module from a file
/// final module2 = JsModule.path(
///   module: 'math',
///   path: '/path/to/math.js',
/// );
///
/// // Create a module from bytes
/// final module3 = JsModule.bytes(
///   module: 'binary-utils',
///   bytes: utf8.encode('export const VERSION = "1.0";'),
/// );
/// ```
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
    ///
    /// ## Parameters
    ///
    /// - `name`: The module name
    /// - `source`: The source code
    ///
    /// ## Returns
    ///
    /// A new `JsModule` instance
    ///
    /// ## Example
    ///
    /// ```dart
    /// final module = JsModule(
    ///   name: 'math',
    ///   source: JsCode.code('export const add = (a, b) => a + b;'),
    /// );
    /// ```
    #[frb(sync)]
    pub fn new(name: String, source: JsCode) -> Self {
        JsModule { name, source }
    }

    /// Creates a module from inline source text.
    ///
    /// This is the most convenient constructor when module code is already
    /// available in memory.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final module = JsModule.code(
    ///   module: 'feature/flags',
    ///   code: 'export const enabled = true;',
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
    /// Use this when the module source should be loaded lazily from disk.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final module = JsModule.path(
    ///   module: 'plugins/logger',
    ///   path: '/absolute/path/to/logger.js',
    /// );
    /// ```
    #[frb(sync)]
    pub fn path(module: String, path: String) -> Self {
        JsModule {
            name: module,
            source: JsCode::Path(path),
        }
    }

    /// Creates a module from raw UTF-8 source bytes.
    ///
    /// The bytes are still JavaScript source text, not QuickJS bytecode.
    /// Use `JsModuleBytecode` for precompiled modules.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final module = JsModule.bytes(
    ///   module: 'embedded/config',
    ///   bytes: utf8.encode('export const env = "prod";'),
    /// );
    /// ```
    #[frb(sync)]
    pub fn bytes(module: String, bytes: Vec<u8>) -> Self {
        JsModule {
            name: module,
            source: JsCode::Bytes(bytes),
        }
    }
}

/// Byte order to use when writing QuickJS module bytecode.
///
/// Use a fixed endianness when bytecode must be shared between devices.
/// `little` is the safest default for modern mobile and desktop targets.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Copy, Hash, Eq, PartialEq, Ord, PartialOrd, Default)]
pub enum JsBytecodeEndianness {
    /// Use the current device's native endianness.
    Native,
    /// Always emit little-endian bytecode.
    #[default]
    Little,
    /// Always emit big-endian bytecode.
    Big,
}

/// Options used when compiling an ES module into QuickJS bytecode.
///
/// QuickJS bytecode is version-specific and must only be loaded from trusted sources.
/// It is useful for distributing pre-compiled modules, but it is not a security boundary.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub struct JsModuleBytecodeOptions {
    /// Byte order used in the serialized bytecode.
    pub endianness: Option<JsBytecodeEndianness>,
    /// Strip embedded source text from the bytecode.
    pub strip_source: Option<bool>,
    /// Strip debug metadata from the bytecode.
    pub strip_debug: Option<bool>,
}

impl Default for JsModuleBytecodeOptions {
    fn default() -> Self {
        Self {
            endianness: Some(JsBytecodeEndianness::Little),
            strip_source: Some(true),
            strip_debug: Some(true),
        }
    }
}

impl JsModuleBytecodeOptions {
    /// Creates bytecode options suitable for distribution.
    ///
    /// Defaults:
    /// - little-endian output
    /// - `stripSource: true`
    /// - `stripDebug: true`
    ///
    /// ## Example
    ///
    /// ```dart
    /// final options = JsModuleBytecodeOptions.defaults();
    /// final bytecode = await JsBytecode.compile(
    ///   module: JsModule.code(
    ///     module: 'feature/main',
    ///     code: 'export default 42;',
    ///   ),
    ///   options: options,
    /// );
    /// ```
    #[frb(sync)]
    pub fn defaults() -> Self {
        Self::default()
    }
}

impl From<JsModuleBytecodeOptions> for WriteOptions {
    fn from(value: JsModuleBytecodeOptions) -> Self {
        let endianness = match value.endianness.unwrap_or_default() {
            JsBytecodeEndianness::Native => WriteOptionsEndianness::Native,
            JsBytecodeEndianness::Little => WriteOptionsEndianness::Little,
            JsBytecodeEndianness::Big => WriteOptionsEndianness::Big,
        };

        WriteOptions {
            endianness,
            strip_source: value.strip_source.unwrap_or(true),
            strip_debug: value.strip_debug.unwrap_or(true),
            ..Default::default()
        }
    }
}

/// Serialized QuickJS bytecode for a single ES module.
///
/// The `name` must match the module name embedded in the bytecode when it is declared
/// or evaluated. Bytecode must be treated as trusted input and recompiled whenever the
/// embedded QuickJS engine version changes.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Hash, Eq, PartialEq, Ord, PartialOrd)]
pub struct JsModuleBytecode {
    /// Module specifier embedded in the compiled bytecode.
    pub name: String,
    /// Serialized QuickJS module bytecode.
    pub bytes: Vec<u8>,
}

impl JsModuleBytecode {
    /// Creates a new module bytecode container.
    ///
    /// Use this when loading previously persisted bytecode bytes back into FJS.
    /// The `name` must match the module name embedded in the bytecode payload.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final compiled = await JsBytecode.compile(
    ///   module: JsModule.code(
    ///     module: 'plugins/auth',
    ///     code: 'export const ready = true;',
    ///   ),
    /// );
    ///
    /// final restored = JsModuleBytecode(
    ///   name: compiled.name,
    ///   bytes: compiled.bytes,
    /// );
    /// ```
    #[frb(sync)]
    pub fn new(name: String, bytes: Vec<u8>) -> Self {
        Self { name, bytes }
    }
}

/// A collection of precompiled ES modules, optionally with a designated entry module.
///
/// Bundles are useful when a feature ships as a module graph rather than a single module.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub struct JsModuleBytecodeBundle {
    /// Optional entry module to execute when evaluating the bundle.
    pub entry: Option<String>,
    /// Serialized bytecode for all modules in the bundle.
    pub modules: Vec<JsModuleBytecode>,
}

impl JsModuleBytecodeBundle {
    /// Creates a new bundle of bytecode modules.
    ///
    /// Set `entry` when the bundle will later be executed with
    /// `engine.evaluateBytecodeBundle(...)`. Leave it `null` when the bundle is
    /// only used for declaration.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final bundle = JsModuleBytecodeBundle(
    ///   entry: 'feature/index',
    ///   modules: [
    ///     featureIndexBytecode,
    ///     sharedUtilBytecode,
    ///   ],
    /// );
    /// ```
    #[frb(sync)]
    pub fn new(entry: Option<String>, modules: Vec<JsModuleBytecode>) -> Self {
        Self { entry, modules }
    }
}

/// Options used when compiling non-module JavaScript into QuickJS bytecode.
///
/// This is intended for classic global/script evaluation, including optional top-level await.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub struct JsScriptBytecodeOptions {
    /// Byte order used in the serialized bytecode.
    pub endianness: Option<JsBytecodeEndianness>,
    /// Strip embedded source text from the bytecode.
    pub strip_source: Option<bool>,
    /// Strip debug metadata from the bytecode.
    pub strip_debug: Option<bool>,
    /// Force strict mode for the compiled script.
    pub strict: Option<bool>,
    /// Do not include previous stack frames in future backtraces.
    pub backtrace_barrier: Option<bool>,
    /// Compile with top-level await support enabled.
    pub promise: Option<bool>,
}

impl Default for JsScriptBytecodeOptions {
    fn default() -> Self {
        Self {
            endianness: Some(JsBytecodeEndianness::Little),
            strip_source: Some(true),
            strip_debug: Some(true),
            strict: Some(true),
            backtrace_barrier: Some(false),
            promise: Some(false),
        }
    }
}

impl JsScriptBytecodeOptions {
    /// Creates script bytecode options suitable for distribution.
    ///
    /// Defaults:
    /// - little-endian output
    /// - `stripSource: true`
    /// - `stripDebug: true`
    /// - `strict: true`
    /// - `backtraceBarrier: false`
    /// - `promise: false`
    ///
    /// ## Example
    ///
    /// ```dart
    /// final options = JsScriptBytecodeOptions.defaults().copyWith(
    ///   promise: true,
    /// );
    ///
    /// final script = await JsBytecode.compileScript(
    ///   name: 'bootstrap.js',
    ///   source: JsCode.code('await Promise.resolve("ready")'),
    ///   options: options,
    /// );
    /// ```
    #[frb(sync)]
    pub fn defaults() -> Self {
        Self::default()
    }
}

impl From<JsScriptBytecodeOptions> for WriteOptions {
    fn from(value: JsScriptBytecodeOptions) -> Self {
        let endianness = match value.endianness.unwrap_or_default() {
            JsBytecodeEndianness::Native => WriteOptionsEndianness::Native,
            JsBytecodeEndianness::Little => WriteOptionsEndianness::Little,
            JsBytecodeEndianness::Big => WriteOptionsEndianness::Big,
        };

        WriteOptions {
            endianness,
            strip_source: value.strip_source.unwrap_or(true),
            strip_debug: value.strip_debug.unwrap_or(true),
            ..Default::default()
        }
    }
}

/// Serialized QuickJS bytecode for a classic global script.
///
/// Unlike module bytecode, the `name` acts as compile-time metadata and source filename.
/// QuickJS does not expose an embedded script name that can be verified on load, so
/// validation is structural only.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Hash, Eq, PartialEq, Ord, PartialOrd)]
pub struct JsScriptBytecode {
    /// Logical script name and compile-time filename.
    pub name: String,
    /// Serialized QuickJS script bytecode.
    pub bytes: Vec<u8>,
}

impl JsScriptBytecode {
    /// Creates a new script bytecode container.
    ///
    /// Use this when restoring previously persisted classic-script bytecode.
    /// Unlike module bytecode, the `name` is descriptive metadata and is not
    /// verified against the payload on load.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final restored = JsScriptBytecode(
    ///   name: 'bootstrap.js',
    ///   bytes: storedBytes,
    /// );
    /// ```
    #[frb(sync)]
    pub fn new(name: String, bytes: Vec<u8>) -> Self {
        Self { name, bytes }
    }
}

/// Options for JavaScript code evaluation.
///
/// This struct provides configuration options for how JavaScript
/// code should be executed and evaluated.
///
/// ## Example
///
/// ```dart
/// // Default options
/// final opts1 = JsEvalOptions.defaults();
///
/// // With promise support
/// final opts2 = JsEvalOptions.withPromise();
///
/// // Custom options
/// final opts3 = JsEvalOptions(
///   global: true,
///   strict: true,
///   backtraceBarrier: false,
///   promise: true,
/// );
/// ```
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
    ///
    /// ## Parameters
    ///
    /// - `global`: Whether to evaluate in global scope
    /// - `strict`: Whether to enforce strict mode
    /// - `backtraceBarrier`: Whether to create a backtrace barrier
    /// - `promise`: Whether to enable promise/async support
    ///
    /// ## Returns
    ///
    /// A new `JsEvalOptions` instance
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
    ///
    /// Default settings:
    /// - global: true
    /// - strict: true
    /// - backtraceBarrier: false
    /// - promise: false
    ///
    /// ## Returns
    ///
    /// A `JsEvalOptions` instance with default values
    ///
    /// ## Example
    ///
    /// ```dart
    /// final opts = JsEvalOptions.defaults();
    /// ```
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
    ///
    /// Enables top-level await and async/await support.
    ///
    /// ## Returns
    ///
    /// A `JsEvalOptions` instance with promise support
    ///
    /// ## Example
    ///
    /// ```dart
    /// final opts = JsEvalOptions.withPromise();
    /// ```
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
    ///
    /// Module scope (not global), strict mode, with promise support.
    ///
    /// ## Returns
    ///
    /// A `JsEvalOptions` instance configured for modules
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
///
/// ## Example
///
/// ```dart
/// // Enable all builtins
/// final opts1 = JsBuiltinOptions.all();
///
/// // Enable only essential modules
/// final opts2 = JsBuiltinOptions.essential();
///
/// // Web-like environment
/// final opts3 = JsBuiltinOptions.web();
///
/// // Custom configuration
/// final opts4 = JsBuiltinOptions(
///   console: true,
///   timers: true,
///   fetch: true,
/// );
/// ```
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Default)]
pub struct JsBuiltinOptions {
    /// Enable abort functionality
    pub abort: Option<bool>,
    /// Enable the `assert` module
    pub assert: Option<bool>,
    /// Enable the `asyncHooks` module
    pub async_hooks: Option<bool>,
    /// Enable buffer module
    pub buffer: Option<bool>,
    /// Enable the `childProcess` module
    pub child_process: Option<bool>,
    /// Enable console module
    pub console: Option<bool>,
    /// Enable crypto module
    pub crypto: Option<bool>,
    /// Enable dgram module
    pub dgram: Option<bool>,
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
    /// Enable https module
    pub https: Option<bool>,
    /// Enable lightweight Intl.DateTimeFormat timezone support
    pub intl: Option<bool>,
    /// Enable navigator object
    pub navigator: Option<bool>,
    /// Enable net module
    pub net: Option<bool>,
    /// Enable os module
    pub os: Option<bool>,
    /// Enable path module
    pub path: Option<bool>,
    /// Enable the `perfHooks` module
    pub perf_hooks: Option<bool>,
    /// Enable process module
    pub process: Option<bool>,
    /// Enable the `streamWeb` module
    pub stream_web: Option<bool>,
    /// Enable the `stringDecoder` module
    pub string_decoder: Option<bool>,
    /// Enable Temporal global
    pub temporal: Option<bool>,
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
    /// This enables every available builtin module,
    /// providing maximum compatibility at the cost of larger binary size.
    ///
    /// ## Returns
    ///
    /// A `JsBuiltinOptions` instance with all modules enabled
    ///
    /// ## Example
    ///
    /// ```dart
    /// final opts = JsBuiltinOptions.all();
    /// final runtime = await JsAsyncRuntime.withOptions(builtin: opts);
    /// ```
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
            dgram: Some(true),
            dns: Some(true),
            events: Some(true),
            exceptions: Some(true),
            fetch: Some(true),
            fs: Some(true),
            https: Some(true),
            intl: Some(true),
            navigator: Some(true),
            net: Some(true),
            os: Some(true),
            path: Some(true),
            perf_hooks: Some(true),
            process: Some(true),
            stream_web: Some(true),
            string_decoder: Some(true),
            temporal: Some(true),
            timers: Some(true),
            tty: Some(true),
            url: Some(true),
            util: Some(true),
            zlib: Some(true),
            json: Some(true),
        }
    }

    /// Creates builtin options with no modules enabled.
    ///
    /// Creates a minimal runtime without any builtin modules.
    /// Use this when you want complete control over which modules are available.
    ///
    /// ## Returns
    ///
    /// A `JsBuiltinOptions` instance with no modules enabled
    ///
    /// ## Example
    ///
    /// ```dart
    /// final opts = JsBuiltinOptions.none();
    /// final runtime = await JsAsyncRuntime.withOptions(builtin: opts);
    /// ```
    #[frb(sync)]
    pub fn none() -> Self {
        JsBuiltinOptions::default()
    }

    /// Creates builtin options with essential modules only.
    ///
    /// Enables only the most commonly needed modules: console, timers, buffer, util, json.
    /// This provides a good balance between functionality and binary size.
    ///
    /// ## Returns
    ///
    /// A `JsBuiltinOptions` instance with essential modules
    ///
    /// ## Example
    ///
    /// ```dart
    /// final opts = JsBuiltinOptions.essential();
    /// final runtime = await JsAsyncRuntime.withOptions(builtin: opts);
    /// ```
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
    ///
    /// Enables modules typically available in web browsers:
    /// console, timers, fetch, url, crypto, streamWeb, navigator, exceptions, intl, json.
    ///
    /// ## Returns
    ///
    /// A `JsBuiltinOptions` instance configured for web-like environment
    ///
    /// ## Example
    ///
    /// ```dart
    /// final opts = JsBuiltinOptions.web();
    /// final runtime = await JsAsyncRuntime.withOptions(builtin: opts);
    /// ```
    #[frb(sync)]
    pub fn web() -> Self {
        JsBuiltinOptions {
            console: Some(true),
            timers: Some(true),
            fetch: Some(true),
            url: Some(true),
            crypto: Some(true),
            intl: Some(true),
            stream_web: Some(true),
            navigator: Some(true),
            exceptions: Some(true),
            json: Some(true),
            ..Default::default()
        }
    }

    /// Creates builtin options for Node.js-like environment.
    ///
    /// Enables most Node.js-compatible modules except OS-specific ones.
    /// Suitable for server-side JavaScript applications.
    ///
    /// ## Returns
    ///
    /// A `JsBuiltinOptions` instance configured for Node.js-like environment
    ///
    /// ## Example
    ///
    /// ```dart
    /// final opts = JsBuiltinOptions.node();
    /// final runtime = await JsAsyncRuntime.withOptions(builtin: opts);
    /// ```
    #[frb(sync)]
    pub fn node() -> Self {
        JsBuiltinOptions {
            abort: Some(true),
            assert: Some(true),
            async_hooks: Some(true),
            buffer: Some(true),
            console: Some(true),
            crypto: Some(true),
            dgram: Some(true),
            dns: Some(true),
            events: Some(true),
            exceptions: Some(true),
            fs: Some(true),
            https: Some(true),
            intl: Some(true),
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
