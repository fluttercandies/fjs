// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'engine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JsAction {
  int get id;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsActionCopyWith<JsAction> get copyWith =>
      _$JsActionCopyWithImpl<JsAction>(this as JsAction, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsAction &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @override
  String toString() {
    return 'JsAction(id: $id)';
  }
}

/// @nodoc
abstract mixin class $JsActionCopyWith<$Res> {
  factory $JsActionCopyWith(JsAction value, $Res Function(JsAction) _then) =
      _$JsActionCopyWithImpl;
  @useResult
  $Res call({int id});
}

/// @nodoc
class _$JsActionCopyWithImpl<$Res> implements $JsActionCopyWith<$Res> {
  _$JsActionCopyWithImpl(this._self, this._then);

  final JsAction _self;
  final $Res Function(JsAction) _then;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [JsAction].
extension JsActionPatterns on JsAction {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(JsAction_Eval value)? eval,
    TResult Function(JsAction_DeclareNewModule value)? declareNewModule,
    TResult Function(JsAction_DeclareNewModules value)? declareNewModules,
    TResult Function(JsAction_ClearNewModules value)? clearNewModules,
    TResult Function(JsAction_EvaluateModule value)? evaluateModule,
    TResult Function(JsAction_GetDeclaredModules value)? getDeclaredModules,
    TResult Function(JsAction_IsModuleDeclared value)? isModuleDeclared,
    TResult Function(JsAction_CallFunction value)? callFunction,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsAction_Eval() when eval != null:
        return eval(_that);
      case JsAction_DeclareNewModule() when declareNewModule != null:
        return declareNewModule(_that);
      case JsAction_DeclareNewModules() when declareNewModules != null:
        return declareNewModules(_that);
      case JsAction_ClearNewModules() when clearNewModules != null:
        return clearNewModules(_that);
      case JsAction_EvaluateModule() when evaluateModule != null:
        return evaluateModule(_that);
      case JsAction_GetDeclaredModules() when getDeclaredModules != null:
        return getDeclaredModules(_that);
      case JsAction_IsModuleDeclared() when isModuleDeclared != null:
        return isModuleDeclared(_that);
      case JsAction_CallFunction() when callFunction != null:
        return callFunction(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(JsAction_Eval value) eval,
    required TResult Function(JsAction_DeclareNewModule value) declareNewModule,
    required TResult Function(JsAction_DeclareNewModules value)
        declareNewModules,
    required TResult Function(JsAction_ClearNewModules value) clearNewModules,
    required TResult Function(JsAction_EvaluateModule value) evaluateModule,
    required TResult Function(JsAction_GetDeclaredModules value)
        getDeclaredModules,
    required TResult Function(JsAction_IsModuleDeclared value) isModuleDeclared,
    required TResult Function(JsAction_CallFunction value) callFunction,
  }) {
    final _that = this;
    switch (_that) {
      case JsAction_Eval():
        return eval(_that);
      case JsAction_DeclareNewModule():
        return declareNewModule(_that);
      case JsAction_DeclareNewModules():
        return declareNewModules(_that);
      case JsAction_ClearNewModules():
        return clearNewModules(_that);
      case JsAction_EvaluateModule():
        return evaluateModule(_that);
      case JsAction_GetDeclaredModules():
        return getDeclaredModules(_that);
      case JsAction_IsModuleDeclared():
        return isModuleDeclared(_that);
      case JsAction_CallFunction():
        return callFunction(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(JsAction_Eval value)? eval,
    TResult? Function(JsAction_DeclareNewModule value)? declareNewModule,
    TResult? Function(JsAction_DeclareNewModules value)? declareNewModules,
    TResult? Function(JsAction_ClearNewModules value)? clearNewModules,
    TResult? Function(JsAction_EvaluateModule value)? evaluateModule,
    TResult? Function(JsAction_GetDeclaredModules value)? getDeclaredModules,
    TResult? Function(JsAction_IsModuleDeclared value)? isModuleDeclared,
    TResult? Function(JsAction_CallFunction value)? callFunction,
  }) {
    final _that = this;
    switch (_that) {
      case JsAction_Eval() when eval != null:
        return eval(_that);
      case JsAction_DeclareNewModule() when declareNewModule != null:
        return declareNewModule(_that);
      case JsAction_DeclareNewModules() when declareNewModules != null:
        return declareNewModules(_that);
      case JsAction_ClearNewModules() when clearNewModules != null:
        return clearNewModules(_that);
      case JsAction_EvaluateModule() when evaluateModule != null:
        return evaluateModule(_that);
      case JsAction_GetDeclaredModules() when getDeclaredModules != null:
        return getDeclaredModules(_that);
      case JsAction_IsModuleDeclared() when isModuleDeclared != null:
        return isModuleDeclared(_that);
      case JsAction_CallFunction() when callFunction != null:
        return callFunction(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int id, JsCode source, JsEvalOptions? options)? eval,
    TResult Function(int id, JsModule module)? declareNewModule,
    TResult Function(int id, List<JsModule> modules)? declareNewModules,
    TResult Function(int id)? clearNewModules,
    TResult Function(int id, JsModule module)? evaluateModule,
    TResult Function(int id)? getDeclaredModules,
    TResult Function(int id, String moduleName)? isModuleDeclared,
    TResult Function(
            int id, String module, String method, List<JsValue>? params)?
        callFunction,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsAction_Eval() when eval != null:
        return eval(_that.id, _that.source, _that.options);
      case JsAction_DeclareNewModule() when declareNewModule != null:
        return declareNewModule(_that.id, _that.module);
      case JsAction_DeclareNewModules() when declareNewModules != null:
        return declareNewModules(_that.id, _that.modules);
      case JsAction_ClearNewModules() when clearNewModules != null:
        return clearNewModules(_that.id);
      case JsAction_EvaluateModule() when evaluateModule != null:
        return evaluateModule(_that.id, _that.module);
      case JsAction_GetDeclaredModules() when getDeclaredModules != null:
        return getDeclaredModules(_that.id);
      case JsAction_IsModuleDeclared() when isModuleDeclared != null:
        return isModuleDeclared(_that.id, _that.moduleName);
      case JsAction_CallFunction() when callFunction != null:
        return callFunction(_that.id, _that.module, _that.method, _that.params);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int id, JsCode source, JsEvalOptions? options)
        eval,
    required TResult Function(int id, JsModule module) declareNewModule,
    required TResult Function(int id, List<JsModule> modules) declareNewModules,
    required TResult Function(int id) clearNewModules,
    required TResult Function(int id, JsModule module) evaluateModule,
    required TResult Function(int id) getDeclaredModules,
    required TResult Function(int id, String moduleName) isModuleDeclared,
    required TResult Function(
            int id, String module, String method, List<JsValue>? params)
        callFunction,
  }) {
    final _that = this;
    switch (_that) {
      case JsAction_Eval():
        return eval(_that.id, _that.source, _that.options);
      case JsAction_DeclareNewModule():
        return declareNewModule(_that.id, _that.module);
      case JsAction_DeclareNewModules():
        return declareNewModules(_that.id, _that.modules);
      case JsAction_ClearNewModules():
        return clearNewModules(_that.id);
      case JsAction_EvaluateModule():
        return evaluateModule(_that.id, _that.module);
      case JsAction_GetDeclaredModules():
        return getDeclaredModules(_that.id);
      case JsAction_IsModuleDeclared():
        return isModuleDeclared(_that.id, _that.moduleName);
      case JsAction_CallFunction():
        return callFunction(_that.id, _that.module, _that.method, _that.params);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int id, JsCode source, JsEvalOptions? options)? eval,
    TResult? Function(int id, JsModule module)? declareNewModule,
    TResult? Function(int id, List<JsModule> modules)? declareNewModules,
    TResult? Function(int id)? clearNewModules,
    TResult? Function(int id, JsModule module)? evaluateModule,
    TResult? Function(int id)? getDeclaredModules,
    TResult? Function(int id, String moduleName)? isModuleDeclared,
    TResult? Function(
            int id, String module, String method, List<JsValue>? params)?
        callFunction,
  }) {
    final _that = this;
    switch (_that) {
      case JsAction_Eval() when eval != null:
        return eval(_that.id, _that.source, _that.options);
      case JsAction_DeclareNewModule() when declareNewModule != null:
        return declareNewModule(_that.id, _that.module);
      case JsAction_DeclareNewModules() when declareNewModules != null:
        return declareNewModules(_that.id, _that.modules);
      case JsAction_ClearNewModules() when clearNewModules != null:
        return clearNewModules(_that.id);
      case JsAction_EvaluateModule() when evaluateModule != null:
        return evaluateModule(_that.id, _that.module);
      case JsAction_GetDeclaredModules() when getDeclaredModules != null:
        return getDeclaredModules(_that.id);
      case JsAction_IsModuleDeclared() when isModuleDeclared != null:
        return isModuleDeclared(_that.id, _that.moduleName);
      case JsAction_CallFunction() when callFunction != null:
        return callFunction(_that.id, _that.module, _that.method, _that.params);
      case _:
        return null;
    }
  }
}

