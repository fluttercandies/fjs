import 'package:fjs/fjs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

/// Screen to test JsError types and error handling
class ErrorApiScreen extends StatefulWidget {
  const ErrorApiScreen({super.key});

  @override
  State<ErrorApiScreen> createState() => _ErrorApiScreenState();
}

class _ErrorApiScreenState extends State<ErrorApiScreen> {
  JsAsyncRuntime? _runtime;
  JsAsyncContext? _context;
  JsEngine? _engine;
  // ignore: unused_field - used for internal state tracking
  bool _isInitialized = false;
  bool _isLoading = false;

  final Map<String, _TestResult> _testResults = {};

  @override
  void initState() {
    super.initState();
    _initializeEngine();
  }

  Future<void> _initializeEngine() async {
    setState(() => _isLoading = true);
    try {
      _runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.all(),
      );
      _context = await JsAsyncContext.from(rt: _runtime!);
      _engine = JsEngine(_context!);
      await _engine!.init();
      setState(() => _isInitialized = true);
    } catch (e) {
      if (kDebugMode) print('Failed to initialize engine: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runTest(String testId, Future<dynamic> Function() test) async {
    setState(() {
      _testResults[testId] = _TestResult(isLoading: true);
    });
    try {
      final result = await test();
      setState(() {
        _testResults[testId] = _TestResult(
          isSuccess: true,
          result: result,
        );
      });
    } catch (e) {
      setState(() {
        _testResults[testId] = _TestResult(
          isSuccess: false,
          error: e.toString(),
        );
      });
    }
  }

  @override
  void dispose() {
    _engine?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Handling Tests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _engine?.dispose();
              setState(() {
                _isInitialized = false;
                _testResults.clear();
              });
              await _initializeEngine();
            },
            tooltip: 'Reinitialize',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Error Types
                  const ApiTestSection(
                    title: 'JsError Types',
                    description: 'Create and inspect different error types',
                    icon: Icons.error_outline,
                  ),
                  _buildErrorTypesTests(),

                  // Runtime Errors
                  const ApiTestSection(
                    title: 'Runtime Errors',
                    description: 'Test JavaScript runtime errors',
                    icon: Icons.warning,
                  ),
                  _buildRuntimeErrorTests(),

                  // Syntax Errors
                  const ApiTestSection(
                    title: 'Syntax Errors',
                    description: 'Test JavaScript syntax errors',
                    icon: Icons.code_off,
                  ),
                  _buildSyntaxErrorTests(),

                  // JsResult
                  const ApiTestSection(
                    title: 'JsResult Handling',
                    description: 'Test JsResult ok/err pattern',
                    icon: Icons.check_box,
                  ),
                  _buildResultTests(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorTypesTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'JsError.promise()',
          subtitle: 'Promise-related errors',
          icon: Icons.pending,
          isSuccess: _testResults['error_promise']?.isSuccess,
          isLoading: _testResults['error_promise']?.isLoading ?? false,
          result: _testResults['error_promise']?.result,
          error: _testResults['error_promise']?.error,
          onRun: () => _runTest('error_promise', () async {
            const error = JsError.promise('Promise rejected with error');
            return {
              'error': error.toString(),
              'code': error.code(),
              'isRecoverable': error.isRecoverable(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsError.module()',
          subtitle: 'Module-related errors',
          icon: Icons.view_module,
          isSuccess: _testResults['error_module']?.isSuccess,
          isLoading: _testResults['error_module']?.isLoading ?? false,
          result: _testResults['error_module']?.result,
          error: _testResults['error_module']?.error,
          onRun: () => _runTest('error_module', () async {
            const error = JsError.module(
              module: 'my-module',
              method: 'doSomething',
              message: 'Module not found',
            );
            return {
              'error': error.toString(),
              'code': error.code(),
              'isRecoverable': error.isRecoverable(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsError.context()',
          subtitle: 'Context attachment errors',
          icon: Icons.layers,
          isSuccess: _testResults['error_context']?.isSuccess,
          isLoading: _testResults['error_context']?.isLoading ?? false,
          result: _testResults['error_context']?.result,
          error: _testResults['error_context']?.error,
          onRun: () => _runTest('error_context', () async {
            const error = JsError.context('Failed to attach global object');
            return {
              'error': error.toString(),
              'code': error.code(),
              'isRecoverable': error.isRecoverable(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsError.io()',
          subtitle: 'File I/O errors',
          icon: Icons.folder,
          isSuccess: _testResults['error_io']?.isSuccess,
          isLoading: _testResults['error_io']?.isLoading ?? false,
          result: _testResults['error_io']?.result,
          error: _testResults['error_io']?.error,
          onRun: () => _runTest('error_io', () async {
            const error = JsError.io(
              path: '/path/to/file.js',
              message: 'File not found',
            );
            return {
              'error': error.toString(),
              'code': error.code(),
              'isRecoverable': error.isRecoverable(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsError.conversion()',
          subtitle: 'Type conversion errors',
          icon: Icons.swap_horiz,
          isSuccess: _testResults['error_conversion']?.isSuccess,
          isLoading: _testResults['error_conversion']?.isLoading ?? false,
          result: _testResults['error_conversion']?.result,
          error: _testResults['error_conversion']?.error,
          onRun: () => _runTest('error_conversion', () async {
            const error = JsError.conversion(
              from: 'string',
              to: 'number',
              message: 'Cannot convert "abc" to number',
            );
            return {
              'error': error.toString(),
              'code': error.code(),
              'isRecoverable': error.isRecoverable(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsError.timeout()',
          subtitle: 'Timeout errors',
          icon: Icons.timer_off,
          isSuccess: _testResults['error_timeout']?.isSuccess,
          isLoading: _testResults['error_timeout']?.isLoading ?? false,
          result: _testResults['error_timeout']?.result,
          error: _testResults['error_timeout']?.error,
          onRun: () => _runTest('error_timeout', () async {
            final error = JsError.timeout(
              operation: 'eval',
              timeoutMs: BigInt.from(5000),
            );
            return {
              'error': error.toString(),
              'code': error.code(),
              'isRecoverable': error.isRecoverable(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsError.memoryLimit()',
          subtitle: 'Memory limit exceeded errors',
          icon: Icons.memory,
          isSuccess: _testResults['error_memory']?.isSuccess,
          isLoading: _testResults['error_memory']?.isLoading ?? false,
          result: _testResults['error_memory']?.result,
          error: _testResults['error_memory']?.error,
          onRun: () => _runTest('error_memory', () async {
            final error = JsError.memoryLimit(
              current: BigInt.from(150 * 1024 * 1024),
              limit: BigInt.from(100 * 1024 * 1024),
            );
            return {
              'error': error.toString(),
              'code': error.code(),
              'isRecoverable': error.isRecoverable(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsError.syntax()',
          subtitle: 'Syntax errors with location',
          icon: Icons.code_off,
          isSuccess: _testResults['error_syntax']?.isSuccess,
          isLoading: _testResults['error_syntax']?.isLoading ?? false,
          result: _testResults['error_syntax']?.result,
          error: _testResults['error_syntax']?.error,
          onRun: () => _runTest('error_syntax', () async {
            const error = JsError.syntax(
              line: 10,
              column: 5,
              message: 'Unexpected token "}"',
            );
            return {
              'error': error.toString(),
              'code': error.code(),
              'isRecoverable': error.isRecoverable(),
            };
          }),
        ),
        ApiTestCard(
          title: 'Other Error Types',
          subtitle: 'Test remaining error types',
          icon: Icons.error,
          isSuccess: _testResults['error_others']?.isSuccess,
          isLoading: _testResults['error_others']?.isLoading ?? false,
          result: _testResults['error_others']?.result,
          error: _testResults['error_others']?.error,
          onRun: () => _runTest('error_others', () async {
            final errors = {
              'runtime': const JsError.runtime('Uncaught ReferenceError'),
              'generic': const JsError.generic('Unknown error occurred'),
              'engine': const JsError.engine('Engine not initialized'),
              'bridge': const JsError.bridge('Bridge communication failed'),
              'storage': const JsError.storage('Storage initialization failed'),
              'stackOverflow':
                  const JsError.stackOverflow('Maximum call stack exceeded'),
              'reference': const JsError.reference('x is not defined'),
              'type': const JsError.type('Cannot read property of undefined'),
              'cancelled':
                  const JsError.cancelled('Operation cancelled by user'),
            };

            final results = <String, Map<String, dynamic>>{};
            for (final entry in errors.entries) {
              results[entry.key] = {
                'error': entry.value.toString(),
                'code': entry.value.code(),
                'isRecoverable': entry.value.isRecoverable(),
              };
            }
            return results;
          }),
        ),
      ],
    );
  }

  Widget _buildRuntimeErrorTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'ReferenceError',
          subtitle: 'Access undefined variable',
          icon: Icons.help_outline,
          isSuccess: _testResults['runtime_reference']?.isSuccess,
          isLoading: _testResults['runtime_reference']?.isLoading ?? false,
          result: _testResults['runtime_reference']?.result,
          error: _testResults['runtime_reference']?.error,
          onRun: () => _runTest('runtime_reference', () async {
            if (_engine == null) throw 'Engine not initialized';
            try {
              await _engine!.eval(JsCode.code('undefinedVariable'));
              return {'error': 'Expected error was not thrown'};
            } catch (e) {
              return {
                'caught': true,
                'errorType': e.runtimeType.toString(),
                'message': e.toString(),
              };
            }
          }),
        ),
        ApiTestCard(
          title: 'TypeError',
          subtitle: 'Call non-function',
          icon: Icons.do_not_disturb,
          isSuccess: _testResults['runtime_type']?.isSuccess,
          isLoading: _testResults['runtime_type']?.isLoading ?? false,
          result: _testResults['runtime_type']?.result,
          error: _testResults['runtime_type']?.error,
          onRun: () => _runTest('runtime_type', () async {
            if (_engine == null) throw 'Engine not initialized';
            try {
              await _engine!.eval(JsCode.code('null.foo()'));
              return {'error': 'Expected error was not thrown'};
            } catch (e) {
              return {
                'caught': true,
                'errorType': e.runtimeType.toString(),
                'message': e.toString(),
              };
            }
          }),
        ),
        ApiTestCard(
          title: 'Promise Rejection',
          subtitle: 'Unhandled promise rejection',
          icon: Icons.cancel,
          isSuccess: _testResults['runtime_promise']?.isSuccess,
          isLoading: _testResults['runtime_promise']?.isLoading ?? false,
          result: _testResults['runtime_promise']?.result,
          error: _testResults['runtime_promise']?.error,
          onRun: () => _runTest('runtime_promise', () async {
            if (_engine == null) throw 'Engine not initialized';
            try {
              await _engine!.eval(JsCode.code('''
                (async () => {
                  throw new Error("Intentional rejection");
                })()
              '''));
              return {'error': 'Expected error was not thrown'};
            } catch (e) {
              return {
                'caught': true,
                'errorType': e.runtimeType.toString(),
                'message': e.toString(),
              };
            }
          }),
        ),
        ApiTestCard(
          title: 'Custom Error Throw',
          subtitle: 'Throw custom error object',
          icon: Icons.sports_handball,
          isSuccess: _testResults['runtime_custom']?.isSuccess,
          isLoading: _testResults['runtime_custom']?.isLoading ?? false,
          result: _testResults['runtime_custom']?.result,
          error: _testResults['runtime_custom']?.error,
          onRun: () => _runTest('runtime_custom', () async {
            if (_engine == null) throw 'Engine not initialized';
            try {
              await _engine!.eval(JsCode.code('''
                class CustomError extends Error {
                  constructor(message, code) {
                    super(message);
                    this.code = code;
                  }
                }
                throw new CustomError("Something went wrong", 500);
              '''));
              return {'error': 'Expected error was not thrown'};
            } catch (e) {
              return {
                'caught': true,
                'errorType': e.runtimeType.toString(),
                'message': e.toString(),
              };
            }
          }),
        ),
      ],
    );
  }

  Widget _buildSyntaxErrorTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'Missing Bracket',
          subtitle: 'Syntax error: missing closing bracket',
          icon: Icons.code_off,
          isSuccess: _testResults['syntax_bracket']?.isSuccess,
          isLoading: _testResults['syntax_bracket']?.isLoading ?? false,
          result: _testResults['syntax_bracket']?.result,
          error: _testResults['syntax_bracket']?.error,
          onRun: () => _runTest('syntax_bracket', () async {
            if (_engine == null) throw 'Engine not initialized';
            try {
              await _engine!.eval(JsCode.code('function test( { }'));
              return {'error': 'Expected syntax error was not thrown'};
            } catch (e) {
              return {
                'caught': true,
                'errorType': e.runtimeType.toString(),
                'message': e.toString(),
              };
            }
          }),
        ),
        ApiTestCard(
          title: 'Unexpected Token',
          subtitle: 'Syntax error: unexpected token',
          icon: Icons.error_outline,
          isSuccess: _testResults['syntax_token']?.isSuccess,
          isLoading: _testResults['syntax_token']?.isLoading ?? false,
          result: _testResults['syntax_token']?.result,
          error: _testResults['syntax_token']?.error,
          onRun: () => _runTest('syntax_token', () async {
            if (_engine == null) throw 'Engine not initialized';
            try {
              await _engine!.eval(JsCode.code('let x = @@@'));
              return {'error': 'Expected syntax error was not thrown'};
            } catch (e) {
              return {
                'caught': true,
                'errorType': e.runtimeType.toString(),
                'message': e.toString(),
              };
            }
          }),
        ),
        ApiTestCard(
          title: 'Invalid JSON',
          subtitle: 'JSON parse error',
          icon: Icons.data_object,
          isSuccess: _testResults['syntax_json']?.isSuccess,
          isLoading: _testResults['syntax_json']?.isLoading ?? false,
          result: _testResults['syntax_json']?.result,
          error: _testResults['syntax_json']?.error,
          onRun: () => _runTest('syntax_json', () async {
            if (_engine == null) throw 'Engine not initialized';
            try {
              await _engine!.eval(JsCode.code('JSON.parse("{invalid}")'));
              return {'error': 'Expected error was not thrown'};
            } catch (e) {
              return {
                'caught': true,
                'errorType': e.runtimeType.toString(),
                'message': e.toString(),
              };
            }
          }),
        ),
      ],
    );
  }

  Widget _buildResultTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'JsResult.ok()',
          subtitle: 'Test successful result',
          icon: Icons.check_circle,
          isSuccess: _testResults['result_ok']?.isSuccess,
          isLoading: _testResults['result_ok']?.isLoading ?? false,
          result: _testResults['result_ok']?.result,
          error: _testResults['result_ok']?.error,
          onRun: () => _runTest('result_ok', () async {
            const result = JsResult.ok(JsValue.string('Success!'));
            return {
              'isOk': result.isOk,
              'isErr': result.isErr,
              'value': result.ok.value,
            };
          }),
        ),
        ApiTestCard(
          title: 'JsResult.err()',
          subtitle: 'Test error result',
          icon: Icons.error,
          isSuccess: _testResults['result_err']?.isSuccess,
          isLoading: _testResults['result_err']?.isLoading ?? false,
          result: _testResults['result_err']?.result,
          error: _testResults['result_err']?.error,
          onRun: () => _runTest('result_err', () async {
            const result =
                JsResult.err(JsError.generic('Something went wrong'));
            return {
              'isOk': result.isOk,
              'isErr': result.isErr,
              'error': result.err.toString(),
              'errorCode': result.err.code(),
            };
          }),
        ),
        ApiTestCard(
          title: 'Context eval() Result',
          subtitle: 'Test actual context evaluation result',
          icon: Icons.science,
          isSuccess: _testResults['result_context']?.isSuccess,
          isLoading: _testResults['result_context']?.isLoading ?? false,
          result: _testResults['result_context']?.result,
          error: _testResults['result_context']?.error,
          onRun: () => _runTest('result_context', () async {
            if (_context == null) throw 'Context not initialized';

            // Test successful eval
            final successResult = await _context!.eval(code: '1 + 2 + 3');

            // Test error eval
            final errorResult = await _context!.eval(code: 'undefinedVar');

            return {
              'success': {
                'isOk': successResult.isOk,
                'value': successResult.isOk ? successResult.ok.value : null,
              },
              'error': {
                'isErr': errorResult.isErr,
                'error': errorResult.isErr ? errorResult.err.toString() : null,
              },
            };
          }),
        ),
      ],
    );
  }
}

class _TestResult {
  final bool isLoading;
  final bool? isSuccess;
  final dynamic result;
  final String? error;

  _TestResult({
    this.isLoading = false,
    this.isSuccess,
    this.result,
    this.error,
  });
}
