import 'dart:async';
import 'dart:convert';

import 'package:fjs/fjs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// JavaScript execution modes
enum JsExecutionMode {
  /// Script mode - uses eval(), does not support import statements
  script,

  /// Module mode - supports import/export statements
  module,
}

class FjsService extends ChangeNotifier {
  JsEngine? _engine;
  JsAsyncRuntime? _runtime;
  JsAsyncContext? _context;
  bool _isInitialized = false;
  bool _isExecuting = false;
  String? _lastError;
  String? _lastExecutionResult;
  JsExecutionMode _lastExecutionMode = JsExecutionMode.script;

  bool get isInitialized => _isInitialized;

  bool get isExecuting => _isExecuting;

  String? get lastError => _lastError;

  String? get lastExecutionResult => _lastExecutionResult;

  JsExecutionMode get lastExecutionMode => _lastExecutionMode;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load custom modules (linkedom, which depends on canvas)
      final linkedomBundle =
          await rootBundle.load('assets/examples/linkedom.bundle.mjs');
      final canvasBundle =
          await rootBundle.load('assets/examples/canvas.bundle.mjs');

      // Create runtime with builtin modules and custom modules
      _runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions(
          console: true,
          fetch: true,
          timers: true,
          url: true,
        ),
        additional: [
          JsModule(
            name: 'canvas',
            source: JsCode.bytes(canvasBundle.buffer.asUint8List()),
          ),
          JsModule(
            name: 'linkedom',
            source: JsCode.bytes(linkedomBundle.buffer.asUint8List()),
          ),
        ],
      );
      _context = await JsAsyncContext.from(runtime: _runtime!);
      _engine = JsEngine(context: _context!);

      await _engine!.initWithoutBridge();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to initialize FJS service: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ========== Basic Execution ==========

  /// Execute JavaScript code in Script mode
  ///
  /// Script mode uses eval() and does not support static import statements.
  /// If you need to use modules, use dynamic import() or executeAsModule().
  Future<dynamic> executeAsScript(String code) async {
    return _executeCode(code, JsExecutionMode.script);
  }

  /// Execute JavaScript code in Module mode
  ///
  /// Module mode supports import/export statements.
  /// Code will be wrapped as a module and evaluated.
  Future<dynamic> executeAsModule(String code) async {
    return _executeCode(code, JsExecutionMode.module);
  }

  /// Internal execution method
  Future<dynamic> _executeCode(String code, JsExecutionMode mode) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isExecuting) {
      throw Exception('Another execution is in progress');
    }

    if (code.trim().isEmpty) {
      return '';
    }

    _isExecuting = true;
    _lastError = null;
    _lastExecutionResult = null;
    _lastExecutionMode = mode;
    notifyListeners();

    try {
      JsValue result;

      if (mode == JsExecutionMode.module) {
        // Module mode: supports import/export
        result = await _executeAsModule(code);
      } else {
        // Script mode: does not support import
        result = await _executeAsScript(code);
      }

      _lastExecutionResult = JsonEncoder.withIndent('  ').convert(result.value);
      return result;
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  /// Execute in Script mode
  Future<JsValue> _executeAsScript(String code) async {
    return await _engine!.eval(source: JsCode.code(code));
  }

  /// Execute in Module mode
  Future<JsValue> _executeAsModule(String code) async {
    // Generate unique module name
    final moduleName = '_module_${DateTime.now().millisecondsSinceEpoch}';

    if (kDebugMode) {
      print('Executing Module mode:');
      print('Module name: $moduleName');
      print('Code:\n$code');
    }

    // Evaluate module
    await _engine!.evaluateModule(
      module: JsModule.code(module: moduleName, code: code),
    );

    // Import module and get result
    // If module exported default, return default; otherwise return entire module object
    final importCode = '''
(async () => {
  const module = await import('$moduleName');
  return module.default !== undefined ? module.default : module;
})()
    ''';

    return await _engine!.eval(source: JsCode.code(importCode));
  }

  // ========== Module Management ==========

  /// Declare a new module without executing it
  ///
  /// The module will be available for import in subsequent evaluations.
  Future<Map<String, dynamic>> declareModule({
    required String moduleName,
    required String code,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _engine!.declareNewModule(
        module: JsModule.code(module: moduleName, code: code),
      );
      return {
        'success': true,
        'moduleName': moduleName,
        'action': 'declared',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'action': 'declare_module',
      };
    }
  }

  /// Evaluate a module (declare and execute it)
  ///
  /// Unlike declareModule, this also executes the module's top-level code
  /// and returns its result.
  Future<Map<String, dynamic>> evaluateModuleWrapper({
    required String moduleName,
    required String code,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final result = await _engine!.evaluateModule(
        module: JsModule.code(module: moduleName, code: code),
      );
      return {
        'success': true,
        'moduleName': moduleName,
        'action': 'evaluated',
        'result': result.value,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'action': 'evaluate_module',
      };
    }
  }

  /// Declare multiple modules at once
  Future<Map<String, dynamic>> declareMultipleModules({
    required List<Map<String, String>> modules,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final jsModules = modules
          .map((m) => JsModule.code(
                module: m['name']!,
                code: m['code']!,
              ))
          .toList();

      await _engine!.declareNewModules(modules: jsModules);
      return {
        'success': true,
        'count': modules.length,
        'action': 'declared_multiple',
        'modules': modules.map((m) => m['name']).toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'action': 'declare_multiple_modules',
      };
    }
  }

  /// Clear all dynamically declared modules
  Future<Map<String, dynamic>> clearModules() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _engine!.clearNewModules();
      return {
        'success': true,
        'action': 'cleared_all_modules',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'action': 'clear_modules',
      };
    }
  }

  /// Get all declared module names
  Future<Map<String, dynamic>> getDeclaredModules() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final modules = await _engine!.getDeclaredModules();
      return {
        'success': true,
        'action': 'get_declared_modules',
        'modules': modules,
        'count': modules.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'action': 'get_declared_modules',
      };
    }
  }

  /// Check if a module is declared
  Future<Map<String, dynamic>> isModuleDeclared({
    required String moduleName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final isDeclared =
          await _engine!.isModuleDeclared(moduleName: moduleName);
      return {
        'success': true,
        'action': 'is_module_declared',
        'moduleName': moduleName,
        'isDeclared': isDeclared,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'action': 'is_module_declared',
      };
    }
  }

  /// Run comprehensive module test suite
  ///
  /// This method runs a series of tests to demonstrate module functionality.
  /// Returns a list of test results with success/failure status.
  Future<List<Map<String, dynamic>>> runTestSuite() async {
    final results = <Map<String, dynamic>>[];

    // Test 1: Declare a simple module
    results.add(await declareModule(
      moduleName: 'math-utils',
      code: '''
        export function add(a, b) {
          return a + b;
        }
        export function multiply(a, b) {
          return a * b;
        }
        export const PI = 3.14159;
      ''',
    ));

    // Test 2: Check if module is declared
    results.add(await isModuleDeclared(moduleName: 'math-utils'));

    // Test 3: Get all declared modules
    results.add(await getDeclaredModules());

    // Test 4: Declare multiple modules
    results.add(await declareMultipleModules(modules: [
      {
        'name': 'string-utils',
        'code': '''
          export function reverse(str) {
            return str.split('').reverse().join('');
          }
          export function capitalize(str) {
            return str.charAt(0).toUpperCase() + str.slice(1);
          }
        ''',
      },
      {
        'name': 'array-utils',
        'code': '''
          export function sum(arr) {
            return arr.reduce((a, b) => a + b, 0);
          }
          export function unique(arr) {
            return [...new Set(arr)];
          }
        ''',
      },
    ]));

    // Test 5: Module dependencies - use modules in another module
    results.add(await evaluateModuleWrapper(
      moduleName: 'calculator-test',
      code: '''
        import { add, multiply } from 'math-utils';

        export default {
          sum: add(5, 3),
          product: multiply(4, 7),
        };
      ''',
    ));

    // Test 6: Named exports
    results.add(await evaluateModuleWrapper(
      moduleName: 'date-utils',
      code: '''
        export function getCurrentDate() {
          return new Date().toISOString().split('T')[0];
        }
        export function formatTimestamp(date) {
          return date.toISOString();
        }
        export default {
          description: 'Date utility module',
          createdAt: new Date().toISOString(),
        };
      ''',
    ));

    // Test 7: Dynamic import in module
    results.add(await evaluateModuleWrapper(
      moduleName: 'dynamic-test',
      code: '''
        export async function getMathUtils() {
          const utils = await import('math-utils');
          return {
            add: utils.add,
            multiply: utils.multiply,
            PI: utils.PI,
          };
        }
        export default {
          description: 'Module with dynamic imports',
          createdAt: new Date().toISOString(),
        };
      ''',
    ));

    // Test 8: Clear modules
    results.add(await clearModules());

    return results;
  }

  @override
  void dispose() {
    _engine?.dispose();
    super.dispose();
  }
}
