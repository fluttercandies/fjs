import 'dart:io';

import 'package:build_tool/src/crate_hash.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

const _publicKey =
    'a4c3433798eb2c36edf2b94dbb4dd899d57496ca373a8982d8a792410b7f6445';

void main() {
  late Directory temporaryDirectory;
  late Directory workspace;
  late Directory manifest;

  setUp(() {
    final resolvedSystemTemp =
        Directory(Directory.systemTemp.resolveSymbolicLinksSync());
    temporaryDirectory = resolvedSystemTemp.createTempSync('crate_hash_test.');
    workspace = Directory(path.join(temporaryDirectory.path, 'workspace'))
      ..createSync();
    manifest = Directory(path.join(workspace.path, 'crate'))..createSync();
    _write(manifest, 'Cargo.toml', '[package]\nname = "test_crate"\n');
    _write(manifest, 'src/lib.rs', 'pub fn answer() -> i32 { 42 }\n');
    _writeConfig(manifest);
  });

  tearDown(() {
    temporaryDirectory.deleteSync(recursive: true);
  });

  test('existing Rust input names and contents affect the hash', () {
    final original = CrateHash.compute(manifest.path);

    _write(manifest, 'src/lib.rs', 'pub fn answer() -> i32 { 43 }\n');
    final contentChanged = CrateHash.compute(manifest.path);
    expect(contentChanged, isNot(original));

    final source = File(path.join(manifest.path, 'src/lib.rs'));
    source.renameSync(path.join(manifest.path, 'src/renamed.rs'));
    final pathChanged = CrateHash.compute(manifest.path);
    expect(pathChanged, isNot(contentChanged));
  });

  test('declared files and directories are hashed recursively', () {
    _write(workspace, 'producer.txt', 'producer-v1');
    _write(workspace, 'tool/nested/build.sh', 'build-v1');
    _writeConfig(
      manifest,
      hashInputs: const ['producer.txt', 'tool'],
    );
    final original = CrateHash.compute(manifest.path);

    _write(workspace, 'producer.txt', 'producer-v2');
    final fileChanged = CrateHash.compute(manifest.path);
    expect(fileChanged, isNot(original));

    _write(workspace, 'tool/nested/build.sh', 'build-v2');
    final nestedFileChanged = CrateHash.compute(manifest.path);
    expect(nestedFileChanged, isNot(fileChanged));

    File(path.join(workspace.path, 'tool/nested/build.sh')).renameSync(
      path.join(workspace.path, 'tool/nested/assemble.sh'),
    );
    final nestedPathChanged = CrateHash.compute(manifest.path);
    expect(nestedPathChanged, isNot(nestedFileChanged));
  });

  test('adding empty nested declared directories affects the hash', () {
    Directory(path.join(workspace.path, 'tool')).createSync();
    _writeConfig(manifest, hashInputs: const ['tool']);
    final original = CrateHash.compute(manifest.path);

    Directory(path.join(workspace.path, 'tool/nested/empty'))
        .createSync(recursive: true);

    expect(CrateHash.compute(manifest.path), isNot(original));
  });

  test('removing empty nested declared directories affects the hash', () {
    final nested = Directory(path.join(workspace.path, 'tool/nested/empty'))
      ..createSync(recursive: true);
    _writeConfig(manifest, hashInputs: const ['tool']);
    final original = CrateHash.compute(manifest.path);

    nested.parent.deleteSync(recursive: true);

    expect(CrateHash.compute(manifest.path), isNot(original));
  });

  test('renaming empty nested declared directories affects the hash', () {
    final empty = Directory(path.join(workspace.path, 'tool/nested/empty'))
      ..createSync(recursive: true);
    _writeConfig(manifest, hashInputs: const ['tool']);
    final original = CrateHash.compute(manifest.path);

    empty.renameSync(path.join(workspace.path, 'tool/nested/renamed'));

    expect(CrateHash.compute(manifest.path), isNot(original));
  });

  test('undeclared workspace files do not affect the hash', () {
    _write(workspace, 'producer.txt', 'producer');
    _writeConfig(manifest, hashInputs: const ['producer.txt']);
    final original = CrateHash.compute(manifest.path);

    _write(workspace, 'unrelated.txt', 'first');
    expect(CrateHash.compute(manifest.path), original);

    _write(workspace, 'unrelated.txt', 'second');
    expect(CrateHash.compute(manifest.path), original);
  });

  test('pinned build recipe changes affect the hash', () {
    _writeConfig(manifest, rustToolchain: '1.88.0');
    final original = CrateHash.compute(manifest.path);

    _writeConfig(manifest, rustToolchain: '1.89.0');
    expect(CrateHash.compute(manifest.path), isNot(original));
  });

  test('persistent cache entries cannot override the content hash', () {
    final cache = Directory(path.join(temporaryDirectory.path, 'cache'));
    final source = File(path.join(manifest.path, 'src/lib.rs'));
    final modified = source.lastModifiedSync();
    final original = CrateHash.compute(manifest.path, tempStorage: cache.path);

    source.writeAsStringSync('pub fn answer() -> i32 { 43 }\n');
    source.setLastModifiedSync(modified);
    final expected = CrateHash.compute(manifest.path);

    // Seed the cache for the exact post-change path, size, mtime, and ctime.
    expect(
      CrateHash.compute(manifest.path, tempStorage: cache.path),
      expected,
    );
    final cacheFiles = Directory(path.join(cache.path, 'crate_hash'))
        .listSync()
        .whereType<File>();
    for (final cacheFile in cacheFiles) {
      cacheFile.writeAsStringSync(original);
    }

    expect(
      CrateHash.compute(manifest.path, tempStorage: cache.path),
      expected,
    );
  });

  test('missing declared inputs fail closed', () {
    _writeConfig(manifest, hashInputs: const ['missing.txt']);

    expect(
      () => CrateHash.compute(manifest.path),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('declared symlinks fail closed', () {
    _write(workspace, 'producer.txt', 'producer');
    Link(path.join(workspace.path, 'producer-link'))
        .createSync(path.join(workspace.path, 'producer.txt'));
    _writeConfig(manifest, hashInputs: const ['producer-link']);

    expect(
      () => CrateHash.compute(manifest.path),
      throwsA(isA<FileSystemException>()),
    );
  },
      skip: Platform.isWindows
          ? 'Creating symlinks requires privileges.'
          : false);

  test('workspace root must contain the crate manifest', () {
    _writeConfig(manifest, workspaceRoot: '../other');

    expect(
      () => CrateHash.compute(manifest.path),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('intermediate workspace root symlinks fail closed', () {
    final realWorkspace =
        Directory(path.join(temporaryDirectory.path, 'real/workspace'))
          ..createSync(recursive: true);
    final realManifest = Directory(path.join(realWorkspace.path, 'crate'))
      ..createSync();
    _write(realManifest, 'Cargo.toml', '[package]\nname = "linked_crate"\n');
    _write(realManifest, 'src/lib.rs', 'pub fn linked() {}\n');
    Link(path.join(temporaryDirectory.path, 'workspace-link'))
        .createSync(path.join(temporaryDirectory.path, 'real'));
    _writeConfig(
      realManifest,
      workspaceRoot: '../../../workspace-link/workspace',
    );

    expect(
      () => CrateHash.compute(realManifest.path),
      throwsA(isA<FileSystemException>()),
    );
  },
      skip: Platform.isWindows
          ? 'Creating symlinks requires privileges.'
          : false);

  test('intermediate manifest symlinks fail closed', () {
    final realWorkspace =
        Directory(path.join(temporaryDirectory.path, 'real/workspace'))
          ..createSync(recursive: true);
    final realManifest = Directory(path.join(realWorkspace.path, 'crate'))
      ..createSync();
    _write(realManifest, 'Cargo.toml', '[package]\nname = "linked_crate"\n');
    _write(realManifest, 'src/lib.rs', 'pub fn linked() {}\n');
    _writeConfig(realManifest, workspaceRoot: '../..');
    Link(path.join(temporaryDirectory.path, 'workspace-link'))
        .createSync(realWorkspace.path);
    final linkedManifest =
        Directory(path.join(temporaryDirectory.path, 'workspace-link/crate'));

    expect(
      () => CrateHash.compute(linkedManifest.path),
      throwsA(isA<FileSystemException>()),
    );
  },
      skip: Platform.isWindows
          ? 'Creating symlinks requires privileges.'
          : false);
}

void _write(Directory root, String relativePath, String contents) {
  final file = File(path.join(root.path, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

void _writeConfig(
  Directory manifest, {
  String workspaceRoot = '..',
  List<String> hashInputs = const [],
  String? rustToolchain,
}) {
  final recipe = rustToolchain == null
      ? ''
      : '''
build_recipe:
  rust_toolchain: '$rustToolchain'
  flutter_version: '3.32.8'
  xcode_version: '16.4'
  sdk_versions:
    iphoneos: '18.5'
  deployment_targets:
    ios: '12.0'
  rust_targets:
    - aarch64-apple-ios
''';
  final inputs = hashInputs.isEmpty
      ? ''
      : 'hash_inputs:\n${hashInputs.map((input) => '  - $input').join('\n')}\n';
  _write(manifest, 'cargokit.yaml', '''
precompiled_binaries:
  url_prefix: https://example.com/precompiled_
  public_key: $_publicKey
  workspace_root: $workspaceRoot
${_indent(inputs, 2)}${_indent(recipe, 2)}''');
}

String _indent(String value, int spaces) {
  if (value.isEmpty) {
    return value;
  }
  final prefix = ' ' * spaces;
  return value
      .split('\n')
      .map((line) => line.isEmpty ? line : '$prefix$line')
      .join('\n');
}
