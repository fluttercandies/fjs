# Changelog

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

## 1.0.9

* Bug fixes and stability improvements

## 1.0.3

* Precompiled binaries support for macOS, iOS, Linux, Windows, and Android

## 1.0.2

* Improved flate2 configuration with zlib-rs backend

## 1.0.0

* **BREAKING CHANGE**: First stable release with enhanced compatibility
* Improved cross-platform support
* Stabilized API interface

## 0.0.1

* Initial release with basic functionality
