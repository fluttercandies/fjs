import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  final outputDir = Directory(options.outputDir);
  outputDir.createSync(recursive: true);

  final appJson = '${outputDir.path}${Platform.pathSeparator}app.json';
  final launchJson = '${outputDir.path}${Platform.pathSeparator}launch.json';
  final readJson = '${outputDir.path}${Platform.pathSeparator}read.json';
  final workflowJson =
      '${outputDir.path}${Platform.pathSeparator}workflow.json';
  final runScriptJson =
      '${outputDir.path}${Platform.pathSeparator}run_script.json';
  final bundleSummaryJson =
      '${outputDir.path}${Platform.pathSeparator}bundle_summary.json';
  final bundleRoot = '${outputDir.path}${Platform.pathSeparator}task_bundle';
  final errorsJson = '${outputDir.path}${Platform.pathSeparator}errors.json';
  final stopJson = '${outputDir.path}${Platform.pathSeparator}stop.json';

  _writeJson(workflowJson, _buildWorkflow(options));

  try {
    await _runWithRetry(<String>[
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
    ], attempts: 2);

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

    await _run(<String>[
      'dart',
      'run',
      'cockpit',
      'run-script',
      '--app-json',
      appJson,
      '--script',
      workflowJson,
      '--platform',
      options.platform,
      '--output-root',
      bundleRoot,
      '--output',
      runScriptJson,
      '--output-format',
      'json',
    ]);

    final bundleDir = _findBundleDir(
      runScriptResult: File(runScriptJson),
      outputRoot: Directory(bundleRoot),
    );
    await _run(<String>[
      'dart',
      'run',
      'cockpit',
      'read-task-bundle-summary',
      '--bundle-dir',
      bundleDir,
      '--output',
      bundleSummaryJson,
      '--output-format',
      'json',
    ]);
    _ensureBundleEvidence(File(bundleSummaryJson));

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

Map<String, Object?> _buildWorkflow(_Options options) {
  final retryDelayMs = (options.assertTimeoutMs ~/ 10).clamp(500, 3000);
  return <String, Object?>{
    'schemaVersion': 1,
    'sessionId': 'fjs-ci-${options.platform}',
    'taskId': 'fjs-example-smoke',
    'platform': options.platform,
    'failFast': true,
    'steps': <Object?>[
      <String, Object?>{
        'stepId': 'assert-home',
        'stepType': 'retry',
        'maxAttempts': 6,
        'delayMs': retryDelayMs,
        'step': <String, Object?>{
          'stepType': 'command',
          'command': <String, Object?>{
            'commandId': 'assert-fjs-home',
            'commandType': 'assertText',
            'parameters': <String, Object?>{'text': options.expectedText},
            'timeoutMs': options.assertTimeoutMs,
          },
        },
      },
      <String, Object?>{
        'stepId': 'tap-execute',
        'stepType': 'command',
        'command': <String, Object?>{
          'commandId': 'tap-fjs-execute',
          'commandType': 'tap',
          'locator': <String, Object?>{
            'key': 'fjs_execute_button',
            'fallbacks': <Object?>[
              <String, Object?>{'key': 'fjs_execute_app_bar_button'},
              <String, Object?>{'text': 'Execute Code'},
              <String, Object?>{'tooltip': 'Execute Code'},
            ],
          },
          'parameters': <String, Object?>{
            'actionExpectationTimeoutMs': options.assertTimeoutMs,
          },
          'timeoutMs': options.assertTimeoutMs,
        },
      },
      <String, Object?>{
        'stepId': 'assert-result',
        'stepType': 'retry',
        'maxAttempts': 6,
        'delayMs': retryDelayMs,
        'step': <String, Object?>{
          'stepType': 'command',
          'command': <String, Object?>{
            'commandId': 'assert-fjs-smoke-result',
            'commandType': 'assertText',
            'parameters': <String, Object?>{'text': options.expectedResult},
            'timeoutMs': options.assertTimeoutMs,
          },
        },
      },
      <String, Object?>{
        'stepId': 'capture-result',
        'stepType': 'command',
        'command': <String, Object?>{
          'commandId': 'capture-fjs-smoke-result',
          'commandType': 'captureScreenshot',
          'screenshotRequest': <String, Object?>{
            'reason': 'acceptance',
            'name': 'fjs-example-smoke-${options.platform}',
            'includeSnapshot': true,
            'attachToStep': true,
          },
          'timeoutMs': options.assertTimeoutMs,
        },
      },
    ],
  };
}

void _writeJson(String path, Map<String, Object?> json) {
  File(
    path,
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(json));
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
  return error.errorCode == -15 ||
      message.contains('exit code -15') ||
      message.contains('remoteUnavailable') ||
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

void _ensureBundleEvidence(File summaryFile) {
  final json =
      jsonDecode(summaryFile.readAsStringSync()) as Map<String, Object?>;
  final gateSummary = json['gateSummary'] as Map<String, Object?>? ?? const {};
  final gates = gateSummary['gates'] as Map<String, Object?>? ?? const {};
  final issueEvidence =
      json['issueEvidence'] as Map<String, Object?>? ?? const {};
  final counts = issueEvidence['counts'] as Map<String, Object?>? ?? const {};
  final requiredGates = <String>[
    'sessionReachable',
    'targetReachable',
    'executionFinished',
    'bundleWritten',
    'postconditionsSatisfied',
    'artifactsReady',
    'screenshotReady',
    'finalAssertionPassed',
  ];
  final failedGates = requiredGates
      .where((gate) => gates[gate] != true)
      .toList(growable: false);
  final failedCommandCount = counts['failedCommandCount'] as int? ?? 0;
  final runtimeIssueCount = counts['runtimeIssueCount'] as int? ?? 0;
  final artifactIssueCount = counts['artifactIssueCount'] as int? ?? 0;
  if (failedGates.isEmpty &&
      failedCommandCount == 0 &&
      runtimeIssueCount == 0 &&
      artifactIssueCount == 0) {
    return;
  }

  throw StateError(
    'Cockpit bundle evidence did not satisfy CI gates: '
    '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{'failedGates': failedGates, 'counts': counts, 'issueEvidence': issueEvidence})}',
  );
}

String _findBundleDir({
  required File runScriptResult,
  required Directory outputRoot,
}) {
  if (runScriptResult.existsSync()) {
    final json =
        jsonDecode(runScriptResult.readAsStringSync()) as Map<String, Object?>;
    final direct = _firstString(json, const <List<String>>[
      <String>['bundleDir'],
      <String>['bundle', 'bundleDir'],
      <String>['result', 'bundleDir'],
    ]);
    if (direct != null && Directory(direct).existsSync()) {
      return direct;
    }
  }

  final manifestFiles = <File>[];
  if (outputRoot.existsSync()) {
    for (final entity in outputRoot.listSync(recursive: true)) {
      if (entity is File && entity.uri.pathSegments.last == 'manifest.json') {
        manifestFiles.add(entity);
      }
    }
  }
  if (manifestFiles.isEmpty) {
    throw StateError('Cockpit run-script did not write a task bundle.');
  }
  manifestFiles.sort(
    (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
  );
  return manifestFiles.first.parent.path;
}

String? _firstString(Map<String, Object?> json, List<List<String>> paths) {
  for (final path in paths) {
    Object? current = json;
    for (final segment in path) {
      if (current is Map<String, Object?>) {
        current = current[segment];
      } else {
        current = null;
        break;
      }
    }
    if (current is String && current.isNotEmpty) {
      return current;
    }
  }
  return null;
}

final class _Options {
  const _Options({
    required this.platform,
    required this.outputDir,
    required this.sessionPort,
    required this.launchTimeoutSeconds,
    required this.assertTimeoutMs,
    required this.expectedText,
    required this.expectedResult,
    this.deviceId,
  });

  final String platform;
  final String? deviceId;
  final String outputDir;
  final int sessionPort;
  final int launchTimeoutSeconds;
  final int assertTimeoutMs;
  final String expectedText;
  final String expectedResult;

  static _Options parse(List<String> args) {
    String? platform;
    String? deviceId;
    var outputDir = '.dart_tool/flutter_cockpit/ci';
    var sessionPort = 57331;
    var launchTimeoutSeconds = 900;
    var assertTimeoutMs = 30000;
    var expectedText = 'Welcome to FJS';
    var expectedResult = 'Cockpit smoke result: 42';

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
        case '--expected-result':
          expectedResult = readValue();
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
      expectedResult: expectedResult,
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
  --expected-result <text>         Defaults to "Cockpit smoke result: 42".
''');
  }
}
