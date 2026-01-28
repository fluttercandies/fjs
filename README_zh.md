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

  // 创建运行时，启用内置模块
  final runtime = await JsAsyncRuntime.withOptions(
    builtin: JsBuiltinOptions(
      console: true,
      fetch: true,
      timers: true,
    ),
  );

  // 创建上下文
  final context = await JsAsyncContext.from(runtime);

  // 创建引擎
  final engine = JsEngine(context);
  await engine.init(bridge: (jsValue) {
    return JsResult.ok(JsValue.string('来自 Dart 的问候'));
  });

  // 执行 JavaScript
  final result = await engine.eval(source: JsCode.code('''
    console.log('你好，FJS！');
    1 + 2
  '''));
  print(result.value); // 3

  await engine.dispose();
}
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
  import { add, multiply } from 'math';
  console.log(add(2, 3));        // 5
  console.log(multiply(4, 5));   // 20
'''));
```

## 🌉 桥接通信

```dart
await engine.init(bridge: (jsValue) async {
  final data = jsValue.value;

  if (data is Map && data['action'] == 'fetchUser') {
    final user = await fetchUser(data['id']);
    return JsResult.ok(JsValue.from(user));
  }

  return JsResult.ok(JsValue.none());
});

// JavaScript 端
await engine.eval(source: JsCode.code('''
  const user = await fjs.bridge_call({ action: 'fetchUser', id: 123 });
  console.log(user);
'''));
```

## 🧠 内存管理

```dart
// 设置限制
await runtime.setMemoryLimit(50 * 1024 * 1024); // 50MB
await runtime.setGcThreshold(10 * 1024 * 1024);  // 10MB

// 监控使用
final usage = await runtime.memoryUsage();
print(usage.summary());

// 强制 GC
await runtime.runGc();
```

## 📚 核心 API

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
  const factory JsCode.code(String value);    // 内联代码
  const factory JsCode.path(String value);    // 文件路径
  const factory JsCode.bytes(Uint8List value); // 原始字节
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

## 🧩 内置模块

| 模块 | 描述 |
|------|------|
| `console` | 控制台日志（`console.log`、`console.error` 等） |
| `timers` | 定时器函数（`setTimeout`、`setInterval`、`setImmediate`） |
| `buffer` | Buffer 二进制数据处理 |
| `util` | 工具函数 |
| `json` | JSON 解析与序列化 |
| `fetch` | HTTP 客户端（Fetch API） |
| `url` | URL 解析与格式化 |
| `crypto` | 加密函数（哈希、HMAC、随机字节） |
| `events` | EventEmitter 实现 |
| `streamWeb` | Web Streams API |
| `navigator` | Navigator 信息（Web 兼容） |
| `exceptions` | 错误处理工具 |
| `fs` | 文件系统操作（Node.js 兼容） |
| `path` | 路径处理（POSIX/Windows） |
| `process` | 进程信息与环境变量 |
| `os` | 操作系统工具 |
| `net` | 网络 TCP/UDP 套接字 |
| `dns` | DNS 解析 |
| `childProcess` | 子进程派生 |
| `asyncHooks` | 异步生命周期追踪 |
| `perfHooks` | 性能测量 API |
| `tty` | 终端工具 |
| `stringDecoder` | Buffer 字符串解码 |
| `zlib` | 压缩/解压（gzip、deflate） |
| `assert` | 断言测试 |
| `abort` | AbortController 支持 |

### 快速预设

```dart
// 基础模块：console、timers、buffer、util、json
JsBuiltinOptions.essential()

// Web 环境：console、timers、fetch、url、crypto、streamWeb、navigator、exceptions、json
JsBuiltinOptions.web()

// Node.js 环境：除 OS 特定模块外的大部分模块
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

## ⚠️ 错误处理

```dart
try {
  final result = await engine.eval(source: JsCode.code('invalid.code()'));
} on JsError catch (e) {
  print('错误: ${e.code()} - ${e}');
}
```

## ⚡ 性能建议

1. **复用引擎** - 创建一次，多次使用
2. **设置内存限制** - 配置适当的限制
3. **使用字节** - 二进制数据优先使用 `JsCode.bytes()`
4. **批量操作** - 将相关操作分组执行

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件。
