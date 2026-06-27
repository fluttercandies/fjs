import 'package:flutter/material.dart';
import 'package:flutter_cockpit/flutter_cockpit_flutter.dart';
import 'package:fjs_example/app/bootstrap.dart';

Future<void> main() async {
  const enableDebugDiagnostics = bool.fromEnvironment(
    'FLUTTER_COCKPIT_ENABLE_DEBUG_DIAGNOSTICS',
  );
  const enableTapFeedback = bool.fromEnvironment(
    'FLUTTER_COCKPIT_ENABLE_TAP_FEEDBACK',
  );
  final config = FlutterCockpitConfig.production(
    initialRouteName: '/',
    remoteSession: CockpitRemoteSessionConfiguration.resolveFromEnvironment(
      fallback: const CockpitRemoteSessionConfiguration(
        enabled: true,
        host: '127.0.0.1',
        port: 57331,
      ),
    ),
    diagnostics: const CockpitDiagnosticsConfig(
      enableRebuildTracking: enableDebugDiagnostics,
      enableTapFeedback: enableTapFeedback,
    ),
  );

  FlutterCockpit.ensureInitialized(config);

  try {
    final app = await buildFjsExampleApp(
      navigatorObservers: <NavigatorObserver>[FlutterCockpit.navigatorObserver],
      initialCode: '21 + 21',
      showSmokeResult: true,
    );
    runApp(FlutterCockpitApp(config: config, child: app));
  } catch (error, stackTrace) {
    runApp(
      FlutterCockpitApp(
        config: config,
        child: buildInitializationFailureApp(error, stackTrace),
      ),
    );
  }
}
