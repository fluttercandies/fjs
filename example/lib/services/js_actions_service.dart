import 'dart:async';
import 'dart:convert';

import 'package:fjs/fjs.dart';
import 'package:flutter/foundation.dart';

/// Service for testing JsAction functionality
class JsActionsService extends ChangeNotifier {
  JsEngine? _engine;
  bool _isInitialized = false;
  bool _isExecuting = false;
  String? _lastError;
  String? _lastExecutionResult;

  bool get isInitialized => _isInitialized;
  bool get isExecuting => _isExecuting;
  String? get lastError => _lastError;
  String? get lastExecutionResult => _lastExecutionResult;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.all(),
      );
      final context = await JsAsyncContext.from(rt: runtime);
      _engine = JsEngine(context);

      await _engine!.init();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to initialize JsActions service: $e';
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _engine?.dispose();
    super.dispose();
  }

  /// Test declaring a new module
  Future<Map<String, dynamic>> testDeclareModule({
    required String moduleName,
    required String code,
  }) async {
    return _executeAction('declare_module', () async {
      await _engine!.declareNewModule(
        JsModule(
          name: moduleName,
          source: JsCode.code(code),
        ),
      );
      return {
        'success': true,
        'moduleName': moduleName,
        'action': 'declared',
      };
    });
  }

  /// Test evaluating a module
  Future<Map<String, dynamic>> testEvaluateModule({
    required String moduleName,
    required String code,
  }) async {
    return _executeAction('evaluate_module', () async {
      final result = await _engine!.evaluateModule(
        JsModule(
          name: moduleName,
          source: JsCode.code(code),
        ),
      );
      return {
        'success': true,
        'moduleName': moduleName,
        'action': 'evaluated',
        'result': result.value,
      };
    });
  }

  /// Test declaring multiple modules
  Future<Map<String, dynamic>> testDeclareMultipleModules({
    required List<Map<String, String>> modules,
  }) async {
    return _executeAction('declare_multiple_modules', () async {
      final jsModules = modules.map((m) => 
        JsModule(
          name: m['name']!,
          source: JsCode.code(m['code']!),
        )
      ).toList();
      
      await _engine!.declareNewModules(jsModules);
      return {
        'success': true,
        'count': modules.length,
        'action': 'declared_multiple',
        'modules': modules.map((m) => m['name']).toList(),
      };
    });
  }

  /// Test clearing all modules
  Future<Map<String, dynamic>> testClearModules() async {
    return _executeAction('clear_modules', () async {
      await _engine!.clearNewModules();
      return {
        'success': true,
        'action': 'cleared_all_modules',
      };
    });
  }

  /// Test getting declared modules
  Future<Map<String, dynamic>> testGetDeclaredModules() async {
    return _executeAction('get_declared_modules', () async {
      final modules = await _engine!.getDeclaredModules();
      return {
        'success': true,
        'action': 'get_declared_modules',
        'modules': modules,
        'count': modules.length,
      };
    });
  }

  /// Test checking if a module is declared
  Future<Map<String, dynamic>> testIsModuleDeclared({
    required String moduleName,
  }) async {
    return _executeAction('is_module_declared', () async {
      final isDeclared = await _engine!.isModuleDeclared(moduleName);
      return {
        'success': true,
        'action': 'is_module_declared',
        'moduleName': moduleName,
        'isDeclared': isDeclared,
      };
    });
  }

  /// Test module dependencies (importing one module from another)
  Future<Map<String, dynamic>> testModuleDependencies({
    required String moduleName1,
    required String code1,
    required String moduleName2,
    required String code2,
  }) async {
    return _executeAction('module_dependencies', () async {
      // Declare first module
      await _engine!.declareNewModule(
        JsModule(
          name: moduleName1,
          source: JsCode.code(code1),
        ),
      );
      
      // Declare second module that imports the first
      await _engine!.declareNewModule(
        JsModule(
          name: moduleName2,
          source: JsCode.code(code2),
        ),
      );
      
      // Evaluate the second module
      final result = await _engine!.evaluateModule(
        JsModule(
          name: moduleName2,
          source: JsCode.code(code2),
        ),
      );
      
      return {
        'success': true,
        'action': 'module_dependencies',
        'modules': [moduleName1, moduleName2],
        'result': result.value,
      };
    });
  }

  /// Test module with named exports
  Future<Map<String, dynamic>> testNamedExports({
    required String moduleName,
    required String code,
    required String functionName,
  }) async {
    return _executeAction('named_exports', () async {
      // Declare module
      await _engine!.declareNewModule(
        JsModule(
          name: moduleName,
          source: JsCode.code(code),
        ),
      );
      
      // Import and call specific function
      final importCode = '''
        import { $functionName } from '$moduleName';
        $functionName();
      ''';
      
      final result = await _engine!.evaluateModule(
        JsModule(
          name: '${moduleName}_test',
          source: JsCode.code(importCode),
        ),
      );
      
      return {
        'success': true,
        'action': 'named_exports',
        'moduleName': moduleName,
        'functionName': functionName,
        'result': result.value,
      };
    });
  }

  /// Test dynamic import in module context
  Future<Map<String, dynamic>> testDynamicImportInModule({
    required String moduleName,
    required String code,
  }) async {
    return _executeAction('dynamic_import_in_module', () async {
      final result = await _engine!.evaluateModule(
        JsModule(
          name: moduleName,
          source: JsCode.code(code),
        ),
      );
      
      return {
        'success': true,
        'action': 'dynamic_import_in_module',
        'moduleName': moduleName,
        'result': result.value,
      };
    });
  }

  /// Execute action with error handling
  Future<Map<String, dynamic>> _executeAction(
    String actionName,
    Future<Map<String, dynamic>> Function() action,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isExecuting) {
      return {
        'success': false,
        'error': 'Another action is in progress',
        'action': actionName,
      };
    }

    _isExecuting = true;
    _lastError = null;
    _lastExecutionResult = null;
    notifyListeners();

    try {
      final result = await action();
      _lastExecutionResult = JsonEncoder.withIndent('  ').convert(result);
      return result;
    } catch (e) {
      final errorResult = {
        'success': false,
        'error': e.toString(),
        'action': actionName,
      };
      _lastError = e.toString();
      _lastExecutionResult = JsonEncoder.withIndent('  ').convert(errorResult);
      return errorResult;
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  /// Run comprehensive test suite
  Future<List<Map<String, dynamic>>> runTestSuite() async {
    final results = <Map<String, dynamic>>[];

    // Test 1: Declare a simple module
    results.add(await testDeclareModule(
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
    results.add(await testIsModuleDeclared(moduleName: 'math-utils'));

    // Test 3: Get all declared modules
    results.add(await testGetDeclaredModules());

    // Test 4: Declare multiple modules
    results.add(await testDeclareMultipleModules(modules: [
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

    // Test 5: Module dependencies
    results.add(await testModuleDependencies(
      moduleName1: 'calculator',
      code1: '''
        export function add(a, b) {
          return a + b;
        }
        export function subtract(a, b) {
          return a - b;
        }
      ''',
      moduleName2: 'advanced-calculator',
      code2: '''
        import { add, subtract } from 'calculator';
        
        export function calculate(operation, a, b) {
          switch (operation) {
            case 'add':
              return add(a, b);
            case 'subtract':
              return subtract(a, b);
            default:
              throw new Error('Unknown operation');
          }
        }
      ''',
    ));

    // Test 6: Named exports
    results.add(await testNamedExports(
      moduleName: 'date-utils',
      code: '''
        export function getCurrentDate() {
          return new Date().toISOString().split('T')[0];
        }
        
        export function formatTimestamp(date) {
          return date.toISOString();
        }
      ''',
      functionName: 'getCurrentDate',
    ));

    // Test 7: Dynamic import in module
    results.add(await testDynamicImportInModule(
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
    results.add(await testClearModules());

    return results;
  }
}
