import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/fjs_service.dart';
import '../services/js_examples_service.dart';
import '../services/storage_service.dart';
import '../widgets/widgets.dart';

/// Home screen with navigation to all features
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _result = '';
  bool _isExecuting = false;
  bool _copiedToClipboard = false;
  int _selectedNavIndex = 0;

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
        _result = const JsonEncoder.withIndent('  ').convert(result.value);
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

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _copiedToClipboard = false;
          });
        }
      });

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      return _buildDesktopLayout(context);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveLayout.horizontalPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeCard(context),
            const SizedBox(height: 16),
            _buildQuickActionsCard(context),
            const SizedBox(height: 16),
            _buildCodeEditorSection(context),
            const SizedBox(height: 16),
            _buildResultSection(context),
            const SizedBox(height: 16),
            _buildExamplesSection(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Side navigation
          NavigationRail(
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedNavIndex = index);
              _handleNavigation(index);
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.javascript,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'FJS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Consumer<StorageService>(
                    builder: (context, storageService, _) {
                      return IconButton(
                        icon: Icon(
                          storageService.themeMode == ThemeMode.dark
                              ? Icons.light_mode
                              : Icons.dark_mode,
                        ),
                        onPressed: () => storageService.toggleTheme(),
                        tooltip: 'Toggle Theme',
                      );
                    },
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.code_outlined),
                selectedIcon: Icon(Icons.code),
                label: Text('Playground'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.api_outlined),
                selectedIcon: Icon(Icons.api),
                label: Text('API'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.science_outlined),
                selectedIcon: Icon(Icons.science),
                label: Text('Tests'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          // Main content
          Expanded(
            child: Scaffold(
              appBar: _buildAppBar(context, showDrawer: false),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWelcomeCard(context),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildCodeEditorSection(context),
                                const SizedBox(height: 16),
                                _buildExamplesSection(context),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildQuickActionsCard(context),
                                const SizedBox(height: 16),
                                _buildResultSection(context),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.pushNamed(context, '/playground');
        break;
      case 2:
        Navigator.pushNamed(context, '/api');
        break;
      case 3:
        Navigator.pushNamed(context, '/js-actions-test');
        break;
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context,
      {bool showDrawer = true}) {
    return AppBar(
      title: const Text('FJS JavaScript Runtime'),
      automaticallyImplyLeading: showDrawer,
      actions: [
        IconButton(
          icon: const Icon(Icons.play_circle_outline),
          onPressed: _executeCode,
          tooltip: 'Execute Code',
        ),
        if (!ResponsiveLayout.isDesktop(context))
          Consumer<StorageService>(
            builder: (context, storageService, child) {
              return IconButton(
                icon: Icon(
                  storageService.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () => storageService.toggleTheme(),
                tooltip: 'Toggle Theme',
              );
            },
          ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'playground':
                Navigator.pushNamed(context, '/playground');
                break;
              case 'api':
                Navigator.pushNamed(context, '/api');
                break;
              case 'js-actions-test':
                Navigator.pushNamed(context, '/js-actions-test');
                break;
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
              value: 'api',
              child: Row(
                children: [
                  Icon(Icons.api),
                  SizedBox(width: 8),
                  Text('API Reference'),
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
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.javascript,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 8),
                Text(
                  'FJS',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Flutter JavaScript Runtime',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Playground'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/playground');
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'API Reference',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.api),
            title: const Text('Overview'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/api');
            },
          ),
          ListTile(
            leading: const Icon(Icons.memory),
            title: const Text('JsEngine'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/api/engine');
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('JsRuntime'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/api/runtime');
            },
          ),
          ListTile(
            leading: const Icon(Icons.data_object),
            title: const Text('JsValue'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/api/value');
            },
          ),
          ListTile(
            leading: const Icon(Icons.error_outline),
            title: const Text('JsError'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/api/error');
            },
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/api/source');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.science),
            title: const Text('JsActions Test'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/js-actions-test');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.science),
            title: const Text('Example Screen'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/example');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.javascript,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to FJS',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Flutter JavaScript Runtime powered by QuickJS',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeatureChip(icon: Icons.speed, label: 'Fast'),
              _FeatureChip(icon: Icons.security, label: 'Safe'),
              _FeatureChip(icon: Icons.sync, label: 'Async'),
              _FeatureChip(icon: Icons.view_module, label: 'Modules'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.pushNamed(context, '/playground'),
                  icon: const Icon(Icons.code),
                  label: const Text('Playground'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.pushNamed(context, '/api'),
                  icon: const Icon(Icons.api),
                  label: const Text('API Docs'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/js-actions-test'),
                  icon: const Icon(Icons.science),
                  label: const Text('Run Tests'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeEditorSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              ],
            ),
            const SizedBox(height: 12),
            CodeEditorWidget(
              controller: _codeController,
              hintText:
                  '// Enter your JavaScript code here...\nconsole.log("Hello, FJS!");',
              height: 200,
              isLoading: _isExecuting,
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
        padding: const EdgeInsets.all(16),
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
                if (_result.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      _copiedToClipboard ? Icons.check : Icons.copy,
                      size: 18,
                    ),
                    onPressed: _copyResultToClipboard,
                    tooltip: 'Copy Result',
                  ),
                if (_result.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _result = ''),
                    tooltip: 'Clear',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ResultDisplayWidget(
              result: _result.isNotEmpty && !_result.startsWith('Error:')
                  ? _result
                  : null,
              error: _result.startsWith('Error:') ? _result : null,
              isLoading: _isExecuting,
              height: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamplesSection(BuildContext context) {
    return Consumer<JsExamplesService>(
      builder: (context, examplesService, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                ...JsExampleCategory.values.take(4).map((category) {
                  final examples =
                      examplesService.getExamplesByCategory(category);
                  if (examples.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: examples
                            .take(4)
                            .map((example) => ActionChip(
                                  label: Text(example.label),
                                  onPressed: () => _loadExample(example),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
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

  Future<void> _loadExample(JsExample example) async {
    final examplesService =
        Provider.of<JsExamplesService>(context, listen: false);
    final code = await examplesService.loadExampleCode(example.fileName);
    if (code != null) {
      _codeController.text = code;
    }
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
