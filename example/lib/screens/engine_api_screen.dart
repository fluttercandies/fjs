
import 'package:fjs/fjs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

/// Screen to test JsEngine APIs - the main high-level API
class EngineApiScreen extends StatefulWidget {
  const EngineApiScreen({super.key});

  @override
  State<EngineApiScreen> createState() => _EngineApiScreenState();
}

class _EngineApiScreenState extends State<EngineApiScreen> {
  JsAsyncRuntime? _runtime;
  JsAsyncContext? _context;
  JsEngine? _engine;
  bool _isInitialized = false;
  bool _isLoading = false;

  final Map<String, _TestResult> _testResults = {};
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeEngine();
    _codeController.text = '2 + 2';
  }

  Future<void> _initializeEngine() async {
    setState(() => _isLoading = true);
    try {
      _runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.all(),
      );
      _context = await JsAsyncContext.from(runtime: _runtime!);
      _engine = JsEngine(context: _context!);
      await _engine!.init(
        bridge: (value) async {
          if (kDebugMode) {
            print('Bridge call received: ${value.value}');
          }
          return JsResult.ok(JsValue.string('Response from Dart: ${value.value}'));
        },
      );
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
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JsEngine API Tests'),
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
            tooltip: 'Reinitialize Engine',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildStatusBar(),

                  // Engine Status
                  const ApiTestSection(
                    title: 'Engine Status',
                    description: 'Check engine state',
                    icon: Icons.info,
                  ),
                  _buildStatusTests(),

                  // Code Evaluation
                  const ApiTestSection(
                    title: 'Code Evaluation',
                    description: 'Test eval() and options',
                    icon: Icons.code,
                  ),
                  _buildEvalTests(),

                  // Module Management
                  const ApiTestSection(
                    title: 'Module Management',
                    description: 'Test module declaration and evaluation',
                    icon: Icons.view_module,
                  ),
                  _buildModuleTests(),

                  // Bridge Communication
                  const ApiTestSection(
                    title: 'Bridge Communication',
                    description: 'Test Dart-JS bridge',
                    icon: Icons.sync_alt,
                  ),
                  _buildBridgeTests(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isInitialized ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isInitialized ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isInitialized ? Icons.check_circle : Icons.warning,
            color: _isInitialized ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isInitialized ? 'Engine Ready' : 'Engine Not Ready',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isInitialized
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                if (_engine != null)
                  Text(
                    'running: ${_engine!.running}, disposed: ${_engine!.disposed}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isInitialized
                          ? Colors.green.shade600
                          : Colors.orange.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'engine.running',
          subtitle: 'Check if engine is running (initialized)',
          icon: Icons.power_settings_new,
          isSuccess: _testResults['running_state']?.isSuccess,
          isLoading: _testResults['running_state']?.isLoading ?? false,
          result: _testResults['running_state']?.result,
          error: _testResults['running_state']?.error,
          onRun: () => _runTest('running_state', () async {
            return {'running': _engine?.running ?? false};
          }),
        ),
        ApiTestCard(
          title: 'engine.running',
          subtitle: 'Check if engine is running',
          icon: Icons.play_circle,
          isSuccess: _testResults['running']?.isSuccess,
          isLoading: _testResults['running']?.isLoading ?? false,
          result: _testResults['running']?.result,
          error: _testResults['running']?.error,
          onRun: () => _runTest('running', () async {
            return {'running': _engine?.running ?? false};
          }),
        ),
        ApiTestCard(
          title: 'engine.disposed',
          subtitle: 'Check if engine is disposed',
          icon: Icons.delete,
          isSuccess: _testResults['disposed']?.isSuccess,
          isLoading: _testResults['disposed']?.isLoading ?? false,
          result: _testResults['disposed']?.result,
          error: _testResults['disposed']?.error,
          onRun: () => _runTest('disposed', () async {
            return {'disposed': _engine?.disposed ?? true};
          }),
        ),
      ],
    );
  }

  Widget _buildEvalTests() {
    return Column(
      children: [
        // Custom code input
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: CodeEditorWidget(
            controller: _codeController,
            hintText: '// Enter JavaScript code to evaluate',
            height: 120,
          ),
        ),
        ApiTestCard(
          title: 'eval(JsCode.code())',
          subtitle: 'Evaluate inline JavaScript code',
          icon: Icons.play_arrow,
          isSuccess: _testResults['eval_code']?.isSuccess,
          isLoading: _testResults['eval_code']?.isLoading ?? false,
          result: _testResults['eval_code']?.result,
          error: _testResults['eval_code']?.error,
          onRun: () => _runTest('eval_code', () async {
            if (_engine == null) throw 'Engine not initialized';
            final result = await _engine!.eval(
              source: JsCode.code(_codeController.text),
            );
            return {
              'code': _codeController.text,
              'result': result.value,
              'typeName': result.typeName(),
            };
          }),
        ),
        ApiTestCard(
          title: 'eval() with JsEvalOptions',
          subtitle: 'Test different evaluation options',
          icon: Icons.tune,
          isSuccess: _testResults['eval_options']?.isSuccess,
          isLoading: _testResults['eval_options']?.isLoading ?? false,
          result: _testResults['eval_options']?.result,
          error: _testResults['eval_options']?.error,
          onRun: () => _runTest('eval_options', () async {
            if (_engine == null) throw 'Engine not initialized';
            
            // Test with strict mode
            final strictResult = await _engine!.eval(
              source: JsCode.code('"use strict"; let x = 10; x * 2'),
              options: JsEvalOptions(strict: true),
            );
            
            // Test with global scope
            final globalResult = await _engine!.eval(
              source: JsCode.code('globalThis.myGlobal = 42; globalThis.myGlobal'),
              options: JsEvalOptions(global: true),
            );
            
            return {
              'strictMode': {
                'result': strictResult.value,
              },
              'globalScope': {
                'result': globalResult.value,
              },
              'optionPresets': {
                'defaults': JsEvalOptions.defaults().toString(),
                'module': JsEvalOptions.module().toString(),
                'withPromise': JsEvalOptions.withPromise().toString(),
              },
            };
          }),
        ),
        ApiTestCard(
          title: 'eval() with Promises',
          subtitle: 'Test async JavaScript code',
          icon: Icons.hourglass_empty,
          isSuccess: _testResults['eval_promise']?.isSuccess,
          isLoading: _testResults['eval_promise']?.isLoading ?? false,
          result: _testResults['eval_promise']?.result,
          error: _testResults['eval_promise']?.error,
          onRun: () => _runTest('eval_promise', () async {
            if (_engine == null) throw 'Engine not initialized';
            final result = await _engine!.eval(
              source: JsCode.code('''
                (async () => {
                  const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));
                  await delay(100);
                  return "Async result after 100ms";
                })()
              '''),
            );
            return {
              'result': result.value,
            };
          }),
        ),
        ApiTestCard(
          title: 'eval() Complex Expressions',
          subtitle: 'Test various JavaScript expressions',
          icon: Icons.calculate,
          isSuccess: _testResults['eval_complex']?.isSuccess,
          isLoading: _testResults['eval_complex']?.isLoading ?? false,
          result: _testResults['eval_complex']?.result,
          error: _testResults['eval_complex']?.error,
          onRun: () => _runTest('eval_complex', () async {
            if (_engine == null) throw 'Engine not initialized';
            
            final expressions = {
              'math': 'Math.sqrt(16) + Math.pow(2, 3)',
              'string': '"Hello".split("").reverse().join("")',
              'array': '[1,2,3].map(x => x * 2).filter(x => x > 2)',
              'object': '({name: "FJS", version: "1.0", features: ["fast", "safe"]})',
              'date': 'new Date().toISOString()',
              'json': 'JSON.stringify({a: 1, b: [2, 3]})',
            };
            
            final results = <String, dynamic>{};
            for (final entry in expressions.entries) {
              final result = await _engine!.eval(source: JsCode.code(entry.value));
              results[entry.key] = {
                'expression': entry.value,
                'result': result.value,
              };
            }
            return results;
          }),
        ),
      ],
    );
  }

  Widget _buildModuleTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'declareNewModule()',
          subtitle: 'Declare a new module',
          icon: Icons.add_box,
          isSuccess: _testResults['declare_module']?.isSuccess,
          isLoading: _testResults['declare_module']?.isLoading ?? false,
          result: _testResults['declare_module']?.result,
          error: _testResults['declare_module']?.error,
          onRun: () => _runTest('declare_module', () async {
            if (_engine == null) throw 'Engine not initialized';
            await _engine!.declareNewModule(
              module: JsModule(
                name: 'test-math',
                source: JsCode.code('''
                  export function add(a, b) { return a + b; }
                  export function multiply(a, b) { return a * b; }
                  export const PI = 3.14159;
                '''),
              ),
            );
            return {'status': 'Module "test-math" declared successfully'};
          }),
        ),
        ApiTestCard(
          title: 'declareNewModules()',
          subtitle: 'Declare multiple modules at once',
          icon: Icons.library_add,
          isSuccess: _testResults['declare_modules']?.isSuccess,
          isLoading: _testResults['declare_modules']?.isLoading ?? false,
          result: _testResults['declare_modules']?.result,
          error: _testResults['declare_modules']?.error,
          onRun: () => _runTest('declare_modules', () async {
            if (_engine == null) throw 'Engine not initialized';
            await _engine!.declareNewModules(
              modules: [
              JsModule(
                name: 'string-utils',
                source: JsCode.code('''
                  export function reverse(s) { return s.split('').reverse().join(''); }
                  export function capitalize(s) { return s.charAt(0).toUpperCase() + s.slice(1); }
                '''),
              ),
              JsModule(
                name: 'array-utils',
                source: JsCode.code('''
                  export function sum(arr) { return arr.reduce((a, b) => a + b, 0); }
                  export function unique(arr) { return [...new Set(arr)]; }
                '''),
              ),
            ],
            );
            return {'status': 'Modules declared: string-utils, array-utils'};
          }),
        ),
        ApiTestCard(
          title: 'getDeclaredModules()',
          subtitle: 'Get list of declared modules',
          icon: Icons.list,
          isSuccess: _testResults['get_modules']?.isSuccess,
          isLoading: _testResults['get_modules']?.isLoading ?? false,
          result: _testResults['get_modules']?.result,
          error: _testResults['get_modules']?.error,
          onRun: () => _runTest('get_modules', () async {
            if (_engine == null) throw 'Engine not initialized';
            final modules = await _engine!.getDeclaredModules();
            return {
              'modules': modules,
              'count': modules.length,
            };
          }),
        ),
        ApiTestCard(
          title: 'isModuleDeclared()',
          subtitle: 'Check if a module is declared',
          icon: Icons.search,
          isSuccess: _testResults['is_module_declared']?.isSuccess,
          isLoading: _testResults['is_module_declared']?.isLoading ?? false,
          result: _testResults['is_module_declared']?.result,
          error: _testResults['is_module_declared']?.error,
          onRun: () => _runTest('is_module_declared', () async {
            if (_engine == null) throw 'Engine not initialized';
            final exists = await _engine!.isModuleDeclared(moduleName: 'test-math');
            final notExists = await _engine!.isModuleDeclared(moduleName: 'non-existent');
            return {
              'test-math': exists,
              'non-existent': notExists,
            };
          }),
        ),
        ApiTestCard(
          title: 'evaluateModule()',
          subtitle: 'Evaluate a module directly',
          icon: Icons.play_circle_fill,
          isSuccess: _testResults['evaluate_module']?.isSuccess,
          isLoading: _testResults['evaluate_module']?.isLoading ?? false,
          result: _testResults['evaluate_module']?.result,
          error: _testResults['evaluate_module']?.error,
          onRun: () => _runTest('evaluate_module', () async {
            if (_engine == null) throw 'Engine not initialized';
            final result = await _engine!.evaluateModule(
              module: JsModule(
                name: 'eval-test',
                source: JsCode.code('''
                  export default {
                    message: "Hello from module",
                    timestamp: Date.now(),
                  };
                '''),
              ),
            );
            return {
              'result': result.value,
            };
          }),
        ),
        ApiTestCard(
          title: 'Use Declared Module',
          subtitle: 'Import and use a declared module',
          icon: Icons.integration_instructions,
          isSuccess: _testResults['use_module']?.isSuccess,
          isLoading: _testResults['use_module']?.isLoading ?? false,
          result: _testResults['use_module']?.result,
          error: _testResults['use_module']?.error,
          onRun: () => _runTest('use_module', () async {
            if (_engine == null) throw 'Engine not initialized';
            
            // First make sure module is declared
            await _engine!.declareNewModule(
              module: JsModule(
                name: 'calc-module',
                source: JsCode.code('''
                  export function calculate(a, b, op) {
                    switch(op) {
                      case '+': return a + b;
                      case '-': return a - b;
                      case '*': return a * b;
                      case '/': return a / b;
                      default: throw new Error('Unknown operation');
                    }
                  }
                '''),
              ),
            );
            
            // Then use it via dynamic import
            final result = await _engine!.eval(
              source: JsCode.code('''
                (async () => {
                  const { calculate } = await import('calc-module');
                  return {
                    add: calculate(10, 5, '+'),
                    sub: calculate(10, 5, '-'),
                    mul: calculate(10, 5, '*'),
                    div: calculate(10, 5, '/'),
                  };
                })()
              '''),
            );
            return result.value;
          }),
        ),
        ApiTestCard(
          title: 'clearNewModules()',
          subtitle: 'Clear all declared modules',
          icon: Icons.delete_sweep,
          isSuccess: _testResults['clear_modules']?.isSuccess,
          isLoading: _testResults['clear_modules']?.isLoading ?? false,
          result: _testResults['clear_modules']?.result,
          error: _testResults['clear_modules']?.error,
          onRun: () => _runTest('clear_modules', () async {
            if (_engine == null) throw 'Engine not initialized';
            await _engine!.clearNewModules();
            final modules = await _engine!.getDeclaredModules();
            return {
              'status': 'All modules cleared',
              'remainingModules': modules,
            };
          }),
        ),
      ],
    );
  }

  Widget _buildBridgeTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'Bridge Call from JS',
          subtitle: 'Call Dart function from JavaScript',
          icon: Icons.call_made,
          isSuccess: _testResults['bridge_call']?.isSuccess,
          isLoading: _testResults['bridge_call']?.isLoading ?? false,
          result: _testResults['bridge_call']?.result,
          error: _testResults['bridge_call']?.error,
          onRun: () => _runTest('bridge_call', () async {
            if (_engine == null) throw 'Engine not initialized';
            final result = await _engine!.eval(
              source: JsCode.code('''
                (async () => {
                  const response = await fjs.bridge_call("Hello from JavaScript!");
                  return {
                    sent: "Hello from JavaScript!",
                    received: response,
                  };
                })()
              '''),
            );
            return result.value;
          }),
        ),
        ApiTestCard(
          title: 'Bridge with Complex Data',
          subtitle: 'Pass complex objects through bridge',
          icon: Icons.data_object,
          isSuccess: _testResults['bridge_complex']?.isSuccess,
          isLoading: _testResults['bridge_complex']?.isLoading ?? false,
          result: _testResults['bridge_complex']?.result,
          error: _testResults['bridge_complex']?.error,
          onRun: () => _runTest('bridge_complex', () async {
            if (_engine == null) throw 'Engine not initialized';
            final result = await _engine!.eval(
              source: JsCode.code('''
                (async () => {
                  const data = {
                    type: "request",
                    payload: {
                      items: [1, 2, 3],
                      metadata: { timestamp: Date.now() }
                    }
                  };
                  const response = await fjs.bridge_call(JSON.stringify(data));
                  return { sent: data, response };
                })()
              '''),
            );
            return result.value;
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
