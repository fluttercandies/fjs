import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/js_actions_service.dart';

class JsActionsTestScreen extends StatefulWidget {
  const JsActionsTestScreen({super.key});

  @override
  State<JsActionsTestScreen> createState() => _JsActionsTestScreenState();
}

class _JsActionsTestScreenState extends State<JsActionsTestScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _testResults = [];
  bool _isRunningTests = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _runAllTests() async {
    if (_isRunningTests) return;

    setState(() {
      _isRunningTests = true;
      _testResults.clear();
    });

    try {
      final jsActionsService =
          Provider.of<JsActionsService>(context, listen: false);
      final results = await jsActionsService.runTestSuite();

      setState(() {
        _testResults.addAll(results);
      });

      // Scroll to bottom to show latest results
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _testResults.add({
          'success': false,
          'error': e.toString(),
          'action': 'test_suite',
        });
      });
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  Future<void> _runIndividualTest(
      String testName, Future<Map<String, dynamic>> Function() test) async {
    try {
      final result = await test();
      setState(() {
        _testResults.add(result);
      });

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _testResults.add({
          'success': false,
          'error': e.toString(),
          'action': testName,
        });
      });
    }
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  Future<void> _copyResultsToClipboard() async {
    if (_testResults.isEmpty) return;

    try {
      final jsonResults = JsonEncoder.withIndent('  ').convert(_testResults);
      await Clipboard.setData(ClipboardData(text: jsonResults));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test results copied to clipboard!'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JsActions Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            onPressed: _testResults.isEmpty ? null : _copyResultsToClipboard,
            tooltip: 'Copy Results',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearResults,
            tooltip: 'Clear Results',
          ),
        ],
      ),
      body: Consumer<JsActionsService>(
        builder: (context, jsActionsService, child) {
          return Column(
            children: [
              // Status bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: jsActionsService.isInitialized
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  border: Border(
                    bottom: BorderSide(
                      color: jsActionsService.isInitialized
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      jsActionsService.isInitialized
                          ? Icons.check_circle
                          : Icons.info_outline,
                      color: jsActionsService.isInitialized
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        jsActionsService.isInitialized
                            ? 'JsActions Service Ready'
                            : 'Initializing JsActions Service...',
                        style: TextStyle(
                          color: jsActionsService.isInitialized
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (jsActionsService.isExecuting)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main test button
                    FilledButton.icon(
                      onPressed:
                          jsActionsService.isInitialized && !_isRunningTests
                              ? _runAllTests
                              : null,
                      icon: _isRunningTests
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(_isRunningTests
                          ? 'Running Tests...'
                          : 'Run All Tests'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Individual test buttons
                    const Text(
                      'Individual Tests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: jsActionsService.isInitialized &&
                                  !_isRunningTests
                              ? () => _runIndividualTest(
                                    'declare_module',
                                    () => jsActionsService.testDeclareModule(
                                      moduleName: 'test-module',
                                      code: 'export const value = 42;',
                                    ),
                                  )
                              : null,
                          icon: const Icon(Icons.add),
                          label: const Text('Declare Module'),
                        ),
                        ElevatedButton.icon(
                          onPressed: jsActionsService.isInitialized &&
                                  !_isRunningTests
                              ? () => _runIndividualTest(
                                    'evaluate_module',
                                    () => jsActionsService.testEvaluateModule(
                                      moduleName: 'test-eval',
                                      code:
                                          'export const result = "Hello from module";',
                                    ),
                                  )
                              : null,
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Evaluate Module'),
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              jsActionsService.isInitialized && !_isRunningTests
                                  ? () => _runIndividualTest(
                                        'get_modules',
                                        () => jsActionsService
                                            .testGetDeclaredModules(),
                                      )
                                  : null,
                          icon: const Icon(Icons.list),
                          label: const Text('Get Modules'),
                        ),
                        ElevatedButton.icon(
                          onPressed: jsActionsService.isInitialized &&
                                  !_isRunningTests
                              ? () => _runIndividualTest(
                                    'clear_modules',
                                    () => jsActionsService.testClearModules(),
                                  )
                              : null,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Clear Modules'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Results section
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: _testResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.science_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No test results yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Click "Run All Tests" to start testing JsActions functionality',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _testResults.length,
                          itemBuilder: (context, index) {
                            final result = _testResults[index];
                            final isSuccess = result['success'] == true;
                            final action =
                                result['action'] as String? ?? 'Unknown';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isSuccess
                                              ? Icons.check_circle
                                              : Icons.error,
                                          color: isSuccess
                                              ? Colors.green
                                              : Colors.red,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            action,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: isSuccess
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Test ${index + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (result['error'] != null)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: Colors.red.shade200),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Error:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.red.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              result['error'].toString(),
                                              style: TextStyle(
                                                color: Colors.red.shade800,
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: Colors.green.shade200),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Success:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              JsonEncoder.withIndent('  ')
                                                  .convert(result)
                                                  .replaceAll(
                                                      'Success: true,\n', ''),
                                              style: TextStyle(
                                                color: Colors.green.shade800,
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
