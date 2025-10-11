import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/fjs_service.dart';
import '../app/theme.dart';
import '../app/router.dart';

class FjsExampleApp extends StatelessWidget {
  const FjsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<StorageService, FjsService>(
      builder: (context, storageService, fjsService, child) {
        return MaterialApp(
          title: 'FJS - JavaScript Runtime',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: storageService.themeMode,
          home: const HomePage(),
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _codeController = TextEditingController();
  String _result = '';
  bool _isExecuting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _executeCode() async {
    if (_codeController.text.trim().isEmpty) return;

    setState(() {
      _isExecuting = true;
      _result = '';
    });

    try {
      final fjsService = Provider.of<FjsService>(context, listen: false);
      final result = await fjsService.executeCode(_codeController.text);

      setState(() {
        _result = result.toString();
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FJS JavaScript Runtime'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: _executeCode,
          ),
          Consumer<StorageService>(
            builder: (context, storageService, child) {
              return IconButton(
                icon: Icon(
                  storageService.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () {
                  storageService.toggleTheme();
                },
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'playground') {
                Navigator.pushNamed(context, '/playground');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'playground',
                child: Row(
                  children: [
                    Icon(Icons.code),
                    SizedBox(width: 8),
                    Text('Playground'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Code editor section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JavaScript Code',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _codeController,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                          hintText:
                              '// Enter your JavaScript code here...\nconsole.log("Hello, FJS!");',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isExecuting ? null : _executeCode,
                        icon: _isExecuting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.play_arrow),
                        label: Text(_isExecuting ? 'Executing...' : 'Execute'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Result section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Result',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _result.startsWith('Error:')
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _result.startsWith('Error:')
                              ? Colors.red.shade200
                              : Colors.green.shade200,
                        ),
                      ),
                      child: _result.isEmpty
                          ? Text(
                              'Result will appear here...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : Text(
                              _result,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                color: _result.startsWith('Error:')
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick examples
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Examples',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _ExampleChip(
                          label: 'Hello World',
                          code: 'console.log("Hello, World!");',
                          onPressed: () =>
                              _setExampleCode('console.log("Hello, World!");'),
                        ),
                        _ExampleChip(
                          label: 'Math',
                          code: 'Math.sqrt(16)',
                          onPressed: () => _setExampleCode('Math.sqrt(16)'),
                        ),
                        _ExampleChip(
                          label: 'Date',
                          code: 'new Date().toISOString()',
                          onPressed: () =>
                              _setExampleCode('new Date().toISOString()'),
                        ),
                        _ExampleChip(
                          label: 'JSON',
                          code: 'JSON.stringify({name: "FJS", version: "1.0"})',
                          onPressed: () => _setExampleCode(
                              'JSON.stringify({name: "FJS", version: "1.0"})'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setExampleCode(String code) {
    _codeController.text = code;
  }
}

class _ExampleChip extends StatelessWidget {
  final String label;
  final String code;
  final VoidCallback onPressed;

  const _ExampleChip({
    required this.label,
    required this.code,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
