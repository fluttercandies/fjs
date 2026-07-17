import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_frb_content_hash.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync('fjs-frb-hash-');
  });

  tearDown(() {
    temporaryDirectory.deleteSync(recursive: true);
  });

  File sourceFile(String contents) {
    final file = File('${temporaryDirectory.path}/generated.txt');
    return file..writeAsStringSync(contents);
  }

  group('generated Dart metadata', () {
    test('parses the codegen version and content hash', () {
      final file = sourceFile('''
String get codegenVersion => '2.12.0';
int get rustContentHash => -2005216402;
''');

      expect(readGeneratedDartVersion(file), '2.12.0');
      expect(readGeneratedDartHash(file), -2005216402);
    });

    test('rejects a missing version getter', () {
      final file = sourceFile('int get rustContentHash => -2005216402;');

      expect(
        () => readGeneratedDartVersion(file),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a malformed content hash getter', () {
      final file = sourceFile('int get rustContentHash => notAnInteger;');

      expect(
        () => readGeneratedDartHash(file),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('generated Rust metadata', () {
    test('parses the codegen version and content hash', () {
      final file = sourceFile('''
const FLUTTER_RUST_BRIDGE_CODEGEN_VERSION: &str = "2.12.0";
const FLUTTER_RUST_BRIDGE_CODEGEN_CONTENT_HASH: i32 = -2005216402;
''');

      expect(readGeneratedRustVersion(file), '2.12.0');
      expect(readGeneratedRustHash(file), -2005216402);
    });

    test('rejects a malformed version constant', () {
      final file = sourceFile('''
const FLUTTER_RUST_BRIDGE_CODEGEN_VERSION: &str = 2.12.0;
''');

      expect(
        () => readGeneratedRustVersion(file),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a missing content hash constant', () {
      final file = sourceFile('''
const FLUTTER_RUST_BRIDGE_CODEGEN_VERSION: &str = "2.12.0";
''');

      expect(
        () => readGeneratedRustHash(file),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('accepts equal generated versions and hashes', () {
    expect(
      () => requireMatchingCodegenVersions(dart: '2.12.0', rust: '2.12.0'),
      returnsNormally,
    );
    expect(
      () => requireMatchingContentHashes(
        dart: -2005216402,
        rust: -2005216402,
        binary: -2005216402,
      ),
      returnsNormally,
    );
  });

  test('rejects codegen version drift', () {
    expect(
      () => requireMatchingCodegenVersions(dart: '2.12.0', rust: '2.11.1'),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects content hash drift and an unexpected override', () {
    expect(
      () => requireMatchingContentHashes(dart: 1, rust: 1, binary: 2),
      throwsA(isA<StateError>()),
    );
    expect(
      () => requireMatchingContentHashes(
        dart: -2005216402,
        rust: -2005216402,
        binary: -2005216402,
        expected: 1,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
