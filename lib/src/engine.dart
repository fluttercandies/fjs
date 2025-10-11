/// JavaScript Engine for Flutter
///
/// This file provides the high-level [JsEngine] class that offers a simplified
/// and user-friendly interface for executing JavaScript code within Flutter applications.
/// The engine manages the underlying JavaScript runtime, context, and provides
/// convenient methods for code evaluation, module management, and bridge communication.
///
/// ## Key Features
///
/// - **Simplified API**: High-level interface that abstracts away low-level details
/// - **Async/Await Support**: First-class support for asynchronous JavaScript operations
/// - **Module Management**: Easy dynamic loading and execution of JavaScript modules
/// - **Error Handling**: Comprehensive error propagation and reporting
/// - **Bridge Communication**: Bidirectional communication between Dart and JavaScript
/// - **Resource Management**: Automatic cleanup and disposal of engine resources
///
/// ## Example Usage
///
/// ```dart
/// // Create a runtime and context
/// final runtime = await JsAsyncRuntime.withOptions(
///   builtin: JsBuiltinOptions.all(),
/// );
/// final context = await JsAsyncContext.from(runtime);
///
/// // Create and initialize the engine
/// final engine = JsEngine(context);
/// await engine.init(
///   bridgeCall: (value) async {
///     print('Bridge call: ${value.value}');
///     return JsValue.string('Response from Dart');
///   },
/// );
///
/// // Execute JavaScript code
/// final result = await engine.eval(
///   JsCode.code('2 + 2'),
/// );
/// print('Result: ${result.value}'); // 4
///
/// // Dispose the engine when done
/// await engine.dispose();
/// ```

import 'dart:async';

import '../fjs.dart';
import 'frb/api/js.dart';

/// High-level JavaScript engine for Flutter applications.
///
/// The [JsEngine] class provides a user-friendly interface for executing JavaScript
/// code, managing modules, and handling bidirectional communication between Dart and JavaScript.
/// It abstracts away the complexity of the underlying runtime and context management.
///
/// ## Thread Safety
///
/// The engine is designed to be used from a single isolate/thread. All operations
/// are asynchronous and return [Future] objects to handle concurrency safely.
///
/// ## Resource Management
///
/// Always call [dispose] when the engine is no longer needed to properly clean up
/// resources and prevent memory leaks.
class JsEngine {
  /// Creates a new JavaScript engine with the given context.
  ///
  /// This factory constructor creates a [JsEngineCore] and wraps it in the
  /// high-level [JsEngine] interface.
  ///
  /// # Parameters
  ///
  /// - [context]: The asynchronous context to use for JavaScript execution
  ///
  /// # Returns
  ///
  /// Returns a new [JsEngine] instance.
  ///
  /// # Example
  ///
  /// ```dart
  /// final runtime = await JsAsyncRuntime.new();
  /// final context = await JsAsyncContext.from(runtime);
  /// final engine = JsEngine(context);
  /// ```
  JsEngine._(this._core);

  /// Factory constructor to create a new JavaScript engine.
  ///
  /// This is the recommended way to create a [JsEngine] instance.
  ///
  /// # Parameters
  ///
  /// - [context]: The asynchronous context for JavaScript execution
  ///
  /// # Returns
  ///
  /// Returns a new [JsEngine] instance.
  factory JsEngine(JsAsyncContext context) {
    return JsEngine._(JsEngineCore(context: context));
  }

  /// The underlying engine core that handles low-level operations.
  final JsEngineCore _core;

  /// Map of pending operations by their unique IDs.
  ///
  /// This is used to track asynchronous operations and match
  /// results with their corresponding requests.
  final Map<int, Completer<JsValue>> _map = {};

  /// Counter for generating unique operation IDs.
  int _id = 0;

  /// Flag indicating whether the engine has been initialized.
  ///
  /// The engine must be initialized with [init] before executing code.
  bool _initialized = false;

  /// Gets the next unique operation ID.
  ///
  /// This method generates a sequential ID for tracking operations
  /// and their results between Dart and JavaScript.
  ///
  /// # Returns
  ///
  /// Returns the next unique ID as an integer.
  int get _nextId => ++_id;

  /// Disposes the engine and cleans up all resources.
  ///
  /// This method should be called when the engine is no longer needed.
  /// It will stop the underlying engine core and clear all pending operations.
  ///
  /// # Returns
  ///
  /// Returns a [Future] that completes when disposal is done.
  ///
  /// # Example
  ///
  /// ```dart
  /// final engine = JsEngine(context);
  /// await engine.init();
  /// 
  /// // Use the engine...
  /// 
  /// // Clean up when done
  /// await engine.dispose();
  /// ```
  Future<void> dispose() {
    return _core.dispose().whenComplete(() {
      _map.clear();
    });
  }

  /// Gets whether the engine has been disposed.
  ///
  /// Once disposed, the engine can no longer be used.
  ///
  /// # Returns
  ///
  /// Returns `true` if the engine is disposed, `false` otherwise.
  bool get disposed => _core.disposed;

