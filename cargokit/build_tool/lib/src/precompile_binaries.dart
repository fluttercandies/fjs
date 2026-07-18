/// This is copied from Cargokit (which is the official way to use it currently)
/// Details: https://fzyzcjy.github.io/flutter_rust_bridge/manual/integrate/builtin

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:github/github.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'artifacts_provider.dart';
import 'builder.dart';
import 'cargo.dart';
import 'composite_artifacts.dart';
import 'crate_hash.dart';
import 'options.dart';
import 'rustup.dart';
import 'target.dart';

final _log = Logger('precompile_binaries');

const localPrecompiledGenerationFragmentFileName = 'local-generation.json';

typedef LocalPrecompiledTargetBuilder = Future<String> Function(
  Target target,
  BuildEnvironment environment,
  String toolchain,
);

class LocalPrecompiledGeneration {
  LocalPrecompiledGeneration({
    required this.manifestDir,
    required this.outputDir,
    required this.tempDir,
    required this.targetTriples,
    LocalPrecompiledTargetBuilder? targetBuilder,
    this.currentHost,
    this.compositeProcessRunner,
  }) : targetBuilder = targetBuilder ?? _buildTarget;

  final String manifestDir;
  final String outputDir;
  final String tempDir;
  final List<String> targetTriples;
  final LocalPrecompiledTargetBuilder targetBuilder;
  final CompositeHost? currentHost;
  final CompositeProcessRunner? compositeProcessRunner;