/// @nodoc

class JsAction_Eval extends JsAction {
  const JsAction_Eval({required this.id, required this.source, this.options})
      : super._();

  @override
  final int id;
  final JsCode source;
  final JsEvalOptions? options;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsAction_EvalCopyWith<JsAction_Eval> get copyWith =>
      _$JsAction_EvalCopyWithImpl<JsAction_Eval>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsAction_Eval &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.options, options) || other.options == options));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, source, options);

  @override
  String toString() {
    return 'JsAction.eval(id: $id, source: $source, options: $options)';
  }
}

/// @nodoc
abstract mixin class $JsAction_EvalCopyWith<$Res>
    implements $JsActionCopyWith<$Res> {
  factory $JsAction_EvalCopyWith(
          JsAction_Eval value, $Res Function(JsAction_Eval) _then) =
      _$JsAction_EvalCopyWithImpl;
  @override
  @useResult
  $Res call({int id, JsCode source, JsEvalOptions? options});

  $JsCodeCopyWith<$Res> get source;
  $JsEvalOptionsCopyWith<$Res>? get options;
}

/// @nodoc
class _$JsAction_EvalCopyWithImpl<$Res>
    implements $JsAction_EvalCopyWith<$Res> {
  _$JsAction_EvalCopyWithImpl(this._self, this._then);

  final JsAction_Eval _self;
  final $Res Function(JsAction_Eval) _then;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? source = null,
    Object? options = freezed,
  }) {
    return _then(JsAction_Eval(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      source: null == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as JsCode,
      options: freezed == options
          ? _self.options
          : options // ignore: cast_nullable_to_non_nullable
              as JsEvalOptions?,
    ));
  }

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JsCodeCopyWith<$Res> get source {
    return $JsCodeCopyWith<$Res>(_self.source, (value) {
      return _then(_self.copyWith(source: value));
    });
  }

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JsEvalOptionsCopyWith<$Res>? get options {
    if (_self.options == null) {
      return null;
    }

    return $JsEvalOptionsCopyWith<$Res>(_self.options!, (value) {
      return _then(_self.copyWith(options: value));
    });
  }
}

