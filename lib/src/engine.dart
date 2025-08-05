import 'dart:async';

import '../fjs.dart';
import 'frb/api/js.dart';

class JsError implements Exception {
  JsError(this.message);

  final String message;

  @override
  String toString() {
    return 'FjsError: $message';
  }
}

class JsEngine {
  JsEngine._(this._core);

  factory JsEngine(JsAsyncContext context) {
    return JsEngine._(JsEngineCore(context: context));
  }

  final JsEngineCore _core;
  final Map<int, Completer<JsValue>> _map = {};
  final Set<String> _enabledBuiltinModules = {};
  int _id = 0;
  bool _initialized = false;

  int get _nextId => ++_id;

  Future<void> dispose() {
    return _core.dispose().whenComplete(() {
      _map.clear();
      _enabledBuiltinModules.clear();
    });
  }

  bool get disposed => _core.disposed;

  bool get running => _core.running;

  bool get initialized => _initialized;

  Set<String> get enabledBuiltinModules => _enabledBuiltinModules;

  Future<void> init({
    FutureOr<JsValue?> Function(JsValue)? bridgeCall,
  }) {
    if (_initialized) {
      return Future.error(
        JsError('JsEngine is already initialized.'),
      );
    }
    _initialized = true;
    final completer = Completer();
    _core.start(
      bridge: (v) {
        return v.when(
          initialized: () {
            completer.complete();
            return const JsCallbackResult.initialized();
          },
          handler: (r) {
            final id = r.id;
            final res = r.result;
            final completer = _map[id];
            if (completer != null) {
              if (res.isErr) {
                completer.completeError(JsError(res.err));
              } else {
                completer.complete(res.ok);
              }
            }
            return const JsCallbackResult.handler();
          },
          bridge: (v) async {
            if (bridgeCall != null) {
              try {
                final jsValue = await bridgeCall(v);
                return JsCallbackResult.bridge(
                  JsResult.ok(jsValue ?? const JsValue.none()),
                );
              } catch (e) {
                return JsCallbackResult.bridge(JsResult.err(
                  'Error in bridge call: ${e.toString()}',
                ));
              }
            } else {
              return const JsCallbackResult.bridge(JsResult.err(
                'No bridge call function provided.',
              ));
            }
          },
        );
      },
    );
    return completer.future
        .timeout(const Duration(milliseconds: 500))
        .catchError((e) {
      if (!_core.disposed) {
        dispose();
      }
      _initialized = false;
    });
  }

  Future<JsValue> _exec(int id, JsAction action, {Duration? timeout}) async {
    if (!_initialized) {
      return Future.error(JsError('JsEngine is not initialized.'));
    }
    if (_core.disposed) {
      return Future.error(JsError('JsEngine is disposed.'));
    }
    final completer = Completer<JsValue>();
    _map[id] = completer;
    _core.exec(action: action).catchError((e) {
      _map.remove(id);
      completer.completeError(e);
    });
    final future =
        timeout == null ? completer.future : completer.future.timeout(timeout);
    return future.whenComplete(() {
      _map.remove(id);
    });
  }

  Future<JsValue> eval(
    JsCode source, {
    JsEvalOptions? options,
    Duration? timeout,
  }) {
    final nextId = _nextId;
    return _exec(
      nextId,
      JsAction.eval(id: nextId, source: source, options: options),
      timeout: timeout,
    );
  }

  Future<JsValue> enableBuiltinModule(
    JsBuiltinOptions options, {
    Duration? timeout,
  }) {
    final nextId = _nextId;
    final enableModules = options.enabledModules.where((module) {
      if (_enabledBuiltinModules.contains(module)) {
        return false;
      }
      _enabledBuiltinModules.add(module);
      return true;
    }).toSet();

    return _exec(
      nextId,
      JsAction.enableBuiltinModule(
        id: nextId,
        builtinOptions: JsBuiltinOptions.from(enableModules),
      ),
      timeout: timeout,
    );
  }

  Future<JsValue> importModule(String specifier, {Duration? timeout}) {
    final nextId = _nextId;
    return _exec(
      nextId,
      JsAction.importModule(id: nextId, specifier: specifier),
      timeout: timeout,
    );
  }

  Future<JsValue> evaluateModule(JsModule module, {Duration? timeout}) {
    final nextId = _nextId;
    return _exec(
      nextId,
      JsAction.evaluateModule(id: nextId, module: module),
      timeout: timeout,
    );
  }

  Future<JsValue> declareModule(JsModule module, {Duration? timeout}) {
    final nextId = _nextId;
    return _exec(
      nextId,
      JsAction.declareModule(id: nextId, module: module),
      timeout: timeout,
    );
  }
}
