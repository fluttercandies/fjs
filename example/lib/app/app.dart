import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'theme.dart';
import 'home_screen.dart';
import '../services/fjs_service.dart';
import '../services/js_actions_service.dart';
import '../services/js_examples_service.dart';
import '../services/storage_service.dart';

class FjsExampleApp extends StatelessWidget {
  const FjsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FjsService()),
        ChangeNotifierProvider(create: (_) => JsActionsService()),
        ChangeNotifierProvider(create: (_) => JsExamplesService()),
        ChangeNotifierProvider(create: (_) => StorageService()),
      ],
      child: Consumer<StorageService>(
        builder: (context, storageService, child) {
          return MaterialApp(
            title: 'FJS - JavaScript Runtime',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: storageService.themeMode,
            home: const HomeScreen(),
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
