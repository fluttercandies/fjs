# Changelog

## 3.3.0

* **BREAKING**: Raised the supported toolchain floor to Flutter 3.24.0 and Dart 3.5.0, aligned Cargokit and precompiled generation with that minimum, and added a minimum-version public API compilation gate while keeping the example on the latest pinned Flutter release.
* **FIX**: Fixed issue 19 by making the embedded CargoKit Gradle plugin compatible with Gradle 9 while retaining Gradle 8 support.
* **FIX**: Preserved QuickJS async result normalization for the single-field `{ value: ... }` wrapper and added focused regression coverage for wrapper and multi-key object behavior.
* **SECURITY**: Made JavaScript value conversion depth- and node-bounded, cycle-safe, and explicit about conversion failures.
* **SECURITY**: Bounded synchronous and asynchronous file-backed source reads so oversized inputs are rejected before unbounded allocation.
* **FIX**: Preserved rooted module specifiers during resolution and normalized rooted bytecode modules consistently.
* **INTERNAL**: Updated dependencies for resolved security advisories and recorded the remaining reviewed exception.
* **INTERNAL**: Documented Rust public APIs plus handwritten unsafe, lifetime, runtime-driver, and error-sink invariants.
* **INTERNAL**: Made Darwin release artifacts reproducible and self-verifying with an atomic symlink-preserving SwiftPM zip, synchronized 3.3.0 metadata, FRB codegen/content-hash checks, exact architecture and framework-version validation, and a real SwiftPM fixture build.
* **INTERNAL**: Added production CI gates for strict Rust and Dart quality, Gradle 8/9 Android compatibility, and clean-HEAD Darwin release packaging.
* **DOCS**: Clarified the trusted-script security boundary, native builtin capabilities, and isolation requirements for untrusted code.

## 3.2.0

* **BREAKING**: `JsEngine.close()` is now immediate/non-draining. It marks the engine closed, requests runtime shutdown, stops the driver, detaches host globals, and causes in-flight foreground work to fail with `JsError.cancelled` instead of waiting for timers, Promise callbacks, bridge calls, fetches, or spawned work to complete.
* **FEATURE**: Added `JsEngine.closeGracefully()` for the previous draining shutdown behavior. Use it when already-scheduled JavaScript work must be allowed to finish before teardown completes.
* **FIX**: Runtime shutdown now installs a QuickJS interrupt handler at runtime creation, so CPU-bound JavaScript can be interrupted when the engine is closed.
* **FIX**: Pending `fjs.bridge_call(...)` futures now observe engine shutdown and release their Dart-side callback future instead of keeping the runtime alive until the host future completes.
* **INTERNAL**: Added shutdown lifecycle coverage for pending evals, module calls, bridge calls, CPU-bound JavaScript, closed-state API rejection, and mixed multi-API close integration.

## 3.1.0

* **FIX**: Normalized Android Cargokit bindgen sysroot/include paths to forward slashes and passed the Android clang target explicitly, fixing Windows Android builds that failed to find NDK headers such as `stdio.h`.
* **FIX**: Pinned Cargokit cargo builds to the selected rustup toolchain's `rustc`, avoiding host `PATH` contamination from other Rust installations during cross-compilation.
* **FIX**: Made `tool/build_fjs_xcframework.sh --zip-output` handle relative output paths correctly.
* **INTERNAL**: Strengthened Darwin CocoaPods/SwiftPM release validation so local XCFramework artifacts must match the package version before release checks pass.

## 3.0.0