  Future<File> run() async {
    final manifest = path.normalize(path.absolute(manifestDir));
    if (FileSystemEntity.typeSync(manifest, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw ArgumentError('Manifest directory does not exist: $manifestDir');
    }
    final crateOptions = CargokitCrateOptions.load(manifestDir: manifest);
    final precompiled = crateOptions.precompiledBinaries;
    final recipe = precompiled?.buildRecipe;
    if (precompiled == null || recipe == null) {
      throw ArgumentError(
        'A complete precompiled binaries config and build recipe are required.',
      );
    }
    if (targetTriples.isEmpty) {
      throw ArgumentError('At least one --target is required.');
    }

    final requested = <Target>[];
    final seen = <String>{};
    final pinned = recipe.rustTargets.toSet();
    for (final triple in targetTriples) {
      if (!seen.add(triple)) {
        throw ArgumentError('Duplicate target: $triple');
      }
      final target = Target.forRustTriple(triple);
      if (target == null) throw ArgumentError('Unknown target: $triple');
      if (!pinned.contains(triple)) {
        throw ArgumentError('Target is not in the build recipe: $triple');
      }
      requested.add(target);
    }
    for (final group in precompiled.compositeGroups) {
      final overlap = group.requiredTargets.any(seen.contains);
      if (overlap && !group.requiredTargets.every(seen.contains)) {
        throw ArgumentError(
          'Requested targets are incomplete for composite group ${group.name}.',
        );
      }
    }

    final generationHash = CrateHash.compute(manifest);
    final workspaceRoot = path.normalize(path.absolute(path.join(
      manifest,
      precompiled.workspaceRoot,
    )));
    final finalOutput = path.normalize(path.absolute(outputDir));
    final finalParent = Directory(path.dirname(finalOutput))
      ..createSync(recursive: true);
    final staging = Directory(path.join(
      finalParent.path,
      '.${path.basename(finalOutput)}.$pid.${DateTime.now().microsecondsSinceEpoch}',
    ))
      ..createSync();
    final targetOutputRoot = Directory(path.join(staging.path, 'targets'))
      ..createSync();
    final buildTemp = Directory(path.normalize(path.absolute(tempDir)))
      ..createSync(recursive: true);
    final assets = <Map<String, Object>>[];

    try {
      final environment = BuildEnvironment(
        configuration: BuildConfiguration.release,
        crateOptions: crateOptions,
        targetTempDir: buildTemp.path,
        manifestDir: manifest,
        crateInfo: CrateInfo.load(manifest),
        isAndroid: false,
        iosDeploymentTarget: recipe.deploymentTargets['ios'],
        macosDeploymentTarget: recipe.deploymentTargets['macos'],
      );
      for (final target in requested) {
        final buildOutput = path.normalize(path.absolute(
          await targetBuilder(target, environment, recipe.rustToolchain),
        ));
        final retained =
            Directory(path.join(targetOutputRoot.path, target.rust))
              ..createSync();
        for (final artifactType in AritifactType.values) {
          for (final localName in getArtifactNames(
            target: target,
            libraryName: environment.crateInfo.packageName,
            remote: true,
            aritifactType: artifactType,
          )) {
            final source = path.join(buildOutput, localName);
            _requireBuildFile(buildOutput, source);
            final remoteName = PrecompileBinaries.fileName(target, localName);
            final destination = path.join(retained.path, remoteName);
            File(source).copySync(destination);
            assets.add(_assetJson(
              name: remoteName,
              relativePath: path.posix.join('targets', target.rust, remoteName),
              file: File(destination),
            ));
          }
        }
      }

      final selected = seen.toSet();
      final compositeBuilder = CompositeArtifactBuilder(
        workspaceRoot: workspaceRoot,
        generationHash: generationHash,
        targetOutputRoot: targetOutputRoot.path,
        outputRoot: staging.path,
        currentHost: currentHost,
        processRunner: compositeProcessRunner,
      );
      for (final group in precompiled.compositeGroups) {
        if (!compositeBuilder.supports(group, selected)) continue;
        final result = await compositeBuilder.build(group);
        for (final output in group.outputs) {
          assets.add(_assetJson(
            name: output,
            relativePath: path.posix.join('composites', group.name, output),
            file: File(result.outputs[output]!),
          ));
        }
      }

      assets.sort((left, right) =>
          (left['name'] as String).compareTo(right['name'] as String));
      final fragment = <String, Object>{
        'schema_version': 1,
        'scope': 'cargokit-local-precompiled-generation',
        'generation_hash': generationHash,
        'recipe': _recipeJson(recipe),
        'assets': assets,
      };
      File(path.join(staging.path, localPrecompiledGenerationFragmentFileName))
          .writeAsStringSync('${jsonEncode(fragment)}\n', flush: true);
      _publishDirectory(staging, finalOutput);
      return File(
        path.join(finalOutput, localPrecompiledGenerationFragmentFileName),
      );
    } finally {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
    }
  }

  static Future<String> _buildTarget(
    Target target,
    BuildEnvironment environment,
    String toolchain,
  ) async {
    final rustup = Rustup();
    final builder = RustBuilder(
      target: target,
      environment: environment,
      toolchain: toolchain,
    );
    builder.prepare(rustup);
    return builder.build();
  }
}

Map<String, Object> _assetJson({
  required String name,
  required String relativePath,
  required File file,
}) {
  final bytes = file.readAsBytesSync();
  return {
    'name': name,
    'length': bytes.length,
    'sha256': sha256.convert(bytes).toString(),
    'path': relativePath,
  };
}

Map<String, Object> _recipeJson(PrecompiledBuildRecipe recipe) => {
      'rust_toolchain': recipe.rustToolchain,
      'flutter_version': recipe.flutterVersion,
      'xcode_version': recipe.xcodeVersion,
      'sdk_versions': Map.fromEntries(
        recipe.sdkVersions.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      ),
      'deployment_targets': Map.fromEntries(
        recipe.deploymentTargets.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      ),
      'rust_targets': [...recipe.rustTargets]..sort(),
    };

void _requireBuildFile(String root, String filePath) {
  final normalizedRoot = path.normalize(path.absolute(root));
  final normalizedFile = path.normalize(path.absolute(filePath));
  if (!path.isWithin(normalizedRoot, normalizedFile) ||
      FileSystemEntity.typeSync(normalizedFile, followLinks: false) !=
          FileSystemEntityType.file) {
    throw FileSystemException(
        'Missing or invalid Rust build artifact.', filePath);
  }
}

void _publishDirectory(Directory staging, String finalPath) {
  final existingType = FileSystemEntity.typeSync(finalPath, followLinks: false);
  if (existingType != FileSystemEntityType.notFound &&
      existingType != FileSystemEntityType.directory) {
    throw FileSystemException(
        'Generation output must be a directory.', finalPath);
  }
  final backup = '$finalPath.previous.$pid';
  if (Directory(backup).existsSync()) {
    Directory(backup).deleteSync(recursive: true);
  }
  if (existingType == FileSystemEntityType.directory) {
    Directory(finalPath).renameSync(backup);
  }
  try {
    staging.renameSync(finalPath);
    if (Directory(backup).existsSync()) {
      Directory(backup).deleteSync(recursive: true);
    }
  } on Object {
    if (!Directory(finalPath).existsSync() && Directory(backup).existsSync()) {
      Directory(backup).renameSync(finalPath);
    }
    rethrow;
  }
}

class PrecompileBinaries {
  PrecompileBinaries({
    required this.privateKey,
    required this.githubToken,
    required this.repositorySlug,
    required this.manifestDir,
    required this.targets,
    this.androidSdkLocation,
    this.androidNdkVersion,
    this.androidMinSdkVersion,
    this.tempDir,
  });

