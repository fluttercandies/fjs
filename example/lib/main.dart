import 'package:fjs/fjs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/fjs_service.dart';
import 'services/js_examples_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await LibFjs.init();

    // Initialize services
    final storageService = StorageService();
    final fjsService = FjsService();

    // Initialize storage first
    await storageService.initialize();

    final jsExamplesService = JsExamplesService();

    runApp(
      FjsExampleApp(
        storageService: storageService,
        fjsService: fjsService,
        jsExamplesService: jsExamplesService,
      ),
    );
  } catch (e, stackTrace) {
    // Fallback error handling for initialization failures
    debugPrint('FATAL: Failed to initialize app: $e');
    debugPrint('Stack trace: $stackTrace');

    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red.shade50,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Initialization Failed',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The application failed to start properly. Please restart the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (kDebugMode) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Error: $e',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
