import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/router.dart';
import '../app/theme.dart';

import '../services/fjs_service.dart';
import '../services/js_actions_service.dart';
import '../services/js_examples_service.dart';
import '../services/storage_service.dart';

class FjsExampleApp extends StatelessWidget {
  const FjsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FjsService()),
        ChangeNotifierProvider(create: (_) => JsActionsService()),
        ChangeNotifierProvider(create: (_) => JsExamplesService()),
        ChangeNotifierProvider(create: (_) => StorageService()),
      ],
      child: Consumer3<StorageService, FjsService, JsExamplesService>(
        builder: (context, storageService, fjsService, examplesService, child) {
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
      ),
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
  bool _copiedToClipboard = false;

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
      
      // Check for import statements to auto-select mode
      final hasImport = RegExp(
        r'^\s*import\s+.*\s+from\s+',
        multiLine: true,
      ).hasMatch(_codeController.text);
      
      dynamic result;
      if (hasImport) {
        result = await fjsService.executeAsModule(_codeController.text);
      } else {
        result = await fjsService.executeAsScript(_codeController.text);
      }

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

  Future<void> _copyResultToClipboard() async {
    if (_result.trim().isEmpty) return;

    try {
      await Clipboard.setData(ClipboardData(text: _result));
      
      setState(() {
        _copiedToClipboard = true;
      });

      // Reset the copied state after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _copiedToClipboard = false;
          });
        }
      });

      // Show a snackbar for better feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Result copied to clipboard!'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      // Show error message if copy fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _copyCodeToClipboard() async {
    if (_codeController.text.trim().isEmpty) return;

    try {
      await Clipboard.setData(ClipboardData(text: _codeController.text));

      // Show a snackbar for feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Code copied to clipboard!'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      // Show error message if copy fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1200;

    // Responsive padding
    final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
    final verticalPadding = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FJS JavaScript Runtime'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: _executeCode,
            tooltip: 'Execute Code',
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
                tooltip: 'Toggle Theme',
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'playground') {
                Navigator.pushNamed(context, '/playground');
              } else if (value == 'js-actions-test') {
                Navigator.pushNamed(context, '/js-actions-test');
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
              const PopupMenuItem(
                value: 'js-actions-test',
                child: Row(
                  children: [
                    Icon(Icons.science),
                    SizedBox(width: 8),
                    Text('JsActions Test'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom -
                verticalPadding * 2,
          ),
          child: isDesktop
              ? _buildDesktopLayout(context)
              : (isTablet
                  ? _buildTabletLayout(context)
                  : _buildMobileLayout(context)),
        ),
      ),
    );
  }

  // Mobile layout (vertical stack)
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCodeEditorSection(context, height: 200),
        const SizedBox(height: 16),
        _buildResultSection(context),
        const SizedBox(height: 16),
        _buildExamplesSection(context),
      ],
    );
  }

  // Tablet layout (vertical stack with more space)
  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCodeEditorSection(context, height: 250),
        const SizedBox(height: 20),
        _buildResultSection(context),
        const SizedBox(height: 20),
        _buildExamplesSection(context),
      ],
    );
  }

  // Desktop layout (side-by-side)
  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top row with code editor and result
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Code editor (left side)
              Expanded(
                flex: 3,
                child: _buildCodeEditorSection(context, height: 400),
              ),
              const SizedBox(width: 20),
              // Result (right side)
              Expanded(
                flex: 2,
                child: _buildResultSection(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Examples section (bottom)
        _buildExamplesSection(context),
      ],
    );
  }

  Widget _buildCodeEditorSection(BuildContext context,
      {required double height}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.code,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'JavaScript Code',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                // Copy code button
                if (_codeController.text.trim().isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton.filled(
                      onPressed: _isExecuting ? null : _copyCodeToClipboard,
                      icon: const Icon(Icons.copy, size: 18),
                      iconSize: 18,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      tooltip: 'Copy Code',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: height,
              constraints: const BoxConstraints(
                minHeight: 150,
                maxHeight: 500,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isExecuting ? null : _executeCode,
                icon: _isExecuting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isExecuting ? 'Executing...' : 'Execute Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.output,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Result',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                // Copy result button with dynamic state
                if (_result.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: _copiedToClipboard 
                          ? Colors.green.shade100 
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _copiedToClipboard 
                            ? Colors.green.shade300 
                            : Colors.transparent,
                      ),
                    ),
                    child: IconButton.filled(
                      onPressed: _isExecuting ? null : _copyResultToClipboard,
                      icon: Icon(
                        _copiedToClipboard 
                            ? Icons.check_circle 
                            : Icons.copy,
                        size: 18,
                      ),
                      iconSize: 18,
                      style: IconButton.styleFrom(
                        backgroundColor: _copiedToClipboard 
                            ? Colors.green.shade200 
                            : null,
                        foregroundColor: _copiedToClipboard 
                            ? Colors.green.shade700 
                            : null,
                        minimumSize: const Size(36, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      tooltip: _copiedToClipboard ? 'Copied!' : 'Copy Result',
                    ),
                  ),
                const SizedBox(width: 8),
                if (_result.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _result = '';
                      });
                    },
                    tooltip: 'Clear Result',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 100,
                maxHeight: 300,
              ),
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
              child: SingleChildScrollView(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamplesSection(BuildContext context) {
    return Consumer<JsExamplesService>(
      builder: (context, examplesService, child) {
        if (examplesService.isLoading) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading examples...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (examplesService.error != null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading examples',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    examplesService.error!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Examples',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Build examples from JsExamplesService
                ...JsExampleCategory.values.map((category) {
                  final examples = examplesService.getExamplesByCategory(category);
                  if (examples.isEmpty) return const SizedBox.shrink();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: examples.map((example) => 
                          _ExampleChip(
                            label: example.label,
                            fileName: example.fileName,
                            executionMode: example.executionMode,
                            onPressed: () => _loadAndSetExample(example),
                          ),
                        ).toList(),
                      ),
                      if (category != JsExampleCategory.values.last) 
                        const SizedBox(height: 16),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadAndSetExample(JsExample example) async {
    final examplesService = Provider.of<JsExamplesService>(context, listen: false);
    
    final code = await examplesService.loadExampleCode(example.fileName);
    if (code != null) {
      _codeController.text = code;
    }
  }

  
}

class _ExampleChip extends StatelessWidget {
  final String label;
  final String fileName;
  final VoidCallback onPressed;
  final JsExecutionMode? executionMode;

  const _ExampleChip({
    required this.label,
    required this.fileName,
    required this.onPressed,
    this.executionMode,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
