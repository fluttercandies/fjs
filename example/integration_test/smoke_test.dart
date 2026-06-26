import 'package:fjs/fjs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('loads native library and evaluates JavaScript', () async {
    await LibFjs.init();

    final engine = await JsEngine.create(
      builtins: JsBuiltinOptions.essential(),
    );

    try {
      await engine.initWithoutBridge();

      final result = await engine.eval(
        source: const JsCode.code('1 + 2'),
      );

      expect(result.value, 3);
    } finally {
      if (!engine.closed) {
        await engine.close();
      }
    }
  });
}
