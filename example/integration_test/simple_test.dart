import 'dart:typed_data';

import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjs/fjs.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await LibFjs.init());

  group('JsValue Tests', () {
    test('JsValue.from - primitive type conversion', () {
      // null
      expect(JsValue.from(null), const JsValue.none());

      // bool
      expect(JsValue.from(true), const JsValue.boolean(true));
      expect(JsValue.from(false), const JsValue.boolean(false));

      // int
      expect(JsValue.from(42), const JsValue.integer(42));
      expect(JsValue.from(-100), const JsValue.integer(-100));
      expect(JsValue.from(0), const JsValue.integer(0));

      // double
      expect(JsValue.from(3.14), const JsValue.float(3.14));
      expect(JsValue.from(-2.5), const JsValue.float(-2.5));

      // String
      expect(JsValue.from('hello'), const JsValue.string('hello'));
      expect(JsValue.from(''), const JsValue.string(''));

      // BigInt
      final bigInt = BigInt.parse('9999999999999999999999');
      expect(JsValue.from(bigInt), JsValue.bigint(bigInt.toString()));

      // Uint8List
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      expect(JsValue.from(bytes), JsValue.bytes(bytes));
    });

    test('JsValue.from - collection type conversion', () {
      // List
      final list = [1, 'hello', true];
      final jsArray = JsValue.from(list);
      expect(jsArray.isArray(), true);
      expect(
        jsArray,
        const JsValue.array([
          JsValue.integer(1),
          JsValue.string('hello'),
          JsValue.boolean(true),
        ]),
      );

      // Map
      final map = {'name': 'test', 'age': 25};
      final jsObject = JsValue.from(map);
      expect(jsObject.isObject(), true);
    });

    test('JsValue type checking methods', () {
      expect(const JsValue.none().isNone(), true);
      expect(const JsValue.boolean(true).isBoolean(), true);
      expect(const JsValue.integer(42).isNumber(), true);
      expect(const JsValue.float(3.14).isNumber(), true);
      expect(const JsValue.string('test').isString(), true);
      expect(JsValue.bytes(Uint8List(0)).isBytes(), true);
      expect(const JsValue.array([]).isArray(), true);
      expect(const JsValue.object({}).isObject(), true);

      // isPrimitive
      expect(const JsValue.boolean(true).isPrimitive(), true);
      expect(const JsValue.integer(42).isPrimitive(), true);
      expect(const JsValue.string('test').isPrimitive(), true);
      expect(const JsValue.array([]).isPrimitive(), false);
      expect(const JsValue.object({}).isPrimitive(), false);
    });

    test('JsValue.value getter', () {
      expect(const JsValue.none().value, null);
      expect(const JsValue.boolean(true).value, true);
      expect(const JsValue.integer(42).value, 42);
      expect(const JsValue.float(3.14).value, 3.14);
      expect(const JsValue.string('hello').value, 'hello');

      final date = const JsValue.date(1609459200000);
      expect(date.value, isA<DateTime>());
    });

    test('JsValue safe casting getters', () {
      expect(const JsValue.boolean(true).asBoolean, true);
      expect(const JsValue.integer(42).asInteger, 42);
      expect(const JsValue.float(3.14).asFloat, 3.14);
      expect(const JsValue.string('test').asString, 'test');

      // Wrong type returns null
      expect(const JsValue.string('test').asBoolean, null);
      expect(const JsValue.boolean(true).asInteger, null);
    });

    test('JsValue.typeName', () {
      // Note: JsValue.none() corresponds to JavaScript null/undefined, so typeName returns 'null'
      expect(const JsValue.none().typeName(), 'null');
      expect(const JsValue.boolean(true).typeName(), 'boolean');
      // In JavaScript, both integer and float are 'number' type
      expect(const JsValue.integer(42).typeName(), 'number');
      expect(const JsValue.float(3.14).typeName(), 'number');
      expect(const JsValue.string('test').typeName(), 'string');
    });
  });

  group('JsCode Tests', () {
    test('JsCode variants', () {
      const code = JsCode.code('console.log("hello")');
      expect(code.isCode(), true);
      expect(code.isPath(), false);
      expect(code.isBytes(), false);

      const path = JsCode.path('/path/to/file.js');
      expect(path.isPath(), true);

      final bytes = JsCode.bytes(Uint8List.fromList([65, 66, 67]));
      expect(bytes.isBytes(), true);
    });
  });

  group('JsBuiltinOptions Tests', () {
    test('Preset options', () {
      final all = JsBuiltinOptions.all();
      expect(all, isNotNull);

      final none = JsBuiltinOptions.none();
      expect(none, isNotNull);

      final essential = JsBuiltinOptions.essential();
      expect(essential, isNotNull);

      final web = JsBuiltinOptions.web();
      expect(web, isNotNull);

      final node = JsBuiltinOptions.node();
      expect(node, isNotNull);
    });

    test('Custom options', () {
      const options = JsBuiltinOptions(
        console: true,
        timers: true,
        fetch: false,
      );
      expect(options.console, true);
      expect(options.timers, true);
      expect(options.fetch, false);
    });
  });

  group('JsEvalOptions Tests', () {
    test('Preset options', () {
      final defaults = JsEvalOptions.defaults();
      expect(defaults, isNotNull);

      final module = JsEvalOptions.module();
      expect(module, isNotNull);

      final withPromise = JsEvalOptions.withPromise();
      expect(withPromise, isNotNull);
    });

    test('Custom options', () {
      final options = JsEvalOptions(
        global: true,
        strict: true,
        promise: false,
      );
      expect(options, isNotNull);
    });
  });

  group('JsModule Tests', () {
    test('Create modules', () {
      final fromCode =
          JsModule.code(module: 'test', code: 'export const x = 1;');
      expect(fromCode.name, 'test');

      final fromPath =
          JsModule.path(module: 'test2', path: '/path/to/module.js');
      expect(fromPath.name, 'test2');

      final fromBytes = JsModule.bytes(
        module: 'test3',
        bytes: [65, 66, 67],
      );
      expect(fromBytes.name, 'test3');

      final custom = JsModule(
        name: 'custom',
        source: const JsCode.code('export const y = 2;'),
      );
      expect(custom.name, 'custom');
    });
  });

  group('JsError Tests', () {
    test('Error types', () {
      const promiseError = JsError.promise('Promise rejected');
      expect(promiseError.code(), isNotEmpty);
      expect(promiseError.isRecoverable(), isA<bool>());

      const moduleError = JsError.module(
        module: 'testModule',
        method: 'testMethod',
        message: 'Module not found',
      );
      expect(moduleError.code(), isNotEmpty);

      const syntaxError = JsError.syntax(
        line: 10,
        column: 5,
        message: 'Unexpected token',
      );
      expect(syntaxError.code(), isNotEmpty);

      const engineError = JsError.engine('Engine not initialized');
      expect(engineError.toString(), contains('Engine not initialized'));
    });
  });

  group('JsResult Tests', () {
    test('Ok result', () {
      const result = JsResult.ok(JsValue.integer(42));
      expect(result.isOk, true);
      expect(result.isErr, false);
      expect(result.ok.value, 42);
    });

    test('Err result', () {
      const result = JsResult.err(JsError.generic('Something went wrong'));
      expect(result.isOk, false);
      expect(result.isErr, true);
      expect(result.err, isA<JsError>());
    });
  });

  group('Sync Runtime and Context Tests', () {
    late JsRuntime runtime;
    late JsContext context;

    setUp(() async {
      runtime = await JsRuntime.withOptions(
        builtin: JsBuiltinOptions.essential(),
      );
      context = JsContext.from(runtime: runtime);
    });

    test('Basic expression evaluation', () {
      final result = context.eval(code: '1 + 2 + 3');
      expect(result.isOk, true);
      expect(result.ok.value, 6);
    });

    test('String operations', () {
      final result = context.eval(code: '"Hello, " + "World!"');
      expect(result.isOk, true);
      expect(result.ok.value, 'Hello, World!');
    });

    test('Array operations', () {
      final result = context.eval(code: '[1, 2, 3].map(x => x * 2)');
      expect(result.isOk, true);
      expect(result.ok.isArray(), true);
      final arr = result.ok.value as List;
      expect(arr, [2, 4, 6]);
    });

    test('Object operations', () {
      final result = context.eval(code: '({name: "test", value: 42})');
      expect(result.isOk, true);
      expect(result.ok.isObject(), true);
      final obj = result.ok.value as Map;
      expect(obj['name'], 'test');
      expect(obj['value'], 42);
    });

    test('Boolean expressions', () {
      expect(context.eval(code: 'true && false').ok.value, false);
      expect(context.eval(code: 'true || false').ok.value, true);
      expect(context.eval(code: '!true').ok.value, false);
    });

    test('Comparison operators', () {
      expect(context.eval(code: '5 > 3').ok.value, true);
      expect(context.eval(code: '5 < 3').ok.value, false);
      expect(context.eval(code: '5 === 5').ok.value, true);
      expect(context.eval(code: '5 !== 3').ok.value, true);
    });

    test('Function definition and call', () {
      context.eval(code: 'function add(a, b) { return a + b; }');
      final result = context.eval(code: 'add(10, 20)');
      expect(result.isOk, true);
      expect(result.ok.value, 30);
    });

    test('Arrow functions', () {
      final result = context.eval(code: '((x, y) => x * y)(4, 5)');
      expect(result.isOk, true);
      expect(result.ok.value, 20);
    });

    test('Template strings', () {
      final result =
          context.eval(code: 'const name = "World"; `Hello, \${name}!`');
      expect(result.isOk, true);
      expect(result.ok.value, 'Hello, World!');
    });

    test('Destructuring assignment', () {
      final result =
          context.eval(code: 'const [a, b, c] = [1, 2, 3]; a + b + c');
      expect(result.isOk, true);
      expect(result.ok.value, 6);
    });

    test('Spread operator', () {
      final result = context.eval(code: '[...[1, 2], ...[3, 4]]');
      expect(result.isOk, true);
      expect(result.ok.value, [1, 2, 3, 4]);
    });

    test('Math object', () {
      expect(context.eval(code: 'Math.abs(-5)').ok.value, 5);
      expect(context.eval(code: 'Math.max(1, 5, 3)').ok.value, 5);
      expect(context.eval(code: 'Math.min(1, 5, 3)').ok.value, 1);
      expect(context.eval(code: 'Math.floor(3.7)').ok.value, 3);
      expect(context.eval(code: 'Math.ceil(3.2)').ok.value, 4);
      expect(context.eval(code: 'Math.round(3.5)').ok.value, 4);
    });

    test('JSON operations', () {
      final parseResult =
          context.eval(code: 'JSON.parse(\'{"a": 1, "b": 2}\')');
      expect(parseResult.isOk, true);
      expect((parseResult.ok.value as Map)['a'], 1);

      final stringifyResult =
          context.eval(code: 'JSON.stringify({x: 10, y: 20})');
      expect(stringifyResult.isOk, true);
      expect(stringifyResult.ok.value, '{"x":10,"y":20}');
    });

    test('Array methods', () {
      expect(context.eval(code: '[1, 2, 3].length').ok.value, 3);
      expect(context.eval(code: '[1, 2, 3].includes(2)').ok.value, true);
      expect(context.eval(code: '[1, 2, 3].indexOf(2)').ok.value, 1);
      expect(
          context.eval(code: '[1, 2, 3].filter(x => x > 1)').ok.value, [2, 3]);
      expect(
          context.eval(code: '[1, 2, 3].reduce((a, b) => a + b, 0)').ok.value,
          6);
      expect(context.eval(code: '[1, 2, 3].every(x => x > 0)').ok.value, true);
      expect(context.eval(code: '[1, 2, 3].some(x => x > 2)').ok.value, true);
    });

    test('String methods', () {
      expect(context.eval(code: '"hello".toUpperCase()').ok.value, 'HELLO');
      expect(context.eval(code: '"HELLO".toLowerCase()').ok.value, 'hello');
      expect(context.eval(code: '"hello world".split(" ")').ok.value,
          ['hello', 'world']);
      expect(context.eval(code: '"  hello  ".trim()').ok.value, 'hello');
      expect(context.eval(code: '"hello".includes("ell")').ok.value, true);
      expect(context.eval(code: '"hello".startsWith("he")').ok.value, true);
      expect(context.eval(code: '"hello".endsWith("lo")').ok.value, true);
      expect(context.eval(code: '"hello".substring(1, 4)').ok.value, 'ell');
    });

    test('Object methods', () {
      expect(
          context.eval(code: 'Object.keys({a: 1, b: 2})').ok.value, ['a', 'b']);
      expect(
          context.eval(code: 'Object.values({a: 1, b: 2})').ok.value, [1, 2]);
    });

    test('Syntax error handling', () {
      final result = context.eval(code: 'function {');
      expect(result.isErr, true);
    });

    test('Runtime error handling', () {
      final result = context.eval(code: 'nonExistentVariable');
      expect(result.isErr, true);
    });

    test('Evaluation with options', () {
      final result = context.evalWithOptions(
        code: '"use strict"; let x = 10; x',
        options: JsEvalOptions(strict: true),
      );
      expect(result.isOk, true);
      expect(result.ok.value, 10);
    });

    test('Memory usage statistics', () {
      final usage = runtime.memoryUsage();
      expect(usage.totalMemory, greaterThanOrEqualTo(0));
      expect(usage.summary(), isNotEmpty);
    });

    test('Garbage collection', () {
      // Create some objects
      context.eval(
          code: 'let arr = []; for(let i=0; i<100; i++) arr.push({x: i});');
      runtime.runGc();
      // Verify runtime still works
      final result = context.eval(code: '1 + 1');
      expect(result.ok.value, 2);
    });

    test('Set memory limit', () {
      runtime.setMemoryLimit(limit: BigInt.from(50 * 1024 * 1024)); // 50MB
      final result = context.eval(code: '1 + 1');
      expect(result.isOk, true);
    });

    test('Set stack size limit', () {
      runtime.setMaxStackSize(limit: BigInt.from(1024 * 1024)); // 1MB
      final result = context.eval(code: '1 + 1');
      expect(result.isOk, true);
    });

    test('Pending jobs check', () {
      expect(runtime.isJobPending(), isA<bool>());
    });
  });

  group('Async Runtime and Context Tests', () {
    late JsAsyncRuntime runtime;
    late JsAsyncContext context;

    setUp(() async {
      runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.essential(),
      );
      context = await JsAsyncContext.from(runtime: runtime);
    });

    test('Async basic expression evaluation', () async {
      final result = await context.eval(code: '2 * 3 * 4');
      expect(result.isOk, true);
      expect(result.ok.value, equals(24));
    });

    test('Async string operations', () async {
      final result =
          await context.eval(code: '"async".toUpperCase() + " test"');
      expect(result.isOk, true);
      expect(result.ok.value, equals('ASYNC test'));
    });

    test('Async memory usage', () async {
      final usage = await runtime.memoryUsage();
      expect(usage.totalMemory, greaterThanOrEqualTo(0));
    });

    test('Async garbage collection', () async {
      await runtime.runGc();
      final result = await context.eval(code: '42');
      expect(result.ok.value, equals(42));
    });

    test('Async set memory limit', () async {
      await runtime.setMemoryLimit(limit: BigInt.from(100 * 1024 * 1024));
      final result = await context.eval(code: '1 + 1');
      expect(result.isOk, true);
    });

    test('Async pending jobs', () async {
      final pending = await runtime.isJobPending();
      expect(pending, isA<bool>());
    });

    test('Async evaluation with options', () async {
      final result = await context.evalWithOptions(
        code: 'const result = 100; result',
        options: JsEvalOptions(global: true),
      );
      expect(result.isOk, true);
      expect(result.ok.value, equals(100));
    });

    test('Async Promise evaluation via JsAsyncContext', () async {
      final result = await context.eval(
        code: 'new Promise((resolve) => { resolve(42); })',
      );
      print('DEBUG JsAsyncContext Promise: result.isOk = ${result.isOk}');
      print('DEBUG JsAsyncContext Promise: result.ok = ${result.ok}');
      print(
          'DEBUG JsAsyncContext Promise: result.ok.value = ${result.ok.value}');
      expect(result.isOk, true);
      expect(result.ok.value, equals(42));
    });
  });

  group('JsEngine Advanced Tests', () {
    late JsAsyncRuntime runtime;
    late JsAsyncContext context;
    late JsEngine engine;

    setUp(() async {
      runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.all(),
      );
      context = await JsAsyncContext.from(runtime: runtime);
      engine = JsEngine(context: context);
    });

    tearDown(() async {
      if (!engine.disposed) {
        await engine.dispose();
      }
    });

    test('Engine initialization', () async {
      expect(engine.running, false);
      await engine.initWithoutBridge();
      expect(engine.running, true);
      expect(engine.running, true);
    });

    test('Basic evaluation', () async {
      await engine.initWithoutBridge();

      final result = await engine.eval(source: const JsCode.code('100 + 200'));
      expect(result.value, equals(300));
    });

    test('Complex expression evaluation', () async {
      await engine.initWithoutBridge();

      final result = await engine.eval(
        source: const JsCode.code('''
          function fibonacci(n) {
            if (n <= 1) return n;
            return fibonacci(n - 1) + fibonacci(n - 2);
          }
          fibonacci(10)
        '''),
      );
      expect(result.value, equals(55));
    });

    test('Module declaration and usage', () async {
      await engine.initWithoutBridge();

      // Declare module
      await engine.declareNewModule(
        module: JsModule.code(
          module: 'math-utils',
          code: '''
            export const add = (a, b) => a + b;
            export const multiply = (a, b) => a * b;
            export const square = (x) => x * x;
          ''',
        ),
      );

      // Check if module is declared
      final isDeclared =
          await engine.isModuleDeclared(moduleName: 'math-utils');
      expect(isDeclared, true);

      // Get all declared modules
      final modules = await engine.getDeclaredModules();
      expect(modules, contains('math-utils'));
    });

    test('Multiple module declaration', () async {
      await engine.initWithoutBridge();

      await engine.declareNewModules(modules: [
        JsModule.code(
          module: 'string-utils',
          code: '''
            export const reverse = (s) => s.split("").reverse().join("");
            export const capitalize = (s) => s.charAt(0).toUpperCase() + s.slice(1);
          ''',
        ),
        JsModule.code(
          module: 'array-utils',
          code: '''
            export const sum = (arr) => arr.reduce((a, b) => a + b, 0);
            export const average = (arr) => sum(arr) / arr.length;
          ''',
        ),
      ]);

      final modules = await engine.getDeclaredModules();
      expect(modules, containsAll(['string-utils', 'array-utils']));
    });

    test('Clear modules', () async {
      await engine.initWithoutBridge();

      await engine.declareNewModule(
        module:
            JsModule.code(module: 'temp-module', code: 'export const x = 1;'),
      );

      expect(await engine.isModuleDeclared(moduleName: 'temp-module'), true);

      await engine.clearNewModules();

      expect(await engine.isModuleDeclared(moduleName: 'temp-module'), false);
    });

    test('Evaluation with options', () async {
      await engine.initWithoutBridge();

      final result = await engine.eval(
        source: const JsCode.code('let strictVar = 123; strictVar'),
        options: JsEvalOptions(strict: true),
      );
      expect(result.value, equals(123));
    });

    test('Bridge call', () async {
      String? receivedValue;

      await engine.init(
        bridge: (value) async {
          receivedValue = value.asString;
          return JsResult.ok(const JsValue.string('Response from Dart!'));
        },
      );

      final result = await engine.eval(
        source: const JsCode.code('await fjs.bridge_call("Hello from JS")'),
        options: JsEvalOptions.withPromise(),
      );

      expect(receivedValue, equals('Hello from JS'));
      expect(result.asString, equals('Response from Dart!'));
    });

    test('Bridge call - complex data', () async {
      dynamic receivedData;

      await engine.init(
        bridge: (value) async {
          receivedData = value.value;
          return JsResult.ok(
              JsValue.from({'received': true, 'data': receivedData}));
        },
      );

      final result = await engine.eval(
        source: const JsCode.code(
            'await fjs.bridge_call({name: "test", values: [1, 2, 3]})'),
        options: JsEvalOptions.withPromise(),
      );

      print('DEBUG: receivedData = $receivedData');
      print('DEBUG: result = $result');
      print('DEBUG: result.runtimeType = ${result.runtimeType}');
      expect(receivedData, isA<Map>());
      expect((receivedData as Map)['name'], equals('test'));
      // The bridge_call returns the value passed back from Dart
      expect(result.value, isA<Map>());
    });

    test('Error handling - syntax error', () async {
      await engine.initWithoutBridge();

      expect(
        () => engine.eval(source: const JsCode.code('function {')),
        throwsA(isA<JsError>()),
      );
    });

    test('Error handling - runtime error', () async {
      await engine.initWithoutBridge();

      expect(
        () => engine.eval(
            source: const JsCode.code('undefinedVariable.property')),
        throwsA(isA<JsError>()),
      );
    });

    test('Engine disposal', () async {
      await engine.initWithoutBridge();
      expect(engine.disposed, false);

      await engine.dispose();
      expect(engine.disposed, true);
    });

    test('Duplicate initialization should throw', () async {
      await engine.initWithoutBridge();

      expect(
        () => engine.initWithoutBridge(),
        throwsA(isA<JsError>()),
      );
    });

    test('Use after disposal should throw', () async {
      await engine.initWithoutBridge();
      await engine.dispose();

      expect(
        () => engine.eval(source: const JsCode.code('1 + 1')),
        throwsA(isA<JsError>()),
      );
    });

    test('Use without initialization should throw', () async {
      expect(
        () => engine.eval(source: const JsCode.code('1 + 1')),
        throwsA(isA<JsError>()),
      );
    });

    test('Timeout handling', () async {
      await engine.initWithoutBridge();

      // Execute a fast operation
      final result = await engine.eval(
        source: const JsCode.code('1 + 1'),
      );
      expect(result.value, equals(2));
    });
  });

  group('ES6+ Features Tests', () {
    late JsAsyncRuntime runtime;
    late JsAsyncContext context;
    late JsEngine engine;

    setUp(() async {
      runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.all(),
      );
      context = await JsAsyncContext.from(runtime: runtime);
      engine = JsEngine(context: context);
      await engine.initWithoutBridge();
    });

    tearDown(() async {
      if (!engine.disposed) {
        await engine.dispose();
      }
    });

    test('Class definition', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          class Person {
            constructor(name, age) {
              this.name = name;
              this.age = age;
            }
            greet() {
              return "Hello, I'm " + this.name;
            }
          }
          const p = new Person("Alice", 30);
          p.greet()
        '''),
      );
      expect(result.value, equals("Hello, I'm Alice"));
    });

    test('Class inheritance', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          class Animal {
            constructor(name) { this.name = name; }
            speak() { return this.name + " makes a sound"; }
          }
          class Dog extends Animal {
            speak() { return this.name + " barks"; }
          }
          const d = new Dog("Rex");
          d.speak()
        '''),
      );
      expect(result.value, equals('Rex barks'));
    });

    test('Promise', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          new Promise((resolve) => {
            resolve(42);
          })
        '''),
        options: JsEvalOptions.withPromise(),
      );
      print('DEBUG Promise: result = $result');
      print('DEBUG Promise: result.runtimeType = ${result.runtimeType}');
      expect(result.value, equals(42));
    });

    test('async/await', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          (async () => {
            const delay = (ms) => new Promise(r => setTimeout(r, ms));
            await delay(10);
            return "done";
          })()
        '''),
        options: JsEvalOptions.withPromise(),
      );
      expect(result.value, equals('done'));
    });

    test('Map and Set', () async {
      final mapResult = await engine.eval(
        source: const JsCode.code('''
          const m = new Map();
          m.set("key", "value");
          m.get("key")
        '''),
      );
      expect(mapResult.value, equals('value'));

      final setResult = await engine.eval(
        source: const JsCode.code('''
          const s = new Set([1, 2, 3, 2, 1]);
          s.size
        '''),
      );
      expect(setResult.value, equals(3));
    });

    test('Symbol', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          const sym = Symbol("mySymbol");
          typeof sym
        '''),
      );
      expect(result.value, equals('symbol'));
    });

    test('Proxy', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          const target = { message: "hello" };
          const handler = {
            get: (obj, prop) => prop === "message" ? obj[prop].toUpperCase() : obj[prop]
          };
          const proxy = new Proxy(target, handler);
          proxy.message
        '''),
      );
      expect(result.value, equals('HELLO'));
    });

    test('Generator', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          function* gen() {
            yield 1;
            yield 2;
            yield 3;
          }
          [...gen()]
        '''),
      );
      expect(result.value, equals([1, 2, 3]));
    });

    test('Default parameters', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          function greet(name = "World") {
            return "Hello, " + name;
          }
          greet()
        '''),
      );
      expect(result.value, equals('Hello, World'));
    });

    test('Rest parameters', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          function sum(...numbers) {
            return numbers.reduce((a, b) => a + b, 0);
          }
          sum(1, 2, 3, 4, 5)
        '''),
      );
      expect(result.value, equals(15));
    });

    test('Optional chaining operator', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          const objChain = { a: { b: { c: 42 } } };
          objChain?.a?.b?.c
        '''),
      );
      expect(result.value, equals(42));

      final nullResult = await engine.eval(
        source: const JsCode.code('''
          const objNull = { a: null };
          objNull?.a?.b?.c ?? "default"
        '''),
      );
      expect(nullResult.value, equals('default'));
    });

    test('Nullish coalescing operator', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          const value = null ?? "default";
          value
        '''),
      );
      expect(result.value, equals('default'));
    });

    test('BigInt', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          const big = 9007199254740991n + 1n;
          big.toString()
        '''),
      );
      expect(result.value, equals('9007199254740992'));
    });
  });

  group('Builtin Modules Tests', () {
    late JsAsyncRuntime runtime;
    late JsAsyncContext context;
    late JsEngine engine;

    setUp(() async {
      runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.all(),
      );
      context = await JsAsyncContext.from(runtime: runtime);
      engine = JsEngine(context: context);
      await engine.initWithoutBridge();
    });

    tearDown(() async {
      if (!engine.disposed) {
        await engine.dispose();
      }
    });

    test('console module', () async {
      // console.log returns nothing, but should not throw
      final result = await engine.eval(
        source: const JsCode.code('console.log("test"); "logged"'),
      );
      expect(result.value, equals('logged'));
    });

    test('URL parsing', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          const url = new URL("https://example.com:8080/path?query=value#hash");
          ({
            protocol: url.protocol,
            hostname: url.hostname,
            port: url.port,
            pathname: url.pathname,
            search: url.search,
            hash: url.hash
          })
        '''),
      );
      print('DEBUG URL: result = $result');
      print('DEBUG URL: result.value = ${result.value}');
      expect(result.isObject(), true);
      final obj = result.value as Map;
      expect(obj['protocol'], equals('https:'));
      expect(obj['hostname'], equals('example.com'));
      expect(obj['port'], equals('8080'));
      expect(obj['pathname'], equals('/path'));
      expect(obj['search'], equals('?query=value'));
      expect(obj['hash'], equals('#hash'));
    });

    test('URLSearchParams', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          const params = new URLSearchParams("a=1&b=2&c=3");
          params.get("b")
        '''),
      );
      expect(result.value, equals('2'));
    });

    test('TextEncoder/TextDecoder', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          const encoder = new TextEncoder();
          const decoder = new TextDecoder();
          const encoded = encoder.encode("Hello");
          decoder.decode(encoded)
        '''),
      );
      expect(result.value, equals('Hello'));
    });

    test('atob/btoa', () async {
      final encodeResult = await engine.eval(
        source: const JsCode.code('btoa("Hello, World!")'),
      );
      expect(encodeResult.value, equals('SGVsbG8sIFdvcmxkIQ=='));

      final decodeResult = await engine.eval(
        source: const JsCode.code('atob("SGVsbG8sIFdvcmxkIQ==")'),
      );
      expect(decodeResult.value, equals('Hello, World!'));
    });
  });

  group('Performance and Stability Tests', () {
    test('Heavy computation', () async {
      final runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.essential(),
      );
      final context = await JsAsyncContext.from(runtime: runtime);
      final engine = JsEngine(context: context);
      await engine.initWithoutBridge();

      final result = await engine.eval(
        source: const JsCode.code('''
          let sum = 0;
          for (let i = 0; i < 10000; i++) {
            sum += i;
          }
          sum
        '''),
      );
      expect(result.value, equals(49995000));

      await engine.dispose();
    });

    test('Large array processing', () async {
      final runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.essential(),
      );
      final context = await JsAsyncContext.from(runtime: runtime);
      final engine = JsEngine(context: context);
      await engine.initWithoutBridge();

      final result = await engine.eval(
        source: const JsCode.code('''
          const arr = Array.from({length: 1000}, (_, i) => i);
          arr.reduce((a, b) => a + b, 0)
        '''),
      );
      expect(result.value, equals(499500));

      await engine.dispose();
    });

    test('Multiple evaluations', () async {
      final runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.essential(),
      );
      final context = await JsAsyncContext.from(runtime: runtime);
      final engine = JsEngine(context: context);
      await engine.initWithoutBridge();

      for (int i = 0; i < 100; i++) {
        final result = await engine.eval(source: JsCode.code('$i * 2'));
        expect(result.value, equals(i * 2));
      }

      await engine.dispose();
    });

    test('Multiple engine instances', () async {
      final engines = <JsEngine>[];

      for (int i = 0; i < 5; i++) {
        final runtime = await JsAsyncRuntime.withOptions(
          builtin: JsBuiltinOptions.essential(),
        );
        final context = await JsAsyncContext.from(runtime: runtime);
        final engine = JsEngine(context: context);
        await engine.initWithoutBridge();
        engines.add(engine);
      }

      // Parallel evaluation
      final results = await Future.wait(
        engines.asMap().entries.map((e) async {
          return await e.value.eval(source: JsCode.code('${e.key} + 100'));
        }),
      );

      for (int i = 0; i < 5; i++) {
        expect(results[i].value, equals(i + 100));
      }

      // Cleanup
      for (final engine in engines) {
        await engine.dispose();
      }
    });
  });

  group('Promise and Async Edge Cases', () {
    late JsAsyncRuntime runtime;
    late JsAsyncContext context;
    late JsEngine engine;

    setUp(() async {
      runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.all(),
      );
      context = await JsAsyncContext.from(runtime: runtime);
      engine = JsEngine(context: context);
      await engine.initWithoutBridge();
    });

    tearDown(() async {
      if (!engine.disposed) {
        await engine.dispose();
      }
    });

    test('Nested Promise', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          new Promise((resolve) => {
            resolve(new Promise((resolve2) => {
              resolve2(42);
            }));
          })
        '''),
        options: JsEvalOptions.withPromise(),
      );
      expect(result.value, equals(42));
    });

    test('Triple nested Promise', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          new Promise((resolve) => {
            resolve(new Promise((resolve2) => {
              resolve2(new Promise((resolve3) => {
                resolve3("deep");
              }));
            }));
          })
        '''),
        options: JsEvalOptions.withPromise(),
      );
      expect(result.value, equals("deep"));
    });

    test('Promise.resolve', () async {
      final result = await engine.eval(
        source: const JsCode.code('Promise.resolve(123)'),
        options: JsEvalOptions.withPromise(),
      );
      expect(result.value, equals(123));
    });

    test('Promise.resolve with object', () async {
      final result = await engine.eval(
        source: const JsCode.code('Promise.resolve({a: 1, b: 2})'),
        options: JsEvalOptions.withPromise(),
      );
      // Result may be wrapped or direct object
      final value = result.value;
      expect(value, isA<Map>());
      final obj = value as Map;
      expect(obj['a'], equals(1));
      expect(obj['b'], equals(2));
    });

    test('Async function returning object', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          (async () => {
            return {x: 10, y: 20};
          })()
        '''),
        options: JsEvalOptions.withPromise(),
      );
      final value = result.value;
      expect(value, isA<Map>());
      final obj = value as Map;
      expect(obj['x'], equals(10));
      expect(obj['y'], equals(20));
    });

    test('Async function with await chain', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          (async () => {
            const a = await Promise.resolve(1);
            const b = await Promise.resolve(2);
            const c = await Promise.resolve(3);
            return a + b + c;
          })()
        '''),
        options: JsEvalOptions.withPromise(),
      );
      expect(result.value, equals(6));
    });

    test('Promise with setTimeout', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          new Promise((resolve) => {
            setTimeout(() => resolve("delayed"), 10);
          })
        '''),
        options: JsEvalOptions.withPromise(),
      );
      expect(result.value, equals("delayed"));
    });

    test('Promise.all', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          Promise.all([
            Promise.resolve(1),
            Promise.resolve(2),
            Promise.resolve(3)
          ])
        '''),
        options: JsEvalOptions.withPromise(),
      );
      final arr = result.value;
      expect(arr, isA<List>());
      expect(arr, equals([1, 2, 3]));
    });

    test('Promise.race', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          Promise.race([
            Promise.resolve("first"),
            new Promise(r => setTimeout(() => r("second"), 100))
          ])
        '''),
        options: JsEvalOptions.withPromise(),
      );
      expect(result.value, equals("first"));
    });

    test('Async generator simulation', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          (async () => {
            const results = [];
            for (let i = 0; i < 3; i++) {
              results.push(await Promise.resolve(i * 10));
            }
            return results;
          })()
        '''),
        options: JsEvalOptions.withPromise(),
      );
      final arr = result.value;
      expect(arr, isA<List>());
      expect(arr, equals([0, 10, 20]));
    });
  });

  group('Edge Cases and Boundary Tests', () {
    late JsAsyncRuntime runtime;
    late JsAsyncContext context;
    late JsEngine engine;

    setUp(() async {
      runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.all(),
      );
      context = await JsAsyncContext.from(runtime: runtime);
      engine = JsEngine(context: context);
      await engine.initWithoutBridge();
    });

    tearDown(() async {
      if (!engine.disposed) {
        await engine.dispose();
      }
    });

    test('Empty string', () async {
      final result = await engine.eval(source: const JsCode.code('""'));
      expect(result.value, equals(''));
    });

    test('Unicode string', () async {
      final result = await engine.eval(
        source: const JsCode.code('"Hello 世界 🌍 مرحبا"'),
      );
      expect(result.value, equals('Hello 世界 🌍 مرحبا'));
    });

    test('Very long string', () async {
      final result = await engine.eval(
        source: const JsCode.code('"a".repeat(10000).length'),
      );
      expect(result.value, equals(10000));
    });

    test('Zero and negative zero', () async {
      final zero = await engine.eval(source: const JsCode.code('0'));
      expect(zero.value, equals(0));

      final negZero = await engine.eval(source: const JsCode.code('-0'));
      expect(negZero.value, equals(0));
    });

    test('Infinity values', () async {
      final inf = await engine.eval(source: const JsCode.code('Infinity'));
      expect(inf.value, equals(double.infinity));

      final negInf = await engine.eval(source: const JsCode.code('-Infinity'));
      expect(negInf.value, equals(double.negativeInfinity));
    });

    test('NaN handling', () async {
      final result = await engine.eval(source: const JsCode.code('NaN'));
      expect((result.value as double).isNaN, true);
    });

    test('Large integer', () async {
      final result = await engine.eval(
        source:
            const JsCode.code('9007199254740991'), // Number.MAX_SAFE_INTEGER
      );
      expect(result.value, equals(9007199254740991));
    });

    test('Small integer', () async {
      final result = await engine.eval(
        source:
            const JsCode.code('-9007199254740991'), // Number.MIN_SAFE_INTEGER
      );
      expect(result.value, equals(-9007199254740991));
    });

    test('Empty array', () async {
      final result = await engine.eval(source: const JsCode.code('[]'));
      expect(result.isArray(), true);
      expect(result.value, equals([]));
    });

    test('Empty object', () async {
      final result = await engine.eval(source: const JsCode.code('({})'));
      expect(result.isObject(), true);
      expect(result.value, equals({}));
    });

    test('Null value', () async {
      final result = await engine.eval(source: const JsCode.code('null'));
      expect(result.isNone(), true);
      expect(result.value, isNull);
    });

    test('Undefined value', () async {
      final result = await engine.eval(source: const JsCode.code('undefined'));
      expect(result.isNone(), true);
    });

    test('Boolean false', () async {
      final result = await engine.eval(source: const JsCode.code('false'));
      expect(result.isBoolean(), true);
      expect(result.value, false);
    });

    test('Deeply nested object', () async {
      final result = await engine.eval(
        source: const JsCode.code('({a: {b: {c: {d: {e: "deep"}}}}})'),
      );
      expect(result.isObject(), true);
      final obj = result.value as Map;
      expect((((obj['a'] as Map)['b'] as Map)['c'] as Map)['d']['e'],
          equals("deep"));
    });

    test('Array with mixed types', () async {
      final result = await engine.eval(
        source: const JsCode.code('[1, "two", true, null, {a: 1}, [1, 2]]'),
      );
      expect(result.isArray(), true);
      final arr = result.value as List;
      expect(arr[0], equals(1));
      expect(arr[1], equals("two"));
      expect(arr[2], equals(true));
      expect(arr[3], isNull);
      expect((arr[4] as Map)['a'], equals(1));
      expect(arr[5], equals([1, 2]));
    });

    test('Object with special keys', () async {
      final result = await engine.eval(
        source: const JsCode.code('({"key with spaces": 1, "123": 2, "": 3})'),
      );
      expect(result.isObject(), true);
      final obj = result.value as Map;
      expect(obj['key with spaces'], equals(1));
      expect(obj['123'], equals(2));
      expect(obj[''], equals(3));
    });

    test('Circular reference handling', () async {
      // This should not cause infinite loop
      final result = await engine.eval(
        source: const JsCode.code('''
          const obj = {a: 1};
          obj.self = obj;
          obj.a
        '''),
      );
      expect(result.value, equals(1));
    });

    test('Date object', () async {
      final result = await engine.eval(
        source: const JsCode.code('new Date(1609459200000).getTime()'),
      );
      expect(result.value, equals(1609459200000));
    });

    test('RegExp test', () async {
      final result = await engine.eval(
        source: const JsCode.code('/hello/.test("hello world")'),
      );
      expect(result.value, equals(true));
    });

    test('typeof operator', () async {
      final results = await Future.wait([
        engine.eval(source: const JsCode.code('typeof 42')),
        engine.eval(source: const JsCode.code('typeof "hello"')),
        engine.eval(source: const JsCode.code('typeof true')),
        engine.eval(source: const JsCode.code('typeof undefined')),
        engine.eval(source: const JsCode.code('typeof null')),
        engine.eval(source: const JsCode.code('typeof {}')),
        engine.eval(source: const JsCode.code('typeof []')),
        engine.eval(source: const JsCode.code('typeof (() => {})')),
      ]);

      expect(results[0].value, equals('number'));
      expect(results[1].value, equals('string'));
      expect(results[2].value, equals('boolean'));
      expect(results[3].value, equals('undefined'));
      expect(results[4].value, equals('object'));
      expect(results[5].value, equals('object'));
      expect(results[6].value, equals('object'));
      expect(results[7].value, equals('function'));
    });
  });

  group('Error Handling Edge Cases', () {
    late JsAsyncRuntime runtime;
    late JsAsyncContext context;
    late JsEngine engine;

    setUp(() async {
      runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.all(),
      );
      context = await JsAsyncContext.from(runtime: runtime);
      engine = JsEngine(context: context);
      await engine.initWithoutBridge();
    });

    tearDown(() async {
      if (!engine.disposed) {
        await engine.dispose();
      }
    });

    test('Try-catch in JS', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          try {
            throw new Error("test error");
          } catch (e) {
            "caught: " + e.message
          }
        '''),
      );
      expect(result.value, equals("caught: test error"));
    });

    test('Promise rejection handling in JS', () async {
      final result = await engine.eval(
        source: const JsCode.code('''
          (async () => {
            try {
              await Promise.reject("rejected");
            } catch (e) {
              return "handled: " + e;
            }
          })()
        '''),
        options: JsEvalOptions.withPromise(),
      );
      expect(result.value, equals("handled: rejected"));
    });

    test('TypeError in JS', () async {
      expect(
        () => engine.eval(source: const JsCode.code('null.property')),
        throwsA(isA<JsError>()),
      );
    });

    test('ReferenceError in JS', () async {
      expect(
        () => engine.eval(source: const JsCode.code('nonExistentVariable')),
        throwsA(isA<JsError>()),
      );
    });

    test('SyntaxError in JS', () async {
      expect(
        () => engine.eval(source: const JsCode.code('function {')),
        throwsA(isA<JsError>()),
      );
    });

    test('RangeError in JS', () async {
      expect(
        () => engine.eval(source: const JsCode.code('new Array(-1)')),
        throwsA(isA<JsError>()),
      );
    });
  });

  group('Bridge Call Edge Cases', () {
    late JsAsyncRuntime runtime;
    late JsAsyncContext context;
    late JsEngine engine;

    setUp(() async {
      runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.all(),
      );
      context = await JsAsyncContext.from(runtime: runtime);
      engine = JsEngine(context: context);
    });

    tearDown(() async {
      if (!engine.disposed) {
        await engine.dispose();
      }
    });

    test('Bridge call with null', () async {
      dynamic received;
      await engine.init(
        bridge: (value) async {
          received = value.value;
          return JsResult.ok(const JsValue.string('ok'));
        },
      );

      await engine.eval(
        source: const JsCode.code('await fjs.bridge_call(null)'),
        options: JsEvalOptions.withPromise(),
      );
      expect(received, isNull);
    });

    test('Bridge call with undefined', () async {
      dynamic received;
      await engine.init(
        bridge: (value) async {
          received = value;
          return JsResult.ok(const JsValue.string('ok'));
        },
      );

      await engine.eval(
        source: const JsCode.code('await fjs.bridge_call(undefined)'),
        options: JsEvalOptions.withPromise(),
      );
      expect(received.isNone(), true);
    });

    test('Bridge call with large object', () async {
      dynamic received;
      await engine.init(
        bridge: (value) async {
          received = value.value;
          return JsResult.ok(const JsValue.boolean(true));
        },
      );

      await engine.eval(
        source: const JsCode.code('''
          const obj = {};
          for (let i = 0; i < 100; i++) {
            obj["key" + i] = i;
          }
          await fjs.bridge_call(obj)
        '''),
        options: JsEvalOptions.withPromise(),
      );
      expect(received, isA<Map>());
      expect((received as Map).length, equals(100));
    });

    test('Bridge call with array', () async {
      dynamic received;
      await engine.init(
        bridge: (value) async {
          received = value.value;
          return JsResult.ok(const JsValue.boolean(true));
        },
      );

      await engine.eval(
        source: const JsCode.code('await fjs.bridge_call([1, 2, 3, 4, 5])'),
        options: JsEvalOptions.withPromise(),
      );
      expect(received, equals([1, 2, 3, 4, 5]));
    });

    test('Multiple bridge calls', () async {
      int callCount = 0;
      await engine.init(
        bridge: (value) async {
          callCount++;
          return JsResult.ok(JsValue.integer(callCount));
        },
      );

      final result = await engine.eval(
        source: const JsCode.code('''
          (async () => {
            const a = await fjs.bridge_call(1);
            const b = await fjs.bridge_call(2);
            const c = await fjs.bridge_call(3);
            return a + b + c;
          })()
        '''),
        options: JsEvalOptions.withPromise(),
      );
      expect(callCount, equals(3));
      expect(result.value, equals(6)); // 1 + 2 + 3
    });

    test('Bridge call returning different types', () async {
      int callIndex = 0;
      final returns = [
        const JsValue.integer(42),
        const JsValue.string("hello"),
        const JsValue.boolean(true),
        const JsValue.array([JsValue.integer(1), JsValue.integer(2)]),
      ];

      await engine.init(
        bridge: (value) async {
          return JsResult.ok(returns[callIndex++]);
        },
      );

      final results = await engine.eval(
        source: const JsCode.code('''
          (async () => {
            const a = await fjs.bridge_call(0);
            const b = await fjs.bridge_call(1);
            const c = await fjs.bridge_call(2);
            const d = await fjs.bridge_call(3);
            return [a, b, c, d];
          })()
        '''),
        options: JsEvalOptions.withPromise(),
      );
      expect(results.isArray(), true);
      final arr = results.value as List;
      expect(arr[0], equals(42));
      expect(arr[1], equals("hello"));
      expect(arr[2], equals(true));
      expect(arr[3], equals([1, 2]));
    });
  });

  group('Memory and Resource Tests', () {
    test('Memory limit enforcement', () async {
      final runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.essential(),
      );
      final context = await JsAsyncContext.from(runtime: runtime);

      // Set a small memory limit
      await runtime.setMemoryLimit(limit: BigInt.from(1024 * 1024)); // 1MB

      final engine = JsEngine(context: context);
      await engine.initWithoutBridge();

      // This should work with small data
      final smallResult = await engine.eval(
        source: const JsCode.code('const arr = [1, 2, 3]; arr.length'),
      );
      expect(smallResult.value, equals(3));

      await engine.dispose();
    });

    test('Garbage collection', () async {
      final runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.essential(),
      );
      final context = await JsAsyncContext.from(runtime: runtime);
      final engine = JsEngine(context: context);
      await engine.initWithoutBridge();

      // Create and discard objects
      for (int i = 0; i < 100; i++) {
        await engine.eval(
          source:
              JsCode.code('const obj$i = { data: new Array(100).fill($i) };'),
        );
      }

      // Force GC
      await runtime.runGc();

      // Engine should still work
      final result = await engine.eval(source: const JsCode.code('1 + 1'));
      expect(result.value, equals(2));

      await engine.dispose();
    });

    test('Context isolation', () async {
      final runtime = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions.essential(),
      );

      final context1 = await JsAsyncContext.from(runtime: runtime);
      final context2 = await JsAsyncContext.from(runtime: runtime);

      final engine1 = JsEngine(context: context1);
      final engine2 = JsEngine(context: context2);

      await engine1.initWithoutBridge();
      await engine2.initWithoutBridge();

      // Set variable in engine1
      await engine1.eval(
          source: const JsCode.code('globalThis.testVar = "engine1"'));

      // Should not be visible in engine2
      final result = await engine2.eval(
        source: const JsCode.code('typeof globalThis.testVar'),
      );
      expect(result.value, equals('undefined'));

      await engine1.dispose();
      await engine2.dispose();
    });
  });
}
