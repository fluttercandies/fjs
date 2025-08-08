import 'package:fjs/fjs.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await LibFjs.init().catchError((e, s) {
    print("Error initializing LibFjs: $e $s");
  });
  runApp(const MyApp());
}

const codes =
// language=js
    """
export async function test(){
                console.log(arguments);
                console.debug(arguments);
                console.warn(arguments);
                console.error(arguments);
                console.log(JSON.stringify(arguments));
                console.log(await fetch('https://www.google.com/').then((res) => res.text()));
                console.log(await fetch('https://www.baidu.com/').then((res) => res.text()));
                console.log(await fetch('https://httpbin.org/get').then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/get').then((res) => res.text()));
                console.log(await fetch('https://httpbin.org/get').then((res) => res.arrayBuffer()).then((a) => a.byteLength));
                console.log(await fetch('https://httpbin.org/post', { method: 'POST'}).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/put', { method: 'PUT'}).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/patch', { method: 'PATCH'}).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/delete', { method: 'DELETE'}).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/post', { method: 'POST', headers: { "content-TYPE": "application/x-www-form-urlencoded" }, body: { hello: "world" } }).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/post', { method: 'POST', headers: { "content-TYPE": "application/x-www-form-urlencoded" }, body: "hello=world" }).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/post', { method: 'POST', body: { hello: "world" } }).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/post', { method: 'POST', body: ["hello", "world"] }).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/post', { method: 'POST', body: JSON.stringify({ hello: "world" }) }).then((res) => res.json()));
                return arguments;
}
    """;
final jsEngine = (() async {
  final rt = JsAsyncRuntime();
  final ctx = await JsAsyncContext.from(rt: rt);
  final engine = JsEngine(ctx);
  await engine.init(bridgeCall: (v) {
    final value = v.value;
    return JsValue.string("Hello from Dart! $value");
  }).catchError((e) {
    print("Error initializing JsEngine: $e");
  });
  return engine;
})();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                  onPressed: () async {
                    final engine = await jsEngine;

                    try {
                      final start = DateTime.now();
                      for (var i = 0; i < 10000; i++) {
                        await engine.eval(JsCode.code("1+$i"));
                      }
                      final end = DateTime.now();
                      print(
                          "Time taken for 10000 evaluations: ${end.difference(start).inMilliseconds} ms");
                    } catch (e) {
                      print(e);
                    }
                  },
                  child: const Text("eval 10000 times")),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: () async {
                    final engine = await jsEngine;

                    try {
                      final start = DateTime.now();
                      final _ = await engine.eval(const JsCode.code(
                          // language=js
                          "(()=>{let obj = {};for(var i = 0; i < 100000; i++) { let k = Math.random().toString();obj[k] = k;}return obj;})()"));
                      final end = DateTime.now();
                      print(
                          "Time taken for large object creation: ${end.difference(start).inMilliseconds} ms");
                    } catch (e) {
                      print(e);
                    }
                  },
                  child: const Text("large object")),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: () async {
                    final engine = await jsEngine;

                    try {
                      final jsValue = await engine.eval(JsCode.code(
                          "await fjs.bridge_call('Hello from JS! ${DateTime.now()}')"));
                      print("JS Value: ${jsValue.value}");
                    } catch (e) {
                      print(e);
                    }
                  },
                  child: const Text("bridge call")),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: () async {
                    final engine = await jsEngine;
                    try {
                      await engine.enableBuiltinModule(const JsBuiltinOptions(
                        fetch: true,
                        console: true,
                      ));
                      await engine.declareModule(
                        JsModule.code(module: "test", code: codes),
                        timeout: const Duration(seconds: 5),
                      );
                      await engine.evaluateModule(
                        JsModule.code(
                            module: "test",
                            code:
                                "import {test} from 'test';console.log(test('Hello', 'from', 'JS!'));test('Hello', 'from', 'JS!')"),
                        timeout: const Duration(seconds: 5),
                      );
                      final jsValue4 = await engine.eval(
                        const JsCode.code(
                            "let v = await fetch('https://httpbin.org/get').then((res) => res.json());console.log(v);v"),
                      );
                      print("JS Value 4: $jsValue4");

                      var jsValue5 = await engine.eval(const JsCode.code(
                          "import {price} from 'assets_test';console.log(price);await price('So11111111111111111111111111111111111111112')"));
                      print("JS Value 5: $jsValue5");
                    } catch (e) {
                      print(e);
                    }
                  },
                  child: const Text("module")),
            ],
          ),
        ),
      ),
    );
  }
}