* **BREAKING**: `JsEngine`, `JsBytecode`, `JsRuntime`, `JsContext`, `JsAsyncRuntime`, and `JsAsyncContext` methods now throw a typed `JsError` instead of `AnyhowException`; catch with `on JsError` and match `code()` or the freezed variants
* **BREAKING**: `JsError.memoryLimit` now carries a message string instead of `current`/`limit` byte counts (those fields were never populated)
* **BREAKING**: `JsEngine.close()` now succeeds while `init()` is still in flight; the interrupted `init()` reports the failure instead
* **FEATURE**: Real QuickJS exceptions are classified into structured `JsError` variants — `syntax` (with line/column), `type`, `reference`, `stackOverflow`, `memoryLimit` — with full message and stack text preserved
* **FEATURE**: `rquickjs` error mapping now produces `conversion`, `module`, `io`, and `memoryLimit` variants instead of flattening everything into `runtime`
* **FEATURE**: Added public `JsEngine.drainUnhandledJobErrors()` to observe background JavaScript failures without failing an unrelated engine call; works in every engine state, including after `close()`
* **PERF**: Replaced the 5 ms background driver poll loop with an event-driven design (runtime schedular wakes + foreground notifications + 1 s defensive fallback); idle runtimes no longer consume CPU and detached timers fire on time
* **PERF**: Bytecode bundle validation reuses a single scratch QuickJS runtime for all modules; engine bytecode evaluation/bundle paths no longer validate or decode payloads twice
* **FIX**: Dropping `JsAsyncRuntime`/`JsAsyncContext` no longer blocks the calling thread (often the Dart main thread); cleanup now runs detached on the JS executor while `close()` stays deterministic
* **FIX**: Lock poisoning in driver/module/engine state no longer panics across the FFI boundary; locks recover the inner state instead
* **FIX**: Converting plain JavaScript objects no longer leaves a stale pending `TypeError` on the context (the previous `ArrayBuffer` probe threw internally for every non-ArrayBuffer object); detached `ArrayBuffer`/`TypedArray`/`DataView` values now raise a clear conversion error instead of silently producing empty bytes
* **FIX**: Background error acknowledgements are bounded: a handled promise rejection only removes its own queued error, so a recycled promise address can no longer swallow an unrelated background failure
* **INTERNAL**: Collapsed the six engine module declaration/evaluation methods into shared helpers; unified relative-specifier normalization; macro-ized typed-array byte extraction
* **INTERNAL**: Regenerated Flutter Rust Bridge bindings with `flutter_rust_bridge_codegen 2.12.0`

## 2.2.0

* **BREAKING**: Renamed runtime and engine factory APIs from `withOptions(...)` to `create(...)`
* **BREAKING**: Renamed factory parameters from `builtin`/`additional` to `builtins`/`modules`
* **FEATURE**: Added `JsEngineRuntimeOptions` for engine-owned runtime limits and metadata during construction
* **FEATURE**: Added runtime control proxies on `JsEngine`, including memory, GC, stack, scheduler, and info APIs
* **FIX**: Kept `JsEngine` as the sole owner of its runtime/context while restoring access to runtime-level safety controls
* **FIX**: Corrected engine integration tests to validate engine-owned runtime behavior instead of unrelated standalone runtimes
* **FIX**: Restored and expanded lifecycle regression coverage for engine initialization and close state transitions
* **DOCS**: Updated README, README_zh, FRB-generated API docs, and example app code to the final `create(...)` API
* **INTERNAL**: Regenerated Flutter Rust Bridge bindings with `flutter_rust_bridge_codegen 2.12.0`
* **INTERNAL**: Cleaned remaining Rust test warnings caused by unused async test contexts

## 2.1.0

* **BREAKING**: Renamed `clearNewModules()` to `clearPendingModules()` to match its actual semantics; only not-yet-loaded dynamic modules can be cleared
* **IMPROVEMENT**: Upgraded LLRT dependencies to revision `a2e1640`
* **IMPROVEMENT**: Added more LLRT-backed runtime capabilities, including `dgram`, `https`, `intl`, and `temporal`
* **IMPROVEMENT**: Added module inventory APIs to inspect all available modules, including builtins and additional configured modules
* **IMPROVEMENT**: Clarified dynamic module lifecycle with `clearPendingModules()`, which only clears not-yet-loaded registrations
* **FEATURE**: Added QuickJS bytecode APIs for ES modules, module bundles, and classic scripts, with compile, validate, declare, and evaluate workflows
* **FIX**: Moved bytecode compile and validate onto generated FRB APIs outside `JsEngine`, with both sync and async variants
* **FIX**: Made module bytecode compilation side-effect free and added eager bytecode validation before declaration/evaluation
* **FIX**: Prevented redefinition of dynamically loaded modules inside the same context lifecycle
* **FIX**: Corrected relative resolution for dynamically declared modules
* **FIX**: Hardened `JsEngine` lifecycle with an explicit initializing state, so `running` only becomes true after successful initialization
* **FIX**: Stabilized `dispose()` semantics to detach the bridge, drain pending runtime work, run GC, and leave ownership of the underlying context/runtime unchanged
* **FIX**: Rejected duplicate module names in bulk `declareNewModules()` and `declareNewBytecodeModules()` requests instead of silently overriding entries
* **FIX**: Hardened `JsValue` conversions for `Date`, `BigInt`, safe integers, and typed arrays
* **FIX**: Removed implicit runtime draining from hot execution paths; pending jobs now advance only through explicit runtime APIs
* **DOCS**: Updated README, README_zh, generated API docs, and example code to match the current production API and module semantics

