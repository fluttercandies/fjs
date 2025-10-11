import 'dart:async';
import 'package:fjs/fjs.dart';
import 'package:flutter/foundation.dart';

class FjsService extends ChangeNotifier {
  JsEngine? _engine;
  JsAsyncRuntime? _runtime;
  JsAsyncContext? _context;
  bool _isInitialized = false;
  bool _isExecuting = false;
  String? _lastError;
  dynamic _lastExecutionResult;

  bool get isInitialized => _isInitialized;
  bool get isExecuting => _isExecuting;
  String? get lastError => _lastError;
  dynamic get lastExecutionResult => _lastExecutionResult;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _runtime = await JsAsyncRuntime.withOptions(builtin: JsBuiltinOptions.all());
      _context = await JsAsyncContext.from(rt: _runtime!);
      _engine = JsEngine(_context!);
      
      await _engine!.init();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to initialize FJS service: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<dynamic> executeCode(String code) async {
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
    notifyListeners();

    try {
      final result = await _engine!.eval(JsCode.code(code));
      _lastExecutionResult = result;
      return result;
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _engine?.dispose();
    super.dispose();
  }
}