/// @nodoc

class JsAction_DeclareNewModule extends JsAction {
  const JsAction_DeclareNewModule({required this.id, required this.module})
      : super._();

  @override
  final int id;
  final JsModule module;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsAction_DeclareNewModuleCopyWith<JsAction_DeclareNewModule> get copyWith =>
      _$JsAction_DeclareNewModuleCopyWithImpl<JsAction_DeclareNewModule>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsAction_DeclareNewModule &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.module, module) || other.module == module));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, module);

  @override
  String toString() {
    return 'JsAction.declareNewModule(id: $id, module: $module)';
  }
}

/// @nodoc
abstract mixin class $JsAction_DeclareNewModuleCopyWith<$Res>
    implements $JsActionCopyWith<$Res> {
  factory $JsAction_DeclareNewModuleCopyWith(JsAction_DeclareNewModule value,
          $Res Function(JsAction_DeclareNewModule) _then) =
      _$JsAction_DeclareNewModuleCopyWithImpl;
  @override
  @useResult
  $Res call({int id, JsModule module});

  $JsModuleCopyWith<$Res> get module;
}

/// @nodoc
class _$JsAction_DeclareNewModuleCopyWithImpl<$Res>
    implements $JsAction_DeclareNewModuleCopyWith<$Res> {
  _$JsAction_DeclareNewModuleCopyWithImpl(this._self, this._then);

  final JsAction_DeclareNewModule _self;
  final $Res Function(JsAction_DeclareNewModule) _then;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? module = null,
  }) {
    return _then(JsAction_DeclareNewModule(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      module: null == module
          ? _self.module
          : module // ignore: cast_nullable_to_non_nullable
              as JsModule,
    ));
  }

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JsModuleCopyWith<$Res> get module {
    return $JsModuleCopyWith<$Res>(_self.module, (value) {
      return _then(_self.copyWith(module: value));
    });
  }
}

/// @nodoc

class JsAction_DeclareNewModules extends JsAction {
  const JsAction_DeclareNewModules(
      {required this.id, required final List<JsModule> modules})
      : _modules = modules,
        super._();

  @override
  final int id;
  final List<JsModule> _modules;
  List<JsModule> get modules {
    if (_modules is EqualUnmodifiableListView) return _modules;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modules);
  }

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsAction_DeclareNewModulesCopyWith<JsAction_DeclareNewModules>
      get copyWith =>
          _$JsAction_DeclareNewModulesCopyWithImpl<JsAction_DeclareNewModules>(
              this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsAction_DeclareNewModules &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._modules, _modules));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, const DeepCollectionEquality().hash(_modules));

  @override
  String toString() {
    return 'JsAction.declareNewModules(id: $id, modules: $modules)';
  }
}

/// @nodoc
abstract mixin class $JsAction_DeclareNewModulesCopyWith<$Res>
    implements $JsActionCopyWith<$Res> {
  factory $JsAction_DeclareNewModulesCopyWith(JsAction_DeclareNewModules value,
          $Res Function(JsAction_DeclareNewModules) _then) =
      _$JsAction_DeclareNewModulesCopyWithImpl;
  @override
  @useResult
  $Res call({int id, List<JsModule> modules});
}

