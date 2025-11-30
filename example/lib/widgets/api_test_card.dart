import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable card widget for API test results
class ApiTestCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool? isSuccess;
  final dynamic result;
  final String? error;
  final bool isLoading;
  final VoidCallback? onRun;
  final Widget? trailing;
  final Widget? expandedContent;

  const ApiTestCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.isSuccess,
    this.result,
    this.error,
    this.isLoading = false,
    this.onRun,
    this.trailing,
    this.expandedContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color getStatusColor() {
      if (isLoading) return colorScheme.primary;
      if (isSuccess == null) return colorScheme.outline;
      return isSuccess! ? Colors.green : Colors.red;
    }

    IconData getStatusIcon() {
      if (isLoading) return Icons.hourglass_empty;
      if (isSuccess == null) return Icons.help_outline;
      return isSuccess! ? Icons.check_circle : Icons.error;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: getStatusColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: getStatusColor()),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isSuccess != null)
              Icon(getStatusIcon(), color: getStatusColor()),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
            if (onRun != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: isLoading ? null : onRun,
                tooltip: 'Run Test',
              ),
            ],
          ],
        ),
        children: [
          if (expandedContent != null) expandedContent!,
          if (result != null || error != null)
            _ResultSection(
              result: result,
              error: error,
              isSuccess: isSuccess,
            ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final dynamic result;
  final String? error;
  final bool? isSuccess;

  const _ResultSection({
    this.result,
    this.error,
    this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable - may be used in future
    final _ = Theme.of(context);

    String formatResult(dynamic value) {
      if (value == null) return 'null';
      if (value is String) return value;
      try {
        return const JsonEncoder.withIndent('  ').convert(value);
      } catch (e) {
        return value.toString();
      }
    }

    final displayText = error ?? formatResult(result);
    final hasError = error != null || isSuccess == false;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasError ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasError ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                hasError ? 'Error:' : 'Result:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: hasError ? Colors.red.shade700 : Colors.green.shade700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: displayText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                tooltip: 'Copy',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                iconSize: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            displayText,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: hasError ? Colors.red.shade800 : Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

/// A section header for grouping tests
class ApiTestSection extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;

  const ApiTestSection({
    super.key,
    required this.title,
    this.description,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (description != null)
                  Text(
                    description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple status indicator widget
class StatusIndicator extends StatelessWidget {
  final bool? status;
  final String? label;

  const StatusIndicator({
    super.key,
    this.status,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = status == null
        ? Colors.grey
        : status!
            ? Colors.green
            : Colors.red;
    final icon = status == null
        ? Icons.help_outline
        : status!
            ? Icons.check_circle
            : Icons.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label!,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
