<div align="center">
  <img src="fjs.png" alt="FJS Logo" width="240">

  # 🚀 FJS - Flutter JavaScript 引擎

  基于 Rust 构建的高性能 JavaScript 运行时 ⚡
  为 Flutter 应用提供无缝的 JavaScript 执行能力 🎯

  [![pub package](https://img.shields.io/pub/v/fjs.svg)](https://pub.dev/packages/fjs)
  [![GitHub stars](https://img.shields.io/github/stars/fluttercandies/fjs.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/fluttercandies/fjs)
  [![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/fluttercandies/fjs/blob/main/LICENSE)

  *[🌍 English Document](README.md)*
</div>

## ✨ 为何选择 FJS？

- **高性能** - Rust 驱动，专为移动平台优化
- **ES6 模块** - 完整支持 import/export 语法
- **异步支持** - 原生 async/await JavaScript 执行
- **类型安全** - 强类型 Dart API，使用 sealed classes
- **桥接通信** - Dart 与 JavaScript 双向通信
- **跨平台** - Android、iOS、Linux、macOS、Windows
- **内存安全** - 内置 GC，可配置内存限制

## 🎯 真实使用案例

**[Mikan Flutter](https://github.com/iota9star/mikan_flutter)** - [蜜柑计划](https://mikanani.me)的 Flutter 客户端，一款动漫番剧订阅与管理应用。FJS 为其核心 JavaScript 执行引擎提供动力。

## 📦 安装

```yaml
dependencies:
  fjs: any
```

## 🚀 快速开始

```dart
import 'package:fjs/fjs.dart';

void main() async {
  await LibFjs.init();

  // 创建引擎并启用内置模块
  final engine = await JsEngine.create(
    builtins: JsBuiltinOptions(
      console: true,
      fetch: true,
      timers: true,
    ),
  );
  await engine.init(bridge: (jsValue) {
    return JsResult.ok(JsValue.string('来自 Dart 的问候'));
  });

  // 执行 JavaScript
  final result = await engine.eval(source: JsCode.code('''
    console.log('你好，FJS！');
    1 + 2
  '''));
  print(result.value); // 3

  await engine.close();
}
```

## 🏗️ Runtime 与 Context API

```dart
// 创建一个异步 runtime，启用 web 风格 builtin，并额外挂一个 ES 模块。
final runtime = await JsAsyncRuntime.create(
  builtins: JsBuiltinOptions.web(),
  modules: [
    JsModule.code(
      module: 'app/math',
      code: 'export function add(a, b) { return a + b; }',
    ),
  ],
);

// 设置运行时级别的诊断信息与安全限制。
await runtime.setInfo(info: 'main-runtime');
await runtime.setMemoryLimit(limit: BigInt.from(64 * 1024 * 1024));
await runtime.setGcThreshold(threshold: BigInt.from(8 * 1024 * 1024));
await runtime.setMaxStackSize(limit: BigInt.from(512 * 1024));

// 基于该 runtime 创建 context。
final context = await JsAsyncContext.from(runtime: runtime);

// 执行简单表达式，并读取结构化的 JsResult。
final evalResult = await context.eval(code: '21 + 21');
print(evalResult.ok.value); // 42

// 显式启用 top-level await / Promise 支持。
final asyncResult = await context.evalWithOptions(
  code: 'await Promise.resolve(40 + 2)',
  options: JsEvalOptions.withPromise(),
);
print(asyncResult.ok.value); // 42

// 从文件加载并执行代码。
final fileResult = await context.evalFile(path: '/absolute/path/to/script.js');
final strictFileResult = await context.evalFileWithOptions(
  path: '/absolute/path/to/script.js',
  options: JsEvalOptions.defaults(),
);

// 调用运行时中已经可见模块导出的函数。
final functionResult = await context.evalFunction(
  module: 'app/math',
  method: 'add',
  params: [JsValue.integer(2), JsValue.integer(3)],
);
print(functionResult.ok.value); // 5

// 查看当前 context 能 import 的模块列表。
final availableModules = await context.getAvailableModules();
print(availableModules);

// 游离 Promise、timer、fetch 和其他后台异步任务会自动推进。
// 对预期内、由 JS 自己负责的失败，优先在 JavaScript 里使用 .catch()。
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

底层 context API 返回的是 `JsResult`，适合你需要结构化成功/失败结果，而不是直接依赖异常的场景。
后台 JavaScript 任务会自动调度。预期内的后台失败应优先用 JavaScript `.catch()`
处理；未处理的后台错误会在后续 `eval()`、`call()`、底层 context 操作或 `close()`
时自动暴露。如果你希望只做日志记录而不影响正常调用，可以主动调用
`engine.drainUnhandledJobErrors()` 取走这些错误（任何引擎状态下都可用，包括
`close()` 之后）。

### 异步任务与错误处理

异步 runtime 会在内部管理后台 driver。正常业务代码不需要启动、停止、轮询或 drain
这个 driver：

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

// 上面的 timer 会由 FJS 自动推进。timer 触发后，后续任意 engine 操作都能观察到
// 更新后的 JS 状态。
await Future<void>.delayed(const Duration(milliseconds: 20));
final ready = await engine.eval(
  source: const JsCode.code('globalThis.ready === true'),
);
print(ready.value); // true

await engine.close();
```

如果某个游离的 JavaScript 任务自己拥有失败路径，应在 JavaScript 里捕获：

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

如果游离任务失败但没有 JavaScript `.catch()`，FJS 会把格式化后的 QuickJS 错误放入
runtime 的有界队列，并在后续 public 操作中自动暴露：

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
  // 包含 "Unhandled JavaScript background error" 和原始 JS stack。
  print(error);
}
```

这样用户侧生命周期保持很小：创建 engine，执行 JavaScript，owner 结束时调用
`close()`。如果使用更底层的异步 runtime/context，也会得到相同的自动 driver 行为；
Dart 应用代码不需要启动、停止、轮询或 drain 这个 driver。

### 同步 Runtime 与 Context

```dart
// 如果不需要异步 JavaScript 执行，可以使用同步 runtime。
final runtime = await JsRuntime.create(
  builtins: JsBuiltinOptions.essential(),
);
final context = JsContext.from(runtime: runtime);

// 同步 context 直接返回 JsResult。
final result = context.eval(code: '6 * 7');
print(result.ok.value); // 42

// 通过 eval 选项控制严格模式等行为。
final strictResult = context.evalWithOptions(
  code: '"use strict"; 8 * 8',
  options: JsEvalOptions.defaults(),
);
print(strictResult.ok.value); // 64

// 文件执行同样返回 JsResult。
final fileResult = context.evalFile(path: '/absolute/path/to/script.js');
final fileWithOptions = context.evalFileWithOptions(
  path: '/absolute/path/to/script.js',
  options: JsEvalOptions.defaults(),
);

// 查看当前 context 可见的模块。
final modules = context.getAvailableModules();
print(modules);

// 同步模式下手动推进 QuickJS job 队列。
while (runtime.isJobPending()) {
  runtime.executePendingJob();
}

// 配置 runtime 限制并查看内存统计。
runtime.setMemoryLimit(limit: BigInt.from(32 * 1024 * 1024));
runtime.setGcThreshold(threshold: BigInt.from(4 * 1024 * 1024));
runtime.setMaxStackSize(limit: BigInt.from(256 * 1024));
runtime.setInfo(info: 'sync-runtime');
print(runtime.memoryUsage().summary());
runtime.runGc();
```

## 🧱 Source 输入与 Eval 选项

```dart
import 'dart:convert';
import 'dart:typed_data';

// 源码既可以来自字符串，也可以来自文件路径或 UTF-8 字节。
final inlineCode = JsCode.code('1 + 1');
final fileCode = JsCode.path('/absolute/path/to/script.js');
final bytesCode = JsCode.bytes(Uint8List.fromList(utf8.encode('2 + 2')));

// 模块同样支持这三种输入形式。
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

// Eval 选项用于控制全局脚本、异步执行或模块执行语义。
final defaultEval = JsEvalOptions.defaults();
final asyncEval = JsEvalOptions.withPromise();
final moduleEval = JsEvalOptions.module();
```

## 📦 ES6 模块

```dart
// 声明模块
await engine.declareNewModule(
  module: JsModule.code(module: 'math', code: '''
    export const add = (a, b) => a + b;
    export const multiply = (a, b) => a * b;
  '''),
);

// 使用模块
await engine.eval(source: JsCode.code('''
  const { add, multiply } = await import('math');
  console.log(add(2, 3));        // 5
  console.log(multiply(4, 5));   // 20
'''));

// 也可以不用自己写 import 包装，直接调用导出的函数。
final sum = await engine.call(
  module: 'math',
  method: 'add',
  params: [JsValue.integer(2), JsValue.integer(3)],
);
print(sum.value); // 5

// 一次性批量注册多个模块。
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

// 立即执行一个模块，并把它留在当前 context 的 cache 中。
await engine.evaluateModule(
  module: JsModule.code(
    module: 'startup',
    code: 'globalThis.started = true; export default "ready";',
  ),
);

// 查看当前 engine 上声明过的动态模块。
final declaredModules = await engine.getDeclaredModules();
final hasMath = await engine.isModuleDeclared(moduleName: 'math');
print(declaredModules);
print(hasMath); // true
```

动态模块只有在尚未加载进当前 context 时才能清除。模块一旦被 `import()` 或 `evaluateModule()` 载入，就需要重建 context 才能替换。

## 📚 模块清单查询

```dart
final modules = await engine.getAvailableModules();
print(modules);

final hasConsole = await engine.isModuleAvailable(moduleName: 'console');
final hasXml = await engine.isModuleAvailable(moduleName: 'llrt:xml');
print('console: $hasConsole, llrt:xml: $hasXml');
```

## 🔄 Engine 生命周期说明

- `JsEngine` 通过 `create()` 创建时会自己持有内部 runtime/context
- `close()` 会先移除 `fjs` bridge、推进待处理的 runtime 工作，再执行 GC，之后 engine 不能再使用
- `clearPendingModules()` 只会清掉还没有被当前 context 真正加载过的动态模块
- `declareNewModules()` 和 `declareNewBytecodeModules()` 会拒绝同一批请求里的重复模块名

## 📦 模块字节码

```dart
// 把一个 ES 模块编译成 QuickJS bytecode，不会影响当前 engine。
final bytecode = await JsBytecode.compile(
  module: JsModule.code(
    module: 'plugin/main.js',
    code: 'export function run() { return "ready"; }',
  ),
  options: JsModuleBytecodeOptions.defaults(),
);

// 在声明前先校验 bytecode 结构是否合法。
await JsBytecode.validate(module: bytecode);

// 把预编译模块注册到 engine。
await engine.declareNewBytecodeModule(module: bytecode);

// 之后就可以像普通 ES 模块一样 import 和执行。
final result = await engine.eval(source: JsCode.code('''
  const { run } = await import('plugin/main.js');
  run();
'''));

// 如果 bytecode 来自磁盘或网络，可以用原始 bytes 重新恢复。
final restored = JsModuleBytecode(
  name: bytecode.name,
  bytes: bytecode.bytes,
);
JsBytecode.validateSync(module: restored);
```

`JsBytecode.compile()` 会在隔离的 QuickJS context 里执行，因此编译不会把模块声明或缓存进当前 engine。`JsBytecode.validate()` 只做结构校验和内嵌模块名校验，不会执行模块。另有 `compileSync()` / `validateSync()` 供同步调用场景使用，但主 isolate 上更建议使用异步版本。

QuickJS 字节码和嵌入的引擎版本强绑定，只应加载可信输入。升级 QuickJS 后需要重新编译字节码。

### 字节码 Bundle

```dart
// 把整个模块图编译成一个可分发的 bundle。
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

// 在加载前先校验 bundle 结构。
await JsBytecode.validateBundle(bundle: bundle);

// 执行入口模块，并把相关模块放进 cache。
await engine.evaluateBytecodeBundle(bundle: bundle);

// 如果要读取导出值，再 import 一次入口模块。
final result = await engine.eval(source: JsCode.code('''
  const { default: plugin } = await import('plugins/main.js');
  plugin
'''));
print(result.value); // { ready: true, answer: 42 }
```

当插件以模块图而不是单文件形式分发时，bundle 更适合这类场景。编译后的 bundle 会保留相对导入关系；如果你只想先注册、不立刻执行入口，也可以使用 `declareNewBytecodeBundle()`。`validateBundle()` 只做结构校验：检查 entry 是否存在、模块名是否重复，以及每个 payload 是否能被当前内嵌的 QuickJS 读取。`evaluateBytecodeBundle()` 会执行入口并把模块放进 cache；如果你要读取导出值，需要像普通模块一样再 `import()` 一次入口模块。

### Classic Script 字节码

```dart
// 把普通 script 源码编译成非模块 bytecode。
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

// 执行前先做结构校验。
await JsBytecode.validateScript(script: script);

// 执行 script bytecode，并读取 completion value。
final result = await engine.evaluateScriptBytecode(script: script);
print(result.value); // { mode: 'script', launchCount: 1 }
```

script 字节码是 ES module 字节码的非模块版本。`validateScript()` 只能做结构校验：它会确认这些 bytes 在当前内嵌的 QuickJS 下能被读取成“可执行的非模块字节码”。QuickJS 不会暴露一个可在加载时再次验证的内嵌脚本名，因此这里的 `name` 主要用于编译时元数据和错误栈里的文件名。

## 🧾 值、结果与错误

```dart
import 'dart:typed_data';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

// 常见 Dart 值可以自动转换成结构化的 JsValue。
final payload = JsValue.from({
  'enabled': true,
  'count': 3,
  'tags': ['a', 'b'],
  'buffer': Uint8List.fromList([1, 2, 3]),
});
print(payload.typeName()); // Object
print(payload.value); // Dart Map<String, dynamic>

// 如果你需要完全控制类型，也可以手动构造 JsValue 树。
final typed = JsValue.object({
  'big': JsValue.bigint('9007199254740993'),
  'createdAt': JsValue.date(DateTime.now().millisecondsSinceEpoch),
});
print(typed.value);

// 底层 context API 返回 JsResult，而不是直接抛异常。
final result = await context.eval(code: '40 + 2');
if (result.isOk) {
  print(result.ok.value); // 42
} else {
  print('${result.err.code()}: ${result.err}');
}

// JsError 适合做结构化错误处理和重试判断。
const syntaxError = JsError.syntax(
  message: 'Unexpected token',
  line: 1,
  column: 10,
);
print(syntaxError.code());
print(syntaxError.isRecoverable());

// 高层执行 API 失败时抛出类型化的 JsError，会根据真实的 QuickJS 异常
// 分类（SyntaxError、TypeError、ReferenceError、栈溢出、内存上限等），
// 并携带行列号和调用栈文本。
try {
  await engine.eval(source: JsCode.code('invalid.code()'));
} on JsError catch (e) {
  print('执行失败 [${e.code()}]: $e');
  switch (e) {
    case JsError_Syntax(:final line, :final column):
      print('语法错误位于 $line:$column');
    case JsError_Reference():
      print('引用错误');
    default:
      break;
  }
}
```

`JsError` 贯穿所有 API：`JsEngine`/`JsBytecode` 的方法失败时直接抛出，底层 context API 和 bridge 则通过 `JsResult.err(...)` 返回。可以用 `code()` 做稳定的程序化匹配，也可以直接对 freezed 变体做模式匹配。

## 🌉 桥接通信

```dart
// bridge 接收一个 JsValue，并把 JsResult 返回给 JavaScript。
await engine.init(bridge: (jsValue) async {
  final data = jsValue.value;

  if (data is Map && data['action'] == 'fetchUser') {
    final user = await fetchUser(data['id']);
    return JsResult.ok(JsValue.from(user));
  }

  return JsResult.ok(JsValue.none());
});

// JavaScript 端通过注入的 fjs 对象回调 Dart。
await engine.eval(source: JsCode.code('''
  const user = await fjs.bridge_call({ action: 'fetchUser', id: 123 });
  console.log(user);
'''));
```

## 🧠 内存管理

```dart
// 设置运行时安全限制。
await runtime.setMemoryLimit(limit: BigInt.from(50 * 1024 * 1024)); // 50MB
await runtime.setGcThreshold(threshold: BigInt.from(10 * 1024 * 1024)); // 10MB
await runtime.setMaxStackSize(limit: BigInt.from(512 * 1024)); // 512KB

// 查看当前内存使用情况。
final usage = await runtime.memoryUsage();
print(usage.summary());

// 在需要立即回收时手动触发 GC。
await runtime.runGc();
```

## 📚 核心 API

### JsAsyncRuntime 与 JsAsyncContext

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

### JsRuntime 与 JsContext

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
  Future<void> declareNewModules({required List<JsModule> modules}); // 同一批请求中不允许重复模块名
  Future<void> declareNewBytecodeBundle({required JsModuleBytecodeBundle bundle});
  Future<void> declareNewBytecodeModule({required JsModuleBytecode module});
  Future<void> declareNewBytecodeModules({required List<JsModuleBytecode> modules}); // 同一批请求中不允许重复模块名
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
  List<String> drainUnhandledJobErrors(); // 后台 JS 错误；任何状态下都可调用
  Future<void> close(); // 会推进待处理的 runtime 工作，然后执行 GC
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
  // ... 还有更细的计数器：atomCount/Size、shapeCount/Size、propCount/Size、
  // jsFuncCount/Size、arrayCount、fastArrayCount、binaryObjectCount/Size 等
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

  // 变体判断与类型化访问器。
  bool isNone() / isBoolean() / isNumber() / isString() / isBytes()
       / isArray() / isObject() / isDate() / isPrimitive();
  bool? get asBoolean; PlatformInt64? get asInteger; double? get asFloat;
  String? get asBigint; String? get asString; Uint8List? get asBytes;
  List<JsValue>? get asArray; Map<String, JsValue>? get asObject; num? get asNum;
}
```

### JsBuiltinOptions 与 JsEvalOptions

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
    // ... 其他 builtin 开关
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

### JsCode、JsModule 与 Bytecode

```dart
sealed class JsCode {
  const factory JsCode.code(String value);    // 内联代码
  const factory JsCode.path(String value);    // 文件路径
  const factory JsCode.bytes(Uint8List value); // UTF-8 源码字节

  bool isCode() / isPath() / isBytes();
}

sealed class JsModule {
  static JsModule code({required String module, required String code});
  static JsModule path({required String module, required String path});
  static JsModule bytes({required String module, required List<int> bytes}); // UTF-8 源码字节
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

### JsResult 与 JsError

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
  String toString(); // 格式化消息，可用时包含调用栈文本
}
```

## 🧩 内置运行时能力

有些 builtin 选项会暴露可 `import` 的模块，有些则会直接在运行时注入全局对象。

| 选项 | 描述 |
|------|------|
| `abort` | `AbortController` 及相关全局对象 |
| `assert_` | 断言辅助 |
| `asyncHooks` | 异步生命周期追踪 |
| `buffer` | Buffer 二进制数据处理 |
| `childProcess` | 子进程派生 |
| `console` | 控制台日志（`console.log`、`console.error` 等） |
| `crypto` | 加密能力和 Web Crypto 全局对象 |
| `dgram` | UDP 套接字 |
| `dns` | DNS 解析 |
| `events` | `EventEmitter` 支持 |
| `exceptions` | 全局异常辅助 |
| `fetch` | Fetch API 全局对象 |
| `fs` | 文件系统操作 |
| `https` | HTTPS 客户端模块 |
| `intl` | 轻量 `Intl.DateTimeFormat` 时区支持 |
| `navigator` | Navigator 全局对象 |
| `net` | TCP 套接字 |
| `os` | 操作系统工具（`iOS` 不提供） |
| `path` | 路径处理（POSIX/Windows） |
| `perfHooks` | 性能测量 API |
| `process` | 进程信息与环境变量 |
| `streamWeb` | Web Streams API |
| `stringDecoder` | Buffer 字符串解码 |
| `temporal` | `Temporal` 全局对象 |
| `timers` | 定时器函数（`setTimeout`、`setInterval`、`setImmediate`） |
| `tty` | 终端工具 |
| `url` | URL 解析与格式化 |
| `util` | 工具函数 |
| `zlib` | 压缩/解压（gzip、deflate） |
| `json` | JSON 静态方法兼容辅助 |

### 快速预设

```dart
// 基础模块：console、timers、buffer、util、json
JsBuiltinOptions.essential()

// Web 环境：console、timers、fetch、url、crypto、streamWeb、navigator、exceptions、intl、json
JsBuiltinOptions.web()

// Node.js 环境：大部分 Node 兼容模块，包含 https 和 intl
JsBuiltinOptions.node()

// 全部模块
JsBuiltinOptions.all()

// 自定义选择
JsBuiltinOptions(
  console: true,
  fetch: true,
  timers: true,
  // ... 其他选项
)
```

## ⚡ 性能建议

1. **复用引擎** - 创建一次，多次使用
2. **设置内存限制** - 配置适当的限制
3. **使用源码字节** - 当 JavaScript 源码本来就是 UTF-8 字节时，优先使用 `JsCode.bytes()` / `JsModule.bytes()`
4. **批量操作** - 将相关操作分组执行

## Darwin 打包与发布

fjs 在 iOS 和 macOS 上同时支持 CocoaPods 与 Swift Package Manager。Flutter 会从
`pubspec.yaml` 发现共享 Darwin 包；应用开发者通常只需要在 `pubspec.yaml` 加入
`fjs`，然后使用常规 Flutter 构建流程。

### CocoaPods

CocoaPods 的共享 Darwin 构建使用 `darwin/fjs.podspec`，`ios/fjs.podspec` 和
`macos/fjs.podspec` 保留给旧版 Flutter 目录布局。podspec 会执行：

```sh
sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../libfjs fjs
```

该 Cargokit 脚本会为当前 Xcode 平台构建 `libfjs.a`，并通过 `-force_load` 链接。
Rustup 可用时默认从本地 Rust 源码构建；Rustup 缺失，或应用通过
`cargokit_options.yaml` 显式选择时，会从 `libfjs/cargokit.yaml` 配置的 GitHub
Release 下载已签名预编译产物。

```yaml
use_precompiled_binaries: true
verbose_logging: false
```

### Swift Package Manager

SwiftPM 使用 `darwin/fjs/Package.swift`。该 package 暴露一个很小的 Swift target，
并链接下面的 binary target：

```text
darwin/fjs/Binaries/fjs.xcframework
```

XCFramework 是发布产物，不应手工编辑。如果你在源码仓库中需要本地刷新它，运行：

```sh
tool/build_fjs_xcframework.sh --configuration Release
```

### 发布检查清单

发布支持 Darwin 的版本前，运行：

```sh
tool/prepare_darwin_release.sh --configuration Release
```

该脚本会用 CocoaPods 相同的 Rust/Cargokit 输入构建 XCFramework，写入
`darwin/fjs/Binaries/fjs.xcframework`，生成
`build/darwin-release/fjs.xcframework.zip`，计算
`build/darwin-release/fjs.xcframework.zip.checksum`，验证 Darwin 包元数据，
验证 SwiftPM 可消费性，并运行 `flutter pub publish --dry-run`。

发布时将 `build/darwin-release/fjs.xcframework.zip` 上传到对应版本的 GitHub
Release。checksum 建议和产物一起保留，用于校验，或未来切换到远程
`binaryTarget(url:checksum:)` manifest。发布脚本会强制本地编译后再打包
XCFramework，确保 CocoaPods、SwiftPM 和 Cargokit 预编译 release 都可以追溯到同一组
Rust 输入。

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件。
