import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A code editor widget with syntax highlighting preview
class CodeEditorWidget extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool readOnly;
  final double? height;
  final VoidCallback? onExecute;
  final bool isLoading;

  const CodeEditorWidget({
    super.key,
    required this.controller,
    this.hintText = '// Enter code here...',
    this.readOnly = false,
    this.height,
    this.onExecute,
    this.isLoading = false,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.code,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'JavaScript',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                // Copy button
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: widget.controller.text),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  tooltip: 'Copy Code',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  iconSize: 18,
                ),
                // Clear button
                if (!widget.readOnly)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => widget.controller.clear(),
                    tooltip: 'Clear',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    iconSize: 18,
                  ),
                // Execute button
                if (widget.onExecute != null)
                  IconButton(
                    icon: widget.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow, size: 18),
                    onPressed: widget.isLoading ? null : widget.onExecute,
                    tooltip: 'Execute',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    iconSize: 18,
                  ),
              ],
            ),
          ),
          // Editor
          Expanded(
            child: TextField(
              controller: widget.controller,
              maxLines: null,
              expands: true,
              readOnly: widget.readOnly,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: isDark ? Colors.green.shade300 : Colors.grey.shade800,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A result display widget
class ResultDisplayWidget extends StatelessWidget {
  final String? result;
  final String? error;
  final bool isLoading;
  final double? height;

  const ResultDisplayWidget({
    super.key,
    this.result,
    this.error,
    this.isLoading = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = error != null;
    final hasContent = result != null || error != null;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: hasError
            ? Colors.red.shade50
            : hasContent
                ? Colors.green.shade50
                : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? Colors.red.shade200
              : hasContent
                  ? Colors.green.shade200
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hasError
                  ? Colors.red.shade100
                  : hasContent
                      ? Colors.green.shade100
                      : theme.colorScheme.surfaceContainerHighest,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(
                  hasError
                      ? Icons.error_outline
                      : hasContent
                          ? Icons.check_circle_outline
                          : Icons.output,
                  size: 16,
                  color: hasError
                      ? Colors.red.shade700
                      : hasContent
                          ? Colors.green.shade700
                          : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  hasError ? 'Error' : 'Result',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasError
                        ? Colors.red.shade700
                        : hasContent
                            ? Colors.green.shade700
                            : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (hasContent)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: error ?? result ?? ''),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Result copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    tooltip: 'Copy Result',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    iconSize: 16,
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: hasContent
                  ? SelectableText(
                      error ?? result ?? '',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: hasError
                            ? Colors.red.shade800
                            : Colors.green.shade800,
                      ),
                    )
                  : Text(
                      'Result will appear here...',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