## 2.0.1

* **IMPROVEMENT**: Upgraded LLRT dependencies from revision 77edb18 to d375ad0
* **IMPROVEMENT**: Added webpki-roots feature to llrt_fetch for enhanced TLS certificate validation
* **IMPROVEMENT**: Added comprehensive test suite to libfjs with 10 test modules
* **IMPROVEMENT**: Updated sysinfo dependency from 0.37.2 to 0.38.0
* **IMPROVEMENT**: Updated windows crates from 0.61.x to 0.62.x
* **FIX**: Fixed example fetch URL to use httpbin.org for proper HTML response testing

## 2.0.0

* **BREAKING**: Renamed `JsEngineCore` to `JsEngine` for clearer naming convention
* **BREAKING**: Removed `JsAction` system - direct API methods are now available on `JsEngine`
* **BREAKING**: Removed `exec()` method - use direct methods like `eval()`, `call()`, `declareNewModule()` instead
* **BREAKING**: Changed `eval()` parameter from positional to named parameter `source:` for better clarity
* **BREAKING**: Changed `declareNewModule()` parameter to named parameter `module:`
* **BREAKING**: Changed `declareNewModules()` parameter to named parameter `modules:`
* **BREAKING**: Removed `engine.freezed.dart` - `JsEngine` is now a regular abstract class
* **FEATURE**: Added `call()` method to invoke exported module functions directly
* **FEATURE**: Added `evaluateModule()` method to execute modules immediately
* **FEATURE**: Added `isModuleDeclared()` method to check module existence
* **FEATURE**: Added `clearNewModules()` method to remove all dynamically declared modules
* **FEATURE**: Added `initWithoutBridge()` method for engines that don't need bridge communication
* **FEATURE**: Added `context` getter to access underlying `JsAsyncContext`
* **FEATURE**: Added `disposed` getter to check engine disposal status
* **FEATURE**: Added comprehensive API documentation with examples for all public methods
* **IMPROVEMENT**: Migrated to named parameters throughout `JsEngine` API for better code clarity
* **IMPROVEMENT**: Updated all example screens to use new API
* **IMPROVEMENT**: Enhanced integration tests with new API coverage
* **IMPROVEMENT**: Simplified engine lifecycle management with direct methods
* **IMPROVEMENT**: Better error messages with detailed documentation
* **DOCS**: Fixed README.md and README_zh.md to match actual API signatures
* **DOCS**: Added detailed parameter descriptions and examples to all API methods
* **CI/CD**: Added GitHub Actions workflow for building all platforms

## 1.4.0

* **BREAKING**: Restructured API modules - removed deprecated `js` module, added `engine`, `error`, `runtime`, and `source` modules for better organization
* **FIX**: Fixed Promise result unwrapping - QuickJS's `JS_EVAL_FLAG_ASYNC` wraps Promise results in `{value: xxx}` format, now properly detected and unwrapped by checking for objects with exactly one `value` property
* **FIX**: Fixed nested Promise handling to correctly await and unwrap chained Promises
* **FIX**: Fixed `undefined` value handling in Promise results - now correctly returns `JsValue.none()` instead of the wrapper object
* **FIX**: Fixed `DynamicModuleResolver` to properly check module existence before resolving
* **FIX**: Fixed `build_loaders()` to properly include additional modules in resolver and loader chains
* **FIX**: Fixed `GlobalAttachment` to correctly initialize each context independently using context-level userdata
* **PERFORMANCE**: Optimized BigInt conversion using native rquickjs API instead of JavaScript evaluation
* **PERFORMANCE**: Improved Symbol description extraction using native rquickjs Symbol API
* **PERFORMANCE**: Simplified file reading with direct `tokio::fs::read()` call
* **IMPROVEMENT**: Added comprehensive integration tests (130+ test cases) covering Promise edge cases, boundary conditions, bridge call scenarios, and memory management
* **IMPROVEMENT**: Updated example app with new API screens for engine, error, runtime, and source modules
* **IMPROVEMENT**: Added widgets directory for reusable UI components in example app
* **INTERNAL**: Improved Promise result detection logic using object key enumeration instead of direct property access
* **INTERNAL**: Removed unused variable in bridge call function
* **INTERNAL**: Improved code clarity and reduced redundant logic

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
