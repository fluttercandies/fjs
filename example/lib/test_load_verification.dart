import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../services/js_examples_service.dart';

/// Quick verification that key JS files can be loaded
Future<Map<String, bool>> verifyKeyFiles() async {
  final keyFiles = [
    'hello_world.js',
    'math_operations.js',
    'test_all_modules.js',
    'script_mode_examples.js',
    'module_mode_examples.js',
    'test_zlib.js',
    'crypto_example.js',
    'events_example.js',
  ];

  final results = <String, bool>{};
  
  for (final file in keyFiles) {
    try {
      final content = await rootBundle.loadString('assets/examples/$file');
      results[file] = content.isNotEmpty;
      if (kDebugMode) {
        print('✅ $file: ${content.length} characters');
      }
    } catch (e) {
      results[file] = false;
      if (kDebugMode) {
        print('❌ $file: $e');
      }
    }
  }
  
  return results;
}

/// Count total JS files in assets
Future<int> countJsFiles() async {
  // Since we can't directly list assets, we'll count from our service
  final allFiles = JsExamplesService.examples.map((e) => e.fileName).toSet();
  return allFiles.length;
}