  final PrivateKey privateKey;
  final String githubToken;
  final RepositorySlug repositorySlug;
  final String manifestDir;
  final List<Target> targets;
  final String? androidSdkLocation;
  final String? androidNdkVersion;
  final int? androidMinSdkVersion;
  final String? tempDir;

  static String fileName(Target target, String name) {
    return '${target.rust}_$name';
  }

  static String signatureFileName(Target target, String name) {
    return '${target.rust}_$name.sig';
  }

  Future<void> run() async {
    final crateInfo = CrateInfo.load(manifestDir);

    final targets = List.of(this.targets);
    if (targets.isEmpty) {
      targets.addAll([
        ...Target.buildableTargets(),
        if (androidSdkLocation != null) ...Target.androidTargets(),
      ]);
    }

    _log.info('Precompiling binaries for $targets');

    final hash = CrateHash.compute(manifestDir);
    _log.info('Computed crate hash: $hash');

    final String tagName = 'precompiled_$hash';

    final github = GitHub(auth: Authentication.withToken(githubToken));
    final repo = github.repositories;
    final release = await _getOrCreateRelease(
      repo: repo,
      tagName: tagName,
      packageName: crateInfo.packageName,
      hash: hash,
    );

    final tempDir = this.tempDir != null
        ? Directory(this.tempDir!)
        : Directory.systemTemp.createTempSync('precompiled_');

    tempDir.createSync(recursive: true);

    final crateOptions = CargokitCrateOptions.load(
      manifestDir: manifestDir,
    );

    final buildEnvironment = BuildEnvironment(
      configuration: BuildConfiguration.release,
      crateOptions: crateOptions,
      targetTempDir: tempDir.path,
      manifestDir: manifestDir,
      crateInfo: crateInfo,
      isAndroid: androidSdkLocation != null,
      androidSdkPath: androidSdkLocation,
      androidNdkVersion: androidNdkVersion,
      androidMinSdkVersion: androidMinSdkVersion,
    );

    final rustup = Rustup();

    for (final target in targets) {
      final artifactNames = getArtifactNames(
        target: target,
        libraryName: crateInfo.packageName,
        remote: true,
      );

      if (artifactNames.every((name) {
        final fileName = PrecompileBinaries.fileName(target, name);
        return (release.assets ?? []).any((e) => e.name == fileName);
      })) {
        _log.info("All artifacts for $target already exist - skipping");
        continue;
      }

      _log.info('Building for $target');

      final builder =
          RustBuilder(target: target, environment: buildEnvironment);
      builder.prepare(rustup);
      final res = await builder.build();

      final assets = <CreateReleaseAsset>[];
      for (final name in artifactNames) {
        final file = File(path.join(res, name));
        if (!file.existsSync()) {
          throw Exception('Missing artifact: ${file.path}');
        }

        final data = file.readAsBytesSync();
        final create = CreateReleaseAsset(
          name: PrecompileBinaries.fileName(target, name),
          contentType: "application/octet-stream",
          assetData: data,
        );
        final signature = sign(privateKey, data);
        final signatureCreate = CreateReleaseAsset(
          name: signatureFileName(target, name),
          contentType: "application/octet-stream",
          assetData: signature,
        );
        bool verified = verify(public(privateKey), data, signature);
        if (!verified) {
          throw Exception('Signature verification failed');
        }
        assets.add(create);
        assets.add(signatureCreate);
      }
      _log.info('Uploading assets: ${assets.map((e) => e.name)}');
      for (final asset in assets) {
        // This seems to be failing on CI so do it one by one
        int retryCount = 0;
        while (true) {
          try {
            await repo.uploadReleaseAssets(release, [asset]);
            break;
          } on Exception catch (e) {
            if (retryCount == 10) {
              rethrow;
            }
            ++retryCount;
            _log.shout(
                'Upload failed (attempt $retryCount, will retry): ${e.toString()}');
            await Future.delayed(Duration(seconds: 2));
          }
        }
      }
    }

    _log.info('Cleaning up');
    tempDir.deleteSync(recursive: true);
  }

  Future<Release> _getOrCreateRelease({
    required RepositoriesService repo,
    required String tagName,
    required String packageName,
    required String hash,
  }) async {
    Release release;
    try {
      _log.info('Fetching release $tagName');
      release = await repo.getReleaseByTagName(repositorySlug, tagName);
    } on ReleaseNotFound {
      _log.info('Release not found - creating release $tagName');
      release = await repo.createRelease(
          repositorySlug,
          CreateRelease.from(
            tagName: tagName,
            name: 'Precompiled binaries ${hash.substring(0, 8)}',
            targetCommitish: null,
            isDraft: false,
            isPrerelease: false,
            body: 'Precompiled binaries for crate $packageName, '
                'crate hash $hash.',
          ));
    }
    return release;
  }
}