  /// Gets whether the engine is currently running.
  ///
  /// This indicates whether the underlying event loop is active.
  ///
  /// # Returns
  ///
  /// Returns `true` if the engine is running, `false` otherwise.
  bool get running => _core.running;

  /// Gets whether the engine has been initialized.
  ///
  /// The engine must be initialized with [init] before executing code.
  ///
  /// # Returns
  ///
  /// Returns `true` if the engine is initialized, `false` otherwise.
  bool get initialized => _initialized;

  /// Initializes the JavaScript engine.
  ///
  /// This method starts the underlying engine core and sets up the bridge for
  /// bidirectional communication between Dart and JavaScript. The engine must be
  /// initialized before executing any JavaScript code.
  ///
  /// # Parameters
  ///
  /// - [bridgeCall]: Optional callback function for handling bridge calls from JavaScript
  ///   to Dart. When JavaScript code calls `fjs.bridge_call(value)`, this function
  ///   will be invoked with the value passed from JavaScript.
  ///
  /// # Returns
  ///
  /// Returns a [Future] that completes when the engine is successfully initialized.
  ///
  /// # Throws
  ///
  /// - [JsError] if the engine is already initialized
  /// - [TimeoutException] if initialization takes longer than 500ms
  ///
  /// # Example
  ///
  /// ```dart
  /// final engine = JsEngine(context);
  /// await engine.init(
  ///   bridgeCall: (value) async {
  ///     // Handle bridge calls from JavaScript
  ///     print('Received from JS: ${value.value}');
  ///     return JsValue.string('Hello from Dart!');
  ///   },
  /// );
  /// ```
  Future<void> init({
    FutureOr<JsValue?> Function(JsValue)? bridgeCall,
  }) {
    if (_initialized) {
      return Future.error(
        JsError.engine('JsEngine is already initialized.'),
      );
    }
    _initialized = true;
    final completer = Completer();
    _core.start(
      bridge: (v) {
        return v.when(
          initialized: () {
            completer.complete();
            return const JsCallbackResult.initialized();
          },
          handler: (r) {
            final id = r.id;
            final res = r.result;
            final completer = _map[id];
            if (completer != null) {
              if (res.isErr) {
                completer.completeError(res.err);
              } else {
                completer.complete(res.ok);
              }
            }
            return const JsCallbackResult.handler();
          },
          bridge: (v) async {
            if (bridgeCall != null) {
              try {
                final jsValue = await bridgeCall(v);
                return JsCallbackResult.bridge(
                  JsResult.ok(jsValue ?? const JsValue.none()),
                );
              } catch (e) {
                return JsCallbackResult.bridge(JsResult.err(
                  JsError.bridge('Error in bridge call: ${e.toString()}'),
                ));
              }
            } else {
              return const JsCallbackResult.bridge(JsResult.err(
                JsError.bridge('No bridge call function provided.'),
              ));
            }
          },
        );
      },
    );
    return completer.future
        .timeout(const Duration(milliseconds: 500))
        .catchError((e) {
      if (!_core.disposed) {
        dispose();
      }
      _initialized = false;
    });
  }

  /// Executes an action on the JavaScript engine.
  ///
  /// This internal method handles the execution of actions with proper error handling,
  /// timeout management, and cleanup of pending operations.
  ///
  /// # Parameters
  ///
  /// - [id]: Unique identifier for this operation
  /// - [action]: The action to execute
  /// - [timeout]: Optional timeout for the operation
  ///
  /// # Returns
  ///
  /// Returns a [Future] that completes with the execution result.
  ///
  /// # Throws
  ///
  /// - [JsError] if the engine is not initialized or disposed
  /// - [TimeoutException] if the operation times out
  Future<JsValue> _exec(int id, JsAction action, {Duration? timeout}) async {
    if (!_initialized) {
      return Future.error(JsError.engine('JsEngine is not initialized.'));
    }
    if (_core.disposed) {
      return Future.error(JsError.engine('JsEngine is disposed.'));
    }
    final completer = Completer<JsValue>();
    _map[id] = completer;
    _core.exec(action: action).catchError((e) {
      _map.remove(id);
      completer.completeError(e);
    });
    final future =
        timeout == null ? completer.future : completer.future.timeout(timeout);
    return future.whenComplete(() {
      _map.remove(id);
    });
  }

  /// Evaluates JavaScript code.
  ///
  /// This method executes JavaScript code and returns the result. The code can be
  /// provided as inline code or as a file path, and execution can be customized with
  /// evaluation options.
  ///
  /// # Parameters
  ///
  /// - [source]: The JavaScript code to evaluate (inline code or file path)
  /// - [options]: Optional evaluation settings (strict mode, global scope, etc.)
  /// - [timeout]: Optional timeout for the evaluation
  ///
  /// # Returns
  ///
  /// Returns a [Future] that completes with the evaluation result as a [JsValue].
  ///
  /// # Throws
  ///
  /// - [JsError] if the engine is not initialized or disposed
  /// - [TimeoutException] if evaluation times out
  /// - [JsError] if JavaScript execution fails
  ///
  /// # Example
  ///
  /// ```dart
  /// // Simple expression evaluation
  /// final result = await engine.eval(
  ///   JsCode.code('2 + 2'),
  /// );
  /// print('Result: ${result.value}'); // 4
  ///
  /// // With custom options
  /// final result2 = await engine.eval(
  ///   JsCode.code('let x = 42; x;'),
  ///   options: JsEvalOptions(
  ///     global: true,
  ///     strict: true,
  ///   ),
  /// );
  ///
  /// // From file
  /// final result3 = await engine.eval(
  ///   JsCode.path('/path/to/script.js'),
  /// );
  /// ```
  Future<JsValue> eval(
    JsCode source, {
    JsEvalOptions? options,
    Duration? timeout,
  }) {
    final nextId = _nextId;
    return _exec(
      nextId,
      JsAction.eval(id: nextId, source: source, options: options),
      timeout: timeout,
    );
  }

