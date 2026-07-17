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

int parseOtoolContentHash(
  String output, {
  required String architecture,
}) {
  if (architecture != 'arm64' && architecture != 'x86_64') {
    throw UnsupportedError(
      'unsupported Mach-O architecture for FRB content hash: $architecture',
    );
  }

  final functionMatch = RegExp(
    r'^_frb_get_rust_content_hash:[ \t]*\r?\n(.*?)(?=^[A-Za-z_.$][^\r\n]*:[ \t]*\r?$|\z)',
    multiLine: true,
    dotAll: true,
  ).firstMatch(output);
  if (functionMatch == null) {
    throw const FormatException(
      'otool output is missing _frb_get_rust_content_hash',
    );
  }
  final body = functionMatch.group(1)!;

  final unsignedHash = switch (architecture) {
    'arm64' => _parseArm64ContentHash(body),
    'x86_64' => _parseX8664ContentHash(body),
    _ => throw StateError('unreachable architecture: $architecture'),
  };
  return unsignedHash >= 0x80000000 ? unsignedHash - 0x100000000 : unsignedHash;
}

int _parseArm64ContentHash(String body) {
  final lowerMatch = RegExp(
    r'\bmov[ \t]+w0,[ \t]*#0x([0-9a-fA-F]{1,4})\b',
  ).firstMatch(body);
  final upperMatch = RegExp(
    r'\bmovk[ \t]+w0,[ \t]*#0x([0-9a-fA-F]{1,4}),[ \t]*lsl[ \t]+#16\b',
  ).firstMatch(body);
  if (lowerMatch == null || upperMatch == null) {
    throw const FormatException(
      'arm64 FRB content hash must use mov w0 plus movk w0, lsl #16',
    );
  }
  final lower = int.parse(lowerMatch.group(1)!, radix: 16);
  final upper = int.parse(upperMatch.group(1)!, radix: 16);
  return lower | (upper << 16);
}

int _parseX8664ContentHash(String body) {
  final match = RegExp(
    r'\bmovl[ \t]+\$0x([0-9a-fA-F]{1,8}),[ \t]*%eax\b',
  ).firstMatch(body);
  if (match == null) {
    throw const FormatException(
      r'x86_64 FRB content hash must use movl $immediate, %eax',
    );
  }
  return int.parse(match.group(1)!, radix: 16);
}

int readMachOContentHash(
  String binaryPath, {
  required String architecture,
}) {
  final result = Process.runSync(
    'otool',
    ['-arch', architecture, '-tvV', binaryPath],
  );
  if (result.exitCode != 0) {
    throw ProcessException(
      'otool',
      ['-arch', architecture, '-tvV', binaryPath],
      result.stderr.toString().trim(),
      result.exitCode,
    );
  }
  return parseOtoolContentHash(
    result.stdout.toString(),
    architecture: architecture,
  );
}

void main(List<String> arguments) {
  final usesOtool = arguments.isNotEmpty && arguments.first == '--otool-arch';
  final validLength = usesOtool
      ? arguments.length == 3 || arguments.length == 4
      : arguments.length == 1 || arguments.length == 2;
  if (!validLength) {
    stderr.writeln(
      'Usage: dart run tool/check_frb_content_hash.dart '
      '<dynamic-library> [expected-hash]\n'
      '   or: dart run tool/check_frb_content_hash.dart '
      '--otool-arch <arm64|x86_64> <Mach-O-binary> [expected-hash]',
    );
    exitCode = 64;
    return;
  }

  final architecture = usesOtool ? arguments[1] : null;
  final binaryPath = usesOtool ? arguments[2] : arguments[0];
  final expectedArgument = usesOtool
      ? (arguments.length == 4 ? arguments[3] : null)
      : (arguments.length == 2 ? arguments[1] : null);
  final expected =
      expectedArgument == null ? null : int.tryParse(expectedArgument);
  if (expectedArgument != null && expected == null) {
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
    final binaryHash = architecture == null
        ? readBinaryContentHash(binaryPath)
        : readMachOContentHash(binaryPath, architecture: architecture);

    requireMatchingCodegenVersions(dart: dartVersion, rust: rustVersion);
    requireMatchingContentHashes(
      dart: dartHash,
      rust: rustHash,
      binary: binaryHash,
      expected: expected,
    );
    stdout.writeln(
      'FRB codegen version $dartVersion; content hash $dartHash '
      '(generated Dart, generated Rust, and '
      '${architecture == null ? 'host binary' : '$architecture slice'} match).',
    );
  } on Object catch (error) {
    stderr.writeln('error: $error');
    exitCode = 1;
  }
}