/// @nodoc
class _$JsAction_DeclareNewModulesCopyWithImpl<$Res>
    implements $JsAction_DeclareNewModulesCopyWith<$Res> {
  _$JsAction_DeclareNewModulesCopyWithImpl(this._self, this._then);

  final JsAction_DeclareNewModules _self;
  final $Res Function(JsAction_DeclareNewModules) _then;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? modules = null,
  }) {
    return _then(JsAction_DeclareNewModules(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      modules: null == modules
          ? _self._modules
          : modules // ignore: cast_nullable_to_non_nullable
              as List<JsModule>,
    ));
  }
}

/// @nodoc

class JsAction_ClearNewModules extends JsAction {
  const JsAction_ClearNewModules({required this.id}) : super._();

  @override
  final int id;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsAction_ClearNewModulesCopyWith<JsAction_ClearNewModules> get copyWith =>
      _$JsAction_ClearNewModulesCopyWithImpl<JsAction_ClearNewModules>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsAction_ClearNewModules &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @override
  String toString() {
    return 'JsAction.clearNewModules(id: $id)';
  }
}

/// @nodoc
abstract mixin class $JsAction_ClearNewModulesCopyWith<$Res>
    implements $JsActionCopyWith<$Res> {
  factory $JsAction_ClearNewModulesCopyWith(JsAction_ClearNewModules value,
          $Res Function(JsAction_ClearNewModules) _then) =
      _$JsAction_ClearNewModulesCopyWithImpl;
  @override
  @useResult
  $Res call({int id});
}

/// @nodoc
class _$JsAction_ClearNewModulesCopyWithImpl<$Res>
    implements $JsAction_ClearNewModulesCopyWith<$Res> {
  _$JsAction_ClearNewModulesCopyWithImpl(this._self, this._then);

  final JsAction_ClearNewModules _self;
  final $Res Function(JsAction_ClearNewModules) _then;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
  }) {
    return _then(JsAction_ClearNewModules(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class JsAction_EvaluateModule extends JsAction {
  const JsAction_EvaluateModule({required this.id, required this.module})
      : super._();

  @override
  final int id;
  final JsModule module;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsAction_EvaluateModuleCopyWith<JsAction_EvaluateModule> get copyWith =>
      _$JsAction_EvaluateModuleCopyWithImpl<JsAction_EvaluateModule>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsAction_EvaluateModule &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.module, module) || other.module == module));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, module);

  @override
  String toString() {
    return 'JsAction.evaluateModule(id: $id, module: $module)';
  }
}

/// @nodoc
abstract mixin class $JsAction_EvaluateModuleCopyWith<$Res>
    implements $JsActionCopyWith<$Res> {
  factory $JsAction_EvaluateModuleCopyWith(JsAction_EvaluateModule value,
          $Res Function(JsAction_EvaluateModule) _then) =
      _$JsAction_EvaluateModuleCopyWithImpl;
  @override
  @useResult
  $Res call({int id, JsModule module});

  $JsModuleCopyWith<$Res> get module;
}

/// @nodoc
class _$JsAction_EvaluateModuleCopyWithImpl<$Res>
    implements $JsAction_EvaluateModuleCopyWith<$Res> {
  _$JsAction_EvaluateModuleCopyWithImpl(this._self, this._then);

  final JsAction_EvaluateModule _self;
  final $Res Function(JsAction_EvaluateModule) _then;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? module = null,
  }) {
    return _then(JsAction_EvaluateModule(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      module: null == module
          ? _self.module
          : module // ignore: cast_nullable_to_non_nullable
              as JsModule,
    ));
  }

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JsModuleCopyWith<$Res> get module {
    return $JsModuleCopyWith<$Res>(_self.module, (value) {
      return _then(_self.copyWith(module: value));
    });
  }
}

/// @nodoc

class JsAction_GetDeclaredModules extends JsAction {
  const JsAction_GetDeclaredModules({required this.id}) : super._();

  @override
  final int id;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsAction_GetDeclaredModulesCopyWith<JsAction_GetDeclaredModules>
      get copyWith => _$JsAction_GetDeclaredModulesCopyWithImpl<
          JsAction_GetDeclaredModules>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsAction_GetDeclaredModules &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @override
  String toString() {
    return 'JsAction.getDeclaredModules(id: $id)';
  }
}

/// @nodoc
abstract mixin class $JsAction_GetDeclaredModulesCopyWith<$Res>
    implements $JsActionCopyWith<$Res> {
  factory $JsAction_GetDeclaredModulesCopyWith(
          JsAction_GetDeclaredModules value,
          $Res Function(JsAction_GetDeclaredModules) _then) =
      _$JsAction_GetDeclaredModulesCopyWithImpl;
  @override
  @useResult
  $Res call({int id});
}

