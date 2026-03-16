import 'package:fjs/fjs.dart';
import 'package:fjs_example/services/fjs_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await LibFjs.init();
  });

  group('FjsService', () {
    testWidgets('infers execution mode from module syntax', (_) async {
      final service = FjsService();
      addTearDown(service.dispose);

      expect(
        service.inferExecutionMode('export default 1;'),
        JsExecutionMode.module,
      );
      expect(
        service.inferExecutionMode('import "foo";'),
        JsExecutionMode.module,
      );
      expect(
        service.inferExecutionMode('const mod = await import("foo");'),
        JsExecutionMode.script,
      );
    });

    testWidgets('serializes concurrent initialization', (_) async {
      final service = FjsService();
      addTearDown(service.dispose);

      await Future.wait([
        service.initialize(),
        service.initialize(),
      ]);

      expect(service.isInitialized, isTrue);
      expect(service.lastError, isNull);
    });

    testWidgets('module execution stays isolated from shared declared modules',
        (_) async {
      final service = FjsService();
      addTearDown(service.dispose);

      await service.initialize();

      final first = await service.executeAsModule('''
        export default {
          value: 1,
          label: 'first',
        };
      ''');
      final second = await service.executeAsModule('''
        export const answer = 42;
      ''');
      final declared = await service.getDeclaredModules();

      expect((first.value as Map)['value'], 1);
      expect((first.value as Map)['label'], 'first');
      expect((second.value as Map)['answer'], 42);
      expect(declared['count'], 0);
      expect(declared['modules'], isEmpty);
    });
  });
}
