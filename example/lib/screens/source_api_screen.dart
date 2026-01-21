import 'package:fjs/fjs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

/// Screen to test JsCode and JsModule source APIs
class SourceApiScreen extends StatefulWidget {
  const SourceApiScreen({super.key});

  @override
  State<SourceApiScreen> createState() => _SourceApiScreenState();
}

class _SourceApiScreenState extends State<SourceApiScreen> {
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
      _engine = JsEngine(context: _context!);
      await _engine!.initWithoutBridge();
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
        title: const Text('Source API Tests'),
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
                  // JsCode
                  const ApiTestSection(
                    title: 'JsCode',
                    description: 'Test JavaScript code source types',
                    icon: Icons.code,
                  ),
                  _buildJsCodeTests(),

                  // JsModule
                  const ApiTestSection(
                    title: 'JsModule',
                    description: 'Test module creation methods',
                    icon: Icons.view_module,
                  ),
                  _buildJsModuleTests(),

                  // JsEvalOptions
                  const ApiTestSection(
                    title: 'JsEvalOptions',
                    description: 'Test evaluation options',
                    icon: Icons.tune,
                  ),
                  _buildEvalOptionsTests(),

                  // JsBuiltinOptions
                  const ApiTestSection(
                    title: 'JsBuiltinOptions',
                    description: 'Test builtin module configurations',
                    icon: Icons.widgets,
                  ),
                  _buildBuiltinOptionsTests(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildJsCodeTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'JsCode.code()',
          subtitle: 'Create code from inline string',
          icon: Icons.text_snippet,
          isSuccess: _testResults['code_inline']?.isSuccess,
          isLoading: _testResults['code_inline']?.isLoading ?? false,
          result: _testResults['code_inline']?.result,
          error: _testResults['code_inline']?.error,
          onRun: () => _runTest('code_inline', () async {
            const code = JsCode.code('const x = 42; x * 2');
            if (_engine == null) throw 'Engine not initialized';
            final result = await _engine!.eval(source: code);
            return {
              'isCode': code.isCode(),
              'isPath': code.isPath(),
              'isBytes': code.isBytes(),
              'result': result.value,
            };
          }),
        ),
        ApiTestCard(
          title: 'JsCode.bytes()',
          subtitle: 'Create code from bytes',
          icon: Icons.data_array,
          isSuccess: _testResults['code_bytes']?.isSuccess,
          isLoading: _testResults['code_bytes']?.isLoading ?? false,
          result: _testResults['code_bytes']?.result,
          error: _testResults['code_bytes']?.error,
          onRun: () => _runTest('code_bytes', () async {
            final codeString = 'const greeting = "Hello from bytes!"; greeting';
            final bytes = Uint8List.fromList(codeString.codeUnits);
            final code = JsCode.bytes(bytes);

            if (_engine == null) throw 'Engine not initialized';
            final result = await _engine!.eval(source: code);
            return {
              'isCode': code.isCode(),
              'isPath': code.isPath(),
              'isBytes': code.isBytes(),
              'bytesLength': bytes.length,
              'result': result.value,
            };
          }),
        ),
        ApiTestCard(
          title: 'JsCode type checks',
          subtitle: 'Test isCode(), isPath(), isBytes()',
          icon: Icons.check_box,
          isSuccess: _testResults['code_type_checks']?.isSuccess,
          isLoading: _testResults['code_type_checks']?.isLoading ?? false,
          result: _testResults['code_type_checks']?.result,
          error: _testResults['code_type_checks']?.error,
          onRun: () => _runTest('code_type_checks', () async {
            const codeVariant = JsCode.code('1 + 1');
            const pathVariant = JsCode.path('/path/to/file.js');
            final bytesVariant = JsCode.bytes(Uint8List.fromList([49, 43, 49]));

            return {
              'codeVariant': {
                'isCode': codeVariant.isCode(),
                'isPath': codeVariant.isPath(),
                'isBytes': codeVariant.isBytes(),
              },
              'pathVariant': {
                'isCode': pathVariant.isCode(),
                'isPath': pathVariant.isPath(),
                'isBytes': pathVariant.isBytes(),
              },
              'bytesVariant': {
                'isCode': bytesVariant.isCode(),
                'isPath': bytesVariant.isPath(),
                'isBytes': bytesVariant.isBytes(),
              },
            };
          }),
        ),
      ],
    );
  }

  Widget _buildJsModuleTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'JsModule()',
          subtitle: 'Create module with name and source',
          icon: Icons.add_box,
          isSuccess: _testResults['module_new']?.isSuccess,
          isLoading: _testResults['module_new']?.isLoading ?? false,
          result: _testResults['module_new']?.result,
          error: _testResults['module_new']?.error,
          onRun: () => _runTest('module_new', () async {
            final module = JsModule(
              name: 'test-module',
              source: JsCode.code('export const value = 42;'),
            );
            if (_engine == null) throw 'Engine not initialized';
            await _engine!.declareNewModule(module: module);
            final isDeclared = await _engine!.isModuleDeclared(moduleName: 'test-module');
            return {
              'moduleName': module.name,
              'isDeclared': isDeclared,
            };
          }),
        ),
        ApiTestCard(
          title: 'JsModule.fromCode()',
          subtitle: 'Create module from code string',
          icon: Icons.text_snippet,
          isSuccess: _testResults['module_from_code']?.isSuccess,
          isLoading: _testResults['module_from_code']?.isLoading ?? false,
          result: _testResults['module_from_code']?.result,
          error: _testResults['module_from_code']?.error,
          onRun: () => _runTest('module_from_code', () async {
            final module = JsModule.fromCode(
              module: 'code-module',
              code: '''
                export function greet(name) {
                  return `Hello, \${name}!`;
                }
              ''',
            );
            if (_engine == null) throw 'Engine not initialized';
            await _engine!.declareNewModule(module: module);
            final result = await _engine!.eval(source: JsCode.code('''
              (async () => {
                const { greet } = await import('code-module');
                return greet('FJS');
              })()
            '''));
            return {
              'moduleName': module.name,
              'result': result.value,
            };
          }),
        ),
        ApiTestCard(
          title: 'JsModule.fromBytes()',
          subtitle: 'Create module from bytes',
          icon: Icons.data_array,
          isSuccess: _testResults['module_from_bytes']?.isSuccess,
          isLoading: _testResults['module_from_bytes']?.isLoading ?? false,
          result: _testResults['module_from_bytes']?.result,
          error: _testResults['module_from_bytes']?.error,
          onRun: () => _runTest('module_from_bytes', () async {
            final codeBytes = 'export const PI = 3.14159;'.codeUnits;
            final module = JsModule.fromBytes(
              module: 'bytes-module',
              bytes: codeBytes,
            );
            if (_engine == null) throw 'Engine not initialized';
            await _engine!.declareNewModule(module: module);
            final result = await _engine!.eval(source: JsCode.code('''
              (async () => {
                const { PI } = await import('bytes-module');
                return PI;
              })()
            '''));
            return {
              'moduleName': module.name,
              'bytesLength': codeBytes.length,
              'result': result.value,
            };
          }),
        ),
        ApiTestCard(
          title: 'Module with Dependencies',
          subtitle: 'Test modules importing other modules',
          icon: Icons.account_tree,
          isSuccess: _testResults['module_deps']?.isSuccess,
          isLoading: _testResults['module_deps']?.isLoading ?? false,
          result: _testResults['module_deps']?.result,
          error: _testResults['module_deps']?.error,
          onRun: () => _runTest('module_deps', () async {
            if (_engine == null) throw 'Engine not initialized';

            // Clear existing modules
            await _engine!.clearNewModules();

            // Create base module
            await _engine!.declareNewModule(module: JsModule.fromCode(
              module: 'math-base',
              code: '''
                export const PI = 3.14159;
                export function square(x) { return x * x; }
              ''',
            ));

            // Create dependent module
            await _engine!.declareNewModule(module: JsModule.fromCode(
              module: 'math-advanced',
              code: '''
                import { PI, square } from 'math-base';
                export function circleArea(r) { return PI * square(r); }
                export function circumference(r) { return 2 * PI * r; }
              ''',
            ));

            // Use the dependent module
            final result = await _engine!.eval(source: JsCode.code('''
              (async () => {
                const { circleArea, circumference } = await import('math-advanced');
                return {
                  area: circleArea(5),
                  circumference: circumference(5),
                };
              })()
            '''));

            return result.value;
          }),
        ),
      ],
    );
  }

  Widget _buildEvalOptionsTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'JsEvalOptions.defaults()',
          subtitle: 'Default evaluation options',
          icon: Icons.settings,
          isSuccess: _testResults['options_defaults']?.isSuccess,
          isLoading: _testResults['options_defaults']?.isLoading ?? false,
          result: _testResults['options_defaults']?.result,
          error: _testResults['options_defaults']?.error,
          onRun: () => _runTest('options_defaults', () async {
            final options = JsEvalOptions.defaults();
            if (_engine == null) throw 'Engine not initialized';
            final result = await _engine!.eval(source: JsCode.code('var defaultTest = 100; defaultTest'),
              options: options,
            );
            return {
              'options': options.toString(),
              'result': result.value,
            };
          }),
        ),
        ApiTestCard(
          title: 'JsEvalOptions.module()',
          subtitle: 'Module evaluation options',
          icon: Icons.view_module,
          isSuccess: _testResults['options_module']?.isSuccess,
          isLoading: _testResults['options_module']?.isLoading ?? false,
          result: _testResults['options_module']?.result,
          error: _testResults['options_module']?.error,
          onRun: () => _runTest('options_module', () async {
            final options = JsEvalOptions.module();
            return {
              'options': options.toString(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsEvalOptions.withPromise()',
          subtitle: 'Promise-enabled evaluation options',
          icon: Icons.pending,
          isSuccess: _testResults['options_promise']?.isSuccess,
          isLoading: _testResults['options_promise']?.isLoading ?? false,
          result: _testResults['options_promise']?.result,
          error: _testResults['options_promise']?.error,
          onRun: () => _runTest('options_promise', () async {
            final options = JsEvalOptions.withPromise();
            if (_engine == null) throw 'Engine not initialized';
            final result = await _engine!.eval(source: JsCode.code('Promise.resolve("Async Success")'),
              options: options,
            );
            return {
              'options': options.toString(),
              'result': result.value,
            };
          }),
        ),
        ApiTestCard(
          title: 'JsEvalOptions()',
          subtitle: 'Custom evaluation options',
          icon: Icons.tune,
          isSuccess: _testResults['options_custom']?.isSuccess,
          isLoading: _testResults['options_custom']?.isLoading ?? false,
          result: _testResults['options_custom']?.result,
          error: _testResults['options_custom']?.error,
          onRun: () => _runTest('options_custom', () async {
            final options = JsEvalOptions(
              global: true,
              strict: true,
              backtraceBarrier: false,
              promise: true,
            );
            if (_engine == null) throw 'Engine not initialized';
            final result = await _engine!.eval(source: JsCode.code('"use strict"; const strictVar = 42; strictVar'),
              options: options,
            );
            return {
              'global': true,
              'strict': true,
              'backtraceBarrier': false,
              'promise': true,
              'result': result.value,
            };
          }),
        ),
      ],
    );
  }

  Widget _buildBuiltinOptionsTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'JsBuiltinOptions.all()',
          subtitle: 'All modules enabled',
          icon: Icons.select_all,
          isSuccess: _testResults['builtin_all']?.isSuccess,
          isLoading: _testResults['builtin_all']?.isLoading ?? false,
          result: _testResults['builtin_all']?.result,
          error: _testResults['builtin_all']?.error,
          onRun: () => _runTest('builtin_all', () async {
            final options = JsBuiltinOptions.all();
            return {
              'description': 'All modules enabled',
              'options': options.toString(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsBuiltinOptions.none()',
          subtitle: 'No modules enabled',
          icon: Icons.block,
          isSuccess: _testResults['builtin_none']?.isSuccess,
          isLoading: _testResults['builtin_none']?.isLoading ?? false,
          result: _testResults['builtin_none']?.result,
          error: _testResults['builtin_none']?.error,
          onRun: () => _runTest('builtin_none', () async {
            final options = JsBuiltinOptions.none();
            return {
              'description': 'No modules enabled',
              'options': options.toString(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsBuiltinOptions.essential()',
          subtitle: 'Essential modules: console, timers, buffer, util, json',
          icon: Icons.star,
          isSuccess: _testResults['builtin_essential']?.isSuccess,
          isLoading: _testResults['builtin_essential']?.isLoading ?? false,
          result: _testResults['builtin_essential']?.result,
          error: _testResults['builtin_essential']?.error,
          onRun: () => _runTest('builtin_essential', () async {
            final options = JsBuiltinOptions.essential();
            return {
              'description':
                  'Essential modules: console, timers, buffer, util, json',
              'options': options.toString(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsBuiltinOptions.web()',
          subtitle: 'Web-like modules: console, timers, fetch, url, crypto',
          icon: Icons.web,
          isSuccess: _testResults['builtin_web']?.isSuccess,
          isLoading: _testResults['builtin_web']?.isLoading ?? false,
          result: _testResults['builtin_web']?.result,
          error: _testResults['builtin_web']?.error,
          onRun: () => _runTest('builtin_web', () async {
            final options = JsBuiltinOptions.web();
            return {
              'description':
                  'Web-like modules: console, timers, fetch, url, crypto',
              'options': options.toString(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsBuiltinOptions.node()',
          subtitle: 'Node.js-like modules',
          icon: Icons.developer_mode,
          isSuccess: _testResults['builtin_node']?.isSuccess,
          isLoading: _testResults['builtin_node']?.isLoading ?? false,
          result: _testResults['builtin_node']?.result,
          error: _testResults['builtin_node']?.error,
          onRun: () => _runTest('builtin_node', () async {
            final options = JsBuiltinOptions.node();
            return {
              'description':
                  'Node.js-like modules (most modules except OS-specific)',
              'options': options.toString(),
            };
          }),
        ),
        ApiTestCard(
          title: 'Custom JsBuiltinOptions',
          subtitle: 'Selective module configuration',
          icon: Icons.tune,
          isSuccess: _testResults['builtin_custom']?.isSuccess,
          isLoading: _testResults['builtin_custom']?.isLoading ?? false,
          result: _testResults['builtin_custom']?.result,
          error: _testResults['builtin_custom']?.error,
          onRun: () => _runTest('builtin_custom', () async {
            // Example of selective module configuration
            return {
              'console': true,
              'timers': true,
              'crypto': true,
              'buffer': true,
              'url': true,
              'json': true,
              'fs': false,
              'path': false,
              'os': false,
              'process': false,
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
