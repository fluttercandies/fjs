import 'dart:io';
import 'dart:typed_data';

import 'package:build_tool/src/artifacts_provider.dart';
import 'package:build_tool/src/builder.dart';
import 'package:build_tool/src/cargo.dart';
import 'package:build_tool/src/options.dart';
import 'package:build_tool/src/precompile_binaries.dart';
import 'package:build_tool/src/precompiled_generation.dart';
import 'package:build_tool/src/target.dart';
import 'package:crypto/crypto.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

const _hash = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _sourceCommit = '1111111111111111111111111111111111111111';
const _privateSeed = <int>[
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  17,
  18,
  19,
  20,
  21,
  22,
  23,
  24,
  25,
  26,
  27,
  28,
  29,
  30,
  31,
];

void main() {
  late Directory temp;
  late Target target;
  late KeyPair keyPair;
  late PrecompiledBuildRecipe recipe;
  late BuildEnvironment environment;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('artifacts-provider-test-');
    target = Target.forRustTriple('x86_64-unknown-linux-gnu')!;
    keyPair = newKeyPair();
    recipe = PrecompiledBuildRecipe(
      rustToolchain: '1.88.0',
      flutterVersion: '3.32.8',
      xcodeVersion: '16.4',
      sdkVersions: const {'linux': '6.8'},
      deploymentTargets: const {'linux': 'glibc-2.35'},
      rustTargets: [target.rust],
    );
    environment = BuildEnvironment(
      configuration: BuildConfiguration.release,
      crateOptions: CargokitCrateOptions(
        precompiledBinaries: PrecompiledBinaries(
          uriPrefix: 'https://assets.example/precompiled/',
          publicKey: keyPair.publicKey,
          buildRecipe: recipe,
        ),
      ),
      targetTempDir: temp.path,
      manifestDir: temp.path,
      crateInfo: CrateInfo(packageName: 'fjs'),
      isAndroid: false,
    );
  });

  tearDown(() => temp.deleteSync(recursive: true));

  test('disabled mode uses local Rust and never contacts remote', () async {
    var localCalls = 0;
    var remoteCalls = 0;
    final local = await _localArtifact(temp, target, 'local.a');
    final provider = _provider(
      environment,
      PrecompiledBinariesMode.disabled,
      httpGet: (_) async {
        remoteCalls++;
        return Response('', 500);
      },
      localBuilder: (target, _) async {
        localCalls++;
        return [local];
      },
    );

    final result = await provider.getArtifacts([target]);

    expect(result[target]!.single.path, local.path);
    expect(localCalls, 1);
    expect(remoteCalls, 0);
  });

  test('auto mode falls back locally only when completion manifest is absent', () async {
    var localCalls = 0;
    var requested = <String>[];
    final local = await _localArtifact(temp, target, 'local.a');
    final provider = _provider(
      environment,
      PrecompiledBinariesMode.auto,
      httpGet: (url) async {
        requested.add(url.path);
        return Response('', 404);
      },
      localBuilder: (target, _) async {
        localCalls++;
        return [local];
      },
    );

    final result = await provider.getArtifacts([target]);

    expect(result[target]!.single.path, local.path);
    expect(localCalls, 1);
    expect(requested, hasLength(1));
    expect(requested.single, contains('completion.json'));
  });

  test('required mode fails on missing completion and never invokes local Rust', () async {
    var localCalls = 0;
    final provider = _provider(
      environment,
      PrecompiledBinariesMode.required,
      httpGet: (url) async => Response('', 404),
      localBuilder: (target, _) async {
        localCalls++;
        return const [];
      },
    );

    await expectLater(
      provider.getArtifacts([target]),
      throwsA(isA<PrecompiledGenerationException>()),
    );
    expect(localCalls, 0);
  });

  test('fetches signed completion first and only exact requested target assets', () async {
    final fixture = _fixture(recipe, target: target, keyPair: keyPair);
    final calls = <String>[];
    final provider = _provider(
      environment,
      PrecompiledBinariesMode.required,
      httpGet: (url) async {
        calls.add(url.path);
        return fixture.responses[url.path] ?? Response('', 404);
      },
    );

    final result = await provider.getArtifacts([target]);

    expect(result[target], hasLength(1));
    expect(result[target]!.single.finalFileName, 'libfjs.so');
    expect(calls.first, contains('completion.json'));
    expect(calls[1], contains('completion.json.sig'));
    expect(calls.where((call) => call.endsWith('.sig')).length, 2);
    expect(calls, everyElement(isNot(contains('other-target'))));
  });

  test('revalidates cached bytes and signatures on every use, repairing a tampered cache', () async {
    final fixture = _fixture(recipe, target: target, keyPair: keyPair);
    var assetRequests = 0;
    final provider = _provider(
      environment,
      PrecompiledBinariesMode.required,
      httpGet: (url) async {
        if (url.path.endsWith('.so') || url.path.endsWith('.so.sig')) assetRequests++;
        return fixture.responses[url.path] ?? Response('', 404);
      },
    );
    await provider.getArtifacts([target]);
    final cacheFile = File(path.join(
      temp.path,
      'precompiled',
      _hash,
      fixture.assetName,
    ));
    cacheFile.writeAsBytesSync([0, 0, 0]);

    final result = await provider.getArtifacts([target]);

    expect(result[target], hasLength(1));
    expect(cacheFile.readAsBytesSync(), fixture.assetBytes);
    expect(assetRequests, 4);
  });

  test('partial or signature-invalid remote generation fails closed without local fallback', () async {
    final fixture = _fixture(recipe, target: target, keyPair: keyPair);
    var localCalls = 0;
    final missingAssetResponses = Map<String, Response>.from(fixture.responses)
      ..removeWhere((key, _) => key.endsWith('.so'));
    final provider = _provider(
      environment,
      PrecompiledBinariesMode.auto,
      httpGet: (url) async =>
          missingAssetResponses[url.path] ?? Response('', 404),
      localBuilder: (target, _) async {
        localCalls++;
        return const [];
      },
    );
    await expectLater(
      provider.getArtifacts([target]),
      throwsA(isA<PrecompiledGenerationException>()),
    );
    expect(localCalls, 0);

    final badSignatureResponses = Map<String, Response>.from(fixture.responses);
    final signaturePath = badSignatureResponses.keys.firstWhere((key) => key.endsWith('.so.sig'));
    badSignatureResponses[signaturePath] = Response.bytes(Uint8List(64), 200);
    final badProvider = _provider(
      environment,
      PrecompiledBinariesMode.required,
      httpGet: (url) async =>
          badSignatureResponses[url.path] ?? Response('', 404),
      localBuilder: (target, _) async {
        localCalls++;
        return const [];
      },
    );
    await expectLater(
      badProvider.getArtifacts([target]),
      throwsA(isA<PrecompiledGenerationException>()),
    );
    expect(localCalls, 0);
  });

  test('download failure leaves no partial cache directory', () async {
    final fixture = _fixture(recipe, target: target, keyPair: keyPair);
    final responses = Map<String, Response>.from(fixture.responses);
    final assetPath = responses.keys.firstWhere((key) => key.endsWith('.so'));
    responses[assetPath] = Response.bytes([1, 2, 3], 200);
    final provider = _provider(
      environment,
      PrecompiledBinariesMode.required,
      httpGet: (url) async => responses[url.path] ?? Response('', 404),
    );

    await expectLater(
      provider.getArtifacts([target]),
      throwsA(isA<PrecompiledGenerationException>()),
    );
    expect(
      Directory(path.join(temp.path, 'precompiled', _hash)).existsSync(),
      isFalse,
    );
    expect(
      Directory(path.join(temp.path, 'precompiled')).listSync().whereType<Directory>(),
      isEmpty,
    );
  });
}

