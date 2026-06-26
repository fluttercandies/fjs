import 'package:flutter/material.dart';

import 'app/bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    runApp(await buildFjsExampleApp());
  } catch (e, stackTrace) {
    runApp(buildInitializationFailureApp(e, stackTrace));
  }
}
