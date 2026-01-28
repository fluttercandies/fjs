<div align="center">
  <img src="fjs.png" alt="FJS Logo" width="240">

  # 🚀 FJS - Flutter JavaScript Engine

  High-performance JavaScript runtime for Flutter ⚡
  Built with Rust and powered by QuickJS 🦀

  [![pub package](https://img.shields.io/pub/v/fjs.svg)](https://pub.dev/packages/fjs)
  [![GitHub stars](https://img.shields.io/github/stars/fluttercandies/fjs.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/fluttercandies/fjs)
  [![License](https://img.shheels.io/badge/license-MIT-blue.svg)](https://github.com/fluttercandies/fjs/blob/main/LICENSE)

  *[🌏 中文文档](README_zh.md)*
</div>

## ✨ Why FJS?

- **High Performance** - Rust-powered, optimized for mobile platforms
- **ES6 Modules** - Full support for import/export syntax
- **Async/Await** - Native async JavaScript execution
- **Type Safe** - Strongly typed Dart API with sealed classes
- **Bridge Communication** - Bidirectional Dart-JS communication
- **Cross Platform** - Android, iOS, Linux, macOS, Windows
- **Memory Safe** - Built-in GC with configurable limits

## 🎯 Real-world Usage

**[Mikan Flutter](https://github.com/iota9star/mikan_flutter)** - A Flutter client for [Mikan Project](https://mikanani.me), an anime subscription and management platform. FJS powers its core JavaScript execution engine.

## 📦 Installation

```yaml
dependencies:
  fjs: any
```

## 🚀 Quick Start

```dart
import 'package:fjs/fjs.dart';

void main() async {
  await LibFjs.init();

  // Create runtime with builtin modules
  final runtime = await JsAsyncRuntime.withOptions(
    builtin: JsBuiltinOptions(
      console: true,
      fetch: true,
      timers: true,
    ),
  );

  // Create context
  final context = await JsAsyncContext.from(runtime);

  // Create engine
  final engine = JsEngine(context);
  await engine.init(bridge: (jsValue) {
    return JsResult.ok(JsValue.string('Hello from Dart'));
  });

  // Execute JavaScript
  final result = await engine.eval(JsCode.code('''
    console.log('Hello from FJS!');
    1 + 2
  '''));
  print(result.value); // 3

  await engine.dispose();
}
```

## 📦 ES6 Modules

```dart
// Declare modules
await engine.declareNewModule(
  module: JsModule.code(module: 'math', code: '''
    export const add = (a, b) => a + b;
    export const multiply = (a, b) => a * b;
  '''),
);

// Use modules
await engine.eval(source: JsCode.code('''
  import { add, multiply } from 'math';
  console.log(add(2, 3));        // 5
  console.log(multiply(4, 5));   // 20
'''));
```

## 🌉 Bridge Communication

```dart
await engine.init(bridge: (jsValue) async {
  final data = jsValue.value;

  if (data is Map && data['action'] == 'fetchUser') {
    final user = await fetchUser(data['id']);
    return JsResult.ok(JsValue.from(user));
  }

  return JsResult.ok(JsValue.none());
});

// In JavaScript
await engine.eval(source: JsCode.code('''
  const user = await fjs.bridge_call({ action: 'fetchUser', id: 123 });
  console.log(user);
'''));
```

## 🧠 Memory Management

```dart
// Set limits
await runtime.setMemoryLimit(50 * 1024 * 1024); // 50MB
await runtime.setGcThreshold(10 * 1024 * 1024);  // 10MB

// Monitor usage
final usage = await runtime.memoryUsage();
print(usage.summary());

// Force GC
await runtime.runGc();
```

## 📚 Core API

### JsEngine

```dart
class JsEngine {
  factory JsEngine({required JsAsyncContext context});

  Future<void> init({required FutureOr<JsResult> Function(JsValue) bridge});
  Future<void> initWithoutBridge();
  Future<JsValue> eval({required JsCode source, JsEvalOptions? options});
  Future<JsValue> call({required String module, required String method, List<JsValue>? params});

  Future<void> declareNewModule({required JsModule module});
  Future<void> declareNewModules({required List<JsModule> modules});
  Future<void> clearNewModules();
  Future<bool> isModuleDeclared({required String moduleName});
  Future<List<String>> getDeclaredModules();
  Future<JsValue> evaluateModule({required JsModule module});

  Future<void> dispose();
  bool get running;
  bool get disposed;
  JsAsyncContext get context;
}
```

### JsValue

```dart
sealed class JsValue {
  const factory JsValue.none();
  const factory JsValue.bool(bool value);
  const factory JsValue.integer(PlatformInt64 value);
  const factory JsValue.float(double value);
  const factory JsValue.string(String value);
  const factory JsValue.array(List<JsValue> value);
  const factory JsValue.object(Map<String, JsValue> value);

  static JsValue from(Object? any);
  dynamic get value;
}
```

### JsCode & JsModule

```dart
sealed class JsCode {
  const factory JsCode.code(String value);    // Inline code
  const factory JsCode.path(String value);    // File path
  const factory JsCode.bytes(Uint8List value); // Raw bytes
}

sealed class JsModule {
  static JsModule code({required String module, required String code});
  static JsModule path({required String module, required String path});
  static JsModule bytes({required String module, required List<int> bytes});
}
```

### JsResult

```dart
sealed class JsResult {
  const factory JsResult.ok(JsValue value);
  const factory JsResult.err(JsError error);

  bool get isOk;
  bool get isErr;
  JsValue get ok;
  JsError get err;
}
```

## 🧩 Built-in Modules

| Module | Description |
|--------|-------------|
| `console` | Console logging (`console.log`, `console.error`, etc.) |
| `timers` | Timer functions (`setTimeout`, `setInterval`, `setImmediate`) |
| `buffer` | Buffer utilities for binary data |
| `util` | Utility functions |
| `json` | JSON parsing and serialization |
| `fetch` | HTTP client (Fetch API) |
| `url` | URL parsing and formatting |
| `crypto` | Cryptographic functions (hash, HMAC, random bytes) |
| `events` | EventEmitter implementation |
| `streamWeb` | Web Streams API |
| `navigator` | Navigator information (web-compatible) |
| `exceptions` | Error handling utilities |
| `fs` | File system operations (Node.js-compatible) |
| `path` | Path manipulation (POSIX/Windows) |
| `process` | Process information and environment |
| `os` | Operating system utilities |
| `net` | Network TCP/UDP sockets |
| `dns` | DNS resolution |
| `childProcess` | Child process spawning |
| `workerThreads` | Worker thread support |
| `asyncHooks` | Async lifecycle tracking |
| `perfHooks` | Performance measurement APIs |
| `perfHooks` | Performance measurement APIs |
| `tty` | Terminal utilities |
| `stringDecoder` | String decoding from buffers |
| `zlib` | Compression/decompression (gzip, deflate) |
| `assert` | Assertion testing |
| `abort` | AbortController support |

### Quick Presets

```dart
// Essential: console, timers, buffer, util, json
JsBuiltinOptions.essential()

// Web: console, timers, fetch, url, crypto, streamWeb, navigator, exceptions, json
JsBuiltinOptions.web()

// Node.js: Most modules except OS-specific ones
JsBuiltinOptions.node()

// All modules
JsBuiltinOptions.all()

// Custom selection
JsBuiltinOptions(
  console: true,
  fetch: true,
  timers: true,
  // ... other options
)
```

## ⚠️ Error Handling

```dart
try {
  final result = await engine.eval(source: JsCode.code('invalid.code()'));
} on JsError catch (e) {
  print('Error: ${e.code()} - ${e}');
}
```

## ⚡ Performance Tips

1. **Reuse Engines** - Create once, use many times
2. **Set Memory Limits** - Configure appropriate limits
3. **Use Bytes** - Prefer `JsCode.bytes()` for binary data
4. **Batch Operations** - Group related operations

## 📄 License

MIT License - see [LICENSE](LICENSE) file.
