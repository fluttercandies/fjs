import 'package:fjs/fjs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/fjs_service.dart';
import '../services/js_examples_service.dart';
import '../services/storage_service.dart';
import 'app.dart';

Future<Widget> buildFjsExampleApp({
  List<NavigatorObserver> navigatorObservers = const <NavigatorObserver>[],
}) async {
  await LibFjs.init();

  final storageService = StorageService();
  final fjsService = FjsService();

  await storageService.initialize();

  return FjsExampleApp(
    storageService: storageService,
    fjsService: fjsService,
    jsExamplesService: JsExamplesService(),
    navigatorObservers: navigatorObservers,
  );
}

Widget buildInitializationFailureApp(Object error, StackTrace stackTrace) {
  debugPrint('FATAL: Failed to initialize app: $error');
  debugPrint('Stack trace: $stackTrace');

  return MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade700),
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
                style: TextStyle(fontSize: 16, color: Colors.red.shade600),
              ),
              const SizedBox(height: 24),
              if (kDebugMode)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
