import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../services/fjs_service.dart';

/// JavaScript example categories
enum JsExampleCategory {
  basic('Basic Operations'),
  dataStructures('Data Structures'),
  strings('String Operations'),
  functions('Functions & Scope'),
  asyncOps('Async & Promises'),
  json('JSON & Data'),
  es6('ES6+ Features'),
  errorHandling('Error Handling & Debug'),
  llrt('LLRT Node.js Compatible Modules'),
  testing('Test Suite & Diagnostics'),
  examples('Advanced Examples'),
  modules('Module System Examples');

  const JsExampleCategory(this.displayName);
  final String displayName;
}

/// JavaScript example item
class JsExample {
  final String id;
  final String label;
  final String fileName;
  final JsExampleCategory category;
  final JsExecutionMode? executionMode;

  const JsExample({
    required this.id,
    required this.label,
    required this.fileName,
    required this.category,
    this.executionMode,
  });
}

/// Service for managing JavaScript examples
class JsExamplesService extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  final Map<String, String> _loadedExamples = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, String> get loadedExamples => Map.unmodifiable(_loadedExamples);

  /// All available examples
  static const List<JsExample> examples = [
    // Basic Operations
    JsExample(
      id: 'hello_world',
      label: 'Hello World',
      fileName: 'hello_world.js',
      category: JsExampleCategory.basic,
    ),
    JsExample(
      id: 'math',
      label: 'Math',
      fileName: 'math_operations.js',
      category: JsExampleCategory.basic,
    ),
    JsExample(
      id: 'date',
      label: 'Date',
      fileName: 'date_operations.js',
      category: JsExampleCategory.basic,
    ),
    JsExample(
      id: 'random',
      label: 'Random',
      fileName: 'random_number.js',
      category: JsExampleCategory.basic,
    ),

    // Data Structures
    JsExample(
      id: 'array_map',
      label: 'Array Map',
      fileName: 'array_map.js',
      category: JsExampleCategory.dataStructures,
    ),
    JsExample(
      id: 'array_filter',
      label: 'Array Filter',
      fileName: 'array_filter.js',
      category: JsExampleCategory.dataStructures,
    ),
    JsExample(
      id: 'array_reduce',
      label: 'Array Reduce',
      fileName: 'array_reduce.js',
      category: JsExampleCategory.dataStructures,
    ),
    JsExample(
      id: 'object_keys',
      label: 'Object Keys',
      fileName: 'object_keys.js',
      category: JsExampleCategory.dataStructures,
    ),
    JsExample(
      id: 'object_values',
      label: 'Object Values',
      fileName: 'object_values.js',
      category: JsExampleCategory.dataStructures,
    ),
    JsExample(
      id: 'destructuring',
      label: 'Destructuring',
      fileName: 'destructuring.js',
      category: JsExampleCategory.dataStructures,
    ),

    // String Operations
    JsExample(
      id: 'template_literal',
      label: 'Template Literal',
      fileName: 'template_literal.js',
      category: JsExampleCategory.strings,
    ),
    JsExample(
      id: 'string_methods',
      label: 'String Methods',
      fileName: 'string_methods.js',
      category: JsExampleCategory.strings,
    ),
    JsExample(
      id: 'regex',
      label: 'Regular Expression',
      fileName: 'regex_match.js',
      category: JsExampleCategory.strings,
    ),
    JsExample(
      id: 'string_padding',
      label: 'String Padding',
      fileName: 'string_padding.js',
      category: JsExampleCategory.strings,
    ),

    // Functions & Scope
    JsExample(
      id: 'arrow_function',
      label: 'Arrow Function',
      fileName: 'arrow_function.js',
      category: JsExampleCategory.functions,
    ),
    JsExample(
      id: 'closure',
      label: 'Closure',
      fileName: 'closure.js',
      category: JsExampleCategory.functions,
    ),
    JsExample(
      id: 'higher_order',
      label: 'Higher Order',
      fileName: 'higher_order.js',
      category: JsExampleCategory.functions,
    ),
    JsExample(
      id: 'recursive',
      label: 'Recursive',
      fileName: 'recursive.js',
      category: JsExampleCategory.functions,
    ),

    // Async & Promises
    JsExample(
      id: 'promise_chain',
      label: 'Promise Chain',
      fileName: 'promise_chain.js',
      category: JsExampleCategory.asyncOps,
    ),
    JsExample(
      id: 'async_await',
      label: 'Async/Await',
      fileName: 'async_await.js',
      category: JsExampleCategory.asyncOps,
    ),
    JsExample(
      id: 'promise_all',
      label: 'Promise All',
      fileName: 'promise_all.js',
      category: JsExampleCategory.asyncOps,
    ),
    JsExample(
      id: 'timeout',
      label: 'Timeout',
      fileName: 'timeout.js',
      category: JsExampleCategory.asyncOps,
    ),

    // JSON & Data
    JsExample(
      id: 'json_stringify',
      label: 'JSON Stringify',
      fileName: 'json_stringify.js',
      category: JsExampleCategory.json,
    ),
    JsExample(
      id: 'json_parse',
      label: 'JSON Parse',
      fileName: 'json_parse.js',
      category: JsExampleCategory.json,
    ),
    JsExample(
      id: 'deep_object',
      label: 'Deep Object',
      fileName: 'deep_object.js',
      category: JsExampleCategory.json,
    ),
    JsExample(
      id: 'optional_chaining',
      label: 'Optional Chaining',
      fileName: 'optional_chaining.js',
      category: JsExampleCategory.json,
    ),

    // ES6+ Features
    JsExample(
      id: 'spread_operator',
      label: 'Spread Operator',
      fileName: 'spread_operator.js',
      category: JsExampleCategory.es6,
    ),
    JsExample(
      id: 'rest_parameters',
      label: 'Rest Parameters',
      fileName: 'rest_parameters.js',
      category: JsExampleCategory.es6,
    ),
    JsExample(
      id: 'set_operations',
      label: 'Set Operations',
      fileName: 'set_operations.js',
      category: JsExampleCategory.es6,
    ),
    JsExample(
      id: 'map_operations',
      label: 'Map Operations',
      fileName: 'map_operations.js',
      category: JsExampleCategory.es6,
    ),
    JsExample(
      id: 'nullish_coalescing',
      label: 'Nullish Coalescing',
      fileName: 'nullish_coalescing.js',
      category: JsExampleCategory.es6,
    ),

    // Error Handling & Debug
    JsExample(
      id: 'try_catch',
      label: 'Try-Catch',
      fileName: 'try_catch.js',
      category: JsExampleCategory.errorHandling,
    ),
    JsExample(
      id: 'custom_error',
      label: 'Custom Error',
      fileName: 'custom_error.js',
      category: JsExampleCategory.errorHandling,
    ),
    JsExample(
      id: 'console_debug',
      label: 'Console Debug',
      fileName: 'console_debug.js',
      category: JsExampleCategory.errorHandling,
    ),
    JsExample(
      id: 'type_check',
      label: 'Type Check',
      fileName: 'type_check.js',
      category: JsExampleCategory.errorHandling,
    ),

    // LLRT Node.js Compatible Modules
    JsExample(
      id: 'llrt_console',
      label: 'console.log',
      fileName: 'llrt_console.js',
      category: JsExampleCategory.llrt,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'llrt_assert',
      label: 'assert',
      fileName: 'llrt_assert.js',
      category: JsExampleCategory.llrt,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'llrt_crypto_hash',
      label: 'crypto.hash',
      fileName: 'llrt_crypto_hash.js',
      category: JsExampleCategory.llrt,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'llrt_crypto_random',
      label: 'crypto.random',
      fileName: 'llrt_crypto_random.js',
      category: JsExampleCategory.llrt,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'llrt_crypto_hmac',
      label: 'crypto.hmac',
      fileName: 'llrt_crypto_hmac.js',
      category: JsExampleCategory.llrt,
      executionMode: JsExecutionMode.module,
    ),

    JsExample(
      id: 'llrt_fs_readfile',
      label: 'fs.readFile',
      fileName: 'llrt_fs_readfile.js',
      category: JsExampleCategory.llrt,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'llrt_path',
      label: 'path.join',
      fileName: 'llrt_path.js',
      category: JsExampleCategory.llrt,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'llrt_util',
      label: 'util.inspect',
      fileName: 'llrt_util.js',
      category: JsExampleCategory.llrt,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'llrt_buffer',
      label: 'buffer.from',
      fileName: 'llrt_buffer.js',
      category: JsExampleCategory.llrt,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'llrt_url',
      label: 'url.URL',
      fileName: 'llrt_url.js',
      category: JsExampleCategory.llrt,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'llrt_timers',
      label: 'setTimeout',
      fileName: 'llrt_timers.js',
      category: JsExampleCategory.llrt,
    ),
    JsExample(
      id: 'llrt_process',
      label: 'process.env',
      fileName: 'llrt_process.js',
      category: JsExampleCategory.llrt,
    ),
    JsExample(
      id: 'llrt_fetch',
      label: 'fetch',
      fileName: 'llrt_fetch.js',
      category: JsExampleCategory.llrt,
      executionMode: JsExecutionMode.module,
    ),

    // Test Suite & Diagnostics
    JsExample(
      id: 'test_all_modules',
      label: 'All Modules Test Runner',
      fileName: 'test_all_modules.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_console',
      label: 'Console Module Test',
      fileName: 'test_console.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_assert',
      label: 'Assert Module Test',
      fileName: 'test_assert.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_buffer',
      label: 'Buffer Module Test',
      fileName: 'test_buffer.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),

    JsExample(
      id: 'test_crypto',
      label: 'Crypto Module Test',
      fileName: 'test_crypto.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_path',
      label: 'Path Module Test',
      fileName: 'test_path.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_url',
      label: 'URL Module Test',
      fileName: 'test_url.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_process',
      label: 'Process Module Test',
      fileName: 'test_process.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_timers',
      label: 'Timers Module Test',
      fileName: 'test_timers.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_async_hooks',
      label: 'Async Hooks Module Test',
      fileName: 'test_async_hooks.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_tty',
      label: 'TTY Module Test',
      fileName: 'test_tty.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_util',
      label: 'Util Module Test',
      fileName: 'test_util.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_zlib',
      label: 'Zlib Module Test',
      fileName: 'test_zlib.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_diagnostic',
      label: 'Diagnostic Tests',
      fileName: 'test_diagnostic.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_builtin_modules',
      label: 'Builtin Modules Test',
      fileName: 'test_builtin_modules.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_copy_functionality',
      label: 'Copy Functionality Test',
      fileName: 'test_copy_functionality.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_simple_check',
      label: 'Simple Check Test',
      fileName: 'test_simple_check.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_homepage_copy',
      label: 'Homepage Copy Test',
      fileName: 'test_homepage_copy.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_import_conversion',
      label: 'Import Conversion Test',
      fileName: 'test_import_conversion.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'test_module_import',
      label: 'Module Import Test',
      fileName: 'test_module_import.js',
      category: JsExampleCategory.testing,
      executionMode: JsExecutionMode.script,
    ),

    // Advanced Examples - Script Mode
    JsExample(
      id: 'script_basic_operations',
      label: 'Script Basic Operations',
      fileName: 'script_basic_operations.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'script_global_objects',
      label: 'Script Global Objects',
      fileName: 'script_global_objects.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'script_fetch',
      label: 'Script Fetch API',
      fileName: 'script_fetch.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'script_dynamic_import',
      label: 'Script Dynamic Import',
      fileName: 'script_dynamic_import.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'script_promises',
      label: 'Script Promises',
      fileName: 'script_promises.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'script_arrays_objects',
      label: 'Script Arrays & Objects',
      fileName: 'script_arrays_objects.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'script_json',
      label: 'Script JSON Operations',
      fileName: 'script_json.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'script_regex',
      label: 'Script Regular Expressions',
      fileName: 'script_regex.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'script_error_handling',
      label: 'Script Error Handling',
      fileName: 'script_error_handling.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'script_timers',
      label: 'Script Timers',
      fileName: 'script_timers.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'script_complex_example',
      label: 'Script Complex Example',
      fileName: 'script_complex_example.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.script,
    ),

    // Advanced Examples - Module Mode
    JsExample(
      id: 'module_basic_import',
      label: 'Module Basic Import',
      fileName: 'module_basic_import.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'module_named_import',
      label: 'Module Named Import',
      fileName: 'module_named_import.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'module_mixed_import',
      label: 'Module Mixed Import',
      fileName: 'module_mixed_import.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'module_filesystem',
      label: 'Module File System',
      fileName: 'module_filesystem.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'module_network',
      label: 'Module Network Operations',
      fileName: 'module_network.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'module_streams',
      label: 'Module Streams',
      fileName: 'module_streams.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'module_comprehensive',
      label: 'Module Comprehensive',
      fileName: 'module_comprehensive.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'crypto_example',
      label: 'Crypto Usage Example',
      fileName: 'crypto_example.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.module,
    ),

    JsExample(
      id: 'fs_example',
      label: 'File System Example',
      fileName: 'fs_example.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'path_example',
      label: 'Path Usage Example',
      fileName: 'path_example.js',
      category: JsExampleCategory.examples,
      executionMode: JsExecutionMode.module,
    ),

    // Module System Examples (LLRT specific)
    JsExample(
      id: 'llrt_script_basic',
      label: 'LLRT Script Basic Operations',
      fileName: 'script_basic_operations.js',
      category: JsExampleCategory.modules,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'llrt_script_promises',
      label: 'LLRT Script Promises',
      fileName: 'script_promises.js',
      category: JsExampleCategory.modules,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'llrt_script_json',
      label: 'LLRT Script JSON',
      fileName: 'script_json.js',
      category: JsExampleCategory.modules,
      executionMode: JsExecutionMode.script,
    ),
    JsExample(
      id: 'llrt_module_basic',
      label: 'LLRT Module Basic Import',
      fileName: 'module_basic_import.js',
      category: JsExampleCategory.modules,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'llrt_module_named',
      label: 'LLRT Module Named Import',
      fileName: 'module_named_import.js',
      category: JsExampleCategory.modules,
      executionMode: JsExecutionMode.module,
    ),
    JsExample(
      id: 'llrt_module_comprehensive',
      label: 'LLRT Module Comprehensive',
      fileName: 'module_comprehensive.js',
      category: JsExampleCategory.modules,
      executionMode: JsExecutionMode.module,
    ),
  ];

  /// Get examples by category
  List<JsExample> getExamplesByCategory(JsExampleCategory category) {
    return examples.where((example) => example.category == category).toList();
  }

  /// Get example by ID
  JsExample? getExampleById(String id) {
    try {
      return examples.firstWhere((example) => example.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Load example code from assets
  Future<String?> loadExampleCode(String fileName) async {
    if (_loadedExamples.containsKey(fileName)) {
      return _loadedExamples[fileName];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final code = await rootBundle.loadString('assets/examples/$fileName');
      _loadedExamples[fileName] = code;
      _isLoading = false;
      notifyListeners();
      return code;
    } catch (e) {
      _error = 'Failed to load example $fileName: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Preload all examples
  Future<void> preloadAllExamples() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      for (final example in examples) {
        if (!_loadedExamples.containsKey(example.fileName)) {
          try {
            final code = await rootBundle
                .loadString('assets/examples/${example.fileName}');
            _loadedExamples[example.fileName] = code;
          } catch (e) {
            if (kDebugMode) {
              print('Failed to preload example ${example.fileName}: $e');
            }
          }
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to preload examples: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear loaded examples
  void clearCache() {
    _loadedExamples.clear();
    notifyListeners();
  }
}
