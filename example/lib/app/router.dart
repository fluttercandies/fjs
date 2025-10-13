import 'package:flutter/material.dart';
import '../screens/playground_screen.dart';
import '../screens/js_actions_test_screen.dart';
import '../app/app.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
        );
      case '/playground':
        return MaterialPageRoute(
          builder: (_) => const PlaygroundScreen(),
        );
      case '/js-actions-test':
        return MaterialPageRoute(
          builder: (_) => const JsActionsTestScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
        );
    }
  }
}
