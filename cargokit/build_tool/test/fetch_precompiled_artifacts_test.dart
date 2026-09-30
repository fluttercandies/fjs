import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:build_tool/src/crate_hash.dart';
import 'package:build_tool/src/fetch_precompiled_artifacts.dart';
import 'package:build_tool/src/options.dart';
import 'package:build_tool/src/precompiled_asset_store.dart';
import 'package:build_tool/src/precompiled_generation.dart';
import 'package:build_tool/src/verify_binaries.dart';
import 'package:crypto/crypto.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed25519;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory temp;
  late _FixtureServer server;
  late ed25519.KeyPair keyPair;
  late Directory crate;
  late String generationHash;
  late Map<String, List<int>> assets;
  late _StoreFixture fixture;

  Future<void> writeCargokitYaml({
    required String urlPrefix,
  }) async {
    final publicKeyHex = keyPair.publicKey.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final precompiled = '''
precompiled_binaries:
  url_prefix: $urlPrefix
  public_key: $publicKeyHex
  workspace_root: .
  hash_inputs:
    - src
  build_recipe:
    rust_toolchain: '1.97.1'
    flutter_version: '3.35.5'
    xcode_version: '16.4'
    sdk_versions:
      macosx: '15.5'
    deployment_targets:
      macos: '10.14'
    rust_targets:
      - aarch64-apple-darwin
      - x86_64-apple-darwin
  composite_groups:
    - name: swiftpm
      host: macos
      required_targets:
        - aarch64-apple-darwin
        - x86_64-apple-darwin
      argv:
        - assemble.sh
      environment:
        LC_ALL: C
      timeout_seconds: 60
      outputs:
        - fjs.xcframework.zip
        - fjs.xcframework.zip.checksum
''';
    File(path.join(crate.path, 'cargokit.yaml')).writeAsStringSync(precompiled);
  }

  setUp(() async {
    final resolvedSystemTemp =
        Directory(Directory.systemTemp.resolveSymbolicLinksSync());
    temp = resolvedSystemTemp.createTempSync('fetch-precompiled-');
    final seed =
        Uint8List.fromList(List<int>.generate(32, (index) => index + 1));
    keyPair = ed25519.KeyPair(
      ed25519.newKeyFromSeed(seed),
      ed25519.public(ed25519.newKeyFromSeed(seed)),
    );

    server = await _FixtureServer.start();
    crate = Directory(path.join(temp.path, 'crate'))..createSync();
    File(path.join(crate.path, 'Cargo.toml')).writeAsStringSync('''
[package]
name = "fjs"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["staticlib"]
''');
    Directory(path.join(crate.path, 'src')).createSync();
    File(path.join(crate.path, 'src', 'lib.rs'))
        .writeAsStringSync('pub fn answer() -> u32 { 42 }\n');

    // cargokit.yaml participates in the crate hash, so it must exist before
    // the fixture generation hash is computed (the fetch command recomputes
    // the hash from the same inputs at run time).
    await writeCargokitYaml(urlPrefix: server.prefix('/'));
    generationHash = CrateHash.compute(crate.path);

    assets = {
      'aarch64-apple-darwin_libfjs.a': utf8.encode('arm64 static lib\n'),
      'aarch64-apple-darwin_libfjs.dylib': utf8.encode('arm64 dylib\n'),
      'x86_64-apple-darwin_libfjs.a': utf8.encode('x64 static lib\n'),
      'x86_64-apple-darwin_libfjs.dylib': utf8.encode('x64 dylib\n'),
      'fjs.xcframework.zip': utf8.encode('fake xcframework zip\n'),
    };
    assets['fjs.xcframework.zip.checksum'] = utf8.encode(
      '${sha256.convert(assets['fjs.xcframework.zip']!)}\n',
    );

    fixture = _fixtureFor(
      generationHash: generationHash,
      keyPair: keyPair,
      assets: assets,
    );
    server.install(fixture);
  });

  tearDown(() async {
    await server.close();
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  FetchPrecompiledArtifacts fetcher({
    required String outputDir,
    List<String> assetNames = const ['fjs.xcframework.zip'],
    String? manifestDir,
  }) {
    return FetchPrecompiledArtifacts(
      manifestDir: manifestDir ?? crate.path,
      outputDir: outputDir,
      assetNames: assetNames,
    );
  }

  test('fetches a verified composite asset into the output directory',
      () async {
    final outputDir = Directory(path.join(temp.path, 'out'));

    await fetcher(outputDir: outputDir.path).run();

    final fetched = File(path.join(outputDir.path, 'fjs.xcframework.zip'));
    expect(fetched.readAsBytesSync(), assets['fjs.xcframework.zip']);
    expect(
      Directory(outputDir.path)
          .listSync()
          .map((entry) => path.basename(entry.path)),
      everyElement(isNot(contains('.staging'))),
    );
  });

  test('fetches several composite outputs sorted and byte-exact', () async {
    final outputDir = Directory(path.join(temp.path, 'out'))..createSync();

    await fetcher(outputDir: outputDir.path, assetNames: [
      'fjs.xcframework.zip.checksum',
      'fjs.xcframework.zip',
    ]).run();

    expect(
      File(path.join(outputDir.path, 'fjs.xcframework.zip')).readAsBytesSync(),
      assets['fjs.xcframework.zip'],
    );
    expect(
      File(path.join(outputDir.path, 'fjs.xcframework.zip.checksum'))
          .readAsBytesSync(),
      assets['fjs.xcframework.zip.checksum'],
    );
  });

  test('rejects asset names that are not composite outputs', () async {
    final outputDir = Directory(path.join(temp.path, 'out'));

    await expectLater(
      fetcher(outputDir: outputDir.path, assetNames: [
        'fjs.xcframework.zip',
        'aarch64-apple-darwin_libfjs.a',
      ]).run(),
      throwsA(isA<PrecompiledGenerationException>().having(
        (error) => error.toString(),
        'message',
        allOf(contains('not composite outputs'),
            contains('aarch64-apple-darwin_libfjs.a')),
      )),
    );
    expect(outputDir.existsSync(), isFalse,
        reason: 'nothing should be written for a rejected request');
  });

  test('requires at least one asset', () async {
    final outputDir = Directory(path.join(temp.path, 'out'));

    await expectLater(
      fetcher(outputDir: outputDir.path, assetNames: const []).run(),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects crates without precompiled binary support', () async {
    File(path.join(crate.path, 'cargokit.yaml')).deleteSync();

    await expectLater(
      fetcher(outputDir: path.join(temp.path, 'out')).run(),
      throwsA(isA<PrecompiledGenerationException>().having(
        (error) => error.toString(),
        'message',
        contains('does not support precompiled binaries'),
      )),
    );
  });

  test('rejects a generation signed by a different key', () async {
    final otherSeed =
        Uint8List.fromList(List<int>.generate(32, (index) => 99 - index));
    final otherKey = ed25519.KeyPair(
      ed25519.newKeyFromSeed(otherSeed),
      ed25519.public(ed25519.newKeyFromSeed(otherSeed)),
    );
    server.install(
      _fixtureFor(
        generationHash: generationHash,
        keyPair: otherKey,
        assets: assets,
      ),
    );

    await expectLater(
      fetcher(outputDir: path.join(temp.path, 'out')).run(),
      throwsA(anyOf(
        isA<PrecompiledTransportException>(),
        isA<PrecompiledGenerationException>(),
      )),
    );
  });

  test('fails when no completed generation is published', () async {
    // Pointing the prefix at an unpublished generation leaves the fixture
    // unreachable under the recomputed crate hash.
    await writeCargokitYaml(urlPrefix: server.prefix('/precompiled_missing_'));

    await expectLater(
      fetcher(outputDir: path.join(temp.path, 'out')).run(),
      throwsA(isA<PrecompiledGenerationException>().having(
        (error) => error.toString(),
        'message',
        contains('unavailable'),
      )),
    );
  });

  test('derived expectations cover the manifest the command validates',
      () async {
    final config = CargokitCrateOptions.load(manifestDir: crate.path);
    final precompiled = config.precompiledBinaries!;
    final recipe = precompiled.buildRecipe!;

    final names = expectedGenerationAssetNames(
      recipe: recipe,
      precompiled: precompiled,
      libraryName: 'fjs',
    );
    expect(names, containsAll(assets.keys));
    expect(names, hasLength(assets.length));
    expect(names, equals(assets.keys.toSet()));

    final pairs = expectedCompositeChecksumPairs(precompiled);
    expect(pairs, {
      'fjs.xcframework.zip\u0000fjs.xcframework.zip.checksum',
    });
  });
}

class _StoreFixture {
  _StoreFixture(this.responses);

  final Map<String, List<int>> responses;
}

_StoreFixture _fixtureFor({
  required String generationHash,
  required ed25519.KeyPair keyPair,
  required Map<String, List<int>> assets,
}) {
  final entries = assets.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  final manifest = PrecompiledGenerationManifest(
    generationHash: generationHash,
    sourceCommit: '0123456789abcdef0123456789abcdef01234567',
    provenance: PrecompiledGenerationProvenance.fromRecipe(
      PrecompiledBuildRecipe(
        rustToolchain: '1.97.1',
        flutterVersion: '3.35.5',
        xcodeVersion: '16.4',
        sdkVersions: const {'macosx': '15.5'},
        deploymentTargets: const {'macos': '10.14'},
        rustTargets: const ['aarch64-apple-darwin', 'x86_64-apple-darwin'],
      ),
    ),
    assets: [
      for (final entry in entries)
        PrecompiledAsset(
          name: entry.key,
          length: entry.value.length,
          sha256: sha256.convert(entry.value).toString(),
        ),
    ],
    compositeChecksums: const [
      PrecompiledCompositeChecksum(
        archive: 'fjs.xcframework.zip',
        checksum: 'fjs.xcframework.zip.checksum',
      ),
    ],
  );
  return _StoreFixture({
    '/$generationHash/$precompiledGenerationManifestFileName':
        manifest.canonicalBytes(),
    '/$generationHash/$precompiledGenerationManifestSignatureFileName':
        manifest.sign(keyPair.privateKey),
    for (final entry in entries) ...{
      '/$generationHash/${entry.key}': entry.value,
      '/$generationHash/${entry.key}.sig': signPrecompiledAssetMetadata(
        keyPair.privateKey,
        generationHash: generationHash,
        name: entry.key,
        length: entry.value.length,
        sha256: sha256.convert(entry.value).toString(),
      ),
    },
  });
}

class _FixtureServer {
  _FixtureServer(this.server, this._fixtures, this._subscription);

  final HttpServer server;
  final Map<String, _StoreFixture> _fixtures;
  final StreamSubscription<HttpRequest> _subscription;

  static Future<_FixtureServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fixtures = <String, _StoreFixture>{};
    return _FixtureServer(server, fixtures, server.listen((request) async {
      final fixture = fixtures[request.uri.path];
      final bytes = fixture?.responses[request.uri.path];
      if (bytes == null) {
        request.response.statusCode = HttpStatus.notFound;
      } else {
        request.response.contentLength = bytes.length;
        request.response.add(bytes);
      }
      await request.response.close();
    }));
  }

  void install(_StoreFixture fixture) {
    // The store requests <url_prefix><generation>/<name>; serving from the
    // server root means the path doubles as the fixture key.
    _fixtures.addEntries(
        fixture.responses.keys.map((key) => MapEntry(key, fixture)));
  }

  String prefix(String pathPrefix) =>
      'http://${server.address.address}:${server.port}$pathPrefix';

  Future<void> close() async {
    await _subscription.cancel();
    await server.close(force: true);
  }
}
