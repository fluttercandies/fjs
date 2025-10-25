# Changelog

## 1.3.0

* **FEATURE**: Added `JsCode.bytes()` variant for direct `Uint8List` support from Dart
* **FEATURE**: Added `JsModule.bytes()` constructor for creating modules from bytes
* **PERFORMANCE**: Significant performance improvement when JavaScript code is already in bytes format
* **PERFORMANCE**: Eliminated unnecessary UTF-8 String conversions for network and file-based JavaScript code
* **PERFORMANCE**: Direct bytes-to-rquickjs pipeline using `Into<Vec<u8>>` API compatibility
* **IMPROVEMENT**: Optimized dynamic module storage from `HashMap<String, String>` to `HashMap<String, Vec<u8>>`
* **IMPROVEMENT**: Enhanced `get_raw_source_code()` to return `Vec<u8>` instead of `String`
* **IMPROVEMENT**: Updated file reading operations to use `read_to_end()` instead of `read_to_string()` for better efficiency
* **DOCS**: Enhanced API documentation with bytes-specific usage patterns and examples
* **DOCS**: Added detailed bytes usage examples to README.md and README_zh.md

## 1.2.0

* **BREAKING**: Complete refactor of example application architecture
* **FEATURE**: Added asset-based JavaScript example system with dynamic loading
* **FEATURE**: Implemented comprehensive example categorization with 12 distinct categories
* **FEATURE**: Created modular example management with 93 individual JavaScript files
* **FEATURE**: Added automatic file caching mechanism for improved performance
* **FEATURE**: Added module declaration management actions to JavaScript engine
* **FEATURE**: Added `getDeclaredModules()` method to retrieve all dynamically declared modules
* **FEATURE**: Added `isModuleDeclared()` method to check if a specific module is declared
* **IMPROVEMENT**: Enhanced module tracking and introspection capabilities
* **IMPROVEMENT**: Standardized all JavaScript examples to use `console.log()` instead of `export` statements
* **IMPROVEMENT**: Removed Chinese comments, all code uses clean English documentation
* **REMOVED**: Eliminated all events-related examples to simplify the codebase

## 1.1.0

* **FEATURE**: Enhanced API design with improved high-level interface
* **FEATURE**: Advanced example application with interactive playground, responsive layout, haptic feedback, and local storage
* **FEATURE**: New module management methods `declareNewModule`, `declareNewModules`, and `clearNewModules` for better module handling
* **FEATURE**: Built-in modules are now configured during runtime creation via `JsAsyncRuntime.withOptions()`
* **DEPRECATED**: Removed `enableBuiltinModule()` method - use runtime options instead
* **DEPRECATED**: Removed `declareModule()` method - use `declareNewModule()` instead
* **DEPRECATED**: Removed `importModule()` method
* **DOCS**: Comprehensive documentation updates with detailed examples and API reference
* **DOCS**: Enhanced quick start guide and advanced usage examples
* **PERF**: Improved memory management and garbage collection controls
* **PERF**: Better error handling and recovery mechanisms
* **INTERNAL**: Updated dependencies for better compatibility
* **INTERNAL**: Enhanced build system for faster development cycles
* **INTERNAL**: Improved Rust FFI bindings and async runtime support
* **INTERNAL**: Added comprehensive error types and proper error propagation

## 1.0.9

* Bug fixes and stability improvements
* **INTERNAL**: Fixed module resolution edge cases
* **INTERNAL**: Improved async context synchronization

## 1.0.3

* Precompiled binaries support for macOS, iOS, Linux, Windows, and Android
* **INTERNAL**: Enhanced cargo configuration for better cross-platform builds

## 1.0.2

* **INTERNAL**: Improved flate2 configuration with zlib-rs backend
* **INTERNAL**: Fixed build configuration for Windows targets

## 1.0.1

* **FIX**: Resolved memory management issues in long-running scripts
* **FIX**: Fixed module loading edge cases and circular dependencies
* **FIX**: Improved error messages for better debugging
* **INTERNAL**: Added comprehensive test suite for JavaScript runtime operations
* **INTERNAL**: Enhanced async runtime performance and stability

## 1.0.0

* **BREAKING CHANGE**: First stable release with enhanced compatibility
* **IMPROVEMENT**: Improved cross-platform support with better build configuration
* **IMPROVEMENT**: Stabilized API interface and error handling
* **IMPROVEMENT**: Enhanced module system with dynamic loading capabilities
* **INTERNAL**: Migrated to Rust-based build system for better performance
* **INTERNAL**: Improved FFI bindings for async runtime operations

## 0.0.1

* Initial release with basic functionality
* **INTERNAL**: Core JavaScript runtime integration with Flutter
* **INTERNAL**: Basic module loading and execution support
