/// This is copied from Cargokit (which is the official way to use it currently)
/// Details: https://fzyzcjy.github.io/flutter_rust_bridge/manual/integrate/builtin

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'builder.dart';
import 'crate_hash.dart';
import 'options.dart';
import 'precompile_binaries.dart';
import 'precompiled_generation.dart';
import 'rustup.dart';
import 'target.dart';

class Artifact {
  /// File system location of the artifact.
  final String path;

  /// Actual file name that the artifact should have in destination folder.
  final String finalFileName;

  AritifactType get type {
    if (finalFileName.endsWith('.dll') ||
        finalFileName.endsWith('.dll.lib') ||
        finalFileName.endsWith('.pdb') ||
        finalFileName.endsWith('.so') ||
        finalFileName.endsWith('.dylib')) {
      return AritifactType.dylib;
    } else if (finalFileName.endsWith('.lib') || finalFileName.endsWith('.a')) {
      return AritifactType.staticlib;
    } else {
      throw Exception('Unknown artifact type for $finalFileName');
    }
  }

  Artifact({
    required this.path,
    required this.finalFileName,
  });
}

typedef ArtifactHttpGet = Future<Response> Function(Uri url);
typedef ArtifactGenerationHash = String Function(BuildEnvironment environment);
typedef ArtifactLocalBuilder = Future<List<Artifact>> Function(
    Target target, BuildEnvironment environment);

final _log = Logger('artifacts_provider');

class ArtifactProvider {
  ArtifactProvider({
    required this.environment,
    required this.userOptions,
    ArtifactHttpGet? httpGet,
    ArtifactGenerationHash? generationHash,
    ArtifactLocalBuilder? localBuilder,
  })  : httpGet = httpGet ?? _defaultHttpGet,
        generationHash = generationHash ??
            ((environment) => CrateHash.compute(
                  environment.manifestDir,
                  tempStorage: environment.targetTempDir,
                )),
        localBuilder = localBuilder ?? _defaultLocalBuilder;

  final BuildEnvironment environment;
  final CargokitUserOptions userOptions;
  final ArtifactHttpGet httpGet;
  final ArtifactGenerationHash generationHash;
  final ArtifactLocalBuilder localBuilder;

  Future<Map<Target, List<Artifact>>> getArtifacts(List<Target> targets) async {
    final result = await _getPrecompiledArtifacts(targets);
    final pendingTargets = List.of(targets)
      ..removeWhere((target) => result.containsKey(target));

    if (pendingTargets.isEmpty) return result;
    if (!userOptions.allowLocalBuild) {
      throw PrecompiledGenerationException(
          'Required precompiled generation did not provide all requested targets.');
    }
    for (final target in pendingTargets) {
      _log.info('Building ${environment.crateInfo.packageName} for $target');
      result[target] = await localBuilder(target, environment);
    }
    return result;
  }

