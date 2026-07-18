/// This is copied from Cargokit (which is the official way to use it currently)
/// Details: https://fzyzcjy.github.io/flutter_rust_bridge/manual/integrate/builtin

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import 'options.dart';

class _HashInput {
  const _HashInput({
    required this.relativePath,
    required this.file,
  });

  final String relativePath;
  final File file;
}

class CrateHash {
  /// Computes a hash uniquely identifying crate content. This takes into account
  /// content all all .rs files inside the src directory, as well as Cargo.toml,
  /// Cargo.lock, build.rs and cargokit.yaml.
  ///
  /// If [tempStorage] is provided, computed hash is stored in a file in that directory
  /// and reused on subsequent calls if the crate content hasn't changed.
  static String compute(String manifestDir, {String? tempStorage}) {
    return CrateHash._(
      manifestDir: manifestDir,
      tempStorage: tempStorage,
    )._compute();
  }

  CrateHash._({
    required this.manifestDir,
    required this.tempStorage,
  });

  String _compute() {
    final inputs = _getInputs();
    final tempStorage = this.tempStorage;
    if (tempStorage != null) {
      final quickHash = _computeQuickHash(inputs);
      final quickHashFolder = Directory(path.join(tempStorage, 'crate_hash'));
      quickHashFolder.createSync(recursive: true);
      final quickHashFile = File(path.join(quickHashFolder.path, quickHash));
      if (quickHashFile.existsSync()) {
        return quickHashFile.readAsStringSync();
      }
      final hash = _computeHash(inputs);
      quickHashFile.writeAsStringSync(hash);
      return hash;
    } else {
      return _computeHash(inputs);
    }
  }

  /// Computes a quick hash based on files stat (without reading contents). This
  /// is used to cache the real hash, which is slower to compute since it involves
  /// reading every single file.
  String _computeQuickHash(List<_HashInput> inputs) {
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);

    final data = ByteData(8);
    for (final hashInput in inputs) {
      _addFramedBytes(input, utf8.encode(hashInput.relativePath), data);
      final stat = hashInput.file.statSync();
      _addUint64(input, data, stat.size);
      _addUint64(input, data, stat.modified.microsecondsSinceEpoch);
      _addUint64(input, data, stat.changed.microsecondsSinceEpoch);
    }

    input.close();
    return base64Url.encode(output.events.single.bytes);
  }

  String _computeHash(List<_HashInput> inputs) {
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);
    final data = ByteData(8);

    for (final hashInput in inputs) {
      _addFramedBytes(input, utf8.encode(hashInput.relativePath), data);
      _addFramedBytes(input, hashInput.file.readAsBytesSync(), data);
    }

    input.close();
    final res = output.events.single;

    // Truncate to 128bits.
    final hash = res.bytes.sublist(0, 16);
    return hex.encode(hash);
  }

  static void _addUint64(
    ByteConversionSink input,
    ByteData data,
    int value,
  ) {
    data.setUint64(0, value);
    input.add(data.buffer.asUint8List());
  }

  static void _addFramedBytes(
    ByteConversionSink input,
    List<int> bytes,
    ByteData data,
  ) {
    _addUint64(input, data, bytes.length);
    input.add(bytes);
  }

  List<_HashInput> _getInputs() {
    final precompiled =
        CargokitCrateOptions.load(manifestDir: manifestDir).precompiledBinaries;
    final configuredWorkspaceRoot = path.normalize(path.absolute(path.join(
      manifestDir,
      precompiled?.workspaceRoot ?? '.',
    )));
    _rejectLink(configuredWorkspaceRoot, 'Workspace root');

    final workspaceRoot =
        Directory(configuredWorkspaceRoot).resolveSymbolicLinksSync();
    final resolvedManifest =
        Directory(path.absolute(manifestDir)).resolveSymbolicLinksSync();
    if (workspaceRoot != resolvedManifest &&
        !path.isWithin(workspaceRoot, resolvedManifest)) {
      throw FileSystemException(
        'Workspace root must contain the crate manifest.',
        configuredWorkspaceRoot,
      );
    }

    final inputs = <String, _HashInput>{};

    void addFile(File file) {
      final absolute = path.normalize(path.absolute(file.path));
      if (absolute != workspaceRoot &&
          !path.isWithin(workspaceRoot, absolute)) {
        throw FileSystemException(
          'Hash input escapes the workspace root.',
          absolute,
        );
      }
      final relative = _normalizedRelativePath(absolute, workspaceRoot);
      inputs[relative] = _HashInput(relativePath: relative, file: file);
    }

    void addEntity(FileSystemEntity entity) {
      final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
      if (type == FileSystemEntityType.link) {
        throw FileSystemException(
          'Symbolic links are not allowed in generation hash inputs.',
          entity.path,
        );
      }
      if (type == FileSystemEntityType.file) {
        addFile(File(entity.path));
        return;
      }
      if (type == FileSystemEntityType.directory) {
        final children = Directory(entity.path).listSync(followLinks: false)
          ..sort((left, right) => left.path.compareTo(right.path));
        for (final child in children) {
          addEntity(child);
        }
        return;
      }
      if (type == FileSystemEntityType.notFound) {
        throw FileSystemException(
            'Generation hash input does not exist.', entity.path);
      }
      throw FileSystemException(
        'Unsupported generation hash input type.',
        entity.path,
      );
    }

    final src = Directory(path.join(resolvedManifest, 'src'));
    addEntity(src);

    void addOptionalManifestFile(String relative) {
      final filePath = path.join(resolvedManifest, relative);
      final type = FileSystemEntity.typeSync(filePath, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        return;
      }
      addEntity(File(filePath));
    }

    addOptionalManifestFile('Cargo.toml');
    addOptionalManifestFile('Cargo.lock');
    addOptionalManifestFile('build.rs');
    addOptionalManifestFile('cargokit.yaml');

    for (final declaredInput in precompiled?.hashInputs ?? const <String>[]) {
      final absolute = path.normalize(path.joinAll([
        workspaceRoot,
        ...path.posix.split(declaredInput),
      ]));
      if (absolute != workspaceRoot &&
          !path.isWithin(workspaceRoot, absolute)) {
        throw FileSystemException(
          'Declared hash input escapes the workspace root.',
          declaredInput,
        );
      }
      _rejectSymlinkComponents(workspaceRoot, absolute);
      addEntity(FileSystemEntity.isDirectorySync(absolute)
          ? Directory(absolute)
          : File(absolute));
    }

    final result = inputs.values.toList()
      ..sort((left, right) => left.relativePath.compareTo(right.relativePath));
    return result;
  }

  static String _normalizedRelativePath(String absolute, String root) {
    final relative = path.relative(absolute, from: root);
    return path.posix.joinAll(path.split(relative));
  }

  static void _rejectSymlinkComponents(String root, String target) {
    var current = root;
    for (final component in path.split(path.relative(target, from: root))) {
      current = path.join(current, component);
      _rejectLink(current, 'Generation hash input');
    }
  }

  static void _rejectLink(String entityPath, String description) {
    if (FileSystemEntity.typeSync(entityPath, followLinks: false) ==
        FileSystemEntityType.link) {
      throw FileSystemException(
        '$description must not contain symbolic links.',
        entityPath,
      );
    }
  }

  List<File> getFiles() {
    return _getInputs().map((input) => input.file).toList(growable: false);
  }

  final String manifestDir;
  final String? tempStorage;
}