/// @nodoc
class _$JsAction_GetDeclaredModulesCopyWithImpl<$Res>
    implements $JsAction_GetDeclaredModulesCopyWith<$Res> {
  _$JsAction_GetDeclaredModulesCopyWithImpl(this._self, this._then);

  final JsAction_GetDeclaredModules _self;
  final $Res Function(JsAction_GetDeclaredModules) _then;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
  }) {
    return _then(JsAction_GetDeclaredModules(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class JsAction_IsModuleDeclared extends JsAction {
  const JsAction_IsModuleDeclared({required this.id, required this.moduleName})
      : super._();

  @override
  final int id;
  final String moduleName;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsAction_IsModuleDeclaredCopyWith<JsAction_IsModuleDeclared> get copyWith =>
      _$JsAction_IsModuleDeclaredCopyWithImpl<JsAction_IsModuleDeclared>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsAction_IsModuleDeclared &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.moduleName, moduleName) ||
                other.moduleName == moduleName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, moduleName);

  @override
  String toString() {
    return 'JsAction.isModuleDeclared(id: $id, moduleName: $moduleName)';
  }
}

/// @nodoc
abstract mixin class $JsAction_IsModuleDeclaredCopyWith<$Res>
    implements $JsActionCopyWith<$Res> {
  factory $JsAction_IsModuleDeclaredCopyWith(JsAction_IsModuleDeclared value,
          $Res Function(JsAction_IsModuleDeclared) _then) =
      _$JsAction_IsModuleDeclaredCopyWithImpl;
  @override
  @useResult
  $Res call({int id, String moduleName});
}

/// @nodoc
class _$JsAction_IsModuleDeclaredCopyWithImpl<$Res>
    implements $JsAction_IsModuleDeclaredCopyWith<$Res> {
  _$JsAction_IsModuleDeclaredCopyWithImpl(this._self, this._then);

  final JsAction_IsModuleDeclared _self;
  final $Res Function(JsAction_IsModuleDeclared) _then;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? moduleName = null,
  }) {
    return _then(JsAction_IsModuleDeclared(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      moduleName: null == moduleName
          ? _self.moduleName
          : moduleName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsAction_CallFunction extends JsAction {
  const JsAction_CallFunction(
      {required this.id,
      required this.module,
      required this.method,
      final List<JsValue>? params})
      : _params = params,
        super._();

  @override
  final int id;
  final String module;
  final String method;
  final List<JsValue>? _params;
  List<JsValue>? get params {
    final value = _params;
    if (value == null) return null;
    if (_params is EqualUnmodifiableListView) return _params;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsAction_CallFunctionCopyWith<JsAction_CallFunction> get copyWith =>
      _$JsAction_CallFunctionCopyWithImpl<JsAction_CallFunction>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsAction_CallFunction &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.module, module) || other.module == module) &&
            (identical(other.method, method) || other.method == method) &&
            const DeepCollectionEquality().equals(other._params, _params));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, module, method,
      const DeepCollectionEquality().hash(_params));

  @override
  String toString() {
    return 'JsAction.callFunction(id: $id, module: $module, method: $method, params: $params)';
  }
}

/// @nodoc
abstract mixin class $JsAction_CallFunctionCopyWith<$Res>
    implements $JsActionCopyWith<$Res> {
  factory $JsAction_CallFunctionCopyWith(JsAction_CallFunction value,
          $Res Function(JsAction_CallFunction) _then) =
      _$JsAction_CallFunctionCopyWithImpl;
  @override
  @useResult
  $Res call({int id, String module, String method, List<JsValue>? params});
}

/// @nodoc
class _$JsAction_CallFunctionCopyWithImpl<$Res>
    implements $JsAction_CallFunctionCopyWith<$Res> {
  _$JsAction_CallFunctionCopyWithImpl(this._self, this._then);

  final JsAction_CallFunction _self;
  final $Res Function(JsAction_CallFunction) _then;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? module = null,
    Object? method = null,
    Object? params = freezed,
  }) {
    return _then(JsAction_CallFunction(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      module: null == module
          ? _self.module
          : module // ignore: cast_nullable_to_non_nullable
              as String,
      method: null == method
          ? _self.method
          : method // ignore: cast_nullable_to_non_nullable
              as String,
      params: freezed == params
          ? _self._params
          : params // ignore: cast_nullable_to_non_nullable
              as List<JsValue>?,
    ));
  }
}

/// @nodoc
mixin _$JsActionResult {
  int get id;
  JsResult get result;

  /// Create a copy of JsActionResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsActionResultCopyWith<JsActionResult> get copyWith =>
      _$JsActionResultCopyWithImpl<JsActionResult>(
          this as JsActionResult, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsActionResult &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.result, result) || other.result == result));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, result);

  @override
  String toString() {
    return 'JsActionResult(id: $id, result: $result)';
  }
}

