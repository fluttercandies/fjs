//! QuickJS module bytecode utilities.

use crate::api::error::JsError;
use crate::api::source::{
    JsModule, JsModuleBytecode, JsModuleBytecodeBundle, JsModuleBytecodeOptions, JsScriptBytecode,
    JsScriptBytecodeOptions, get_raw_source_code, get_raw_source_code_sync,
};
use crate::bytecode_support::{
    compile_module_bundle_impl, compile_module_bytecode_impl, compile_script_bytecode_impl,
    validate_module_bundle_impl, validate_module_bytecode_impl, validate_script_bytecode_impl,
};
use flutter_rust_bridge::frb;

/// Stateless utility namespace for QuickJS bytecode operations.
///
/// This type does not own a runtime or context. It exists only to expose FRB-generated
/// sync/async bytecode APIs outside `JsEngine`.
#[frb(opaque)]
pub struct JsBytecode;

impl JsBytecode {
    /// Compiles a set of ES modules into a bytecode bundle synchronously.
    ///
    /// This reads any file-backed sources on the caller thread. Prefer the async
    /// variant on the Flutter UI isolate.
    ///
    /// When `entry` is provided, it should match one of the module names in
    /// `modules`. The resulting bundle can later be evaluated with
    /// `engine.evaluateBytecodeBundle(...)`.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final bundle = JsBytecode.compileModuleBundleSync(
    ///   modules: [
    ///     JsModule.code(
    ///       module: 'feature/index',
    ///       code: 'export { answer } from "./shared";',
    ///     ),
    ///     JsModule.code(
    ///       module: 'feature/shared',
    ///       code: 'export const answer = 42;',
    ///     ),
    ///   ],
    ///   entry: 'feature/index',
    /// );
    /// ```
    #[frb(sync)]
    pub fn compile_module_bundle_sync(
        modules: Vec<JsModule>,
        entry: Option<String>,
        options: Option<JsModuleBytecodeOptions>,
    ) -> Result<JsModuleBytecodeBundle, JsError> {
        let mut resolved_modules = Vec::with_capacity(modules.len());
        for module in modules {
            let JsModule { name, source } = module;
            let source_code = get_raw_source_code_sync(source)?;
            resolved_modules.push((name, source_code));
        }
        compile_module_bundle_impl(entry, resolved_modules, options.unwrap_or_default())
    }

    /// Compiles a set of ES modules into a bytecode bundle.
    ///
    /// Compilation runs in an isolated QuickJS runtime and does not require a
    /// `JsEngine`. Use this when precompiling a module graph for later
    /// declaration or execution.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final bundle = await JsBytecode.compileModuleBundle(
    ///   modules: [
    ///     JsModule.code(
    ///       module: 'plugins/main',
    ///       code: 'export { default } from "./impl";',
    ///     ),
    ///     JsModule.code(
    ///       module: 'plugins/impl',
    ///       code: 'export default () => "ready";',
    ///     ),
    ///   ],
    ///   entry: 'plugins/main',
    /// );
    /// ```
    pub async fn compile_module_bundle(
        modules: Vec<JsModule>,
        entry: Option<String>,
        options: Option<JsModuleBytecodeOptions>,
    ) -> Result<JsModuleBytecodeBundle, JsError> {
        let mut resolved_modules = Vec::with_capacity(modules.len());
        for module in modules {
            let JsModule { name, source } = module;
            let source_code = get_raw_source_code(source).await?;
            resolved_modules.push((name, source_code));
        }
        compile_module_bundle_impl(entry, resolved_modules, options.unwrap_or_default())
    }

    /// Compiles an ES module into QuickJS bytecode synchronously.
    ///
    /// This variant may block the caller while reading module source from disk.
    /// Prefer `compile()` on the main isolate.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final bytecode = JsBytecode.compileSync(
    ///   module: JsModule.code(
    ///     module: 'feature/main',
    ///     code: 'export default { ready: true };',
    ///   ),
    /// );
    /// ```
    #[frb(sync)]
    pub fn compile_sync(
        module: JsModule,
        options: Option<JsModuleBytecodeOptions>,
    ) -> Result<JsModuleBytecode, JsError> {
        let JsModule {
            name: module_name,
            source,
        } = module;
        let source_code = get_raw_source_code_sync(source)?;
        compile_module_bytecode_impl(&module_name, source_code, options.unwrap_or_default())
    }

    /// Compiles an ES module into QuickJS bytecode.
    ///
    /// Compilation runs in an isolated QuickJS runtime and does not require a
    /// `JsEngine`. The returned bytecode is tied to the embedded QuickJS version
    /// and must only be loaded from trusted sources.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final bytecode = await JsBytecode.compile(
    ///   module: JsModule.path(
    ///     module: 'plugins/auth',
    ///     path: '/absolute/path/to/auth.js',
    ///   ),
    /// );
    /// ```
    pub async fn compile(
        module: JsModule,
        options: Option<JsModuleBytecodeOptions>,
    ) -> Result<JsModuleBytecode, JsError> {
        let JsModule {
            name: module_name,
            source,
        } = module;
        let source_code = get_raw_source_code(source).await?;
        compile_module_bytecode_impl(&module_name, source_code, options.unwrap_or_default())
    }