  Future<Map<Target, List<Artifact>>> _getPrecompiledArtifacts(
      List<Target> targets) async {
    if (userOptions.precompiledBinariesMode ==
        PrecompiledBinariesMode.disabled) {
      _log.info('Precompiled binaries are disabled');
      return {};
    }
    final precompiled = environment.crateOptions.precompiledBinaries;
    if (precompiled == null) {
      return {};
    }
    final recipe = precompiled.buildRecipe;
    if (recipe == null) {
      throw PrecompiledGenerationException(
          'Configured precompiled binaries need a complete build recipe.');
    }

    final crateHash = generationHash(environment);
    final generationDir = path.join(
      environment.targetTempDir,
      'precompiled',
      crateHash,
    );
    final expectedAssets = _expectedAssetNames(recipe, precompiled);
    final expectedComposites = _expectedCompositeChecksums(precompiled);
    final manifestResult = await _fetchManifest(
      precompiled: precompiled,
      generationHash: crateHash,
      expectedAssets: expectedAssets,
      expectedComposites: expectedComposites,
    );
    if (manifestResult == null) {
      final cacheStateExists = FileSystemEntity.typeSync(
            generationDir,
            followLinks: false,
          ) !=
          FileSystemEntityType.notFound;
      if (userOptions.precompiledBinariesMode == PrecompiledBinariesMode.auto) {
        if (!cacheStateExists) {
          return {};
        }
        throw PrecompiledGenerationException(
            'Precompiled generation manifest is unavailable for existing cache state.');
      }
      throw PrecompiledGenerationException(
          'Required precompiled generation manifest is unavailable.');
    }
    final manifest = manifestResult.manifest;
    final pinnedTargets = recipe.rustTargets.toSet();
    if (targets.any((target) => !pinnedTargets.contains(target.rust))) {
      throw PrecompiledGenerationException(
          'Requested Rust target is not included in the signed build recipe.');
    }
    final requiredForTargets = <Target, List<String>>{
      for (final target in targets)
        target: getArtifactNames(
          target: target,
          libraryName: environment.crateInfo.packageName,
          remote: true,
        ).map((name) => PrecompileBinaries.fileName(target, name)).toList(),
    };
    final requiredAssets =
        requiredForTargets.values.expand((names) => names).toSet();
    for (final binding in manifest.compositeChecksums) {
      requiredAssets
        ..add(binding.archive)
        ..add(binding.checksum);
    }

    if (_cacheIsValid(
      generationDir: generationDir,
      manifest: manifest,
      manifestBytes: manifestResult.manifestBytes,
      manifestSignature: manifestResult.manifestSignature,
      requiredAssets: requiredAssets,
      publicKey: precompiled.publicKey,
    )) {
      return _artifactsFromCache(generationDir, requiredForTargets);
    }

    final stagingDir = _stagingDirectory(generationDir);
    Directory(stagingDir).createSync(recursive: true);
    try {
      File(path.join(stagingDir, precompiledGenerationManifestFileName))
          .writeAsBytesSync(manifestResult.manifestBytes);
      File(path.join(
              stagingDir, precompiledGenerationManifestSignatureFileName))
          .writeAsBytesSync(manifestResult.manifestSignature);

      final downloadedBytes = <String, List<int>>{};
      for (final assetName in requiredAssets) {
        final assetBytes = await _downloadAsset(
          precompiled: precompiled,
          generationHash: crateHash,
          manifest: manifest,
          assetName: assetName,
        );
        downloadedBytes[assetName] = assetBytes.bytes;
        _writeStaged(stagingDir, assetName, assetBytes.bytes);
        _writeStaged(stagingDir, '$assetName.sig', assetBytes.signature);
      }
      manifest.validateCompositeChecksums(downloadedBytes);
      _installAtomically(stagingDir, generationDir);
      return _artifactsFromCache(generationDir, requiredForTargets);
    } on PrecompiledGenerationException {
      rethrow;
    } catch (error) {
      throw PrecompiledGenerationException(
          'Failed to install precompiled generation: $error');
    } finally {
      final staging = Directory(stagingDir);
      if (staging.existsSync()) staging.deleteSync(recursive: true);
    }
  }

  Set<String> _expectedAssetNames(
      PrecompiledBuildRecipe recipe, PrecompiledBinaries precompiled) {
    final names = <String>{};
    for (final rustTarget in recipe.rustTargets) {
      final target = Target.forRustTriple(rustTarget);
      if (target == null) {
        throw PrecompiledGenerationException(
            'Manifest recipe has an unsupported Rust target.');
      }
      for (final name in getArtifactNames(
        target: target,
        libraryName: environment.crateInfo.packageName,
        remote: true,
      )) {
        names.add(PrecompileBinaries.fileName(target, name));
      }
    }
    for (final group in precompiled.compositeGroups) {
      names.addAll(group.outputs);
    }
    return names;
  }

  Set<String> _expectedCompositeChecksums(PrecompiledBinaries precompiled) {
    final result = <String>{};
    for (final group in precompiled.compositeGroups) {
      for (final output in group.outputs) {
        if (output.endsWith('.checksum')) {
          final archive =
              output.substring(0, output.length - '.checksum'.length);
          if (group.outputs.contains(archive)) {
            result.add('$archive\u0000$output');
          }
        }
      }
    }
    return result;
  }

  Future<_FetchedManifest?> _fetchManifest({
    required PrecompiledBinaries precompiled,
    required String generationHash,
    required Set<String> expectedAssets,
    required Set<String> expectedComposites,
  }) async {
    final prefix = precompiled.uriPrefix;
    final manifestUrl = Uri.parse(
        '$prefix$generationHash/$precompiledGenerationManifestFileName');
    final manifestResponse = await _get(manifestUrl);
    if (manifestResponse.statusCode == 404) return null;
    _expectOk(manifestResponse, manifestUrl, 'manifest');
    _expectContentLength(manifestResponse, manifestUrl);
    final signatureUrl = Uri.parse(
        '$prefix$generationHash/$precompiledGenerationManifestSignatureFileName');
    final signatureResponse = await _get(signatureUrl);
    _expectOk(signatureResponse, signatureUrl, 'manifest signature');
    _expectContentLength(signatureResponse, signatureUrl);
    final manifestBytes = Uint8List.fromList(manifestResponse.bodyBytes);
    final manifestSignature = Uint8List.fromList(signatureResponse.bodyBytes);
    final manifest = PrecompiledGenerationManifest.parse(manifestBytes);
    manifest.verifySignature(precompiled.publicKey, manifestSignature);
    final recipe = precompiled.buildRecipe;
    if (recipe == null) {
      throw PrecompiledGenerationException('Missing build recipe.');
    }
    manifest.validateFor(
      generationHash: generationHash,
      recipe: recipe,
      expectedAssetNames: expectedAssets,
    );
    final actualComposites = manifest.compositeChecksums
        .map((binding) => '${binding.archive}\u0000${binding.checksum}')
        .toSet();
    if (actualComposites.length != expectedComposites.length ||
        !actualComposites.containsAll(expectedComposites)) {
      throw PrecompiledGenerationException(
          'Manifest composite checksum relationships do not match configuration.');
    }
    return _FetchedManifest(
      manifest: manifest,
      manifestBytes: manifestBytes,
      manifestSignature: manifestSignature,
    );
  }