/// @nodoc
abstract mixin class $JsActionResultCopyWith<$Res> {
  factory $JsActionResultCopyWith(
          JsActionResult value, $Res Function(JsActionResult) _then) =
      _$JsActionResultCopyWithImpl;
  @useResult
  $Res call({int id, JsResult result});

  $JsResultCopyWith<$Res> get result;
}

/// @nodoc
class _$JsActionResultCopyWithImpl<$Res>
    implements $JsActionResultCopyWith<$Res> {
  _$JsActionResultCopyWithImpl(this._self, this._then);

  final JsActionResult _self;
  final $Res Function(JsActionResult) _then;

  /// Create a copy of JsActionResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? result = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      result: null == result
          ? _self.result
          : result // ignore: cast_nullable_to_non_nullable
              as JsResult,
    ));
  }

  /// Create a copy of JsActionResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JsResultCopyWith<$Res> get result {
    return $JsResultCopyWith<$Res>(_self.result, (value) {
      return _then(_self.copyWith(result: value));
    });
  }
}

/// Adds pattern-matching-related methods to [JsActionResult].
extension JsActionResultPatterns on JsActionResult {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_JsActionResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JsActionResult() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_JsActionResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JsActionResult():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_JsActionResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JsActionResult() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(int id, JsResult result)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JsActionResult() when $default != null:
        return $default(_that.id, _that.result);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(int id, JsResult result) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JsActionResult():
        return $default(_that.id, _that.result);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(int id, JsResult result)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JsActionResult() when $default != null:
        return $default(_that.id, _that.result);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _JsActionResult implements JsActionResult {
  const _JsActionResult({required this.id, required this.result});

  @override
  final int id;
  @override
  final JsResult result;

  /// Create a copy of JsActionResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$JsActionResultCopyWith<_JsActionResult> get copyWith =>
      __$JsActionResultCopyWithImpl<_JsActionResult>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _JsActionResult &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.result, result) || other.result == result));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, result);

  @override
  String toString() {
    return 'JsActionResult(id: $id, result: $result)';
  }
}

/// @nodoc
abstract mixin class _$JsActionResultCopyWith<$Res>
    implements $JsActionResultCopyWith<$Res> {
  factory _$JsActionResultCopyWith(
          _JsActionResult value, $Res Function(_JsActionResult) _then) =
      __$JsActionResultCopyWithImpl;
  @override
  @useResult
  $Res call({int id, JsResult result});

  @override
  $JsResultCopyWith<$Res> get result;
}

/// @nodoc
class __$JsActionResultCopyWithImpl<$Res>
    implements _$JsActionResultCopyWith<$Res> {
  __$JsActionResultCopyWithImpl(this._self, this._then);

  final _JsActionResult _self;
  final $Res Function(_JsActionResult) _then;

  /// Create a copy of JsActionResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? result = null,
  }) {
    return _then(_JsActionResult(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      result: null == result
          ? _self.result
          : result // ignore: cast_nullable_to_non_nullable
              as JsResult,
    ));
  }

  /// Create a copy of JsActionResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JsResultCopyWith<$Res> get result {
    return $JsResultCopyWith<$Res>(_self.result, (value) {
      return _then(_self.copyWith(result: value));
    });
  }
}

/// @nodoc
mixin _$JsCallback {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is JsCallback);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'JsCallback()';
  }
}

/// @nodoc
class $JsCallbackCopyWith<$Res> {
  $JsCallbackCopyWith(JsCallback _, $Res Function(JsCallback) __);
}

