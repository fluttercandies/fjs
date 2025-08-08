<div align="center">
  <img src="fjs.png" alt="FJS Logo" width="240">
  
  # 🚀 FJS - Flutter JavaScript Engine
  
  High-performance JavaScript runtime for Flutter ⚡  
  Built with Rust and powered by QuickJS 🦀
  
  [![pub package](https://img.shields.io/pub/v/fjs.svg)](https://pub.dev/packages/fjs)
  [![GitHub stars](https://img.shields.io/github/stars/fluttercandies/fjs.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/fluttercandies/fjs)
  [![GitHub forks](https://img.shields.io/github/forks/fluttercandies/fjs.svg?style=flat&logo=github&colorB=deeppink&label=forks)](https://github.com/fluttercandies/fjs)
  [![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/fluttercandies/fjs/blob/main/LICENSE)
  [![Platform](https://img.shields.io/badge/platform-android%20|%20ios%20|%20linux%20|%20macos%20|%20windows-lightgrey.svg)](https://github.com/fluttercandies/fjs)
  
  *[🌏 中文文档](README_zh.md)*
</div>

## ✨ Features

- 🚀 **High Performance**: Built with Rust for optimal performance
- 📦 **Module Support**: ES6 modules with import/export syntax
- 🌐 **Built-in APIs**: Fetch, Console, Buffer, Timers, Crypto, and more
- 🔄 **Async/Await**: Full support for asynchronous JavaScript
- 🌉 **Bridge Calls**: Seamless communication between Dart and JavaScript
- 📱 **Cross Platform**: Supports Android, iOS, Linux, macOS, and Windows
- 🎯 **Type Safe**: Strongly typed APIs with Dart integration
- 🧠 **Memory Management**: Built-in garbage collection and memory limits

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  fjs: any
```

Then run:

```bash
flutter pub get
```

## 🚀 Quick Start

### ⚡ 1. Initialize the Library

```dart
import 'package:fjs/fjs.dart';

Future<void> main() async {
  await LibFjs.init();
  runApp(MyApp());
}
```

### 🔧 2. Create a JavaScript Engine

```dart
// Create runtime and context
final runtime = JsAsyncRuntime();
final context = await JsAsyncContext.from(rt: runtime);

// Create engine with bridge support
final engine = JsEngine(context);
await engine.init(bridgeCall: (jsValue) {
  // Handle bridge calls from JavaScript
  print('Bridge call from JS: ${jsValue.value}');
  return JsValue.string('Response from Dart');
});
```

### 💻 3. Execute JavaScript Code

```dart
// Simple evaluation
final result = await engine.eval(JsCode.code('1 + 2'));
print(result.value); // 3

// Async JavaScript
final asyncResult = await engine.eval(JsCode.code('''
  (async () => {
    const response = await fetch('https://api.example.com/data');
    return await response.json();
  })()
'''));
```

### 🌐 4. Enable Built-in Modules

```dart
// Enable fetch and console APIs
await engine.enableBuiltinModule(const JsBuiltinOptions(
  fetch: true,
  console: true,
  timers: true,
));

// Now you can use fetch, console.log, setTimeout, etc.
await engine.eval(JsCode.code('''
  console.log('Hello from JavaScript!');
  setTimeout(() => console.log('Delayed message'), 1000);
'''));
```

### 📦 5. Work with Modules

```dart
// Declare a module
const moduleCode = '''
export function greet(name) {
  return `Hello, ${name}!`;
}

export const version = '1.0.0';
''';

await engine.declareModule(
  JsModule.code(module: 'greeting', code: moduleCode)
);

// Use the module
await engine.eval(JsCode.code('''
  import { greet, version } from 'greeting';
  console.log(greet('Flutter'));
  console.log('Version:', version);
'''));
```

## 🔥 Advanced Usage

### 🌉 Bridge Communication

Create bidirectional communication between Dart and JavaScript:

```dart
// Dart side
final engine = JsEngine(context);
await engine.init(bridgeCall: (jsValue) async {
  final data = jsValue.value;
  
  // Process data in Dart
  if (data is Map && data['action'] == 'fetchUserData') {
    final userId = data['userId'];
    final userData = await fetchUserFromDatabase(userId);
    return JsValue.from(userData);
  }
  
  return const JsValue.none();
});

// JavaScript side
await engine.eval(JsCode.code('''
  const userData = await fjs.bridge_call({
    action: 'fetchUserData',
    userId: 12345
  });
  console.log('User data:', userData);
'''));
```

### 🧠 Memory Management

```dart
// Set memory limits
final runtime = JsAsyncRuntime();
await runtime.setMemoryLimit(50 * 1024 * 1024); // 50MB
await runtime.setGcThreshold(10 * 1024 * 1024);  // 10MB

// Monitor memory usage
final usage = await runtime.memoryUsage();
print('Memory used: ${usage.memoryUsedSize} bytes');

// Force garbage collection
await runtime.runGc();
```

### ⚠️ Error Handling

```dart
try {
  final result = await engine.eval(JsCode.code('invalid.syntax()'));
} on JsError catch (e) {
  print('JavaScript Error: ${e.message}');
} catch (e) {
  print('Other Error: $e');
}
```

### 📁 Loading JavaScript from Files

```dart
// Load from file
final result = await engine.eval(JsCode.path('/path/to/script.js'));

// Or use evalFile method on context
final context = await JsAsyncContext.from(rt: runtime);
final result = await context.evalFile(path: '/path/to/script.js');
```

## 🧩 Built-in Modules

FJS provides several built-in modules that can be enabled as needed:

| Module | Description | Enable Option |
|--------|-------------|---------------|
| `fetch` | HTTP client for making network requests | `fetch: true` |
| `console` | Console logging (log, debug, warn, error) | `console: true` |
| `buffer` | Buffer manipulation utilities | `buffer: true` |
| `timers` | setTimeout, setInterval, clearTimeout, etc. | `timers: true` |
| `crypto` | Cryptographic functions | `crypto: true` |
| `stream` | Stream processing utilities | `stream: true` |
| `url` | URL parsing and manipulation | `url: true` |
| `events` | Event emitter implementation | `events: true` |

## 📚 API Reference

### JsEngine

The main interface for JavaScript execution:

```dart
class JsEngine {
  // Initialize the engine
  Future<void> init({FutureOr<JsValue?> Function(JsValue)? bridgeCall});
  
  // Execute JavaScript code
  Future<JsValue> eval(JsCode source, {JsEvalOptions? options, Duration? timeout});
  
  // Enable built-in modules
  Future<JsValue> enableBuiltinModule(JsBuiltinOptions options, {Duration? timeout});
  
  // Module operations
  Future<JsValue> declareModule(JsModule module, {Duration? timeout});
  Future<JsValue> evaluateModule(JsModule module, {Duration? timeout});
  Future<JsValue> importModule(String specifier, {Duration? timeout});
  
  // Cleanup
  Future<void> dispose();
  
  // Status
  bool get disposed;
  bool get running;
  bool get initialized;
}
```

### JsValue

Type-safe representation of JavaScript values:

```dart
sealed class JsValue {
  // Constructors
  const factory JsValue.none();
  const factory JsValue.boolean(bool value);
  const factory JsValue.integer(int value);
  const factory JsValue.float(double value);
  const factory JsValue.string(String value);
  const factory JsValue.array(List<JsValue> value);
  const factory JsValue.object(Map<String, JsValue> value);
  
  // Convert from Dart object
  static JsValue from(Object? any);
  
  // Get Dart value
  dynamic get value;
  
  // Type checking
  bool get isNone;
  bool get isBoolean;
  bool get isInteger;
  // ... other type checkers
}
```

## ⚡ Performance Tips

1. **Reuse Engines**: Create one engine instance and reuse it for multiple evaluations
2. **Set Memory Limits**: Configure appropriate memory limits for your use case
3. **Use Timeouts**: Always set reasonable timeouts for JavaScript execution
4. **Enable Only Needed Modules**: Only enable built-in modules you actually use
5. **Batch Operations**: Group related JavaScript operations together

## 🎯 Examples

Check out the [example](example/) directory for more comprehensive examples including:

- Basic JavaScript evaluation
- Module system usage
- Bridge communication
- Built-in API usage
- Error handling
- Performance testing

## ⚠️ Known Issues

### iOS Simulator Limitations

- **arm64 iOS Simulator**: Currently unable to compile for arm64 iOS simulator on Apple Silicon Macs due to rquickjs library limitations
- **Workaround**: iOS simulator only supports x86_64 architecture, real iOS devices are not affected  
- **Impact**: Development on Apple Silicon Macs will use Rosetta 2 translation when running iOS simulator
- **Production**: Real iOS devices (arm64) are fully supported with normal performance
- **Minimum iOS Version**: Requires iOS 12.0 or later due to native library dependencies

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
