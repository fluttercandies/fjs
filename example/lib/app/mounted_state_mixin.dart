import 'package:flutter/widgets.dart';

mixin MountedStateMixin<T extends StatefulWidget> on State<T> {
  void setStateIfMounted(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }
}
