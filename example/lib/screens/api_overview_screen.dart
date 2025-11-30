import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

/// Main API overview screen with navigation to all API test screens
class ApiOverviewScreen extends StatelessWidget {
  const ApiOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FJS API Reference'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: ConstrainedContent(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero section
              _buildHeroSection(context),
              const SizedBox(height: 24),

              // API Categories
              Text(
                'API Categories',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildApiGrid(context),

              const SizedBox(height: 32),

              // Quick Reference
              Text(
                'Quick Reference',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickReference(context),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
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
                  Icons.api,
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
                      'FJS API Reference',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Complete API documentation and interactive tests',
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
              _buildChip(context, 'JsEngine', Icons.memory),
              _buildChip(context, 'JsRuntime', Icons.play_arrow),
              _buildChip(context, 'JsValue', Icons.data_object),
              _buildChip(context, 'JsError', Icons.error_outline),
              _buildChip(context, 'JsModule', Icons.view_module),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildApiGrid(BuildContext context) {
    final apis = [
      _ApiCategory(
        title: 'JsEngine',
        subtitle: 'High-level JavaScript engine API',
        icon: Icons.memory,
        color: Colors.blue,
        route: '/api/engine',
        features: ['eval()', 'modules', 'bridge'],
      ),
      _ApiCategory(
        title: 'JsRuntime',
        subtitle: 'Runtime and context management',
        icon: Icons.play_arrow,
        color: Colors.green,
        route: '/api/runtime',
        features: ['memory', 'gc', 'jobs'],
      ),
      _ApiCategory(
        title: 'JsValue',
        subtitle: 'Value types and conversion',
        icon: Icons.data_object,
        color: Colors.orange,
        route: '/api/value',
        features: ['types', 'conversion', 'checks'],
      ),
      _ApiCategory(
        title: 'JsError',
        subtitle: 'Error handling and types',
        icon: Icons.error_outline,
        color: Colors.red,
        route: '/api/error',
        features: ['errors', 'JsResult', 'recovery'],
      ),
      _ApiCategory(
        title: 'Source',
        subtitle: 'Code, modules, and options',
        icon: Icons.code,
        color: Colors.purple,
        route: '/api/source',
        features: ['JsCode', 'JsModule', 'options'],
      ),
    ];

    return ResponsiveLayout(
      mobile: Column(
        children: apis.map((api) => _buildApiCard(context, api)).toList(),
      ),
      tablet: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: apis.map((api) => _buildApiCard(context, api)).toList(),
      ),
      desktop: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.3,
        children: apis.map((api) => _buildApiCard(context, api)).toList(),
      ),
    );
  }

  Widget _buildApiCard(BuildContext context, _ApiCategory api) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, api.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: api.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(api.icon, color: api.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          api.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          api.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Spacer(),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: api.features.map((f) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    f,
                    style: theme.textTheme.labelSmall,
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReference(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Usage',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              '''// Initialize
final runtime = await JsAsyncRuntime.withOptions(
  builtin: JsBuiltinOptions.all(),
);
final context = await JsAsyncContext.from(rt: runtime);
final engine = JsEngine(context);
await engine.init();

// Evaluate code
final result = await engine.eval(
  JsCode.code('Math.random() * 100'),
);
print(result.value);

// Declare modules
await engine.declareNewModule(
  JsModule.fromCode(
    module: 'utils',
    code: 'export function add(a, b) { return a + b; }',
  ),
);

// Cleanup
await engine.dispose();''',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final List<String> features;

  _ApiCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.features,
  });
}
