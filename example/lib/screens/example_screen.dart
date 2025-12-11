import 'dart:async';

import 'package:fjs/fjs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyEngine {
  MyEngine._(this._engine);

  final JsEngine _engine;

  static late final MyEngine _instance;
  static bool _initialized = false;

  factory MyEngine() {
    if (!_initialized) {
      throw StateError('MyEngine is not initialized. Call initialize() first.');
    }
    return _instance;
  }

  static Future<void> initialize({
    FutureOr<JsValue?> Function(JsValue)? bridgeCall,
  }) async {
    if (_initialized) {
      return;
    }

    final linkedom =
        await rootBundle.load('assets/examples/linkedom.bundle.mjs');
    final canvas = await rootBundle.load('assets/examples/canvas.bundle.mjs');

    final rt = await JsAsyncRuntime.withOptions(
        builtin: JsBuiltinOptions(
          console: true,
          fetch: true,
          timers: true,
          url: true,
        ),
        additional: [
          JsModule(
              name: 'canvas',
              source: JsCode.bytes(canvas.buffer.asUint8List())),
          JsModule(
              name: 'linkedom',
              source: JsCode.bytes(linkedom.buffer.asUint8List())),
        ]);
    final context = await JsAsyncContext.from(rt: rt);
    final engine = JsEngine(context);
    await engine.init(bridgeCall: bridgeCall);
    _instance = MyEngine._(engine);
    _initialized = true;
  }

  void _assertInitialized() {
    if (!_initialized) {
      throw StateError('MyEngine is not initialized. Call initialize() first.');
    }
  }

  Future<JsValue> evaluateModule(String taskId, String code) async {
    _assertInitialized();
    await _engine
        .evaluateModule(JsModule(name: taskId, source: JsCode.code(code)));
    final result = await _engine.eval(JsCode.code('''
    (()=>{
      const result = globalThis['$taskId'];
      delete globalThis['$taskId'];
      return result;
    })()
    '''));
    return result;
  }

  Future<JsValue> evaluate(String code) async {
    _assertInitialized();
    return _engine.eval(JsCode.code(code));
  }
}

Future<void> test1MyEngine() async {
  await MyEngine.initialize(bridgeCall: (value) async {
    print('Bridge call with value: $value');
    return JsValue.string('Response from Dart');
  });

  final engine = MyEngine();
  final code = '''
await (async () => {
    const {parseHTML} = await import('linkedom');
    const html = await fetch("https://example.com").then((res) => res.text());
    console.log("Fetched HTML:", html);
    const {document} = parseHTML(html);

    return document.toString();
})()
  ''';
  final result = await engine.evaluate(code);

  print('Evaluation result: $result');
}

Future<void> test2MyEngine() async {
  await MyEngine.initialize(bridgeCall: (value) async {
    print('Bridge call with value: $value');
    return JsValue.string('Response from Dart');
  });

  final engine = MyEngine();
  final taskId = DateTime.timestamp().microsecondsSinceEpoch.toRadixString(36);
  final code = '''
import {parseHTML} from 'linkedom';

globalThis['$taskId'] = await (async () => {
    const html = await fetch("https://example.com").then((res) => res.text());
    console.log("Fetched HTML:", html);
    const {document} = parseHTML(html);

    return document.toString();
})();
  ''';
  print(code);
  final result = await engine.evaluateModule(taskId, code);

  print('Evaluation result: $result');
}

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 24.0,
          children: [
            ElevatedButton(
              onPressed: () async {
                await test1MyEngine();
              },
              child: const Text('Run MyEngine Test 1'),
            ),
            ElevatedButton(
              onPressed: () async {
                await test2MyEngine();
              },
              child: const Text('Run MyEngine Test 2'),
            ),
          ],
        ),
      ),
    );
  }
}