  bool _cacheIsValid({
    required String generationDir,
    required PrecompiledGenerationManifest manifest,
    required List<int> manifestBytes,
    required List<int> manifestSignature,
    required Set<String> requiredAssets,
    required PublicKey publicKey,
  }) {
    try {
      final directory = Directory(generationDir);
      if (!directory.existsSync()) return false;
      final cachedManifestFile = File(path.join(
        generationDir,
        precompiledGenerationManifestFileName,
      ));
      final cachedSignatureFile = File(path.join(
        generationDir,
        precompiledGenerationManifestSignatureFileName,
      ));
      if (!cachedManifestFile.existsSync() ||
          !cachedSignatureFile.existsSync()) {
        return false;
      }
      final cachedManifestBytes = cachedManifestFile.readAsBytesSync();
      final cachedSignature = cachedSignatureFile.readAsBytesSync();
      if (!_sameBytes(cachedManifestBytes, manifestBytes) ||
          !_sameBytes(cachedSignature, manifestSignature)) {
        return false;
      }
      final cachedManifest =
          PrecompiledGenerationManifest.parse(cachedManifestBytes);
      cachedManifest.verifySignature(publicKey, cachedSignature);
      final verifiedBytes = <String, List<int>>{};
      for (final name in requiredAssets) {
        final file = File(path.join(generationDir, name));
        final signatureFile = File(path.join(generationDir, '$name.sig'));
        if (!file.existsSync() || !signatureFile.existsSync()) {
          return false;
        }
        final bytes = file.readAsBytesSync();
        cachedManifest.verifyAsset(
          name: name,
          bytes: bytes,
          signature: signatureFile.readAsBytesSync(),
          publicKey: publicKey,
        );
        verifiedBytes[name] = bytes;
      }
      cachedManifest.validateCompositeChecksums(verifiedBytes);
      return true;
    } on Object {
      return false;
    }
  }

  Map<Target, List<Artifact>> _artifactsFromCache(
      String generationDir, Map<Target, List<String>> requiredForTargets) {
    return {
      for (final entry in requiredForTargets.entries)
        entry.key: [
          for (final remoteName in entry.value)
            Artifact(
              path: path.join(generationDir, remoteName),
              finalFileName: remoteName.substring('${entry.key.rust}_'.length),
            ),
        ],
    };
  }

  Future<_FetchedAsset> _downloadAsset({
    required PrecompiledBinaries precompiled,
    required String generationHash,
    required PrecompiledGenerationManifest manifest,
    required String assetName,
  }) async {
    final prefix = precompiled.uriPrefix;
    final signatureUrl = Uri.parse('$prefix$generationHash/$assetName.sig');
    final signatureResponse = await _get(signatureUrl);
    _expectOk(signatureResponse, signatureUrl, 'asset signature');
    _expectContentLength(signatureResponse, signatureUrl);
    final assetUrl = Uri.parse('$prefix$generationHash/$assetName');
    final assetResponse = await _get(assetUrl);
    _expectOk(assetResponse, assetUrl, 'asset');
    _expectContentLength(assetResponse, assetUrl);
    final bytes = Uint8List.fromList(assetResponse.bodyBytes);
    final signature = Uint8List.fromList(signatureResponse.bodyBytes);
    manifest.verifyAsset(
      name: assetName,
      bytes: bytes,
      signature: signature,
      publicKey: precompiled.publicKey,
    );
    return _FetchedAsset(bytes: bytes, signature: signature);
  }

