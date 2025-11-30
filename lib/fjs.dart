/// FJS - Flutter JavaScript Engine
///
/// A comprehensive Flutter library for executing JavaScript code within Flutter applications.
/// Built on top of the QuickJS engine, FJS provides a seamless integration between Dart and JavaScript,
/// enabling developers to run JavaScript code, use Node.js modules, and create hybrid applications.
///
/// ## Features
///
/// - **Synchronous and Asynchronous Execution**: Support for both sync and async JavaScript operations
/// - **Module System**: Full ES6 module support with dynamic loading capabilities
/// - **Node.js Compatibility**: Built-in support for common Node.js modules
/// - **Bidirectional Communication**: Call JavaScript from Dart and Dart from JavaScript
/// - **Memory Management**: Fine-grained control over memory usage and garbage collection
/// - **Type Safety**: Type-safe conversion between Dart and JavaScript values
/// - **Error Handling**: Comprehensive error reporting and debugging capabilities
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:fjs/fjs.dart';
///
/// // Create an async runtime
/// final runtime = await JsAsyncRuntime.withOptions(
///   builtin: JsBuiltinOptions.all(),
/// );
///
/// // Create a context
/// final context = await JsAsyncContext.from(runtime);
///
/// // Create an engine
/// final engine = JsEngine(context);
///
/// // Initialize the engine
/// await engine.init();
///
/// // Execute JavaScript code
/// final result = await engine.eval(
///   JsCode.code('Math.random() * 100'),
/// );
///
/// print('Random number: ${result.value}');
/// ```
///
/// ## Module Usage
///
/// ```dart
/// // Load a module from file
/// await engine.declareNewModule(
///   JsModule.path('utils', '/path/to/utils.js'),
/// );
///
/// // Execute a function from a module
/// final result = await engine.eval(
///   JsCode.code("import { add } from 'utils'; add(2, 3);"),
/// );
/// ```
///
/// ## Bridge Communication
///
/// ```dart
/// await engine.init(
///   bridgeCall: (value) async {
///     print('JavaScript called: ${value.value}');
///     return JsValue.string('Hello from Dart!');
///   },
/// );
/// ```

library;

// Core engine and runtime management
export 'src/engine.dart';

// JavaScript API with high-level abstractions
export 'src/frb/api/engine.dart'
    hide JsActionResult, JsCallback, JsCallbackResult;

// Error handling
export 'src/frb/api/error.dart';

// Runtime and context
export 'src/frb/api/runtime.dart';

// Source code and modules
export 'src/frb/api/source.dart';

// Value conversion and type handling
export 'src/frb/api/value.dart';

// Low-level generated bindings
export 'src/frb/frb_generated.dart' show LibFjs;
