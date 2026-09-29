import 'dart:io';

import 'package:path/path.dart' as path;

import 'cargo.dart';
import 'crate_hash.dart';
import 'options.dart';
import 'precompiled_asset_store.dart';
import 'precompiled_generation.dart';
import 'verify_binaries.dart';

class FetchPrecompiledArtifacts {
  FetchPrecompiledArtifacts({
    required this.manifestDir,
    required this.outputDir,
    required this.assetNames,
  });

  final String manifestDir;
  final String outputDir;
  final List<String> assetNames;

  Future<void> run() async {
    if (assetNames.isEmpty) {
      throw ArgumentError('At least one --asset is required.');
    }
    final config = CargokitCrateOptions.load(manifestDir: manifestDir);
    final precompiled = config.precompiledBinaries;
    if (precompiled == null) {
      throw PrecompiledGenerationException(
          'Crate does not support precompiled binaries.');
    }
    final recipe = precompiled.buildRecipe;
    if (recipe == null) {
      throw PrecompiledGenerationException(
          'Configured precompiled binaries need a complete build recipe.');
    }
    final compositeOutputs = <String>{};
    for (final group in precompiled.compositeGroups) {
      compositeOutputs.addAll(group.outputs);
    }
    final requested = assetNames.toSet();
    final unknown = requested.difference(compositeOutputs);
    if (unknown.isNotEmpty) {
      throw PrecompiledGenerationException(
          'Requested assets are not composite outputs: ${unknown.toList()..sort()}');
    }

    final crateInfo = CrateInfo.load(manifestDir);
    final generationHash = CrateHash.compute(manifestDir);
    final cacheRoot = Directory.systemTemp.createTempSync('cargokit-fetch-');
    final transport = PrecompiledAssetTransport();
    try {
      final store = PrecompiledAssetStore(
        cacheRoot: path.join(cacheRoot.path, 'cache'),
        uriPrefix: Uri.parse(precompiled.uriPrefix),
        publicKey: precompiled.publicKey,
        recipe: recipe,
        expectedAssetNames: expectedGenerationAssetNames(
          recipe: recipe,
          precompiled: precompiled,
          libraryName: crateInfo.packageName,
        ),
        expectedCompositeChecksums: expectedCompositeChecksumPairs(precompiled),
        transport: transport,
      );
      final snapshot = await store.snapshot(
        generationHash: generationHash,
        requestedAssetNames: requested,
      );
      if (snapshot == null) {
        throw PrecompiledGenerationException(
            'Completed v2 precompiled generation is unavailable.');
      }
      final destinationRoot = Directory(outputDir)..createSync(recursive: true);
      for (final name in requested.toList()..sort()) {
        final destination =
            File(path.join(destinationRoot.path, path.basename(name)));
        final staging = File('${destination.path}.staging.$pid');
        staging.writeAsBytesSync(
          File(snapshot.pathFor(name)).readAsBytesSync(),
          flush: true,
        );
        staging.renameSync(destination.path);
        stdout.writeln('Fetched $name');
      }
      stdout.writeln('Fetched generation $generationHash');
    } finally {
      transport.close();
      if (cacheRoot.existsSync()) cacheRoot.deleteSync(recursive: true);
    }
  }
}
