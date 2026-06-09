import 'package:fjs/fjs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await LibFjs.init();
  });

  group('Runtime driver integration', () {
    testWidgets('engine driver advances detached timers without host polling',
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
      expect(await engine.driverRunning(), isTrue);

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
      expect(await engine.driverRunning(), isFalse);
    });

    testWidgets('engine drains background JavaScript job errors', (_) async {
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

      await _eventually(() async {
        final errors = await engine.drainUnhandledJobErrors();
        return errors.any(
          (error) => error.contains('fjs integration timer failure'),
        );
      });
    });

    testWidgets('runtime executePendingJob manually advances detached timers',
        (_) async {
      final runtime = await JsAsyncRuntime.create(
        builtins: JsBuiltinOptions.essential(),
      );
      final context = await JsAsyncContext.from(runtime: runtime);

      final scheduled = await context.eval(
        code: '''
          setTimeout(() => {
            globalThis.__fjsManualPumpDone = true;
          }, 10);
          "scheduled";
        ''',
      );
      expect(scheduled.isOk, isTrue);
      expect(scheduled.ok.value, 'scheduled');

      await runtime.stopDriver();
      expect(await runtime.driverRunning(), isFalse);

      await _eventually(() async {
        await runtime.executePendingJob();
        final result = await context.eval(
          code: 'globalThis.__fjsManualPumpDone === true',
        );
        return result.isOk && result.ok.value == true;
      });

      expect(await runtime.drainUnhandledJobErrors(), isEmpty);
    });

    testWidgets('runtime driver can restart after stop', (_) async {
      final runtime = await JsAsyncRuntime.create(
        builtins: JsBuiltinOptions.essential(),
      );
      final context = await JsAsyncContext.from(runtime: runtime);

      await runtime.startDriver();
      expect(await runtime.driverRunning(), isTrue);
      await runtime.stopDriver();
      expect(await runtime.driverRunning(), isFalse);

      final scheduled = await context.eval(
        code: '''
          setTimeout(() => {
            globalThis.__fjsRestartedDriverDone = true;
          }, 10);
          "scheduled";
        ''',
      );
      expect(scheduled.isOk, isTrue);
      expect(scheduled.ok.value, 'scheduled');

      await runtime.startDriver();
      expect(await runtime.driverRunning(), isTrue);

      await _eventually(() async {
        final result = await context.eval(
          code: 'globalThis.__fjsRestartedDriverDone === true',
        );
        return result.isOk && result.ok.value == true;
      });

      await runtime.stopDriver();
      expect(await runtime.driverRunning(), isFalse);
    });

    testWidgets('runtime drains unhandled promise rejections', (_) async {
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

      await _eventually(() async {
        await runtime.executePendingJob();
        final errors = await runtime.drainUnhandledJobErrors();
        return errors.any(
          (error) => error.contains('fjs integration unhandled rejection'),
        );
      });

      expect(await runtime.drainUnhandledJobErrors(), isEmpty);
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

    testWidgets('background error queue is bounded to newest errors',
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
              throw new Error("fjs bounded queue error " + i);
            });
          }
          "scheduled";
        '''),
      );

      await _eventually(() async {
        final fired = await engine.eval(
          source: const JsCode.code('globalThis.__fjsBoundedQueueFired'),
        );
        return fired.value == 40;
      });

      final drained = await engine.drainUnhandledJobErrors();
      expect(drained.length, 32);
      expect(drained.first, isNot(contains('fjs bounded queue error 0')));
      expect(
        drained,
        contains(
          predicate<String>(
            (error) => error.contains('fjs bounded queue error 39'),
            'latest queued error',
          ),
        ),
      );
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