    /// Validates serialized QuickJS ES module bytecode synchronously.
    ///
    /// Prefer `validate()` on the main isolate.
    ///
    /// ## Example
    ///
    /// ```dart
    /// JsBytecode.validateSync(module: compiledModuleBytecode);
    /// ```
    #[frb(sync)]
    pub fn validate_sync(module: JsModuleBytecode) -> Result<(), JsError> {
        validate_module_bytecode_impl(&module.name, &module.bytes)
    }

    /// Validates a bundle of serialized QuickJS ES module bytecode synchronously.
    ///
    /// Validation is structural: it checks for duplicate module names, verifies the
    /// optional entry exists in the bundle, and validates each module payload. It does
    /// not execute modules or prove that external runtime dependencies will resolve.
    ///
    /// ## Example
    ///
    /// ```dart
    /// JsBytecode.validateBundleSync(bundle: compiledBundle);
    /// ```
    #[frb(sync)]
    pub fn validate_bundle_sync(bundle: JsModuleBytecodeBundle) -> Result<(), JsError> {
        validate_module_bundle_impl(&bundle)
    }

    /// Validates serialized QuickJS ES module bytecode.
    ///
    /// Validation is structural: it ensures the bytes can be read by the embedded
    /// QuickJS version and that the embedded module name matches `module.name`.
    /// It does not declare or execute the module in any engine.
    ///
    /// ## Example
    ///
    /// ```dart
    /// await JsBytecode.validate(module: compiledModuleBytecode);
    /// ```
    pub async fn validate(module: JsModuleBytecode) -> Result<(), JsError> {
        validate_module_bytecode_impl(&module.name, &module.bytes)
    }

    /// Validates a bundle of serialized QuickJS ES module bytecode.
    ///
    /// Validation is structural: it checks for duplicate module names, verifies the
    /// optional entry exists in the bundle, and validates each module payload. It does
    /// not execute modules or prove that external runtime dependencies will resolve.
    ///
    /// ## Example
    ///
    /// ```dart
    /// await JsBytecode.validateBundle(bundle: compiledBundle);
    /// ```
    pub async fn validate_bundle(bundle: JsModuleBytecodeBundle) -> Result<(), JsError> {
        validate_module_bundle_impl(&bundle)
    }

    /// Compiles a classic global script into QuickJS bytecode synchronously.
    ///
    /// This is the non-module counterpart to `compile()`. The returned bytecode can
    /// later be executed with `engine.evaluateScriptBytecode(...)`.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final script = JsBytecode.compileScriptSync(
    ///   name: 'bootstrap.js',
    ///   source: JsCode.code('globalThis.version = "3.0.0";'),
    /// );
    /// ```
    #[frb(sync)]
    pub fn compile_script_sync(
        name: String,
        source: crate::api::source::JsCode,
        options: Option<JsScriptBytecodeOptions>,
    ) -> Result<JsScriptBytecode, JsError> {
        let source_code = get_raw_source_code_sync(source)?;
        compile_script_bytecode_impl(&name, source_code, options.unwrap_or_default())
    }

    /// Compiles a classic global script into QuickJS bytecode.
    ///
    /// Set `options.promise` to `true` when the script should support top-level
    /// `await`.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final script = await JsBytecode.compileScript(
    ///   name: 'bootstrap.js',
    ///   source: JsCode.code('await Promise.resolve(globalThis.ready = true)'),
    ///   options: JsScriptBytecodeOptions.defaults().copyWith(promise: true),
    /// );
    /// ```
    pub async fn compile_script(
        name: String,
        source: crate::api::source::JsCode,
        options: Option<JsScriptBytecodeOptions>,
    ) -> Result<JsScriptBytecode, JsError> {
        let source_code = get_raw_source_code(source).await?;
        compile_script_bytecode_impl(&name, source_code, options.unwrap_or_default())
    }

    /// Validates serialized QuickJS script bytecode synchronously.
    ///
    /// Validation is structural: it ensures the bytes decode under the embedded
    /// QuickJS version and represent executable non-module bytecode.
    ///
    /// ## Example
    ///
    /// ```dart
    /// JsBytecode.validateScriptSync(script: compiledScriptBytecode);
    /// ```
    #[frb(sync)]
    pub fn validate_script_sync(script: JsScriptBytecode) -> Result<(), JsError> {
        validate_script_bytecode_impl(&script.name, &script.bytes)
    }

    /// Validates serialized QuickJS script bytecode.
    ///
    /// Validation is structural: it ensures the bytes decode under the embedded
    /// QuickJS version and represent executable non-module bytecode.
    ///
    /// ## Example
    ///
    /// ```dart
    /// await JsBytecode.validateScript(script: compiledScriptBytecode);
    /// ```
    pub async fn validate_script(script: JsScriptBytecode) -> Result<(), JsError> {
        validate_script_bytecode_impl(&script.name, &script.bytes)
    }
}
