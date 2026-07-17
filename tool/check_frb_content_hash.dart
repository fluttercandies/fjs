import 'dart:ffi';
import 'dart:io';

typedef NativeContentHash = Int32 Function();
typedef DartContentHash = int Function();

final _dartVersionPattern = RegExp(
  r"String\s+get\s+codegenVersion\s*=>\s*'([^']+)'\s*;",
);
final _dartHashPattern = RegExp(
  r'int\s+get\s+rustContentHash\s*=>\s*(-?\d+)\s*;',
);
final _rustVersionPattern = RegExp(
  r'FLUTTER_RUST_BRIDGE_CODEGEN_VERSION:\s*&str\s*=\s*"([^"]+)"\s*;',
);
final _rustHashPattern = RegExp(
  r'FLUTTER_RUST_BRIDGE_CODEGEN_CONTENT_HASH:\s*i32\s*=\s*(-?\d+)\s*;',
);

String readGeneratedDartVersion(File file) =>
    _readRequiredMatch(file, _dartVersionPattern, 'Dart codegen version');

int readGeneratedDartHash(File file) => int.parse(
      _readRequiredMatch(file, _dartHashPattern, 'Dart content hash'),
    );

String readGeneratedRustVersion(File file) =>
    _readRequiredMatch(file, _rustVersionPattern, 'Rust codegen version');

int readGeneratedRustHash(File file) => int.parse(
      _readRequiredMatch(file, _rustHashPattern, 'Rust content hash'),
    );

String _readRequiredMatch(File file, RegExp pattern, String label) {
  final match = pattern.firstMatch(file.readAsStringSync());
  if (match == null) {
    throw FormatException('$label is missing or malformed in ${file.path}');
  }
  return match.group(1)!;
}

void requireMatchingCodegenVersions({
  required String dart,
  required String rust,
}) {
  if (dart != rust) {
    throw StateError(
      'FRB codegen version mismatch: generated Dart=$dart, generated Rust=$rust',
    );
  }
}

void requireMatchingContentHashes({
  required int dart,
  required int rust,
  required int binary,
  int? expected,
}) {
  if (dart != rust || dart != binary) {
    throw StateError(
      'FRB content hash mismatch: generated Dart=$dart, '
      'generated Rust=$rust, binary=$binary',
    );
  }
  if (expected != null && dart != expected) {
    throw StateError(
      'FRB content hash does not match expected value: '
      'generated/binary=$dart, expected=$expected',
    );
  }
}

int readBinaryContentHash(String binaryPath) {
  final library = DynamicLibrary.open(binaryPath);
  return library.lookupFunction<NativeContentHash, DartContentHash>(
    'frb_get_rust_content_hash',
  )();
}

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.length > 2) {
    stderr.writeln(
      'Usage: dart run tool/check_frb_content_hash.dart '
      '<dynamic-library> [expected-hash]',
    );
    exitCode = 64;
    return;
  }

  final expected = arguments.length == 2 ? int.tryParse(arguments[1]) : null;
  if (arguments.length == 2 && expected == null) {
    stderr.writeln('error: expected hash must be a signed integer');
    exitCode = 64;
    return;
  }

  try {
    final repositoryRoot = File.fromUri(Platform.script).parent.parent;
    final dartFile = File(
      '${repositoryRoot.path}/lib/src/frb/frb_generated.dart',
    );
    final rustFile = File('${repositoryRoot.path}/libfjs/src/frb_generated.rs');
    final dartVersion = readGeneratedDartVersion(dartFile);
    final rustVersion = readGeneratedRustVersion(rustFile);
    final dartHash = readGeneratedDartHash(dartFile);
    final rustHash = readGeneratedRustHash(rustFile);
    final binaryHash = readBinaryContentHash(arguments.first);

    requireMatchingCodegenVersions(dart: dartVersion, rust: rustVersion);
    requireMatchingContentHashes(
      dart: dartHash,
      rust: rustHash,
      binary: binaryHash,
      expected: expected,
    );
    stdout.writeln(
      'FRB codegen version $dartVersion; content hash $dartHash '
      '(generated Dart, generated Rust, and binary match).',
    );
  } on Object catch (error) {
    stderr.writeln('error: $error');
    exitCode = 1;
  }
}
