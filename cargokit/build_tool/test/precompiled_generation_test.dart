import 'dart:convert';
import 'dart:typed_data';

import 'package:build_tool/src/options.dart';
import 'package:build_tool/src/precompiled_generation.dart';
import 'package:crypto/crypto.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:test/test.dart';

const _generationHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _archiveHash =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _checksumHash =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _sourceCommit = '1111111111111111111111111111111111111111';

void main() {
  late KeyPair keyPair;
  late PrecompiledBuildRecipe recipe;

  setUp(() {
    keyPair = KeyPair(
      newKeyFromSeed(Uint8List.fromList(List<int>.generate(32, (i) => i))),
      public(newKeyFromSeed(
          Uint8List.fromList(List<int>.generate(32, (i) => i)))),
    );
    recipe = PrecompiledBuildRecipe(
      rustToolchain: '1.88.0',
      flutterVersion: '3.32.8',
      xcodeVersion: '16.4',
      sdkVersions: const {'macosx': '15.5', 'iphoneos': '18.5'},
      deploymentTargets: const {'macos': '10.14', 'ios': '12.0'},
      rustTargets: const [
        'x86_64-apple-darwin',
        'aarch64-apple-darwin',
      ],
    );
  });

  test('canonical encoding is deterministic and recursively sorted', () {
    final first = _manifest(recipe, reverseAssets: true);
    final second = _manifest(recipe);

    expect(first.canonicalBytes(), second.canonicalBytes());
    expect(
      utf8.decode(first.canonicalBytes()),
      '{"assets":[{"length":3,"name":"aarch64-apple-darwin_libfjs.a",'
      '"sha256":"$_checksumHash"},{"length":4,"name":"fjs.xcframework.zip",'
      '"sha256":"$_archiveHash"},{"length":65,'
      '"name":"fjs.xcframework.zip.checksum","sha256":"$_checksumHash"}],'
      '"composite_checksums":[{"algorithm":"sha256",'
      '"archive":"fjs.xcframework.zip",'
      '"checksum":"fjs.xcframework.zip.checksum"}],'
      '"generation_hash":"$_generationHash","provenance":{"actual":'
      '{"deployment_targets":{"ios":"12.0","macos":"10.14"},'
      '"flutter_version":"3.32.8","rust_targets":'
      '["aarch64-apple-darwin","x86_64-apple-darwin"],'
      '"rust_toolchain":"1.88.0","sdk_versions":'
      '{"iphoneos":"18.5","macosx":"15.5"},"xcode_version":"16.4"},'
      '"pinned":{"deployment_targets":{"ios":"12.0","macos":"10.14"},'
      '"flutter_version":"3.32.8","rust_targets":'
      '["aarch64-apple-darwin","x86_64-apple-darwin"],'
      '"rust_toolchain":"1.88.0","sdk_versions":'
      '{"iphoneos":"18.5","macosx":"15.5"},"xcode_version":"16.4"}},'
      '"schema_version":1,"scope":"cargokit-precompiled-generation",'
      '"source_commit":"$_sourceCommit"}',
    );
  });

  test('canonical manifest round trips through strict parsing', () {
    final manifest = _manifest(recipe);

    final parsed = PrecompiledGenerationManifest.parse(manifest.canonicalBytes());

    expect(parsed.canonicalBytes(), manifest.canonicalBytes());
    expect(parsed.asset('fjs.xcframework.zip')?.length, 4);
  });

  group('strict manifest parsing rejects', () {
    test('unknown, missing, and duplicate fields', () {
      final valid = jsonDecode(utf8.decode(_manifest(recipe).canonicalBytes()))
          as Map<String, dynamic>;

      expect(
        () => _parse({...valid, 'unexpected': true}),
        throwsA(isA<PrecompiledGenerationException>()),
      );
      final missing = {...valid}..remove('scope');
      expect(
        () => _parse(missing),
        throwsA(isA<PrecompiledGenerationException>()),
      );
      expect(
        () => PrecompiledGenerationManifest.parse(utf8.encode(
          '{"schema_version":1,"schema_version":1}',
        )),
        throwsA(isA<PrecompiledGenerationException>()),
      );
    });

    test('unsupported schema and scope', () {
      final valid = jsonDecode(utf8.decode(_manifest(recipe).canonicalBytes()))
          as Map<String, dynamic>;

      expect(
        () => _parse({...valid, 'schema_version': 2}),
        throwsA(isA<PrecompiledGenerationException>()),
      );
      expect(
        () => _parse({...valid, 'scope': 'github-release'}),
        throwsA(isA<PrecompiledGenerationException>()),
      );
    });

    test('unsafe paths, malformed hashes, duplicates, and unsorted inventory', () {
      final valid = jsonDecode(utf8.decode(_manifest(recipe).canonicalBytes()))
          as Map<String, dynamic>;
      final assets = (valid['assets'] as List).cast<Map<String, dynamic>>();

      expect(
        () => _parse({...valid, 'generation_hash': 'not-a-sha256'}),
        throwsA(isA<PrecompiledGenerationException>()),
      );
      expect(
        () => _parse({
          ...valid,
          'assets': [
            {...assets.first, 'name': '../escape'},
            ...assets.skip(1),
          ],
        }),
        throwsA(isA<PrecompiledGenerationException>()),
      );
      expect(
        () => _parse({...valid, 'assets': [assets.first, assets.first]}),
        throwsA(isA<PrecompiledGenerationException>()),
      );
      expect(
        () => _parse({...valid, 'assets': assets.reversed.toList()}),
        throwsA(isA<PrecompiledGenerationException>()),
      );
    });
  });

  test('validation rejects incomplete inventory and provenance mismatch', () {
    final manifest = _manifest(recipe);

    expect(
      () => manifest.validateFor(
        generationHash: _generationHash,
        recipe: recipe,
        expectedAssetNames: const {
          'aarch64-apple-darwin_libfjs.a',
          'x86_64-apple-darwin_libfjs.a',
          'fjs.xcframework.zip',
          'fjs.xcframework.zip.checksum',
        },
      ),
      throwsA(isA<PrecompiledGenerationException>()),
    );

    final differentRecipe = PrecompiledBuildRecipe(
      rustToolchain: '1.89.0',
      flutterVersion: recipe.flutterVersion,
      xcodeVersion: recipe.xcodeVersion,
      sdkVersions: recipe.sdkVersions,
      deploymentTargets: recipe.deploymentTargets,
      rustTargets: recipe.rustTargets,
    );
    expect(
      () => manifest.validateFor(
        generationHash: _generationHash,
        recipe: differentRecipe,
        expectedAssetNames: manifest.assets.map((asset) => asset.name).toSet(),
      ),
      throwsA(isA<PrecompiledGenerationException>()),
    );
  });

  test('Ed25519 signs and verifies canonical manifest and asset bytes', () {
    final assetBytes = Uint8List.fromList([9, 8, 7]);
    final assetHash = sha256.convert(assetBytes).toString();
    final manifest = PrecompiledGenerationManifest(
      generationHash: _generationHash,
      sourceCommit: _sourceCommit,
      provenance: PrecompiledGenerationProvenance.fromRecipe(recipe),
      assets: [
        PrecompiledAsset(name: 'asset.bin', length: 3, sha256: assetHash),
      ],
      compositeChecksums: const [],
    );

    final manifestSignature = manifest.sign(keyPair.privateKey);
    final assetSignature = signPrecompiledAsset(keyPair.privateKey, assetBytes);

    manifest.verifySignature(keyPair.publicKey, manifestSignature);
    manifest.verifyAsset(
      name: 'asset.bin',
      bytes: assetBytes,
      signature: assetSignature,
      publicKey: keyPair.publicKey,
    );
    expect(
      () => manifest.verifyAsset(
        name: 'asset.bin',
        bytes: Uint8List.fromList([9, 8, 6]),
        signature: assetSignature,
        publicKey: keyPair.publicKey,
      ),
      throwsA(isA<PrecompiledGenerationException>()),
    );
    final badManifestSignature = Uint8List.fromList(manifestSignature)
      ..[0] ^= 1;
    expect(
      () => manifest.verifySignature(keyPair.publicKey, badManifestSignature),
      throwsA(isA<PrecompiledGenerationException>()),
    );
  });

  test('zip/checksum relationship binds checksum contents to archive digest', () {
    final archive = Uint8List.fromList([1, 2, 3, 4]);
    final checksum = Uint8List.fromList(utf8.encode('${sha256.convert(archive)}\n'));
    final manifest = PrecompiledGenerationManifest(
      generationHash: _generationHash,
      sourceCommit: _sourceCommit,
      provenance: PrecompiledGenerationProvenance.fromRecipe(recipe),
      assets: [
        PrecompiledAsset(
          name: 'fjs.xcframework.zip',
          length: archive.length,
          sha256: sha256.convert(archive).toString(),
        ),
        PrecompiledAsset(
          name: 'fjs.xcframework.zip.checksum',
          length: checksum.length,
          sha256: sha256.convert(checksum).toString(),
        ),
      ],
      compositeChecksums: const [
        PrecompiledCompositeChecksum(
          archive: 'fjs.xcframework.zip',
          checksum: 'fjs.xcframework.zip.checksum',
        ),
      ],
    );

    manifest.validateCompositeChecksums({
      'fjs.xcframework.zip': archive,
      'fjs.xcframework.zip.checksum': checksum,
    });
    expect(
      () => manifest.validateCompositeChecksums({
        'fjs.xcframework.zip': archive,
        'fjs.xcframework.zip.checksum': Uint8List.fromList(utf8.encode(
          'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd\n',
        )),
      }),
      throwsA(isA<PrecompiledGenerationException>()),
    );
  });
}

PrecompiledGenerationManifest _manifest(
  PrecompiledBuildRecipe recipe, {
  bool reverseAssets = false,
}) {
  final assets = [
    const PrecompiledAsset(
      name: 'aarch64-apple-darwin_libfjs.a',
      length: 3,
      sha256: _checksumHash,
    ),
    const PrecompiledAsset(
      name: 'fjs.xcframework.zip',
      length: 4,
      sha256: _archiveHash,
    ),
    const PrecompiledAsset(
      name: 'fjs.xcframework.zip.checksum',
      length: 65,
      sha256: _checksumHash,
    ),
  ];
  return PrecompiledGenerationManifest(
    generationHash: _generationHash,
    sourceCommit: _sourceCommit,
    provenance: PrecompiledGenerationProvenance.fromRecipe(recipe),
    assets: reverseAssets ? assets.reversed.toList() : assets,
    compositeChecksums: const [
      PrecompiledCompositeChecksum(
        archive: 'fjs.xcframework.zip',
        checksum: 'fjs.xcframework.zip.checksum',
      ),
    ],
  );
}

PrecompiledGenerationManifest _parse(Map<String, dynamic> value) =>
    PrecompiledGenerationManifest.parse(utf8.encode(jsonEncode(value)));