/// Adds pattern-matching-related methods to [JsCallback].
extension JsCallbackPatterns on JsCallback {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(JsCallback_Initialized value)? initialized,
    TResult Function(JsCallback_Handler value)? handler,
    TResult Function(JsCallback_Bridge value)? bridge,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsCallback_Initialized() when initialized != null:
        return initialized(_that);
      case JsCallback_Handler() when handler != null:
        return handler(_that);
      case JsCallback_Bridge() when bridge != null:
        return bridge(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(JsCallback_Initialized value) initialized,
    required TResult Function(JsCallback_Handler value) handler,
    required TResult Function(JsCallback_Bridge value) bridge,
  }) {
    final _that = this;
    switch (_that) {
      case JsCallback_Initialized():
        return initialized(_that);
      case JsCallback_Handler():
        return handler(_that);
      case JsCallback_Bridge():
        return bridge(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(JsCallback_Initialized value)? initialized,
    TResult? Function(JsCallback_Handler value)? handler,
    TResult? Function(JsCallback_Bridge value)? bridge,
  }) {
    final _that = this;
    switch (_that) {
      case JsCallback_Initialized() when initialized != null:
        return initialized(_that);
      case JsCallback_Handler() when handler != null:
        return handler(_that);
      case JsCallback_Bridge() when bridge != null:
        return bridge(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialized,
    TResult Function(JsActionResult field0)? handler,
    TResult Function(JsValue field0)? bridge,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsCallback_Initialized() when initialized != null:
        return initialized();
      case JsCallback_Handler() when handler != null:
        return handler(_that.field0);
      case JsCallback_Bridge() when bridge != null:
        return bridge(_that.field0);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialized,
    required TResult Function(JsActionResult field0) handler,
    required TResult Function(JsValue field0) bridge,
  }) {
    final _that = this;
    switch (_that) {
      case JsCallback_Initialized():
        return initialized();
      case JsCallback_Handler():
        return handler(_that.field0);
      case JsCallback_Bridge():
        return bridge(_that.field0);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialized,
    TResult? Function(JsActionResult field0)? handler,
    TResult? Function(JsValue field0)? bridge,
  }) {
    final _that = this;
    switch (_that) {
      case JsCallback_Initialized() when initialized != null:
        return initialized();
      case JsCallback_Handler() when handler != null:
        return handler(_that.field0);
      case JsCallback_Bridge() when bridge != null:
        return bridge(_that.field0);
      case _:
        return null;
    }
  }
}

/// @nodoc

class JsCallback_Initialized extends JsCallback {
  const JsCallback_Initialized() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is JsCallback_Initialized);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'JsCallback.initialized()';
  }
}

/// @nodoc

class JsCallback_Handler extends JsCallback {
  const JsCallback_Handler(this.field0) : super._();

  final JsActionResult field0;

  /// Create a copy of JsCallback
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsCallback_HandlerCopyWith<JsCallback_Handler> get copyWith =>
      _$JsCallback_HandlerCopyWithImpl<JsCallback_Handler>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsCallback_Handler &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsCallback.handler(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsCallback_HandlerCopyWith<$Res>
    implements $JsCallbackCopyWith<$Res> {
  factory $JsCallback_HandlerCopyWith(
          JsCallback_Handler value, $Res Function(JsCallback_Handler) _then) =
      _$JsCallback_HandlerCopyWithImpl;
  @useResult
  $Res call({JsActionResult field0});

  $JsActionResultCopyWith<$Res> get field0;
}

/// @nodoc
class _$JsCallback_HandlerCopyWithImpl<$Res>
    implements $JsCallback_HandlerCopyWith<$Res> {
  _$JsCallback_HandlerCopyWithImpl(this._self, this._then);

  final JsCallback_Handler _self;
  final $Res Function(JsCallback_Handler) _then;

  /// Create a copy of JsCallback
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsCallback_Handler(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as JsActionResult,
    ));
  }

  /// Create a copy of JsCallback
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JsActionResultCopyWith<$Res> get field0 {
    return $JsActionResultCopyWith<$Res>(_self.field0, (value) {
      return _then(_self.copyWith(field0: value));
    });
  }
}

/// @nodoc

class JsCallback_Bridge extends JsCallback {
  const JsCallback_Bridge(this.field0) : super._();

  final JsValue field0;

  /// Create a copy of JsCallback
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsCallback_BridgeCopyWith<JsCallback_Bridge> get copyWith =>
      _$JsCallback_BridgeCopyWithImpl<JsCallback_Bridge>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsCallback_Bridge &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsCallback.bridge(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsCallback_BridgeCopyWith<$Res>
    implements $JsCallbackCopyWith<$Res> {
  factory $JsCallback_BridgeCopyWith(
          JsCallback_Bridge value, $Res Function(JsCallback_Bridge) _then) =
      _$JsCallback_BridgeCopyWithImpl;
  @useResult
  $Res call({JsValue field0});

  $JsValueCopyWith<$Res> get field0;
}

/// @nodoc
class _$JsCallback_BridgeCopyWithImpl<$Res>
    implements $JsCallback_BridgeCopyWith<$Res> {
  _$JsCallback_BridgeCopyWithImpl(this._self, this._then);

  final JsCallback_Bridge _self;
  final $Res Function(JsCallback_Bridge) _then;

  /// Create a copy of JsCallback
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsCallback_Bridge(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as JsValue,
    ));
  }

  /// Create a copy of JsCallback
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JsValueCopyWith<$Res> get field0 {
    return $JsValueCopyWith<$Res>(_self.field0, (value) {
      return _then(_self.copyWith(field0: value));
    });
  }
}

/// @nodoc
mixin _$JsCallbackResult {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is JsCallbackResult);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'JsCallbackResult()';
  }
}

/// @nodoc
class $JsCallbackResultCopyWith<$Res> {
  $JsCallbackResultCopyWith(
      JsCallbackResult _, $Res Function(JsCallbackResult) __);
}

