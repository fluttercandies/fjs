import 'package:fjs/fjs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await LibFjs.init();
  });

  group('Runtime driver integration', () {
    testWidgets('engine advances detached timers without host polling',
        (_) async {
      final engine = await JsEngine.create(
        builtins: JsBuiltinOptions.essential(),
      );
      addTearDown(() async {
        if (!engine.closed) {
          await engine.close();
        }
      });

      await engine.initWithoutBridge();

      final scheduled = await engine.eval(
        source: const JsCode.code('''
          setTimeout(() => {
            globalThis.__fjsDriverIntegrationDone = true;
          }, 10);
          "scheduled"
        '''),
      );
      expect(scheduled.value, 'scheduled');

      await _eventually(() async {
        final value = await engine.eval(
          source: const JsCode.code(
            'globalThis.__fjsDriverIntegrationDone === true',
          ),
        );
        return value.value == true;
      });

      await engine.close();
      expect(engine.closed, isTrue);
    });

    testWidgets('engine surfaces background JavaScript job errors', (_) async {
      final engine = await JsEngine.create(
        builtins: JsBuiltinOptions.essential(),
      );
      addTearDown(() async {
        if (!engine.closed) {
          await engine.close();
        }
      });

      await engine.initWithoutBridge();
      await engine.eval(
        source: const JsCode.code('''
          setTimeout(() => {
            throw new Error("fjs integration timer failure");
          }, 10);
          "scheduled"
        '''),
      );

      final error = await _eventuallyError(() async {
        await engine.eval(
          source: const JsCode.code('1 + 1'),
        );
      });
      expect(error.toString(), contains('fjs integration timer failure'));
    });

    testWidgets('engine recovers after background timer callback errors',
        (_) async {
      final engine = await JsEngine.create(
        builtins: JsBuiltinOptions.essential(),
      );
      addTearDown(() async {
        if (!engine.closed) {
          await engine.close();
        }
      });

      await engine.initWithoutBridge();
      await engine.eval(
        source: const JsCode.code('''
          setTimeout(() => {
            throw new Error("fjs integration recoverable timer failure");
          }, 10);
          "scheduled";
        '''),
      );

      final error = await _eventuallyError(() async {
        await engine.eval(
          source: const JsCode.code('1 + 1'),
        );
      });
      expect(
        error.toString(),
        contains('fjs integration recoverable timer failure'),
      );

      await engine.eval(
        source: const JsCode.code('''
          setTimeout(() => {
            globalThis.__fjsTimerRecovered = true;
          }, 10);
          "scheduled";
        '''),
      );

      await _eventually(() async {
        final value = await engine.eval(
          source: const JsCode.code(
            'globalThis.__fjsTimerRecovered === true',
          ),
        );
        return value.value == true;
      });
    });

    testWidgets('runtime advances detached timers automatically', (_) async {
      final runtime = await JsAsyncRuntime.create(
        builtins: JsBuiltinOptions.essential(),
      );
      final context = await JsAsyncContext.from(runtime: runtime);

      final scheduled = await context.eval(
        code: '''
          setTimeout(() => {
            globalThis.__fjsAutomaticRuntimeDone = true;
          }, 10);
          "scheduled";
        ''',
      );
      expect(scheduled.isOk, isTrue);
      expect(scheduled.ok.value, 'scheduled');

      await _eventually(() async {
        final result = await context.eval(
          code: 'globalThis.__fjsAutomaticRuntimeDone === true',
        );
        return result.isOk && result.ok.value == true;
      });
    });

    testWidgets('runtime advances detached promises automatically', (_) async {
      final runtime = await JsAsyncRuntime.create(
        builtins: JsBuiltinOptions.essential(),
      );
      final context = await JsAsyncContext.from(runtime: runtime);

      final scheduled = await context.eval(
        code: '''
          Promise.resolve().then(() => {
            globalThis.__fjsAutomaticPromiseDone = true;
          });
          "scheduled";
        ''',
      );
      expect(scheduled.isOk, isTrue);
      expect(scheduled.ok.value, 'scheduled');

      await _eventually(() async {
        final result = await context.eval(
          code: 'globalThis.__fjsAutomaticPromiseDone === true',
        );
        return result.isOk && result.ok.value == true;
      });
    });

    testWidgets('runtime surfaces unhandled promise rejections', (_) async {
      final runtime = await JsAsyncRuntime.create();
      final context = await JsAsyncContext.from(runtime: runtime);

      final scheduled = await context.eval(
        code: '''
          Promise.reject(new Error("fjs integration unhandled rejection"));
          "scheduled";
        ''',
      );
      expect(scheduled.isOk, isTrue);
      expect(scheduled.ok.value, 'scheduled');

      final error = await _eventuallyJsResultError(() async {
        return context.eval(
          code: '1 + 1',
        );
      });
      expect(error.toString(), contains('fjs integration unhandled rejection'));
    });

    testWidgets('drop path tolerates bridge and loaded module without close',
        (_) async {
      var engine = await JsEngine.create(
        builtins: JsBuiltinOptions.essential(),
        modules: [
          JsModule.code(
            module: 'integration-drop-fixture',
            code: 'export const value = 42;',
          ),
        ],
      );

      await engine.init(
        bridge: (value) async => JsResult.ok(value),
      );
      await engine.evaluateModule(
        module: JsModule.code(
          module: '/integration-drop-test',
          code: '''
            import { value } from 'integration-drop-fixture';
            export async function run() {
              return await fjs.bridge_call(value);
            }
          ''',
        ),
      );

      final value = await engine.call(
        module: '/integration-drop-test',
        method: 'run',
      );
      expect(value.value, 42);

      engine = await JsEngine.create();
      await engine.initWithoutBridge();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await engine.close();
    });

    testWidgets('oversized async stack limit remains catchable', (_) async {
      final engine = await JsEngine.create(
        builtins: JsBuiltinOptions.essential(),
      );
      addTearDown(() async {
        if (!engine.closed) {
          await engine.close();
        }
      });

      await engine.initWithoutBridge();
      await engine.setMaxStackSize(limit: BigInt.zero);

      Object? caught;
      try {
        await engine.eval(
          source: const JsCode.code('''
            function recurse() {
              return recurse() + 1;
            }
            recurse();
          '''),
        );
      } catch (error) {
        caught = error;
      }

      expect(caught, isNotNull);
      expect(
        caught.toString(),
        contains('Maximum call stack size exceeded'),
      );
    });

    testWidgets('background errors are surfaced through public calls',
        (_) async {
      final engine = await JsEngine.create(
        builtins: JsBuiltinOptions.essential(),
      );
      addTearDown(() async {
        if (!engine.closed) {
          await engine.close();
        }
      });

      await engine.initWithoutBridge();
      await engine.eval(
        source: const JsCode.code('''
          globalThis.__fjsBoundedQueueFired = 0;
          for (let i = 0; i < 40; i++) {
            Promise.resolve().then(() => {
              globalThis.__fjsBoundedQueueFired += 1;
              throw new Error("fjs public background error " + i);
            });
          }
          "scheduled";
        '''),
      );

      final error = await _eventuallyError(() async {
        await engine.eval(
          source: const JsCode.code('globalThis.__fjsBoundedQueueFired'),
        );
      });
      expect(error.toString(), contains('fjs public background error'));
    });
  });
}

Future<void> _eventually(
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 2),
  Duration interval = const Duration(milliseconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) {
      return;
    }
    await Future<void>.delayed(interval);
  }

  if (await condition()) {
    return;
  }
  fail('condition was not met within ${timeout.inMilliseconds}ms');
}

Future<Object> _eventuallyError(
  Future<void> Function() action, {
  Duration timeout = const Duration(seconds: 2),
  Duration interval = const Duration(milliseconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(deadline)) {
    try {
      await action();
    } catch (error) {
      return error;
    }
    await Future<void>.delayed(interval);
  }

  try {
    await action();
  } catch (error) {
    return error;
  }

  fail('error was not thrown within ${timeout.inMilliseconds}ms');
}

Future<JsError> _eventuallyJsResultError(
  Future<JsResult> Function() action, {
  Duration timeout = const Duration(seconds: 2),
  Duration interval = const Duration(milliseconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(deadline)) {
    final result = await action();
    if (result.isErr) {
      return result.err;
    }
    await Future<void>.delayed(interval);
  }

  final result = await action();
  if (result.isErr) {
    return result.err;
  }
  fail('JsResult error was not returned within ${timeout.inMilliseconds}ms');
}
