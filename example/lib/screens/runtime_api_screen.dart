import 'package:fjs/fjs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

/// Screen to test all JsRuntime APIs
class RuntimeApiScreen extends StatefulWidget {
  const RuntimeApiScreen({super.key});

  @override
  State<RuntimeApiScreen> createState() => _RuntimeApiScreenState();
}

class _RuntimeApiScreenState extends State<RuntimeApiScreen> {
  JsAsyncRuntime? _runtime;
  JsAsyncContext? _context;
  JsEngine? _engine;
  bool _isInitialized = false;
  bool _isLoading = false;

  // Test results
  final Map<String, _TestResult> _testResults = {};

  @override
  void initState() {
    super.initState();
    _initializeRuntime();
  }

  Future<void> _initializeRuntime() async {
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
      if (kDebugMode) print('Failed to initialize runtime: $e');
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
        title: const Text('Runtime API Tests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _engine?.dispose();
              setState(() {
                _isInitialized = false;
                _testResults.clear();
              });
              await _initializeRuntime();
            },
            tooltip: 'Reinitialize Runtime',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Status bar
                  _buildStatusBar(),

                  // Runtime Creation Tests
                  const ApiTestSection(
                    title: 'Runtime Creation',
                    description: 'Test runtime initialization methods',
                    icon: Icons.build_circle,
                  ),
                  _buildRuntimeCreationTests(),

                  // Memory Management Tests
                  const ApiTestSection(
                    title: 'Memory Management',
                    description: 'Test memory-related APIs',
                    icon: Icons.memory,
                  ),
                  _buildMemoryTests(),

                  // Job Management Tests
                  const ApiTestSection(
                    title: 'Job Management',
                    description: 'Test pending job APIs',
                    icon: Icons.work,
                  ),
                  _buildJobTests(),

                  // Configuration Tests
                  const ApiTestSection(
                    title: 'Runtime Configuration',
                    description: 'Test runtime configuration methods',
                    icon: Icons.settings,
                  ),
                  _buildConfigTests(),

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
          color:
              _isInitialized ? Colors.green.shade200 : Colors.orange.shade200,
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
                  _isInitialized ? 'Runtime Initialized' : 'Runtime Not Ready',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isInitialized
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                Text(
                  _isInitialized
                      ? 'All APIs are ready for testing'
                      : 'Waiting for runtime initialization...',
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

  Widget _buildRuntimeCreationTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'JsAsyncRuntime()',
          subtitle: 'Create runtime with default configuration',
          icon: Icons.add_circle,
          isSuccess: _testResults['runtime_default']?.isSuccess,
          isLoading: _testResults['runtime_default']?.isLoading ?? false,
          result: _testResults['runtime_default']?.result,
          error: _testResults['runtime_default']?.error,
          onRun: () => _runTest('runtime_default', () async {
            final rt = JsAsyncRuntime();
            return 'JsAsyncRuntime created: ${rt.hashCode}';
          }),
        ),
        ApiTestCard(
          title: 'JsAsyncRuntime.withOptions()',
          subtitle: 'Create runtime with custom builtin modules',
          icon: Icons.tune,
          isSuccess: _testResults['runtime_options']?.isSuccess,
          isLoading: _testResults['runtime_options']?.isLoading ?? false,
          result: _testResults['runtime_options']?.result,
          error: _testResults['runtime_options']?.error,
          onRun: () => _runTest('runtime_options', () async {
            final rt = await JsAsyncRuntime.withOptions(
              builtin: JsBuiltinOptions.all(),
            );
            return 'JsAsyncRuntime.withOptions() created: ${rt.hashCode}';
          }),
        ),
        ApiTestCard(
          title: 'JsBuiltinOptions variants',
          subtitle: 'Test all builtin option presets',
          icon: Icons.widgets,
          isSuccess: _testResults['builtin_variants']?.isSuccess,
          isLoading: _testResults['builtin_variants']?.isLoading ?? false,
          result: _testResults['builtin_variants']?.result,
          error: _testResults['builtin_variants']?.error,
          onRun: () => _runTest('builtin_variants', () async {
            return {
              'all': JsBuiltinOptions.all().toString(),
              'none': JsBuiltinOptions.none().toString(),
              'essential': JsBuiltinOptions.essential().toString(),
              'web': JsBuiltinOptions.web().toString(),
              'node': JsBuiltinOptions.node().toString(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsAsyncContext.from()',
          subtitle: 'Create context from runtime',
          icon: Icons.layers,
          isSuccess: _testResults['context_create']?.isSuccess,
          isLoading: _testResults['context_create']?.isLoading ?? false,
          result: _testResults['context_create']?.result,
          error: _testResults['context_create']?.error,
          onRun: () => _runTest('context_create', () async {
            final rt = JsAsyncRuntime();
            final ctx = await JsAsyncContext.from(rt: rt);
            return 'JsAsyncContext (${ctx.hashCode}) created from runtime (${rt.hashCode})';
          }),
        ),
      ],
    );
  }

  Widget _buildMemoryTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'memoryUsage()',
          subtitle: 'Get current memory usage statistics',
          icon: Icons.analytics,
          isSuccess: _testResults['memory_usage']?.isSuccess,
          isLoading: _testResults['memory_usage']?.isLoading ?? false,
          result: _testResults['memory_usage']?.result,
          error: _testResults['memory_usage']?.error,
          onRun: () => _runTest('memory_usage', () async {
            if (_runtime == null) throw 'Runtime not initialized';
            final usage = await _runtime!.memoryUsage();
            return {
              'summary': usage.summary(),
              'totalMemory': usage.totalMemory.toString(),
              'totalAllocations': usage.totalAllocations.toString(),
              'mallocSize': usage.mallocSize.toString(),
              'mallocCount': usage.mallocCount.toString(),
              'objCount': usage.objCount.toString(),
              'objSize': usage.objSize.toString(),
              'strCount': usage.strCount.toString(),
              'strSize': usage.strSize.toString(),
              'arrayCount': usage.arrayCount.toString(),
              'atomCount': usage.atomCount.toString(),
              'atomSize': usage.atomSize.toString(),
              'jsFuncCount': usage.jsFuncCount.toString(),
              'jsFuncSize': usage.jsFuncSize.toString(),
              'cFuncCount': usage.cFuncCount.toString(),
              'propCount': usage.propCount.toString(),
              'propSize': usage.propSize.toString(),
              'shapeCount': usage.shapeCount.toString(),
              'shapeSize': usage.shapeSize.toString(),
              'fastArrayCount': usage.fastArrayCount.toString(),
              'fastArrayElements': usage.fastArrayElements.toString(),
              'binaryObjectCount': usage.binaryObjectCount.toString(),
              'binaryObjectSize': usage.binaryObjectSize.toString(),
            };
          }),
        ),
        ApiTestCard(
          title: 'runGc()',
          subtitle: 'Force garbage collection',
          icon: Icons.delete_sweep,
          isSuccess: _testResults['run_gc']?.isSuccess,
          isLoading: _testResults['run_gc']?.isLoading ?? false,
          result: _testResults['run_gc']?.result,
          error: _testResults['run_gc']?.error,
          onRun: () => _runTest('run_gc', () async {
            if (_runtime == null) throw 'Runtime not initialized';
            await _runtime!.runGc();
            return 'Garbage collection completed';
          }),
        ),
        ApiTestCard(
          title: 'setMemoryLimit()',
          subtitle: 'Set memory limit (100MB)',
          icon: Icons.speed,
          isSuccess: _testResults['set_memory_limit']?.isSuccess,
          isLoading: _testResults['set_memory_limit']?.isLoading ?? false,
          result: _testResults['set_memory_limit']?.result,
          error: _testResults['set_memory_limit']?.error,
          onRun: () => _runTest('set_memory_limit', () async {
            if (_runtime == null) throw 'Runtime not initialized';
            await _runtime!
                .setMemoryLimit(limit: BigInt.from(100 * 1024 * 1024));
            return 'Memory limit set to 100MB';
          }),
        ),
        ApiTestCard(
          title: 'setGcThreshold()',
          subtitle: 'Set GC threshold (1MB)',
          icon: Icons.tune,
          isSuccess: _testResults['set_gc_threshold']?.isSuccess,
          isLoading: _testResults['set_gc_threshold']?.isLoading ?? false,
          result: _testResults['set_gc_threshold']?.result,
          error: _testResults['set_gc_threshold']?.error,
          onRun: () => _runTest('set_gc_threshold', () async {
            if (_runtime == null) throw 'Runtime not initialized';
            await _runtime!.setGcThreshold(threshold: BigInt.from(1024 * 1024));
            return 'GC threshold set to 1MB';
          }),
        ),
      ],
    );
  }

  Widget _buildJobTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'isJobPending()',
          subtitle: 'Check if there are pending jobs',
          icon: Icons.pending_actions,
          isSuccess: _testResults['is_job_pending']?.isSuccess,
          isLoading: _testResults['is_job_pending']?.isLoading ?? false,
          result: _testResults['is_job_pending']?.result,
          error: _testResults['is_job_pending']?.error,
          onRun: () => _runTest('is_job_pending', () async {
            if (_runtime == null) throw 'Runtime not initialized';
            final isPending = await _runtime!.isJobPending();
            return {'isJobPending': isPending};
          }),
        ),
        ApiTestCard(
          title: 'executePendingJob()',
          subtitle: 'Execute a pending job',
          icon: Icons.play_circle,
          isSuccess: _testResults['execute_pending_job']?.isSuccess,
          isLoading: _testResults['execute_pending_job']?.isLoading ?? false,
          result: _testResults['execute_pending_job']?.result,
          error: _testResults['execute_pending_job']?.error,
          onRun: () => _runTest('execute_pending_job', () async {
            if (_runtime == null) throw 'Runtime not initialized';
            final executed = await _runtime!.executePendingJob();
            return {'jobExecuted': executed};
          }),
        ),
        ApiTestCard(
          title: 'idle()',
          subtitle: 'Put runtime into idle state',
          icon: Icons.pause_circle,
          isSuccess: _testResults['idle']?.isSuccess,
          isLoading: _testResults['idle']?.isLoading ?? false,
          result: _testResults['idle']?.result,
          error: _testResults['idle']?.error,
          onRun: () => _runTest('idle', () async {
            if (_runtime == null) throw 'Runtime not initialized';
            await _runtime!.idle();
            return 'Runtime set to idle state';
          }),
        ),
      ],
    );
  }

  Widget _buildConfigTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'setInfo()',
          subtitle: 'Set runtime info string',
          icon: Icons.info,
          isSuccess: _testResults['set_info']?.isSuccess,
          isLoading: _testResults['set_info']?.isLoading ?? false,
          result: _testResults['set_info']?.result,
          error: _testResults['set_info']?.error,
          onRun: () => _runTest('set_info', () async {
            if (_runtime == null) throw 'Runtime not initialized';
            await _runtime!.setInfo(info: 'FJS Example App Runtime');
            return 'Runtime info set successfully';
          }),
        ),
        ApiTestCard(
          title: 'setMaxStackSize()',
          subtitle: 'Set maximum stack size (256KB)',
          icon: Icons.stacked_bar_chart,
          isSuccess: _testResults['set_max_stack_size']?.isSuccess,
          isLoading: _testResults['set_max_stack_size']?.isLoading ?? false,
          result: _testResults['set_max_stack_size']?.result,
          error: _testResults['set_max_stack_size']?.error,
          onRun: () => _runTest('set_max_stack_size', () async {
            if (_runtime == null) throw 'Runtime not initialized';
            await _runtime!.setMaxStackSize(limit: BigInt.from(256 * 1024));
            return 'Max stack size set to 256KB';
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
