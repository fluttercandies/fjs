import 'dart:async';
import 'dart:convert';

import 'package:fjs/fjs.dart';
import 'package:flutter/foundation.dart';

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
      _runtime =
          await JsAsyncRuntime.withOptions(builtin: JsBuiltinOptions.all());
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
      
      _lastExecutionResult =
          JsonEncoder.withIndent('  ').convert(result.value);
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
    await _engine!.evaluateModule(module: JsModule(
        name: moduleName,
        source: JsCode.code(code),
      ),
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

  @override
  void dispose() {
    _engine?.dispose();
    super.dispose();
  }
}