ArtifactProvider _provider(
  BuildEnvironment environment,
  PrecompiledBinariesMode mode, {
  required ArtifactHttpGet httpGet,
  ArtifactLocalBuilder? localBuilder,
}) {
  return ArtifactProvider(
    environment: environment,
    userOptions: CargokitUserOptions(
      precompiledBinariesMode: mode,
      verboseLogging: false,
    ),
    httpGet: httpGet,
    generationHash: (_) => _hash,
    localBuilder: localBuilder,
  );
}

Future<Artifact> _localArtifact(Directory temp, Target target, String name) async {
  final file = File(path.join(temp.path, name))..writeAsBytesSync([1]);
  return Artifact(path: file.path, finalFileName: name);
}

class _Fixture {
  _Fixture({required this.responses, required this.assetName, required this.assetBytes});
  final Map<String, Response> responses;
  final String assetName;
  final Uint8List assetBytes;
}

_Fixture _fixture(
  PrecompiledBuildRecipe recipe, {
  required Target target,
  required KeyPair keyPair,
}) {
  final assetName = PrecompileBinaries.fileName(target, 'libfjs.so');
  final assetBytes = Uint8List.fromList([5, 4, 3, 2]);
  final manifest = PrecompiledGenerationManifest(
    generationHash: _hash,
    sourceCommit: _sourceCommit,
    provenance: PrecompiledGenerationProvenance.fromRecipe(recipe),
    assets: [
      PrecompiledAsset(
        name: assetName,
        length: assetBytes.length,
        sha256: sha256Bytes(assetBytes),
      ),
    ],
    compositeChecksums: const [],
  );
  final prefix = 'https://assets.example/precompiled/$_hash/';
  return _Fixture(
    assetName: assetName,
    assetBytes: assetBytes,
    responses: {
      '/precompiled/$_hash/completion.json.sig':
          Response.bytes(manifest.sign(keyPair.privateKey), 200),
      '/precompiled/$_hash/completion.json':
          Response.bytes(manifest.canonicalBytes(), 200),
      '/precompiled/$_hash/$assetName.sig':
          Response.bytes(signPrecompiledAsset(keyPair.privateKey, assetBytes), 200),
      '/precompiled/$_hash/$assetName': Response.bytes(assetBytes, 200),
      prefix: Response('', 404),
    },
  );
}

String sha256Bytes(List<int> bytes) => sha256.convert(bytes).toString();

KeyPair newKeyPair() {
  final private = newKeyFromSeed(Uint8List.fromList(_privateSeed));
  return KeyPair(private, public(private));
}
