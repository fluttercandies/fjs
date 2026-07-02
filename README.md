<div align="center">
  <img src="fjs.png" alt="FJS Logo" width="240">

  # 🚀 FJS - Flutter JavaScript Engine

  High-performance JavaScript runtime for Flutter ⚡
  Built with Rust and powered by QuickJS 🦀

  [![pub package](https://img.shields.io/pub/v/fjs.svg)](https://pub.dev/packages/fjs)
  [![GitHub stars](https://img.shields.io/github/stars/fluttercandies/fjs.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/fluttercandies/fjs)
  [![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/fluttercandies/fjs/blob/main/LICENSE)

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

  // Create engine with builtin modules
  final engine = await JsEngine.create(
    builtins: JsBuiltinOptions(
      console: true,
      fetch: true,
      timers: true,
    ),
  );
  await engine.init(bridge: (jsValue) {
    return JsResult.ok(JsValue.string('Hello from Dart'));
  });

  // Execute JavaScript
  final result = await engine.eval(source: JsCode.code('''
    console.log('Hello from FJS!');
    1 + 2
  '''));
  print(result.value); // 3

  await engine.close();
}
```

## 🏗️ Runtime & Context APIs

```dart
// Create an async runtime with web-style builtins and one extra ES module.
final runtime = await JsAsyncRuntime.create(
  builtins: JsBuiltinOptions.web(),
  modules: [
    JsModule.code(
      module: 'app/math',
      code: 'export function add(a, b) { return a + b; }',
    ),
  ],
);

// Apply runtime-level safety and diagnostic limits.
await runtime.setInfo(info: 'main-runtime');
await runtime.setMemoryLimit(limit: BigInt.from(64 * 1024 * 1024));
await runtime.setGcThreshold(threshold: BigInt.from(8 * 1024 * 1024));
await runtime.setMaxStackSize(limit: BigInt.from(512 * 1024));

// Create a context from that runtime.
final context = await JsAsyncContext.from(runtime: runtime);

// Evaluate a simple expression and read the structured JsResult.
final evalResult = await context.eval(code: '21 + 21');
print(evalResult.ok.value); // 42

// Enable top-level await / Promise handling explicitly.
final asyncResult = await context.evalWithOptions(
  code: 'await Promise.resolve(40 + 2)',
  options: JsEvalOptions.withPromise(),
);
print(asyncResult.ok.value); // 42

// Load code from disk.
final fileResult = await context.evalFile(path: '/absolute/path/to/script.js');
final strictFileResult = await context.evalFileWithOptions(
  path: '/absolute/path/to/script.js',
  options: JsEvalOptions.defaults(),
);

// Call an exported function from a module that is already available in the runtime.
final functionResult = await context.evalFunction(
  module: 'app/math',
  method: 'add',
  params: [JsValue.integer(2), JsValue.integer(3)],
);
print(functionResult.ok.value); // 5

// Inspect which modules the context can currently import.
final availableModules = await context.getAvailableModules();
print(availableModules);

// Detached Promise, timer, fetch, and spawned async work is driven automatically.
// Prefer JavaScript .catch() for failures that are expected and owned by JS.
await context.evalWithOptions(
  code: '''
    Promise.resolve()
      .then(() => 'background result')
      .catch((error) => console.log(String(error)));
    undefined
  ''',
  options: JsEvalOptions.withPromise(),
);
```

Low-level context APIs return `JsResult`, which is useful when you want structured success or error handling instead of exceptions.
Detached JavaScript work is scheduled automatically. Use JavaScript `.catch()`
for expected detached failures; unhandled background failures are surfaced on a
later `eval()`, `call()`, low-level context operation, or `close()`. When you
prefer to observe them without failing an unrelated call, drain them explicitly
with `engine.drainUnhandledJobErrors()` (works in every engine state, including
after `close()`).

### Async Work and Error Handling

Async runtimes own their background driver internally. Application code does not
start, stop, poll, or drain the driver for normal use:

```dart
final engine = await JsEngine.create(
  builtins: JsBuiltinOptions.web(),
);
await engine.initWithoutBridge();

await engine.eval(source: const JsCode.code('''
  setTimeout(() => {
    globalThis.ready = true;
  }, 10);
  "scheduled";
'''));

// The timer above is advanced by FJS. Any later engine operation observes the
// updated JS state after the timer fires.
await Future<void>.delayed(const Duration(milliseconds: 20));
final ready = await engine.eval(
  source: const JsCode.code('globalThis.ready === true'),
);
print(ready.value); // true

await engine.close();
```

If detached JavaScript work owns a failure path, catch it in JavaScript:

```dart
await engine.eval(source: const JsCode.code('''
  async function runOptionalBackgroundTask() {
    throw new Error("optional task failed");
  }

  Promise.resolve()
    .then(() => runOptionalBackgroundTask())
    .catch((error) => console.log(String(error)));
  undefined;
'''));
```

If detached work fails without a JavaScript `.catch()`, FJS stores the formatted
QuickJS error in a bounded runtime queue and surfaces it automatically through a
later public operation:

```dart
await engine.eval(source: const JsCode.code('''
  setTimeout(() => {
    throw new Error("background task failed");
  }, 10);
  "scheduled";
'''));

await Future<void>.delayed(const Duration(milliseconds: 20));
try {
  await engine.eval(source: const JsCode.code('1 + 1'));
} catch (error) {
  // Contains "Unhandled JavaScript background error" and the original JS stack.
  print(error);
}
```

This keeps the user-facing lifecycle small: create an engine, run JavaScript,
and call `close()` when the owner is done. In `3.2.0+`, `close()` is immediate:
it stops accepting work and cancels in-flight foreground operations with
`JsError.cancelled` without draining arbitrary timers, Promise callbacks, fetches,
bridge calls, or spawned runtime work. Use `closeGracefully()` only when you
intentionally want the old draining behavior and are prepared to wait for
already-scheduled JavaScript work to finish. Lower-level async runtime/context
users still get the same automatic driver behavior; Dart application code does
not start, stop, poll, or drain that driver.

### Synchronous Runtime & Context

```dart
// Build a synchronous runtime when you do not need async JavaScript execution.
final runtime = await JsRuntime.create(
  builtins: JsBuiltinOptions.essential(),
);
final context = JsContext.from(runtime: runtime);

// Sync contexts return JsResult directly.
final result = context.eval(code: '6 * 7');
print(result.ok.value); // 42

// Apply eval flags such as strict mode.
final strictResult = context.evalWithOptions(
  code: '"use strict"; 8 * 8',
  options: JsEvalOptions.defaults(),
);
print(strictResult.ok.value); // 64

// File-based sync evaluation uses the same JsResult shape.
final fileResult = context.evalFile(path: '/absolute/path/to/script.js');
final fileWithOptions = context.evalFileWithOptions(
  path: '/absolute/path/to/script.js',
  options: JsEvalOptions.defaults(),
);

// Introspect the modules visible to this context.
final modules = context.getAvailableModules();
print(modules);

// Pump the QuickJS job queue manually in sync mode.
while (runtime.isJobPending()) {
  runtime.executePendingJob();
}

// Configure runtime limits and collect memory statistics.
runtime.setMemoryLimit(limit: BigInt.from(32 * 1024 * 1024));
runtime.setGcThreshold(threshold: BigInt.from(4 * 1024 * 1024));
runtime.setMaxStackSize(limit: BigInt.from(256 * 1024));
runtime.setInfo(info: 'sync-runtime');
print(runtime.memoryUsage().summary());
runtime.runGc();
```

## 🧱 Source Inputs & Eval Options

```dart
import 'dart:convert';
import 'dart:typed_data';

// Source code can come from a string, a file path, or UTF-8 bytes.
final inlineCode = JsCode.code('1 + 1');
final fileCode = JsCode.path('/absolute/path/to/script.js');
final bytesCode = JsCode.bytes(Uint8List.fromList(utf8.encode('2 + 2')));

// Modules support the same three source forms.
final inlineModule = JsModule.code(
  module: 'feature/inline',
  code: 'export const enabled = true;',
);
final fileModule = JsModule.path(
  module: 'feature/file',
  path: '/absolute/path/to/feature.js',
);
final bytesModule = JsModule.bytes(
  module: 'feature/bytes',
  bytes: utf8.encode('export const answer = 42;'),
);

// Eval options control whether code runs as global script, async code, or module-style code.
final defaultEval = JsEvalOptions.defaults();
final asyncEval = JsEvalOptions.withPromise();
final moduleEval = JsEvalOptions.module();
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
  const { add, multiply } = await import('math');
  console.log(add(2, 3));        // 5
  console.log(multiply(4, 5));   // 20
'''));

// Or call an exported function directly without writing an import wrapper yourself.
final sum = await engine.call(
  module: 'math',
  method: 'add',
  params: [JsValue.integer(2), JsValue.integer(3)],
);
print(sum.value); // 5

// Batch-register multiple modules in one request.
await engine.declareNewModules(modules: [
  JsModule.code(
    module: 'numbers/double',
    code: 'export const double = (value) => value * 2;',
  ),
  JsModule.code(
    module: 'numbers/triple',
    code: 'export const triple = (value) => value * 3;',
  ),
]);

// Execute a module immediately and leave it cached in the current context.
await engine.evaluateModule(
  module: JsModule.code(
    module: 'startup',
    code: 'globalThis.started = true; export default "ready";',
  ),
);

// Inspect the dynamic modules declared on this engine.
final declaredModules = await engine.getDeclaredModules();
final hasMath = await engine.isModuleDeclared(moduleName: 'math');
print(declaredModules);
print(hasMath); // true
```

Dynamic modules can be cleared only before they are loaded. After a module has been imported or evaluated in a context, recreate the context to replace it.

## 📚 Module Inventory

```dart
final modules = await engine.getAvailableModules();
print(modules);

final hasConsole = await engine.isModuleAvailable(moduleName: 'console');
final hasXml = await engine.isModuleAvailable(moduleName: 'llrt:xml');
print('console: $hasConsole, llrt:xml: $hasXml');
```

## 🔄 Engine Lifecycle Notes

- `JsEngine` creates and owns its internal runtime/context when constructed via `create()`
- `close()` marks the engine closed immediately, requests runtime shutdown, stops the driver, detaches the `fjs` bridge object, and cancels in-flight foreground work with `JsError.cancelled`
- `closeGracefully()` keeps the pre-3.2 draining behavior: it waits for already-scheduled timers, Promise callbacks, fetches, bridge calls, and spawned runtime work to finish before GC
- `clearPendingModules()` only removes dynamic modules that have not been loaded into the current context yet
- `declareNewModules()` and `declareNewBytecodeModules()` reject duplicate module names in a single request

## 📦 Module Bytecode

```dart
// Compile an ES module into QuickJS bytecode without touching the current engine.
final bytecode = await JsBytecode.compile(
  module: JsModule.code(
    module: 'plugin/main.js',
    code: 'export function run() { return "ready"; }',
  ),
  options: JsModuleBytecodeOptions.defaults(),
);

// Validate the bytecode payload before declaring it.
await JsBytecode.validate(module: bytecode);

// Register the precompiled module on the engine.
await engine.declareNewBytecodeModule(module: bytecode);

// Import and execute the declared module like any other ES module.
final result = await engine.eval(source: JsCode.code('''
  const { run } = await import('plugin/main.js');
  run();
'''));

// Reconstruct bytecode from persisted bytes when loading from storage.
final restored = JsModuleBytecode(
  name: bytecode.name,
  bytes: bytecode.bytes,
);
JsBytecode.validateSync(module: restored);
```

`JsBytecode.compile()` runs in an isolated QuickJS context, so compiling does not declare or cache the module inside the current engine. `JsBytecode.validate()` only checks structural validity and embedded module name; it does not execute the module. `compileSync()` / `validateSync()` are also available for synchronous callers, but the async variants are safer on the main isolate.

QuickJS bytecode is version-specific and must be treated as trusted input. Recompile bytecode whenever the embedded QuickJS version changes.

### Bytecode Bundles

```dart
// Compile a full module graph into one distributable bundle.
final bundle = await JsBytecode.compileModuleBundle(
  entry: 'plugins/main.js',
  modules: [
    JsModule.code(
      module: 'plugins/deps/math.js',
      code: 'export const double = (value) => value * 2;',
    ),
    JsModule.code(
      module: 'plugins/main.js',
      code: '''
        import { double } from './deps/math.js';
        export default { ready: true, answer: double(21) };
      ''',
    ),
  ],
);

// Validate the bundle structure before loading it.
await JsBytecode.validateBundle(bundle: bundle);

// Execute the bundle entry and cache the involved modules.
await engine.evaluateBytecodeBundle(bundle: bundle);

// Read exports by importing the entry module afterwards.
final result = await engine.eval(source: JsCode.code('''
  const { default: plugin } = await import('plugins/main.js');
  plugin
'''));
print(result.value); // { ready: true, answer: 42 }
```

Bundles are useful when a plugin ships as a module graph instead of a single file. Relative imports are preserved inside the compiled bundle, and `declareNewBytecodeBundle()` is available when you want to register the bundle without executing its entry yet. `validateBundle()` is structural: it checks entry presence, duplicate names, and that each payload is readable by the embedded QuickJS version. `evaluateBytecodeBundle()` executes the entry and populates the module cache; import the entry afterwards to read its exports.

### Classic Script Bytecode

```dart
// Compile classic script source into non-module bytecode.
final script = await JsBytecode.compileScript(
  name: 'startup.js',
  source: JsCode.code('''
    await Promise.resolve();
    globalThis.launchCount = (globalThis.launchCount ?? 0) + 1;
    ({ mode: 'script', launchCount: globalThis.launchCount })
  '''),
  options: const JsScriptBytecodeOptions(
    promise: true,
    strict: true,
    stripSource: true,
    stripDebug: true,
    endianness: JsBytecodeEndianness.little,
  ),
);

// Validate before evaluation.
await JsBytecode.validateScript(script: script);

// Execute the script bytecode and read its completion value.
final result = await engine.evaluateScriptBytecode(script: script);
print(result.value); // { mode: 'script', launchCount: 1 }
```

Script bytecode is the non-module counterpart to ES module bytecode. `validateScript()` is structural only: it ensures the bytes decode as executable non-module bytecode under the embedded QuickJS version. QuickJS does not expose an embedded script name to verify at load time, so the `name` acts as compile-time metadata and the source filename shown in stack traces.

## 🧾 Values, Results, and Errors

```dart
import 'dart:typed_data';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

// Convert common Dart values into structured JsValue instances automatically.
final payload = JsValue.from({
  'enabled': true,
  'count': 3,
  'tags': ['a', 'b'],
  'buffer': Uint8List.fromList([1, 2, 3]),
});
print(payload.typeName()); // Object
print(payload.value); // Dart Map<String, dynamic>

// Or build typed JsValue trees yourself when you need exact control.
final typed = JsValue.object({
  'big': JsValue.bigint('9007199254740993'),
  'createdAt': JsValue.date(DateTime.now().millisecondsSinceEpoch),
});
print(typed.value);

// Low-level context APIs return JsResult instead of throwing.
final result = await context.eval(code: '40 + 2');
if (result.isOk) {
  print(result.ok.value); // 42
} else {
  print('${result.err.code()}: ${result.err}');
}

// JsError values are useful for structured error handling and retry decisions.
const syntaxError = JsError.syntax(
  message: 'Unexpected token',
  line: 1,
  column: 10,
);
print(syntaxError.code());
print(syntaxError.isRecoverable());

// High-level execution APIs throw a typed JsError on failure, classified
// from the real QuickJS exception (SyntaxError, TypeError, ReferenceError,
// stack overflow, memory limit, ...), including line/column and stack text.
try {
  await engine.eval(source: JsCode.code('invalid.code()'));
} on JsError catch (e) {
  print('Execution failed [${e.code()}]: $e');
  switch (e) {
    case JsError_Syntax(:final line, :final column):
      print('Syntax error at $line:$column');
    case JsError_Reference():
      print('Reference error');
    default:
      break;
  }
}
```

`JsError` is used everywhere: thrown by `JsEngine`/`JsBytecode` methods and returned inside `JsResult.err(...)` by low-level context APIs and the bridge. Use `code()` for stable programmatic matching or pattern-match the freezed variants.

## 🌉 Bridge Communication

```dart
// The bridge receives a JsValue and returns a JsResult back to JavaScript.
await engine.init(bridge: (jsValue) async {
  final data = jsValue.value;

  if (data is Map && data['action'] == 'fetchUser') {
    final user = await fetchUser(data['id']);
    return JsResult.ok(JsValue.from(user));
  }

  return JsResult.ok(JsValue.none());
});

// In JavaScript, call back into Dart through the injected fjs object.
await engine.eval(source: JsCode.code('''
  const user = await fjs.bridge_call({ action: 'fetchUser', id: 123 });
  console.log(user);
'''));
```

## 🧠 Memory Management

```dart
// Set runtime safety limits.
await runtime.setMemoryLimit(limit: BigInt.from(50 * 1024 * 1024)); // 50MB
await runtime.setGcThreshold(threshold: BigInt.from(10 * 1024 * 1024)); // 10MB
await runtime.setMaxStackSize(limit: BigInt.from(512 * 1024)); // 512KB

// Inspect current memory usage.
final usage = await runtime.memoryUsage();
print(usage.summary());

// Force a garbage collection pass when you need immediate cleanup.
await runtime.runGc();
```

## 📚 Core API

### JsAsyncRuntime & JsAsyncContext

```dart
abstract class JsAsyncRuntime {
  factory JsAsyncRuntime();
  static Future<JsAsyncRuntime> create({
    JsBuiltinOptions? builtins,
    List<JsModule>? modules,
  });

  Future<MemoryUsage> memoryUsage();
  Future<void> setMemoryLimit({required BigInt limit});
  Future<void> setGcThreshold({required BigInt threshold});
  Future<void> setMaxStackSize({required BigInt limit});
  Future<void> setInfo({required String info});
  Future<void> runGc();
}

abstract class JsAsyncContext {
  static Future<JsAsyncContext> from({required JsAsyncRuntime runtime});

  Future<JsResult> eval({required String code});
  Future<JsResult> evalWithOptions({required String code, required JsEvalOptions options});
  Future<JsResult> evalFile({required String path});
  Future<JsResult> evalFileWithOptions({required String path, required JsEvalOptions options});
  Future<JsResult> evalFunction({
    required String module,
    required String method,
    List<JsValue>? params,
  });

  Future<List<String>> getAvailableModules();
}
```

### JsRuntime & JsContext

```dart
abstract class JsRuntime {
  factory JsRuntime();
  static Future<JsRuntime> create({
    JsBuiltinOptions? builtins,
    List<JsModule>? modules,
  });

  bool isJobPending();
  bool executePendingJob();
  MemoryUsage memoryUsage();
  void setDumpFlags({required BigInt flags});
  void setMemoryLimit({required BigInt limit});
  void setGcThreshold({required BigInt threshold});
  void setMaxStackSize({required BigInt limit});
  void setInfo({required String info});
  void runGc();
}

abstract class JsContext {
  static JsContext from({required JsRuntime runtime});

  JsResult eval({required String code});
  JsResult evalWithOptions({required String code, required JsEvalOptions options});
  JsResult evalFile({required String path});
  JsResult evalFileWithOptions({required String path, required JsEvalOptions options});
  List<String> getAvailableModules();
}
```

### JsEngine

```dart
abstract class JsEngine {
  static Future<JsEngine> create({
    JsBuiltinOptions? builtins,
    List<JsModule>? modules,
    JsEngineRuntimeOptions? runtimeOptions,
  });

  Future<void> init({required FutureOr<JsResult> Function(JsValue) bridge});
  Future<void> initWithoutBridge();
  Future<JsValue> eval({required JsCode source, JsEvalOptions? options});
  Future<JsValue> call({required String module, required String method, List<JsValue>? params});

  Future<void> declareNewModule({required JsModule module});
  Future<void> declareNewModules({required List<JsModule> modules}); // rejects duplicate names in one request
  Future<void> declareNewBytecodeBundle({required JsModuleBytecodeBundle bundle});
  Future<void> declareNewBytecodeModule({required JsModuleBytecode module});
  Future<void> declareNewBytecodeModules({required List<JsModuleBytecode> modules}); // rejects duplicate names in one request
  Future<void> clearPendingModules();
  Future<List<String>> getAvailableModules();
  Future<bool> isModuleDeclared({required String moduleName});
  Future<bool> isModuleAvailable({required String moduleName});
  Future<List<String>> getDeclaredModules();
  Future<JsValue> evaluateBytecodeBundle({required JsModuleBytecodeBundle bundle});
  Future<JsValue> evaluateModule({required JsModule module});
  Future<JsValue> evaluateBytecodeModule({required JsModuleBytecode module});
  Future<JsValue> evaluateScriptBytecode({required JsScriptBytecode script});

  Future<MemoryUsage> memoryUsage();
  Future<void> runGc();
  Future<void> setGcThreshold({required BigInt threshold});
  Future<void> setInfo({required String info});
  Future<void> setMaxStackSize({required BigInt limit});
  Future<void> setMemoryLimit({required BigInt limit});
  List<String> drainUnhandledJobErrors(); // background JS failures; usable in every state
  Future<void> close(); // immediate shutdown; cancels in-flight foreground work
  Future<void> closeGracefully(); // drains pending runtime work, then runs GC
  bool get running;
  bool get closed;
}
```

### JsEngineRuntimeOptions

```dart
sealed class JsEngineRuntimeOptions {
  const factory JsEngineRuntimeOptions({
    BigInt? memoryLimit,
    BigInt? gcThreshold,
    BigInt? maxStackSize,
    String? info,
  });
}
```

### MemoryUsage

```dart
abstract class MemoryUsage {
  PlatformInt64 get totalMemory;
  PlatformInt64 get totalAllocations;
  PlatformInt64 get mallocSize;
  PlatformInt64 get objCount;
  PlatformInt64 get strCount;
  // ... plus detailed counters: atomCount/Size, shapeCount/Size, propCount/Size,
  // jsFuncCount/Size, arrayCount, fastArrayCount, binaryObjectCount/Size, etc.
  String summary();
}
```

### JsValue

```dart
sealed class JsValue {
  const factory JsValue.none();
  const factory JsValue.boolean(bool value);
  const factory JsValue.integer(PlatformInt64 value);
  const factory JsValue.float(double value);
  const factory JsValue.bigint(String value);
  const factory JsValue.string(String value);
  const factory JsValue.bytes(Uint8List value);
  const factory JsValue.array(List<JsValue> value);
  const factory JsValue.object(Map<String, JsValue> value);
  const factory JsValue.date(PlatformInt64 value);
  const factory JsValue.symbol(String value);
  const factory JsValue.function(String value);

  static JsValue from(Object? any);
  String typeName();
  dynamic get value;

  // Variant tests and typed accessors.
  bool isNone() / isBoolean() / isNumber() / isString() / isBytes()
       / isArray() / isObject() / isDate() / isPrimitive();
  bool? get asBoolean; PlatformInt64? get asInteger; double? get asFloat;
  String? get asBigint; String? get asString; Uint8List? get asBytes;
  List<JsValue>? get asArray; Map<String, JsValue>? get asObject; num? get asNum;
}
```

### JsBuiltinOptions & JsEvalOptions

```dart
sealed class JsBuiltinOptions {
  const factory JsBuiltinOptions({
    bool? assert_,
    bool? console,
    bool? fetch,
    bool? timers,
    bool? crypto,
    bool? fs,
    bool? url,
    bool? process,
    bool? path,
    bool? util,
    bool? intl,
    bool? temporal,
    // ... other builtin toggles
  });

  static JsBuiltinOptions none();
  static JsBuiltinOptions essential();
  static JsBuiltinOptions web();
  static JsBuiltinOptions node();
  static JsBuiltinOptions all();
}

sealed class JsEvalOptions {
  factory JsEvalOptions({
    bool? global,
    bool? strict,
    bool? backtraceBarrier,
    bool? promise,
  });

  static JsEvalOptions defaults();
  static JsEvalOptions withPromise();
  static JsEvalOptions module();
}
```

### JsCode, JsModule, and Bytecode

```dart
sealed class JsCode {
  const factory JsCode.code(String value);    // Inline code
  const factory JsCode.path(String value);    // File path
  const factory JsCode.bytes(Uint8List value); // Raw UTF-8 source bytes

  bool isCode() / isPath() / isBytes();
}

sealed class JsModule {
  static JsModule code({required String module, required String code});
  static JsModule path({required String module, required String path});
  static JsModule bytes({required String module, required List<int> bytes}); // UTF-8 source bytes
}

sealed class JsModuleBytecode {
  factory JsModuleBytecode({required String name, required List<int> bytes});
}

sealed class JsModuleBytecodeBundle {
  factory JsModuleBytecodeBundle({
    String? entry,
    required List<JsModuleBytecode> modules,
  });
}

sealed class JsScriptBytecode {
  factory JsScriptBytecode({required String name, required List<int> bytes});
}

abstract class JsBytecode {
  static JsModuleBytecode compileSync({
    required JsModule module,
    JsModuleBytecodeOptions? options,
  });

  static Future<JsModuleBytecode> compile({
    required JsModule module,
    JsModuleBytecodeOptions? options,
  });

  static JsModuleBytecodeBundle compileModuleBundleSync({
    required List<JsModule> modules,
    String? entry,
    JsModuleBytecodeOptions? options,
  });

  static Future<JsModuleBytecodeBundle> compileModuleBundle({
    required List<JsModule> modules,
    String? entry,
    JsModuleBytecodeOptions? options,
  });

  static JsScriptBytecode compileScriptSync({
    required String name,
    required JsCode source,
    JsScriptBytecodeOptions? options,
  });

  static Future<JsScriptBytecode> compileScript({
    required String name,
    required JsCode source,
    JsScriptBytecodeOptions? options,
  });

  static void validateSync({required JsModuleBytecode module});
  static Future<void> validate({required JsModuleBytecode module});
  static void validateBundleSync({required JsModuleBytecodeBundle bundle});
  static Future<void> validateBundle({required JsModuleBytecodeBundle bundle});
  static void validateScriptSync({required JsScriptBytecode script});
  static Future<void> validateScript({required JsScriptBytecode script});
}

sealed class JsModuleBytecodeOptions {
  const factory JsModuleBytecodeOptions({
    JsBytecodeEndianness? endianness,
    bool? stripSource,
    bool? stripDebug,
  });

  static JsModuleBytecodeOptions defaults();
}

sealed class JsScriptBytecodeOptions {
  const factory JsScriptBytecodeOptions({
    JsBytecodeEndianness? endianness,
    bool? stripSource,
    bool? stripDebug,
    bool? strict,
    bool? backtraceBarrier,
    bool? promise,
  });

  static JsScriptBytecodeOptions defaults();
}
```

### JsResult & JsError

```dart
sealed class JsResult {
  const factory JsResult.ok(JsValue value);
  const factory JsResult.err(JsError error);

  bool get isOk;
  bool get isErr;
  JsValue get ok;
  JsError get err;
}

sealed class JsError {
  const factory JsError.promise(String message);
  const factory JsError.module({String? module, String? method, required String message});
  const factory JsError.context(String message);
  const factory JsError.storage(String message);
  const factory JsError.io({String? path, required String message});
  const factory JsError.runtime(String message);
  const factory JsError.generic(String message);
  const factory JsError.engine(String message);
  const factory JsError.bridge(String message);
  const factory JsError.conversion({
    required String from,
    required String to,
    required String message,
  });
  const factory JsError.timeout({
    required String operation,
    required BigInt timeoutMs,
  });
  const factory JsError.memoryLimit(String message);
  const factory JsError.stackOverflow(String message);
  const factory JsError.syntax({int? line, int? column, required String message});
  const factory JsError.reference(String message);
  const factory JsError.type(String message);
  const factory JsError.cancelled(String message);

  String code();
  bool isRecoverable();
  String toString(); // formatted message including stack text when available
}
```

## 🧩 Built-in Runtime Features

Some builtin options expose importable modules, and some install globals directly on the runtime.

| Option | Description |
|--------|-------------|
| `abort` | `AbortController` and abort-related globals |
| `assert_` | Assertion helpers |
| `asyncHooks` | Async lifecycle tracking |
| `buffer` | Buffer utilities for binary data |
| `childProcess` | Child process spawning |
| `console` | Console logging (`console.log`, `console.error`, etc.) |
| `crypto` | Cryptographic functions and Web Crypto globals |
| `dgram` | UDP sockets |
| `dns` | DNS resolution |
| `events` | `EventEmitter` support |
| `exceptions` | Exception helpers installed globally |
| `fetch` | Fetch API globals |
| `fs` | File system operations |
| `https` | HTTPS client module |
| `intl` | Lightweight `Intl.DateTimeFormat` timezone support |
| `navigator` | Navigator globals |
| `net` | TCP sockets |
| `os` | Operating system utilities (`not available on iOS`) |
| `path` | Path manipulation (POSIX/Windows) |
| `perfHooks` | Performance measurement APIs |
| `process` | Process information and environment |
| `streamWeb` | Web Streams API |
| `stringDecoder` | String decoding from buffers |
| `temporal` | `Temporal` global |
| `timers` | Timer functions (`setTimeout`, `setInterval`, `setImmediate`) |
| `tty` | Terminal utilities |
| `url` | URL parsing and formatting |
| `util` | Utility functions |
| `zlib` | Compression/decompression (gzip, deflate) |
| `json` | JSON static method compatibility helpers |

### Quick Presets

```dart
// Essential: console, timers, buffer, util, json
JsBuiltinOptions.essential()

// Web: console, timers, fetch, url, crypto, streamWeb, navigator, exceptions, intl, json
JsBuiltinOptions.web()

// Node.js: Most Node-compatible modules, plus https and intl
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

## ⚡ Performance Tips

1. **Reuse Engines** - Create once, use many times
2. **Set Memory Limits** - Configure appropriate limits
3. **Use Source Bytes** - Prefer `JsCode.bytes()` / `JsModule.bytes()` when your JavaScript source is already in UTF-8 bytes
4. **Batch Operations** - Group related operations

## Darwin Packaging and Release

fjs supports both CocoaPods and Swift Package Manager on iOS and macOS. Flutter
discovers the shared Darwin package from `pubspec.yaml`; application developers
normally only add `fjs` to `pubspec.yaml` and run the usual Flutter build.

### CocoaPods

CocoaPods consumes `darwin/fjs.podspec` for shared Darwin builds, with
`ios/fjs.podspec` and `macos/fjs.podspec` kept for older Flutter layouts. The
podspec runs:

```sh
sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../libfjs fjs
```

That Cargokit script builds `libfjs.a` for the current Xcode platform and links
it with `-force_load`. When Rustup is installed, it builds from local Rust
source by default. When Rustup is missing, or when the application opts in with
`cargokit_options.yaml`, it downloads signed precompiled artifacts from the
GitHub Release configured in `libfjs/cargokit.yaml`.

```yaml
use_precompiled_binaries: true
verbose_logging: false
```

### Swift Package Manager

SwiftPM consumes `darwin/fjs/Package.swift`. The package exposes a small Swift
target and links the binary target at:

```text
darwin/fjs/Binaries/fjs.xcframework
```

The XCFramework is a release artifact, not a file edited by hand. If you are
working from source and need to refresh it locally, run:

```sh
tool/build_fjs_xcframework.sh --configuration Release
```

### Release Checklist

Before publishing a Darwin-capable release, run:

```sh
tool/prepare_darwin_release.sh --configuration Release
```

The script builds the XCFramework from the same Rust/Cargokit inputs used by
CocoaPods, writes it to `darwin/fjs/Binaries/fjs.xcframework`, creates
`build/darwin-release/fjs.xcframework.zip`, computes
`build/darwin-release/fjs.xcframework.zip.checksum`, validates the Darwin
package metadata, validates SwiftPM consumption, and runs
`flutter pub publish --dry-run`.

Upload `build/darwin-release/fjs.xcframework.zip` to the GitHub Release for the
package version. Keep the checksum next to the artifact for verification or for
a future remote `binaryTarget(url:checksum:)` manifest. The release script
forces local compilation before packaging the XCFramework so CocoaPods, SwiftPM,
and Cargokit precompiled releases are traceable to the same Rust inputs.

## 📄 License

MIT License - see [LICENSE](LICENSE) file.
