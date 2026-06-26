import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  final outputDir = Directory(options.outputDir);
  outputDir.createSync(recursive: true);

  final appJson = '${outputDir.path}${Platform.pathSeparator}app.json';
  final launchJson = '${outputDir.path}${Platform.pathSeparator}launch.json';
  final readJson = '${outputDir.path}${Platform.pathSeparator}read.json';
  final assertJson = '${outputDir.path}${Platform.pathSeparator}assert.json';
  final errorsJson = '${outputDir.path}${Platform.pathSeparator}errors.json';
  final stopJson = '${outputDir.path}${Platform.pathSeparator}stop.json';
  final commandJson =
      '${outputDir.path}${Platform.pathSeparator}assert_command.json';

  final commandFile = File(commandJson);
  commandFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'commandId': 'assert-fjs-home',
      'commandType': 'assertText',
      'parameters': <String, Object?>{'text': options.expectedText},
      'timeoutMs': options.assertTimeoutMs,
    }),
  );

  try {
    await _run(<String>[
      'dart',
      'run',
      'cockpit',
      'launch-app',
      '--project-dir',
      '.',
      '--target',
      'cockpit/main.dart',
      '--platform',
      options.platform,
      if (options.deviceId != null) ...<String>[
        '--device-id',
        options.deviceId!,
      ],
      '--mode',
      'automation',
      '--session-port',
      options.sessionPort.toString(),
      '--launch-timeout-seconds',
      options.launchTimeoutSeconds.toString(),
      '--app-json',
      appJson,
      '--output',
      launchJson,
      '--output-format',
      'json',
    ]);

    await _runWithRetry(<String>[
      'dart',
      'run',
      'cockpit',
      'read-app',
      '--app-json',
      appJson,
      '--profile',
      'standard',
      '--output',
      readJson,
      '--output-format',
      'json',
    ], attempts: 6);

    await _runWithRetry(<String>[
      'dart',
      'run',
      'cockpit',
      'run-command',
      '--app-json',
      appJson,
      '--command-file',
      commandJson,
      '--profile',
      'standard',
      '--output',
      assertJson,
      '--output-format',
      'json',
    ], attempts: 6);

    await _runWithRetry(<String>[
      'dart',
      'run',
      'cockpit',
      'read-errors',
      '--app-json',
      appJson,
      '--max-errors',
      '10',
      '--no-include-latest-task',
      '--no-include-sessions',
      '--output',
      errorsJson,
      '--output-format',
      'json',
    ], attempts: 6);

    _ensureNoRuntimeErrors(File(errorsJson));
  } finally {
    if (File(appJson).existsSync()) {
      await _run(<String>[
        'dart',
        'run',
        'cockpit',
        'stop-app',
        '--app-json',
        appJson,
        '--output',
        stopJson,
        '--output-format',
        'json',
      ], allowFailure: true);
    }
  }
}

Future<void> _runWithRetry(
  List<String> command, {
  required int attempts,
}) async {
  ProcessException? lastException;
  for (var attempt = 1; attempt <= attempts; attempt++) {
    try {
      await _run(command);
      return;
    } on ProcessException catch (error) {
      lastException = error;
      if (!_isRetriableCockpitFailure(error) || attempt == attempts) {
        rethrow;
      }
      final delay = Duration(seconds: attempt * 2);
      stdout.writeln(
        'Retrying cockpit command after ${delay.inSeconds}s '
        '(attempt $attempt/$attempts).',
      );
      await Future<void>.delayed(delay);
    }
  }
  throw lastException ?? StateError('Retry loop ended without a result.');
}

bool _isRetriableCockpitFailure(ProcessException error) {
  final message = error.message;
  return message.contains('remoteUnavailable') ||
      message.contains('Remote session is temporarily unavailable') ||
      message.contains('/health') ||
      message.contains('TimeoutException');
}

Future<void> _run(List<String> command, {bool allowFailure = false}) async {
  final executable = command.first;
  final arguments = command.sublist(1);
  stdout.writeln('> ${command.join(' ')}');
  final result = await Process.run(
    executable,
    arguments,
    runInShell: Platform.isWindows,
  );
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (!allowFailure && result.exitCode != 0) {
    final output = '${result.stdout}\n${result.stderr}';
    throw ProcessException(
      executable,
      arguments,
      'Command failed with exit code ${result.exitCode}.\n$output',
      result.exitCode,
    );
  }
}

void _ensureNoRuntimeErrors(File errorsFile) {
  final json =
      jsonDecode(errorsFile.readAsStringSync()) as Map<String, Object?>;
  final hasErrors = json['hasErrors'] as bool? ?? false;
  final errors = json['errors'] as List<Object?>? ?? const <Object?>[];
  if (!hasErrors && errors.isEmpty) {
    return;
  }
  throw StateError(
    'Cockpit reported runtime errors: ${const JsonEncoder.withIndent('  ').convert(json)}',
  );
}

final class _Options {
  const _Options({
    required this.platform,
    required this.outputDir,
    required this.sessionPort,
    required this.launchTimeoutSeconds,
    required this.assertTimeoutMs,
    required this.expectedText,
    this.deviceId,
  });

  final String platform;
  final String? deviceId;
  final String outputDir;
  final int sessionPort;
  final int launchTimeoutSeconds;
  final int assertTimeoutMs;
  final String expectedText;

  static _Options parse(List<String> args) {
    String? platform;
    String? deviceId;
    var outputDir = '.dart_tool/flutter_cockpit/ci';
    var sessionPort = 57331;
    var launchTimeoutSeconds = 900;
    var assertTimeoutMs = 30000;
    var expectedText = 'Welcome to FJS';

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      String readValue() {
        if (i + 1 >= args.length) {
          throw ArgumentError('Missing value for $arg.');
        }
        return args[++i];
      }

      switch (arg) {
        case '--platform':
          platform = readValue();
        case '--device-id':
          deviceId = readValue();
        case '--output-dir':
          outputDir = readValue();
        case '--session-port':
          sessionPort = int.parse(readValue());
        case '--launch-timeout-seconds':
          launchTimeoutSeconds = int.parse(readValue());
        case '--assert-timeout-ms':
          assertTimeoutMs = int.parse(readValue());
        case '--expected-text':
          expectedText = readValue();
        case '--help':
        case '-h':
          _printUsage();
          exit(0);
        default:
          throw ArgumentError('Unknown argument: $arg.');
      }
    }

    if (platform == null || platform.isEmpty) {
      _printUsage();
      throw ArgumentError('--platform is required.');
    }

    return _Options(
      platform: platform,
      deviceId: deviceId,
      outputDir: outputDir,
      sessionPort: sessionPort,
      launchTimeoutSeconds: launchTimeoutSeconds,
      assertTimeoutMs: assertTimeoutMs,
      expectedText: expectedText,
    );
  }

  static void _printUsage() {
    stdout.writeln('''
Usage: dart run tool/ci_cockpit_verify.dart --platform <platform> [options]

Options:
  --device-id <id>                 Required for android and ios.
  --output-dir <path>              Defaults to .dart_tool/flutter_cockpit/ci.
  --session-port <port>            Defaults to 57331.
  --launch-timeout-seconds <secs>  Defaults to 900.
  --assert-timeout-ms <ms>         Defaults to 30000.
  --expected-text <text>           Defaults to "Welcome to FJS".
''');
  }
}
