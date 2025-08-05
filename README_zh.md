<div align="center">
  <img src="fjs.png" alt="FJS Logo" width="240">
  
  # 🚀 FJS - Flutter JavaScript 引擎
  
  基于 Rust 构建的高性能 JavaScript 运行时 ⚡  
  为 Flutter 应用提供无缝的 JavaScript 执行能力 🎯
  
  [![pub package](https://img.shields.io/pub/v/fjs.svg)](https://pub.dev/packages/fjs)
  [![GitHub stars](https://img.shields.io/github/stars/fluttercandies/fjs.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/fluttercandies/fjs)
  [![GitHub forks](https://img.shields.io/github/forks/fluttercandies/fjs.svg?style=flat&logo=github&colorB=deeppink&label=forks)](https://github.com/fluttercandies/fjs)
  [![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/fluttercandies/fjs/blob/main/LICENSE)
  [![Platform](https://img.shields.io/badge/platform-android%20|%20ios%20|%20linux%20|%20macos%20|%20windows-lightgrey.svg)](https://github.com/fluttercandies/fjs)
  
  *[🌍 English Document](README.md)*
</div>

## ✨ 特性

- 🚀 **高性能**: 基于 Rust 构建，性能优异
- 📦 **模块支持**: 支持 ES6 模块和 import/export 语法
- 🌐 **内置 API**: 提供 Fetch、Console、Buffer、Timers、Crypto 等 API
- 🔄 **异步支持**: 完全支持 async/await 异步 JavaScript
- 🌉 **桥接调用**: Dart 和 JavaScript 之间的无缝通信
- 📱 **跨平台**: 支持 Android、iOS、Linux、macOS 和 Windows
- 🎯 **类型安全**: 与 Dart 集成的强类型 API
- 🧠 **内存管理**: 内置垃圾回收和内存限制

## 📦 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  fjs: any
```

然后运行：

```bash
flutter pub get
```

## 🚀 快速开始

### ⚡ 1. 初始化库

```dart
import 'package:fjs/fjs.dart';

Future<void> main() async {
  await LibFjs.init();
  runApp(MyApp());
}
```

### 🔧 2. 创建 JavaScript 引擎

```dart
// 创建运行时和上下文
final runtime = JsAsyncRuntime();
final context = await JsAsyncContext.from(rt: runtime);

// 创建支持桥接的引擎
final engine = JsEngine(context);
await engine.init(bridgeCall: (jsValue) {
  // 处理来自 JavaScript 的桥接调用
  print('来自 JS 的桥接调用: ${jsValue.value}');
  return JsValue.string('来自 Dart 的响应');
});
```

### 💻 3. 执行 JavaScript 代码

```dart
// 简单求值
final result = await engine.eval(JsCode.code('1 + 2'));
print(result.value); // 3

// 异步 JavaScript
final asyncResult = await engine.eval(JsCode.code('''
  (async () => {
    const response = await fetch('https://api.example.com/data');
    return await response.json();
  })()
'''));
```

### 🌐 4. 启用内置模块

```dart
// 启用 fetch 和 console API
await engine.enableBuiltinModule(const JsBuiltinOptions(
  fetch: true,
  console: true,
  timers: true,
));

// 现在可以使用 fetch、console.log、setTimeout 等
await engine.eval(JsCode.code('''
  console.log('你好，来自 JavaScript！');
  setTimeout(() => console.log('延迟消息'), 1000);
'''));
```

### 📦 5. 使用模块

```dart
// 声明模块
const moduleCode = '''
export function greet(name) {
  return `你好，${name}！`;
}

export const version = '1.0.0';
''';

await engine.declareModule(
  JsModule.code(module: 'greeting', code: moduleCode)
);

// 使用模块
await engine.eval(JsCode.code('''
  import { greet, version } from 'greeting';
  console.log(greet('Flutter'));
  console.log('版本:', version);
'''));
```

## 🔥 高级用法

### 🌉 桥接通信

在 Dart 和 JavaScript 之间创建双向通信：

```dart
// Dart 端
final engine = JsEngine(context);
await engine.init(bridgeCall: (jsValue) async {
  final data = jsValue.value;
  
  // 在 Dart 中处理数据
  if (data is Map && data['action'] == 'fetchUserData') {
    final userId = data['userId'];
    final userData = await fetchUserFromDatabase(userId);
    return JsValue.from(userData);
  }
  
  return const JsValue.none();
});

// JavaScript 端
await engine.eval(JsCode.code('''
  const userData = await fjs.bridge_call({
    action: 'fetchUserData',
    userId: 12345
  });
  console.log('用户数据:', userData);
'''));
```

### 🧠 内存管理

```dart
// 设置内存限制
final runtime = JsAsyncRuntime();
await runtime.setMemoryLimit(50 * 1024 * 1024); // 50MB
await runtime.setGcThreshold(10 * 1024 * 1024);  // 10MB

// 监控内存使用
final usage = await runtime.memoryUsage();
print('内存使用: ${usage.memoryUsedSize} 字节');

// 强制垃圾回收
await runtime.runGc();
```

### ⚠️ 错误处理

```dart
try {
  final result = await engine.eval(JsCode.code('invalid.syntax()'));
} on JsError catch (e) {
  print('JavaScript 错误: ${e.message}');
} catch (e) {
  print('其他错误: $e');
}
```

### 📁 从文件加载 JavaScript

```dart
// 从文件加载
final result = await engine.eval(JsCode.path('/path/to/script.js'));

// 或使用上下文的 evalFile 方法
final context = await JsAsyncContext.from(rt: runtime);
final result = await context.evalFile(path: '/path/to/script.js');
```

## 🧩 内置模块

FJS 提供了几个可按需启用的内置模块：

| 模块 | 描述 | 启用选项 |
|------|------|----------|
| `fetch` | 用于网络请求的 HTTP 客户端 | `fetch: true` |
| `console` | 控制台日志（log、debug、warn、error） | `console: true` |
| `buffer` | Buffer 操作工具 | `buffer: true` |
| `timers` | setTimeout、setInterval、clearTimeout 等 | `timers: true` |
| `crypto` | 加密函数 | `crypto: true` |
| `stream` | 流处理工具 | `stream: true` |
| `url` | URL 解析和操作 | `url: true` |
| `events` | 事件发射器实现 | `events: true` |

## 📚 API 参考

### JsEngine

JavaScript 执行的主要接口：

```dart
class JsEngine {
  // 初始化引擎
  Future<void> init({FutureOr<JsValue?> Function(JsValue)? bridgeCall});
  
  // 执行 JavaScript 代码
  Future<JsValue> eval(JsCode source, {JsEvalOptions? options, Duration? timeout});
  
  // 启用内置模块
  Future<JsValue> enableBuiltinModule(JsBuiltinOptions options, {Duration? timeout});
  
  // 模块操作
  Future<JsValue> declareModule(JsModule module, {Duration? timeout});
  Future<JsValue> evaluateModule(JsModule module, {Duration? timeout});
  Future<JsValue> importModule(String specifier, {Duration? timeout});
  
  // 清理
  Future<void> dispose();
  
  // 状态
  bool get disposed;
  bool get running;
  bool get initialized;
}
```

### JsValue

JavaScript 值的类型安全表示：

```dart
sealed class JsValue {
  // 构造函数
  const factory JsValue.none();
  const factory JsValue.boolean(bool value);
  const factory JsValue.integer(int value);
  const factory JsValue.float(double value);
  const factory JsValue.string(String value);
  const factory JsValue.array(List<JsValue> value);
  const factory JsValue.object(Map<String, JsValue> value);
  
  // 从 Dart 对象转换
  static JsValue from(Object? any);
  
  // 获取 Dart 值
  dynamic get value;
  
  // 类型检查
  bool get isNone;
  bool get isBoolean;
  bool get isInteger;
  // ... 其他类型检查器
}
```

## ⚡ 性能建议

1. **复用引擎**: 创建一个引擎实例并重复使用多次求值
2. **设置内存限制**: 为您的用例配置适当的内存限制
3. **使用超时**: 始终为 JavaScript 执行设置合理的超时
4. **只启用需要的模块**: 只启用您实际使用的内置模块
5. **批量操作**: 将相关的 JavaScript 操作组合在一起

## 🎯 示例

查看 [example](example/) 目录了解更多综合示例，包括：

- 基本 JavaScript 求值
- 模块系统使用
- 桥接通信
- 内置 API 使用
- 错误处理
- 性能测试

## 🤝 贡献

欢迎贡献代码！请随时提交 Pull Request。

## 📄 许可证

本项目基于 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。