/// Adds pattern-matching-related methods to [JsCallbackResult].
extension JsCallbackResultPatterns on JsCallbackResult {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(JsCallbackResult_Initialized value)? initialized,
    TResult Function(JsCallbackResult_Handler value)? handler,
    TResult Function(JsCallbackResult_Bridge value)? bridge,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsCallbackResult_Initialized() when initialized != null:
        return initialized(_that);
      case JsCallbackResult_Handler() when handler != null:
        return handler(_that);
      case JsCallbackResult_Bridge() when bridge != null:
        return bridge(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(JsCallbackResult_Initialized value) initialized,
    required TResult Function(JsCallbackResult_Handler value) handler,
    required TResult Function(JsCallbackResult_Bridge value) bridge,
  }) {
    final _that = this;
    switch (_that) {
      case JsCallbackResult_Initialized():
        return initialized(_that);
      case JsCallbackResult_Handler():
        return handler(_that);
      case JsCallbackResult_Bridge():
        return bridge(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(JsCallbackResult_Initialized value)? initialized,
    TResult? Function(JsCallbackResult_Handler value)? handler,
    TResult? Function(JsCallbackResult_Bridge value)? bridge,
  }) {
    final _that = this;
    switch (_that) {
      case JsCallbackResult_Initialized() when initialized != null:
        return initialized(_that);
      case JsCallbackResult_Handler() when handler != null:
        return handler(_that);
      case JsCallbackResult_Bridge() when bridge != null:
        return bridge(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initialized,
    TResult Function()? handler,
    TResult Function(JsResult field0)? bridge,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsCallbackResult_Initialized() when initialized != null:
        return initialized();
      case JsCallbackResult_Handler() when handler != null:
        return handler();
      case JsCallbackResult_Bridge() when bridge != null:
        return bridge(_that.field0);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initialized,
    required TResult Function() handler,
    required TResult Function(JsResult field0) bridge,
  }) {
    final _that = this;
    switch (_that) {
      case JsCallbackResult_Initialized():
        return initialized();
      case JsCallbackResult_Handler():
        return handler();
      case JsCallbackResult_Bridge():
        return bridge(_that.field0);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initialized,
    TResult? Function()? handler,
    TResult? Function(JsResult field0)? bridge,
  }) {
    final _that = this;
    switch (_that) {
      case JsCallbackResult_Initialized() when initialized != null:
        return initialized();
      case JsCallbackResult_Handler() when handler != null:
        return handler();
      case JsCallbackResult_Bridge() when bridge != null:
        return bridge(_that.field0);
      case _:
        return null;
    }
  }
}

/// @nodoc

class JsCallbackResult_Initialized extends JsCallbackResult {
  const JsCallbackResult_Initialized() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsCallbackResult_Initialized);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'JsCallbackResult.initialized()';
  }
}

/// @nodoc

class JsCallbackResult_Handler extends JsCallbackResult {
  const JsCallbackResult_Handler() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is JsCallbackResult_Handler);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'JsCallbackResult.handler()';
  }
}

/// @nodoc

class JsCallbackResult_Bridge extends JsCallbackResult {
  const JsCallbackResult_Bridge(this.field0) : super._();

  final JsResult field0;

  /// Create a copy of JsCallbackResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsCallbackResult_BridgeCopyWith<JsCallbackResult_Bridge> get copyWith =>
      _$JsCallbackResult_BridgeCopyWithImpl<JsCallbackResult_Bridge>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsCallbackResult_Bridge &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsCallbackResult.bridge(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsCallbackResult_BridgeCopyWith<$Res>
    implements $JsCallbackResultCopyWith<$Res> {
  factory $JsCallbackResult_BridgeCopyWith(JsCallbackResult_Bridge value,
          $Res Function(JsCallbackResult_Bridge) _then) =
      _$JsCallbackResult_BridgeCopyWithImpl;
  @useResult
  $Res call({JsResult field0});

  $JsResultCopyWith<$Res> get field0;
}

/// @nodoc
class _$JsCallbackResult_BridgeCopyWithImpl<$Res>
    implements $JsCallbackResult_BridgeCopyWith<$Res> {
  _$JsCallbackResult_BridgeCopyWithImpl(this._self, this._then);

  final JsCallbackResult_Bridge _self;
  final $Res Function(JsCallbackResult_Bridge) _then;

  /// Create a copy of JsCallbackResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsCallbackResult_Bridge(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as JsResult,
    ));
  }

  /// Create a copy of JsCallbackResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JsResultCopyWith<$Res> get field0 {
    return $JsResultCopyWith<$Res>(_self.field0, (value) {
      return _then(_self.copyWith(field0: value));
    });
  }
}

// dart format on
