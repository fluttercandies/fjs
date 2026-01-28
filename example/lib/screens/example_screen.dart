import 'dart:async';

import 'package:fjs/fjs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/widgets.dart';

/// Example Screen demonstrating advanced FJS features
///
/// This screen showcases various JavaScript capabilities including:
/// - DOM manipulation with Linkedom
/// - Module system
/// - Async operations with fetch
class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _logs = [];
  bool _isExecuting = false;
  int _selectedExampleIndex = 0;

  JsEngine? _engine;

  @override
  void dispose() {
    _scrollController.dispose();
    _engine?.dispose();
    super.dispose();
  }

  Future<void> _ensureEngineInitialized() async {
    if (_engine != null) return;

    _addLog('⚠️ Initializing JavaScript engine...');

    // Load custom modules (linkedom and canvas)
    final linkedomBundle =
        await rootBundle.load('assets/examples/linkedom.bundle.mjs');
    final canvasBundle =
        await rootBundle.load('assets/examples/canvas.bundle.mjs');

    // Create runtime with builtin modules and custom modules
    final runtime = await JsAsyncRuntime.withOptions(
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

    final context = await JsAsyncContext.from(runtime: runtime);
    _engine = JsEngine(context: context);
    await _engine!.initWithoutBridge();

    _addLog('✅ Engine initialized with linkedom and canvas support!');
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $message');
    });

    // Auto-scroll to bottom
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  Future<void> _runExample(int index) async {
    if (_isExecuting) return;

    setState(() {
      _isExecuting = true;
      _selectedExampleIndex = index;
    });

    try {
      await _ensureEngineInitialized();

      switch (index) {
        case 0:
          await _runDomExample();
          break;
        case 1:
          await _runModuleExample();
          break;
        case 2:
          await _runFetchExample();
          break;
        case 3:
          await _runAsyncExample();
          break;
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  /// Example 1: DOM Manipulation with Linkedom
  /// Uses await (async () => { ... })() pattern
  Future<void> _runDomExample() async {
    _addLog('🌳 Starting DOM Example...');

    final code = '''
await (async () => {
    const {parseHTML} = await import('linkedom');
    const html = await fetch("https://httpbin.org/").then((res) => res.text());
    console.log("Fetched HTML:", html);
    const {document} = parseHTML(html);

    return {
      title: document.title,
      hasHtml: !!document.querySelector('html'),
      hasHead: !!document.querySelector('head'),
      hasBody: !!document.querySelector('body'),
      htmlLength: document.toString().length
    };
})()
''';

    final result = await _engine!.eval(source: JsCode.code(code));

    _addLog('✅ DOM Example completed!');
    _addLog('  Result: ${result.value}');
  }

  /// Example 2: Module System
  /// Uses static import with globalThis pattern
  Future<void> _runModuleExample() async {
    _addLog('📦 Starting Module Example...');

    final taskId = '_module_${DateTime.now().microsecondsSinceEpoch}';

    // Declare and evaluate module
    final moduleCode = '''
import {parseHTML} from 'linkedom';

globalThis['$taskId'] = await (async () => {
  const html = `
    <!DOCTYPE html>
    <html>
      <head><title>Module Test</title></head>
      <body>
        <h1>Module Demo</h1>
        <p>This content is from a module!</p>
      </body>
    </html>
  `;

  const {document} = parseHTML(html);

  // Manipulate DOM
  const h1 = document.querySelector('h1');
  h1.textContent = 'Modified by Module!';

  return {
    originalTitle: 'Module Test',
    newTitle: h1.textContent,
    paragraphCount: document.querySelectorAll('p').length
  };
})();
''';

    await _engine!.evaluateModule(
      module: JsModule(name: taskId, source: JsCode.code(moduleCode)),
    );

    // Get result from globalThis
    final result = await _engine!.eval(source: JsCode.code('''
(async () => {
  const result = globalThis['$taskId'];
  delete globalThis['$taskId'];
  return result;
})()
'''));

    _addLog('✅ Module Example completed!');
    _addLog('  Result: ${result.value}');
  }

  /// Example 3: Fetch and Network
  /// Uses await (async () => { ... })() pattern
  Future<void> _runFetchExample() async {
    _addLog('🌐 Starting Fetch Example...');

    final code = '''
await (async () => {
    const response = await fetch('https://httpbin.org/json');
    const data = await response.json();

    return {
      status: response.status,
      ok: response.ok,
      type: response.type,
      slideshowTitle: data.slideshow?.title
    };
})()
''';

    final result = await _engine!.eval(source: JsCode.code(code));

    _addLog('✅ Fetch Example completed!');
    _addLog('  Result: ${result.value}');
  }

  /// Example 4: Async Operations
  /// Uses await (async () => { ... })() pattern
  Future<void> _runAsyncExample() async {
    _addLog('⏱️ Starting Async Example...');

    final code = '''
await (async () => {
  const delays = [100, 200, 150];
  const start = Date.now();

  const results = await Promise.all(
    delays.map(async (delay, index) => {
      await new Promise(resolve => setTimeout(resolve, delay));
      return {
        index: index,
        delay: delay,
        completedAt: Date.now() - start
      };
    })
  );

  const totalDuration = Date.now() - start;

  return {
    operations: results.length,
    totalDuration: totalDuration,
    results: results,
    message: 'Completed ' + results.length + ' operations in ' + totalDuration + 'ms'
  };
})()
''';

    final result = await _engine!.eval(source: JsCode.code(code));

    _addLog('✅ Async Example completed!');
    _addLog('  Result: ${result.value}');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FJS Examples'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _logs.isEmpty ? null : _clearLogs,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildExampleSelector(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildExampleDescription(),
          ),
        ),
        _buildLogPanel(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar with examples
        SizedBox(
          width: 300,
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Examples',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _examples.length,
                    itemBuilder: (context, index) {
                      final example = _examples[index];
                      final isSelected = _selectedExampleIndex == index;

                      return ListTile(
                        leading: Icon(example.icon),
                        title: Text(example.title),
                        subtitle: Text(example.description,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        selected: isSelected,
                        enabled: !_isExecuting,
                        onTap: () => _runExample(index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        // Main content
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildExampleDescription(),
                ),
              ),
              _buildLogPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExampleSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select an Example',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _examples.asMap().entries.map((entry) {
              final index = entry.key;
              final example = entry.value;
              final isSelected = _selectedExampleIndex == index;

              return FilledButton.tonal(
                onPressed: _isExecuting ? null : () => _runExample(index),
                style: FilledButton.styleFrom(
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(example.icon, size: 16),
                    const SizedBox(width: 6),
                    Text(example.title),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleDescription() {
    final example = _examples[_selectedExampleIndex];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    example.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        example.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        example.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'What it demonstrates:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...example.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 18)),
                      Expanded(child: Text(feature)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isExecuting ? null : () => _runExample(_selectedExampleIndex),
              icon: _isExecuting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isExecuting ? 'Running...' : 'Run Example'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogPanel() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Output Log',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                if (_logs.isNotEmpty)
                  Text(
                    '${_logs.length} entries',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Text(
                      'No logs yet. Run an example to see output.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final isError = log.contains('❌') || log.contains('Error');
                      final isSuccess = log.contains('✅');
                      final isWarning = log.contains('⚠️');

                      Color? color;
                      if (isError) {
                        color = Colors.red.shade700;
                      } else if (isSuccess) {
                        color = Colors.green.shade700;
                      } else if (isWarning) {
                        color = Colors.orange.shade700;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (color != null)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            Expanded(
                              child: SelectableText(
                                log,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static const List<_ExampleInfo> _examples = [
    _ExampleInfo(
      icon: Icons.web,
      title: 'DOM Manipulation',
      description: 'Parse and manipulate HTML with Linkedom',
      features: [
        'HTML parsing with Linkedom',
        'Dynamic import()',
        'await (async () => {})() pattern',
        'Fetch + DOM processing',
      ],
    ),
    _ExampleInfo(
      icon: Icons.view_module,
      title: 'Module System',
      description: 'ES6 modules with static imports',
      features: [
        'Static import statements',
        'Module evaluateModule',
        'globalThis for result storage',
        'Module cleanup',
      ],
    ),
    _ExampleInfo(
      icon: Icons.cloud_download,
      title: 'Fetch & Network',
      description: 'HTTP requests with fetch API',
      features: [
        'HTTP GET requests',
        'Response handling',
        'JSON parsing',
        'Real API integration (httpbin.org)',
      ],
    ),
    _ExampleInfo(
      icon: Icons.timer_outlined,
      title: 'Async Operations',
      description: 'Promises and async/await patterns',
      features: [
        'Promise.all for parallel execution',
        'setTimeout for delays',
        'Async/await syntax',
        'Timing measurement',
      ],
    ),
  ];
}

class _ExampleInfo {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;

  const _ExampleInfo({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
  });
}
