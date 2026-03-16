import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'theme.dart';
import 'home_screen.dart';
import '../services/fjs_service.dart';
import '../services/js_examples_service.dart';
import '../services/storage_service.dart';

class FjsExampleApp extends StatefulWidget {
  final StorageService storageService;
  final FjsService fjsService;
  final JsExamplesService jsExamplesService;

  const FjsExampleApp({
    super.key,
    required this.storageService,
    required this.fjsService,
    required this.jsExamplesService,
  });

  @override
  State<FjsExampleApp> createState() => _FjsExampleAppState();
}

class _FjsExampleAppState extends State<FjsExampleApp> {
  @override
  void dispose() {
    widget.jsExamplesService.dispose();
    widget.fjsService.dispose();
    widget.storageService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.storageService),
        ChangeNotifierProvider.value(value: widget.fjsService),
        ChangeNotifierProvider.value(value: widget.jsExamplesService),
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
