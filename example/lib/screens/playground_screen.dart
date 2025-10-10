import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _codeController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _executeCode() async {
    if (_codeController.text.trim().isEmpty) return;

    setState(() {
      _isExecuting = true;
      _resultController.clear();
    });

    try {
      final fjsService = Provider.of<FjsService>(context, listen: false);
      final result = await fjsService.executeCode(_codeController.text);

      setState(() {
        _resultController.text = result.toString();
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
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: _executeCode,
            tooltip: 'Execute Code',
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
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isExecuting ? null : _executeCode,
                              icon: const Icon(Icons.play_arrow),
                              label: Text(
                                  _isExecuting ? 'Executing...' : 'Execute'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _isExecuting ? null : _clearAll,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _executeCode,
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
