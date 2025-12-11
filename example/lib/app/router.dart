import 'package:flutter/material.dart';

import '../screens/api_overview_screen.dart';
import '../screens/engine_api_screen.dart';
import '../screens/error_api_screen.dart';
import '../screens/example_screen.dart';
import '../screens/js_actions_test_screen.dart';
import '../screens/playground_screen.dart';
import '../screens/runtime_api_screen.dart';
import '../screens/source_api_screen.dart';
import '../screens/value_api_screen.dart';
import 'home_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      case '/playground':
        return MaterialPageRoute(
          builder: (_) => const PlaygroundScreen(),
        );
      case '/js-actions-test':
        return MaterialPageRoute(
          builder: (_) => const JsActionsTestScreen(),
        );
      case '/api':
        return MaterialPageRoute(
          builder: (_) => const ApiOverviewScreen(),
        );
      case '/api/engine':
        return MaterialPageRoute(
          builder: (_) => const EngineApiScreen(),
        );
      case '/api/runtime':
        return MaterialPageRoute(
          builder: (_) => const RuntimeApiScreen(),
        );
      case '/api/value':
        return MaterialPageRoute(
          builder: (_) => const ValueApiScreen(),
        );
      case '/api/error':
        return MaterialPageRoute(
          builder: (_) => const ErrorApiScreen(),
        );
      case '/api/source':
        return MaterialPageRoute(
          builder: (_) => const SourceApiScreen(),
        );
      case '/example':
        return MaterialPageRoute(
          builder: (_) => const ExampleScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
    }
  }
}