  /// Evaluates a JavaScript module.
  ///
  /// This method loads and evaluates a JavaScript module, making it available
  /// for import and use in subsequent code evaluations.
  ///
  /// # Parameters
  ///
  /// - [module]: The module to evaluate (name and source)
  /// - [timeout]: Optional timeout for the evaluation
  ///
  /// # Returns
  ///
  /// Returns a [Future] that completes with the evaluation result.
  ///
  /// # Example
  ///
  /// ```dart
  /// // Evaluate a module from inline code
  /// await engine.evaluateModule(
  ///   JsModule.code(
  ///     'math-utils',
  ///     'export const add = (a, b) => a + b;'
  ///   ),
  /// );
  ///
  /// // Use the module in subsequent evaluations
  /// final result = await engine.eval(
  ///   JsCode.code("import { add } from 'math-utils'; add(2, 3);"),
  /// );
  /// ```
  Future<JsValue> evaluateModule(JsModule module, {Duration? timeout}) {
    final nextId = _nextId;
    return _exec(
      nextId,
      JsAction.evaluateModule(id: nextId, module: module),
      timeout: timeout,
    );
  }

  /// Declares a new module in the dynamic module storage.
  ///
  /// This method registers a module in the engine's dynamic module storage,
  /// making it available for import without immediately evaluating it.
  /// The module will be evaluated when first imported.
  ///
  /// # Parameters
  ///
  /// - [module]: The module to declare (name and source)
  /// - [timeout]: Optional timeout for the declaration
  ///
  /// # Returns
  ///
  /// Returns a [Future] that completes when the module is declared.
  ///
  /// # Example
  ///
  /// ```dart
  /// // Declare a module without evaluating it
  /// await engine.declareNewModule(
  ///   JsModule.code(
  ///     'utils',
  ///     'export const multiply = (a, b) => a * b;'
  ///   ),
  /// );
  ///
  /// // Module is evaluated when first used
  /// final result = await engine.eval(
  ///   JsCode.code("import { multiply } from 'utils'; multiply(4, 5);"),
  /// );
  /// ```
  Future<JsValue> declareNewModule(JsModule module, {Duration? timeout}) {
    final nextId = _nextId;
    return _exec(
      nextId,
      JsAction.declareNewModule(id: nextId, module: module),
      timeout: timeout,
    );
  }

  /// Declares multiple new modules at once.
  ///
  /// This method registers multiple modules in the engine's dynamic module storage
  /// in a single operation. This is more efficient than declaring modules individually.
  ///
  /// # Parameters
  ///
  /// - [modules]: List of modules to declare
  /// - [timeout]: Optional timeout for the declaration
  ///
  /// # Returns
  ///
  /// Returns a [Future] that completes when all modules are declared.
  ///
  /// # Example
  ///
  /// ```dart
  /// // Declare multiple modules at once
  /// await engine.declareNewModules([
  ///   JsModule.code('math', 'export const add = (a, b) => a + b;'),
  ///   JsModule.code('string', 'export const reverse = (s) => s.split('').reverse().join("");'),
  ///   JsModule.code('array', 'export const sum = (arr) => arr.reduce((a, b) => a + b, 0);'),
  /// ]);
  /// ```
  Future<JsValue> declareNewModules(List<JsModule> modules,
      {Duration? timeout}) {
    final nextId = _nextId;
    return _exec(
      nextId,
      JsAction.declareNewModules(id: nextId, modules: modules),
      timeout: timeout,
    );
  }

  /// Clears all dynamically declared modules.
  ///
  /// This method removes all modules from the dynamic module storage,
  /// effectively resetting the module system. Previously imported modules
  /// will remain available in the current context, but new imports will fail.
  ///
  /// # Parameters
  ///
  /// - [timeout]: Optional timeout for the operation
  ///
  /// # Returns
  ///
  /// Returns a [Future] that completes when modules are cleared.
  ///
  /// # Example
  ///
  /// ```dart
  /// // Clear all dynamic modules
  /// await engine.clearNewModules();
  ///
  /// // Now you can declare new modules
  /// await engine.declareNewModule(
  ///   JsModule.code('fresh', 'export const value = 42;'),
  /// );
  /// ```
  Future<JsValue> clearNewModules({Duration? timeout}) {
    final nextId = _nextId;
    return _exec(
      nextId,
      JsAction.clearNewModules(id: nextId),
      timeout: timeout,
    );
  }
}