  Future<Response> _get(Uri url) async {
    int attempt = 0;
    const maxAttempts = 10;
    while (true) {
      try {
        return await httpGet(url);
      } on SocketException catch (error) {
        if (attempt++ < maxAttempts &&
            (error.osError?.errorCode == 54 ||
                error.osError?.errorCode == 10054)) {
          _log.severe(
              'Failed to download $url: $error, attempt $attempt of $maxAttempts, will retry...');
          await Future<void>.delayed(const Duration(seconds: 1));
          continue;
        }
        rethrow;
      }
    }
  }

  static void _expectOk(Response response, Uri url, String description) {
    if (response.statusCode != 200) {
      throw PrecompiledGenerationException(
          'Failed to download $description $url: status ${response.statusCode}.');
    }
  }

  static void _expectContentLength(Response response, Uri url) {
    final value = response.headers['content-length'];
    if (value == null) return;
    final declared = int.tryParse(value);
    if (declared == null ||
        declared < 0 ||
        declared != response.bodyBytes.length) {
      throw PrecompiledGenerationException(
          'HTTP content length for $url does not match the response body.');
    }
  }

  static void _writeStaged(String stagingDir, String name, List<int> bytes) {
    final file = File(path.join(stagingDir, name));
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
  }

  static String _stagingDirectory(String generationDir) =>
      '$generationDir.staging-${DateTime.now().microsecondsSinceEpoch}-${Zone.current.hashCode}';

  static void _installAtomically(String stagingDir, String generationDir) {
    final destination = Directory(generationDir);
    final backupPath =
        '$generationDir.previous-${DateTime.now().microsecondsSinceEpoch}';
    Directory? backup;
    try {
      if (destination.existsSync()) {
        backup = destination.renameSync(backupPath);
      }
      Directory(stagingDir).renameSync(generationDir);
      if (backup != null && backup.existsSync()) {
        backup.deleteSync(recursive: true);
      }
    } catch (_) {
      final installed = Directory(generationDir);
      if (installed.existsSync() && !Directory(stagingDir).existsSync()) {
        installed.renameSync(stagingDir);
      }
      if (backup != null && backup.existsSync() && !destination.existsSync()) {
        backup.renameSync(generationDir);
      }
      rethrow;
    }
  }

  static bool _sameBytes(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }
}

Future<Response> _defaultHttpGet(Uri url) => get(url);

Future<List<Artifact>> _defaultLocalBuilder(
    Target target, BuildEnvironment environment) async {
  final rustup = Rustup();
  final builder = RustBuilder(target: target, environment: environment);
  builder.prepare(rustup);
  final targetDir = await builder.build();
  final artifactNames = <String>{
    ...getArtifactNames(
      target: target,
      libraryName: environment.crateInfo.packageName,
      aritifactType: AritifactType.dylib,
      remote: false,
    ),
    ...getArtifactNames(
      target: target,
      libraryName: environment.crateInfo.packageName,
      aritifactType: AritifactType.staticlib,
      remote: false,
    ),
  };
  return artifactNames
      .map((artifactName) => Artifact(
            path: path.join(targetDir, artifactName),
            finalFileName: artifactName,
          ))
      .where((artifact) => File(artifact.path).existsSync())
      .toList();
}

class _FetchedManifest {
  const _FetchedManifest({
    required this.manifest,
    required this.manifestBytes,
    required this.manifestSignature,
  });

  final PrecompiledGenerationManifest manifest;
  final Uint8List manifestBytes;
  final Uint8List manifestSignature;
}

class _FetchedAsset {
  const _FetchedAsset({required this.bytes, required this.signature});

  final Uint8List bytes;
  final Uint8List signature;
}

enum AritifactType {
  staticlib,
  dylib,
}

AritifactType artifactTypeForTarget(Target target) {
  if (target.darwinPlatform != null) {
    return AritifactType.staticlib;
  } else {
    return AritifactType.dylib;
  }
}

List<String> getArtifactNames({
  required Target target,
  required String libraryName,
  required bool remote,
  AritifactType? aritifactType,
}) {
  aritifactType ??= artifactTypeForTarget(target);
  if (target.darwinArch != null) {
    if (aritifactType == AritifactType.staticlib) {
      return ['lib$libraryName.a'];
    } else {
      return ['lib$libraryName.dylib'];
    }
  } else if (target.rust.contains('-windows-')) {
    if (aritifactType == AritifactType.staticlib) {
      return ['$libraryName.lib'];
    } else {
      return [
        '$libraryName.dll',
        '$libraryName.dll.lib',
        if (!remote) '$libraryName.pdb'
      ];
    }
  } else if (target.rust.contains('-linux-')) {
    if (aritifactType == AritifactType.staticlib) {
      return ['lib$libraryName.a'];
    } else {
      return ['lib$libraryName.so'];
    }
  } else {
    throw Exception("Unsupported target: ${target.rust}");
  }
}
