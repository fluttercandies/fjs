import 'package:build_tool/src/builder.dart';
import 'package:build_tool/src/options.dart';
import 'package:build_tool/src/rustup.dart';
import 'package:build_tool/src/util.dart';
import 'package:hex/hex.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  tearDown(() {
    testRunCommandOverride = null;
    testRustupExecutablePathOverride = null;
  });

  test('parse cargo build options', () {
    final yaml = '''
toolchain: nightly
extra_flags:
  - -Z
  - build-std=panic_abort,std
''';

    final options = CargoBuildOptions.parse(loadYamlNode(yaml));

    expect(options.toolchain, Toolchain.nightly);
    expect(options.flags, ['-Z', 'build-std=panic_abort,std']);
  });

  test('parse precompiled binaries config', () {
    final yaml = '''
url_prefix: https://example.com/precompiled_
public_key: a4c3433798eb2c36edf2b94dbb4dd899d57496ca373a8982d8a792410b7f6445
''';

    final config = PrecompiledBinaries.parse(loadYamlNode(yaml));

    expect(config.uriPrefix, 'https://example.com/precompiled_');
    expect(
      config.publicKey.bytes,
      HEX.decode(
        'a4c3433798eb2c36edf2b94dbb4dd899d57496ca373a8982d8a792410b7f6445',
      ),
    );
  });

  test('parse crate options with cargo and precompiled binaries', () {
    final yaml = '''
cargo:
  debug:
    toolchain: nightly
    extra_flags:
      - -Z
      - build-std=panic_abort,std
  release:
    toolchain: beta

precompiled_binaries:
  url_prefix: https://example.com/precompiled_
  public_key: a4c3433798eb2c36edf2b94dbb4dd899d57496ca373a8982d8a792410b7f6445
''';

    final options = CargokitCrateOptions.parse(loadYamlNode(yaml));

    expect(
        options.cargo[BuildConfiguration.debug]!.toolchain, Toolchain.nightly);
    expect(
      options.cargo[BuildConfiguration.debug]!.flags,
      ['-Z', 'build-std=panic_abort,std'],
    );
    expect(
        options.cargo[BuildConfiguration.release]!.toolchain, Toolchain.beta);
    expect(options.precompiledBinaries?.uriPrefix,
        'https://example.com/precompiled_');
  });

  test('default user options build locally when rustup is available', () {
    testRustupExecutablePathOverride = () => '/usr/bin/rustup';

    final options = CargokitUserOptions.parse(loadYamlNode('{}'));

    expect(options.usePrecompiledBinaries, false);
    expect(options.verboseLogging, false);
  });

  test('default user options use precompiled binaries when rustup is missing',
      () {
    testRustupExecutablePathOverride = () => null;

    final options = CargokitUserOptions.parse(loadYamlNode('{}'));

    expect(options.usePrecompiledBinaries, true);
    expect(options.verboseLogging, false);
  });

  test('explicit user options override default precompiled binary behavior',
      () {
    final options = CargokitUserOptions.parse(loadYamlNode('''
use_precompiled_binaries: true
verbose_logging: true
'''));

    expect(options.usePrecompiledBinaries, true);
    expect(options.verboseLogging, true);
  });
}
