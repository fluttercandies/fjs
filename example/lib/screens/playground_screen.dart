import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/fjs_service.dart';

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();
  bool _isExecuting = false;
  bool _copiedToClipboard = false;

  @override
  void dispose() {
    _codeController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _executeCode(JsExecutionMode mode) async {
    if (_codeController.text.trim().isEmpty) return;

    setState(() {
      _isExecuting = true;
      _resultController.clear();
    });

    try {
      final fjsService = Provider.of<FjsService>(context, listen: false);
      
      dynamic result;
      if (mode == JsExecutionMode.script) {
        result = await fjsService.executeAsScript(_codeController.text);
      } else {
        result = await fjsService.executeAsModule(_codeController.text);
      }

      setState(() {
        _resultController.text = JsonEncoder.withIndent('  ').convert(result.value);
      });
    } catch (e) {
      setState(() {
        _resultController.text = 'Error: $e';
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  void _clearAll() {
    _codeController.clear();
    _resultController.clear();
  }

  Future<void> _copyResultToClipboard() async {
    if (_resultController.text.trim().isEmpty) return;

    try {
      await Clipboard.setData(ClipboardData(text: _resultController.text));
      
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('JavaScript Playground'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAll,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Code input section
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.code),
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
                          const SizedBox(width: 8),
                          if (_isExecuting)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
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
                              hintText: '// Enter your JavaScript code here...',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Mode description
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, 
                              size: 20, 
                              color: Colors.blue.shade700
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Script mode: uses eval(), no import support\nModule mode: supports import/export statements',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isExecuting 
                                  ? null 
                                  : () => _executeCode(JsExecutionMode.script),
                              icon: const Icon(Icons.code),
                              label: Text(
                                _isExecuting ? 'Executing...' : 'Run as Script'
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isExecuting 
                                  ? null 
                                  : () => _executeCode(JsExecutionMode.module),
                              icon: const Icon(Icons.integration_instructions),
                              label: Text(
                                _isExecuting ? 'Executing...' : 'Run as Module'
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isExecuting ? null : _clearAll,
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear All'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Result section
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.output),
                          const SizedBox(width: 8),
                          Text(
                            'Result',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          // Copy button with dynamic state
                          if (_resultController.text.trim().isNotEmpty)
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _resultController.text.startsWith('Error:')
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _resultController.text.startsWith('Error:')
                                  ? Colors.red.shade200
                                  : Colors.green.shade200,
                            ),
                          ),
                          child: TextField(
                            controller: _resultController,
                            maxLines: null,
                            expands: true,
                            readOnly: true,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              color: _resultController.text.startsWith('Error:')
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(12),
                              hintText: 'Result will appear here...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<FjsService>(
        builder: (context, fjsService, _) {
          return FloatingActionButton.extended(
            onPressed: _isExecuting 
                ? null 
                : () {
                    // Auto-detect mode based on code
                    final hasImport = RegExp(
                      r'^\s*import\s+.*\s+from\s+["\x27"]',
                      multiLine: true,
                    ).hasMatch(_codeController.text);
                    
                    _executeCode(
                      hasImport 
                          ? JsExecutionMode.module 
                          : JsExecutionMode.script
                    );
                  },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Auto Run'),
            tooltip: 'Auto-detect and execute (Module mode for imports)',
          );
        },
      ),
    );
  }
}
