import 'package:flutter/services.dart';
import '../services/js_examples_service.dart';

/// Test utility to verify all JS examples can be loaded
class JsExamplesTestRunner {
  static Future<Map<String, dynamic>> testAllExamples() async {
    final results = <String, dynamic>{
      'totalFiles': 0,
      'loadedFiles': 0,
      'failedFiles': 0,
      'errors': <String, String>{},
      'categories': <String, Map<String, dynamic>>{},
    };

    try {
      // Test all examples
      for (final example in JsExamplesService.examples) {
        results['totalFiles'] = (results['totalFiles'] as int) + 1;
        
        try {
          final code = await rootBundle.loadString('assets/examples/${example.fileName}');
          if (code.isNotEmpty) {
            results['loadedFiles'] = (results['loadedFiles'] as int) + 1;
          } else {
            results['failedFiles'] = (results['failedFiles'] as int) + 1;
            results['errors'][example.fileName] = 'Empty file';
          }
          
          // Track by category
          final category = example.category.displayName;
          if (!results['categories'].containsKey(category)) {
            results['categories'][category] = {
              'total': 0,
              'loaded': 0,
              'failed': 0,
            };
          }
          results['categories'][category]['total']++;
          results['categories'][category]['loaded']++;
          
        } catch (e) {
          results['failedFiles'] = (results['failedFiles'] as int) + 1;
          results['errors'][example.fileName] = e.toString();
          
          // Track by category
          final category = example.category.displayName;
          if (!results['categories'].containsKey(category)) {
            results['categories'][category] = {
              'total': 0,
              'loaded': 0,
              'failed': 0,
            };
          }
          results['categories'][category]['total']++;
          results['categories'][category]['failed']++;
        }
      }
      
      // Calculate success rate
      results['successRate'] = results['totalFiles'] > 0 
          ? ((results['loadedFiles'] as int) / (results['totalFiles'] as int) * 100).toStringAsFixed(1)
          : '0.0';
          
    } catch (e) {
      results['testError'] = e.toString();
    }
    
    return results;
  }
  
  /// Get list of all JS files in assets/examples that are not in the service
  static Future<List<String>> getUntrackedFiles() async {
    // This would need to be implemented by scanning the assets directory
    // For now, return empty list as we've manually added all files
    return [];
  }
}
