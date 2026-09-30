/// This is copied from Cargokit (which is the official way to use it currently)
/// Details: https://fzyzcjy.github.io/flutter_rust_bridge/manual/integrate/builtin

import 'dart:io';

import 'package:path/path.dart' as path;

import 'artifacts_provider.dart';
import 'cargo.dart';
import 'crate_hash.dart';
import 'options.dart';
import 'precompile_binaries.dart';
import 'precompiled_asset_store.dart';
import 'precompiled_generation.dart';
import 'target.dart';

Set<String> expectedGenerationAssetNames({
  required PrecompiledBuildRecipe recipe,
  required PrecompiledBinaries precompiled,
  required String libraryName,
}) {
  final result = <String>{};
  for (final triple in recipe.rustTargets) {
    final target = Target.forRustTriple(triple);
    if (target == null) {
      throw PrecompiledGenerationException(
          'Build recipe contains an unsupported Rust target.');
    }
    for (final type in AritifactType.values) {
      for (final artifact in getArtifactNames(
        target: target,
        libraryName: libraryName,
        remote: true,
        aritifactType: type,
      )) {
        result.add(PrecompileBinaries.fileName(target, artifact));
      }
    }
  }
  for (final group in precompiled.compositeGroups) {
    for (final checksum
        in group.outputs.where((output) => output.endsWith('.checksum'))) {
      final archive = checksum.substring(0, checksum.length - '.checksum'.length);
      if (group.outputs.contains(archive)) {
        result.add(archive);
        result.add(checksum);
      }
    }
  }
  return result;
}

Set<String> expectedCompositeChecksumPairs(PrecompiledBinaries precompiled) {
  final result = <String>{};
  for (final group in precompiled.compositeGroups) {
    for (final checksum
        in group.outputs.where((output) => output.endsWith('.checksum'))) {
      final archive = checksum.substring(0, checksum.length - '.checksum'.length);
      if (group.outputs.contains(archive)) {
        result.add('$archive\u0000$checksum');
      }
    }
  }
  return result;
}

class VerifyBinaries {
  VerifyBinaries({
    required this.manifestDir,
  });

  final String manifestDir;

  Future<void> run() async {
    final config = CargokitCrateOptions.load(manifestDir: manifestDir);
    final precompiledBinaries = config.precompiledBinaries;
    if (precompiledBinaries == null) {
      stdout.writeln('Crate does not support precompiled binaries.');
      return;
    }
    final recipe = precompiledBinaries.buildRecipe;
    if (recipe == null) {
      throw PrecompiledGenerationException(
          'Configured precompiled binaries need a complete build recipe.');
    }
    final crateInfo = CrateInfo.load(manifestDir);
    final expectedNames = expectedGenerationAssetNames(
      recipe: recipe,
      precompiled: precompiledBinaries,
      libraryName: crateInfo.packageName,
    );
    final compositeChecksums =
        expectedCompositeChecksumPairs(precompiledBinaries);
    final generationHash = CrateHash.compute(manifestDir);
    final cacheRoot = Directory.systemTemp.createTempSync('cargokit-verify-');
    final transport = PrecompiledAssetTransport();
    try {
      final store = PrecompiledAssetStore(
        cacheRoot: path.join(cacheRoot.path, 'cache'),
        uriPrefix: Uri.parse(precompiledBinaries.uriPrefix),
        publicKey: precompiledBinaries.publicKey,
        recipe: recipe,
        expectedAssetNames: expectedNames,
        expectedCompositeChecksums: compositeChecksums,
        transport: transport,
      );
      final snapshot = await store.snapshot(
        generationHash: generationHash,
        requestedAssetNames: expectedNames,
      );
      if (snapshot == null) {
        throw PrecompiledGenerationException(
            'Completed v2 precompiled generation is unavailable.');
      }
      stdout.writeln('Verified generation $generationHash');
    } finally {
      transport.close();
      if (cacheRoot.existsSync()) cacheRoot.deleteSync(recursive: true);
    }
  }
}
