// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'js.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JsAction {
  /// Unique identifier for this action
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
      case _:
        return null;
    }
  }
}

/// @nodoc

class JsAction_Eval extends JsAction {
  const JsAction_Eval({required this.id, required this.source, this.options})
      : super._();

  /// Unique identifier for this action
  @override
  final int id;

  /// The source code to evaluate (either inline code or file path)
  final JsCode source;

  /// Optional evaluation options
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

  /// Unique identifier for this action
  @override
  final int id;

  /// The module to declare
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

  /// Unique identifier for this action
  @override
  final int id;

  /// List of modules to declare
  final List<JsModule> _modules;

  /// List of modules to declare
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

  /// Unique identifier for this action
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

  /// Unique identifier for this action
  @override
  final int id;

  /// The module to evaluate
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

  /// Unique identifier for this action
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

  /// Unique identifier for this action
  @override
  final int id;

  /// The name of the module to check
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
mixin _$JsBuiltinOptions {
  bool? get abort;
  bool? get assert_;
  bool? get asyncHooks;
  bool? get buffer;
  bool? get childProcess;
  bool? get console;
  bool? get crypto;
  bool? get dns;
  bool? get events;
  bool? get exceptions;
  bool? get fetch;
  bool? get fs;
  bool? get navigator;
  bool? get net;
  bool? get os;
  bool? get path;
  bool? get perfHooks;
  bool? get process;
  bool? get streamWeb;
  bool? get stringDecoder;
  bool? get timers;
  bool? get tty;
  bool? get url;
  bool? get util;
  bool? get zlib;
  bool? get json;

  /// Create a copy of JsBuiltinOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsBuiltinOptionsCopyWith<JsBuiltinOptions> get copyWith =>
      _$JsBuiltinOptionsCopyWithImpl<JsBuiltinOptions>(
          this as JsBuiltinOptions, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsBuiltinOptions &&
            (identical(other.abort, abort) || other.abort == abort) &&
            (identical(other.assert_, assert_) || other.assert_ == assert_) &&
            (identical(other.asyncHooks, asyncHooks) ||
                other.asyncHooks == asyncHooks) &&
            (identical(other.buffer, buffer) || other.buffer == buffer) &&
            (identical(other.childProcess, childProcess) ||
                other.childProcess == childProcess) &&
            (identical(other.console, console) || other.console == console) &&
            (identical(other.crypto, crypto) || other.crypto == crypto) &&
            (identical(other.dns, dns) || other.dns == dns) &&
            (identical(other.events, events) || other.events == events) &&
            (identical(other.exceptions, exceptions) ||
                other.exceptions == exceptions) &&
            (identical(other.fetch, fetch) || other.fetch == fetch) &&
            (identical(other.fs, fs) || other.fs == fs) &&
            (identical(other.navigator, navigator) ||
                other.navigator == navigator) &&
            (identical(other.net, net) || other.net == net) &&
            (identical(other.os, os) || other.os == os) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.perfHooks, perfHooks) ||
                other.perfHooks == perfHooks) &&
            (identical(other.process, process) || other.process == process) &&
            (identical(other.streamWeb, streamWeb) ||
                other.streamWeb == streamWeb) &&
            (identical(other.stringDecoder, stringDecoder) ||
                other.stringDecoder == stringDecoder) &&
            (identical(other.timers, timers) || other.timers == timers) &&
            (identical(other.tty, tty) || other.tty == tty) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.util, util) || other.util == util) &&
            (identical(other.zlib, zlib) || other.zlib == zlib) &&
            (identical(other.json, json) || other.json == json));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        abort,
        assert_,
        asyncHooks,
        buffer,
        childProcess,
        console,
        crypto,
        dns,
        events,
        exceptions,
        fetch,
        fs,
        navigator,
        net,
        os,
        path,
        perfHooks,
        process,
        streamWeb,
        stringDecoder,
        timers,
        tty,
        url,
        util,
        zlib,
        json
      ]);

  @override
  String toString() {
    return 'JsBuiltinOptions(abort: $abort, assert_: $assert_, asyncHooks: $asyncHooks, buffer: $buffer, childProcess: $childProcess, console: $console, crypto: $crypto, dns: $dns, events: $events, exceptions: $exceptions, fetch: $fetch, fs: $fs, navigator: $navigator, net: $net, os: $os, path: $path, perfHooks: $perfHooks, process: $process, streamWeb: $streamWeb, stringDecoder: $stringDecoder, timers: $timers, tty: $tty, url: $url, util: $util, zlib: $zlib, json: $json)';
  }
}

/// @nodoc
abstract mixin class $JsBuiltinOptionsCopyWith<$Res> {
  factory $JsBuiltinOptionsCopyWith(
          JsBuiltinOptions value, $Res Function(JsBuiltinOptions) _then) =
      _$JsBuiltinOptionsCopyWithImpl;
  @useResult
  $Res call(
      {bool? abort,
      bool? assert_,
      bool? asyncHooks,
      bool? buffer,
      bool? childProcess,
      bool? console,
      bool? crypto,
      bool? dns,
      bool? events,
      bool? exceptions,
      bool? fetch,
      bool? fs,
      bool? navigator,
      bool? net,
      bool? os,
      bool? path,
      bool? perfHooks,
      bool? process,
      bool? streamWeb,
      bool? stringDecoder,
      bool? timers,
      bool? tty,
      bool? url,
      bool? util,
      bool? zlib,
      bool? json});
}

/// @nodoc
class _$JsBuiltinOptionsCopyWithImpl<$Res>
    implements $JsBuiltinOptionsCopyWith<$Res> {
  _$JsBuiltinOptionsCopyWithImpl(this._self, this._then);

  final JsBuiltinOptions _self;
  final $Res Function(JsBuiltinOptions) _then;

  /// Create a copy of JsBuiltinOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? abort = freezed,
    Object? assert_ = freezed,
    Object? asyncHooks = freezed,
    Object? buffer = freezed,
    Object? childProcess = freezed,
    Object? console = freezed,
    Object? crypto = freezed,
    Object? dns = freezed,
    Object? events = freezed,
    Object? exceptions = freezed,
    Object? fetch = freezed,
    Object? fs = freezed,
    Object? navigator = freezed,
    Object? net = freezed,
    Object? os = freezed,
    Object? path = freezed,
    Object? perfHooks = freezed,
    Object? process = freezed,
    Object? streamWeb = freezed,
    Object? stringDecoder = freezed,
    Object? timers = freezed,
    Object? tty = freezed,
    Object? url = freezed,
    Object? util = freezed,
    Object? zlib = freezed,
    Object? json = freezed,
  }) {
    return _then(_self.copyWith(
      abort: freezed == abort
          ? _self.abort
          : abort // ignore: cast_nullable_to_non_nullable
              as bool?,
      assert_: freezed == assert_
          ? _self.assert_
          : assert_ // ignore: cast_nullable_to_non_nullable
              as bool?,
      asyncHooks: freezed == asyncHooks
          ? _self.asyncHooks
          : asyncHooks // ignore: cast_nullable_to_non_nullable
              as bool?,
      buffer: freezed == buffer
          ? _self.buffer
          : buffer // ignore: cast_nullable_to_non_nullable
              as bool?,
      childProcess: freezed == childProcess
          ? _self.childProcess
          : childProcess // ignore: cast_nullable_to_non_nullable
              as bool?,
      console: freezed == console
          ? _self.console
          : console // ignore: cast_nullable_to_non_nullable
              as bool?,
      crypto: freezed == crypto
          ? _self.crypto
          : crypto // ignore: cast_nullable_to_non_nullable
              as bool?,
      dns: freezed == dns
          ? _self.dns
          : dns // ignore: cast_nullable_to_non_nullable
              as bool?,
      events: freezed == events
          ? _self.events
          : events // ignore: cast_nullable_to_non_nullable
              as bool?,
      exceptions: freezed == exceptions
          ? _self.exceptions
          : exceptions // ignore: cast_nullable_to_non_nullable
              as bool?,
      fetch: freezed == fetch
          ? _self.fetch
          : fetch // ignore: cast_nullable_to_non_nullable
              as bool?,
      fs: freezed == fs
          ? _self.fs
          : fs // ignore: cast_nullable_to_non_nullable
              as bool?,
      navigator: freezed == navigator
          ? _self.navigator
          : navigator // ignore: cast_nullable_to_non_nullable
              as bool?,
      net: freezed == net
          ? _self.net
          : net // ignore: cast_nullable_to_non_nullable
              as bool?,
      os: freezed == os
          ? _self.os
          : os // ignore: cast_nullable_to_non_nullable
              as bool?,
      path: freezed == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as bool?,
      perfHooks: freezed == perfHooks
          ? _self.perfHooks
          : perfHooks // ignore: cast_nullable_to_non_nullable
              as bool?,
      process: freezed == process
          ? _self.process
          : process // ignore: cast_nullable_to_non_nullable
              as bool?,
      streamWeb: freezed == streamWeb
          ? _self.streamWeb
          : streamWeb // ignore: cast_nullable_to_non_nullable
              as bool?,
      stringDecoder: freezed == stringDecoder
          ? _self.stringDecoder
          : stringDecoder // ignore: cast_nullable_to_non_nullable
              as bool?,
      timers: freezed == timers
          ? _self.timers
          : timers // ignore: cast_nullable_to_non_nullable
              as bool?,
      tty: freezed == tty
          ? _self.tty
          : tty // ignore: cast_nullable_to_non_nullable
              as bool?,
      url: freezed == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as bool?,
      util: freezed == util
          ? _self.util
          : util // ignore: cast_nullable_to_non_nullable
              as bool?,
      zlib: freezed == zlib
          ? _self.zlib
          : zlib // ignore: cast_nullable_to_non_nullable
              as bool?,
      json: freezed == json
          ? _self.json
          : json // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// Adds pattern-matching-related methods to [JsBuiltinOptions].
extension JsBuiltinOptionsPatterns on JsBuiltinOptions {
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
    TResult Function(_JsBuiltinOptions value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JsBuiltinOptions() when $default != null:
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
    TResult Function(_JsBuiltinOptions value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JsBuiltinOptions():
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
    TResult? Function(_JsBuiltinOptions value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JsBuiltinOptions() when $default != null:
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
    TResult Function(
            bool? abort,
            bool? assert_,
            bool? asyncHooks,
            bool? buffer,
            bool? childProcess,
            bool? console,
            bool? crypto,
            bool? dns,
            bool? events,
            bool? exceptions,
            bool? fetch,
            bool? fs,
            bool? navigator,
            bool? net,
            bool? os,
            bool? path,
            bool? perfHooks,
            bool? process,
            bool? streamWeb,
            bool? stringDecoder,
            bool? timers,
            bool? tty,
            bool? url,
            bool? util,
            bool? zlib,
            bool? json)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JsBuiltinOptions() when $default != null:
        return $default(
            _that.abort,
            _that.assert_,
            _that.asyncHooks,
            _that.buffer,
            _that.childProcess,
            _that.console,
            _that.crypto,
            _that.dns,
            _that.events,
            _that.exceptions,
            _that.fetch,
            _that.fs,
            _that.navigator,
            _that.net,
            _that.os,
            _that.path,
            _that.perfHooks,
            _that.process,
            _that.streamWeb,
            _that.stringDecoder,
            _that.timers,
            _that.tty,
            _that.url,
            _that.util,
            _that.zlib,
            _that.json);
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
    TResult Function(
            bool? abort,
            bool? assert_,
            bool? asyncHooks,
            bool? buffer,
            bool? childProcess,
            bool? console,
            bool? crypto,
            bool? dns,
            bool? events,
            bool? exceptions,
            bool? fetch,
            bool? fs,
            bool? navigator,
            bool? net,
            bool? os,
            bool? path,
            bool? perfHooks,
            bool? process,
            bool? streamWeb,
            bool? stringDecoder,
            bool? timers,
            bool? tty,
            bool? url,
            bool? util,
            bool? zlib,
            bool? json)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JsBuiltinOptions():
        return $default(
            _that.abort,
            _that.assert_,
            _that.asyncHooks,
            _that.buffer,
            _that.childProcess,
            _that.console,
            _that.crypto,
            _that.dns,
            _that.events,
            _that.exceptions,
            _that.fetch,
            _that.fs,
            _that.navigator,
            _that.net,
            _that.os,
            _that.path,
            _that.perfHooks,
            _that.process,
            _that.streamWeb,
            _that.stringDecoder,
            _that.timers,
            _that.tty,
            _that.url,
            _that.util,
            _that.zlib,
            _that.json);
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
    TResult? Function(
            bool? abort,
            bool? assert_,
            bool? asyncHooks,
            bool? buffer,
            bool? childProcess,
            bool? console,
            bool? crypto,
            bool? dns,
            bool? events,
            bool? exceptions,
            bool? fetch,
            bool? fs,
            bool? navigator,
            bool? net,
            bool? os,
            bool? path,
            bool? perfHooks,
            bool? process,
            bool? streamWeb,
            bool? stringDecoder,
            bool? timers,
            bool? tty,
            bool? url,
            bool? util,
            bool? zlib,
            bool? json)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JsBuiltinOptions() when $default != null:
        return $default(
            _that.abort,
            _that.assert_,
            _that.asyncHooks,
            _that.buffer,
            _that.childProcess,
            _that.console,
            _that.crypto,
            _that.dns,
            _that.events,
            _that.exceptions,
            _that.fetch,
            _that.fs,
            _that.navigator,
            _that.net,
            _that.os,
            _that.path,
            _that.perfHooks,
            _that.process,
            _that.streamWeb,
            _that.stringDecoder,
            _that.timers,
            _that.tty,
            _that.url,
            _that.util,
            _that.zlib,
            _that.json);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _JsBuiltinOptions extends JsBuiltinOptions {
  const _JsBuiltinOptions(
      {this.abort,
      this.assert_,
      this.asyncHooks,
      this.buffer,
      this.childProcess,
      this.console,
      this.crypto,
      this.dns,
      this.events,
      this.exceptions,
      this.fetch,
      this.fs,
      this.navigator,
      this.net,
      this.os,
      this.path,
      this.perfHooks,
      this.process,
      this.streamWeb,
      this.stringDecoder,
      this.timers,
      this.tty,
      this.url,
      this.util,
      this.zlib,
      this.json})
      : super._();

  @override
  final bool? abort;
  @override
  final bool? assert_;
  @override
  final bool? asyncHooks;
  @override
  final bool? buffer;
  @override
  final bool? childProcess;
  @override
  final bool? console;
  @override
  final bool? crypto;
  @override
  final bool? dns;
  @override
  final bool? events;
  @override
  final bool? exceptions;
  @override
  final bool? fetch;
  @override
  final bool? fs;
  @override
  final bool? navigator;
  @override
  final bool? net;
  @override
  final bool? os;
  @override
  final bool? path;
  @override
  final bool? perfHooks;
  @override
  final bool? process;
  @override
  final bool? streamWeb;
  @override
  final bool? stringDecoder;
  @override
  final bool? timers;
  @override
  final bool? tty;
  @override
  final bool? url;
  @override
  final bool? util;
  @override
  final bool? zlib;
  @override
  final bool? json;

  /// Create a copy of JsBuiltinOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$JsBuiltinOptionsCopyWith<_JsBuiltinOptions> get copyWith =>
      __$JsBuiltinOptionsCopyWithImpl<_JsBuiltinOptions>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _JsBuiltinOptions &&
            (identical(other.abort, abort) || other.abort == abort) &&
            (identical(other.assert_, assert_) || other.assert_ == assert_) &&
            (identical(other.asyncHooks, asyncHooks) ||
                other.asyncHooks == asyncHooks) &&
            (identical(other.buffer, buffer) || other.buffer == buffer) &&
            (identical(other.childProcess, childProcess) ||
                other.childProcess == childProcess) &&
            (identical(other.console, console) || other.console == console) &&
            (identical(other.crypto, crypto) || other.crypto == crypto) &&
            (identical(other.dns, dns) || other.dns == dns) &&
            (identical(other.events, events) || other.events == events) &&
            (identical(other.exceptions, exceptions) ||
                other.exceptions == exceptions) &&
            (identical(other.fetch, fetch) || other.fetch == fetch) &&
            (identical(other.fs, fs) || other.fs == fs) &&
            (identical(other.navigator, navigator) ||
                other.navigator == navigator) &&
            (identical(other.net, net) || other.net == net) &&
            (identical(other.os, os) || other.os == os) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.perfHooks, perfHooks) ||
                other.perfHooks == perfHooks) &&
            (identical(other.process, process) || other.process == process) &&
            (identical(other.streamWeb, streamWeb) ||
                other.streamWeb == streamWeb) &&
            (identical(other.stringDecoder, stringDecoder) ||
                other.stringDecoder == stringDecoder) &&
            (identical(other.timers, timers) || other.timers == timers) &&
            (identical(other.tty, tty) || other.tty == tty) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.util, util) || other.util == util) &&
            (identical(other.zlib, zlib) || other.zlib == zlib) &&
            (identical(other.json, json) || other.json == json));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        abort,
        assert_,
        asyncHooks,
        buffer,
        childProcess,
        console,
        crypto,
        dns,
        events,
        exceptions,
        fetch,
        fs,
        navigator,
        net,
        os,
        path,
        perfHooks,
        process,
        streamWeb,
        stringDecoder,
        timers,
        tty,
        url,
        util,
        zlib,
        json
      ]);

  @override
  String toString() {
    return 'JsBuiltinOptions(abort: $abort, assert_: $assert_, asyncHooks: $asyncHooks, buffer: $buffer, childProcess: $childProcess, console: $console, crypto: $crypto, dns: $dns, events: $events, exceptions: $exceptions, fetch: $fetch, fs: $fs, navigator: $navigator, net: $net, os: $os, path: $path, perfHooks: $perfHooks, process: $process, streamWeb: $streamWeb, stringDecoder: $stringDecoder, timers: $timers, tty: $tty, url: $url, util: $util, zlib: $zlib, json: $json)';
  }
}

/// @nodoc
abstract mixin class _$JsBuiltinOptionsCopyWith<$Res>
    implements $JsBuiltinOptionsCopyWith<$Res> {
  factory _$JsBuiltinOptionsCopyWith(
          _JsBuiltinOptions value, $Res Function(_JsBuiltinOptions) _then) =
      __$JsBuiltinOptionsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool? abort,
      bool? assert_,
      bool? asyncHooks,
      bool? buffer,
      bool? childProcess,
      bool? console,
      bool? crypto,
      bool? dns,
      bool? events,
      bool? exceptions,
      bool? fetch,
      bool? fs,
      bool? navigator,
      bool? net,
      bool? os,
      bool? path,
      bool? perfHooks,
      bool? process,
      bool? streamWeb,
      bool? stringDecoder,
      bool? timers,
      bool? tty,
      bool? url,
      bool? util,
      bool? zlib,
      bool? json});
}

/// @nodoc
class __$JsBuiltinOptionsCopyWithImpl<$Res>
    implements _$JsBuiltinOptionsCopyWith<$Res> {
  __$JsBuiltinOptionsCopyWithImpl(this._self, this._then);

  final _JsBuiltinOptions _self;
  final $Res Function(_JsBuiltinOptions) _then;

  /// Create a copy of JsBuiltinOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? abort = freezed,
    Object? assert_ = freezed,
    Object? asyncHooks = freezed,
    Object? buffer = freezed,
    Object? childProcess = freezed,
    Object? console = freezed,
    Object? crypto = freezed,
    Object? dns = freezed,
    Object? events = freezed,
    Object? exceptions = freezed,
    Object? fetch = freezed,
    Object? fs = freezed,
    Object? navigator = freezed,
    Object? net = freezed,
    Object? os = freezed,
    Object? path = freezed,
    Object? perfHooks = freezed,
    Object? process = freezed,
    Object? streamWeb = freezed,
    Object? stringDecoder = freezed,
    Object? timers = freezed,
    Object? tty = freezed,
    Object? url = freezed,
    Object? util = freezed,
    Object? zlib = freezed,
    Object? json = freezed,
  }) {
    return _then(_JsBuiltinOptions(
      abort: freezed == abort
          ? _self.abort
          : abort // ignore: cast_nullable_to_non_nullable
              as bool?,
      assert_: freezed == assert_
          ? _self.assert_
          : assert_ // ignore: cast_nullable_to_non_nullable
              as bool?,
      asyncHooks: freezed == asyncHooks
          ? _self.asyncHooks
          : asyncHooks // ignore: cast_nullable_to_non_nullable
              as bool?,
      buffer: freezed == buffer
          ? _self.buffer
          : buffer // ignore: cast_nullable_to_non_nullable
              as bool?,
      childProcess: freezed == childProcess
          ? _self.childProcess
          : childProcess // ignore: cast_nullable_to_non_nullable
              as bool?,
      console: freezed == console
          ? _self.console
          : console // ignore: cast_nullable_to_non_nullable
              as bool?,
      crypto: freezed == crypto
          ? _self.crypto
          : crypto // ignore: cast_nullable_to_non_nullable
              as bool?,
      dns: freezed == dns
          ? _self.dns
          : dns // ignore: cast_nullable_to_non_nullable
              as bool?,
      events: freezed == events
          ? _self.events
          : events // ignore: cast_nullable_to_non_nullable
              as bool?,
      exceptions: freezed == exceptions
          ? _self.exceptions
          : exceptions // ignore: cast_nullable_to_non_nullable
              as bool?,
      fetch: freezed == fetch
          ? _self.fetch
          : fetch // ignore: cast_nullable_to_non_nullable
              as bool?,
      fs: freezed == fs
          ? _self.fs
          : fs // ignore: cast_nullable_to_non_nullable
              as bool?,
      navigator: freezed == navigator
          ? _self.navigator
          : navigator // ignore: cast_nullable_to_non_nullable
              as bool?,
      net: freezed == net
          ? _self.net
          : net // ignore: cast_nullable_to_non_nullable
              as bool?,
      os: freezed == os
          ? _self.os
          : os // ignore: cast_nullable_to_non_nullable
              as bool?,
      path: freezed == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as bool?,
      perfHooks: freezed == perfHooks
          ? _self.perfHooks
          : perfHooks // ignore: cast_nullable_to_non_nullable
              as bool?,
      process: freezed == process
          ? _self.process
          : process // ignore: cast_nullable_to_non_nullable
              as bool?,
      streamWeb: freezed == streamWeb
          ? _self.streamWeb
          : streamWeb // ignore: cast_nullable_to_non_nullable
              as bool?,
      stringDecoder: freezed == stringDecoder
          ? _self.stringDecoder
          : stringDecoder // ignore: cast_nullable_to_non_nullable
              as bool?,
      timers: freezed == timers
          ? _self.timers
          : timers // ignore: cast_nullable_to_non_nullable
              as bool?,
      tty: freezed == tty
          ? _self.tty
          : tty // ignore: cast_nullable_to_non_nullable
              as bool?,
      url: freezed == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as bool?,
      util: freezed == util
          ? _self.util
          : util // ignore: cast_nullable_to_non_nullable
              as bool?,
      zlib: freezed == zlib
          ? _self.zlib
          : zlib // ignore: cast_nullable_to_non_nullable
              as bool?,
      json: freezed == json
          ? _self.json
          : json // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
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

/// @nodoc
mixin _$JsCode {
  String get field0;

  /// Create a copy of JsCode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsCodeCopyWith<JsCode> get copyWith =>
      _$JsCodeCopyWithImpl<JsCode>(this as JsCode, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsCode &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsCode(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsCodeCopyWith<$Res> {
  factory $JsCodeCopyWith(JsCode value, $Res Function(JsCode) _then) =
      _$JsCodeCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsCodeCopyWithImpl<$Res> implements $JsCodeCopyWith<$Res> {
  _$JsCodeCopyWithImpl(this._self, this._then);

  final JsCode _self;
  final $Res Function(JsCode) _then;

  /// Create a copy of JsCode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_self.copyWith(
      field0: null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [JsCode].
extension JsCodePatterns on JsCode {
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
    TResult Function(JsCode_Code value)? code,
    TResult Function(JsCode_Path value)? path,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsCode_Code() when code != null:
        return code(_that);
      case JsCode_Path() when path != null:
        return path(_that);
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
    required TResult Function(JsCode_Code value) code,
    required TResult Function(JsCode_Path value) path,
  }) {
    final _that = this;
    switch (_that) {
      case JsCode_Code():
        return code(_that);
      case JsCode_Path():
        return path(_that);
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
    TResult? Function(JsCode_Code value)? code,
    TResult? Function(JsCode_Path value)? path,
  }) {
    final _that = this;
    switch (_that) {
      case JsCode_Code() when code != null:
        return code(_that);
      case JsCode_Path() when path != null:
        return path(_that);
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
    TResult Function(String field0)? code,
    TResult Function(String field0)? path,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsCode_Code() when code != null:
        return code(_that.field0);
      case JsCode_Path() when path != null:
        return path(_that.field0);
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
    required TResult Function(String field0) code,
    required TResult Function(String field0) path,
  }) {
    final _that = this;
    switch (_that) {
      case JsCode_Code():
        return code(_that.field0);
      case JsCode_Path():
        return path(_that.field0);
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
    TResult? Function(String field0)? code,
    TResult? Function(String field0)? path,
  }) {
    final _that = this;
    switch (_that) {
      case JsCode_Code() when code != null:
        return code(_that.field0);
      case JsCode_Path() when path != null:
        return path(_that.field0);
      case _:
        return null;
    }
  }
}

/// @nodoc

class JsCode_Code extends JsCode {
  const JsCode_Code(this.field0) : super._();

  @override
  final String field0;

  /// Create a copy of JsCode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsCode_CodeCopyWith<JsCode_Code> get copyWith =>
      _$JsCode_CodeCopyWithImpl<JsCode_Code>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsCode_Code &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsCode.code(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsCode_CodeCopyWith<$Res>
    implements $JsCodeCopyWith<$Res> {
  factory $JsCode_CodeCopyWith(
          JsCode_Code value, $Res Function(JsCode_Code) _then) =
      _$JsCode_CodeCopyWithImpl;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsCode_CodeCopyWithImpl<$Res> implements $JsCode_CodeCopyWith<$Res> {
  _$JsCode_CodeCopyWithImpl(this._self, this._then);

  final JsCode_Code _self;
  final $Res Function(JsCode_Code) _then;

  /// Create a copy of JsCode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsCode_Code(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsCode_Path extends JsCode {
  const JsCode_Path(this.field0) : super._();

  @override
  final String field0;

  /// Create a copy of JsCode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsCode_PathCopyWith<JsCode_Path> get copyWith =>
      _$JsCode_PathCopyWithImpl<JsCode_Path>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsCode_Path &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsCode.path(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsCode_PathCopyWith<$Res>
    implements $JsCodeCopyWith<$Res> {
  factory $JsCode_PathCopyWith(
          JsCode_Path value, $Res Function(JsCode_Path) _then) =
      _$JsCode_PathCopyWithImpl;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsCode_PathCopyWithImpl<$Res> implements $JsCode_PathCopyWith<$Res> {
  _$JsCode_PathCopyWithImpl(this._self, this._then);

  final JsCode_Path _self;
  final $Res Function(JsCode_Path) _then;

  /// Create a copy of JsCode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsCode_Path(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$JsError {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is JsError);
  }

  @override
  int get hashCode => runtimeType.hashCode;
}

/// @nodoc
class $JsErrorCopyWith<$Res> {
  $JsErrorCopyWith(JsError _, $Res Function(JsError) __);
}

/// Adds pattern-matching-related methods to [JsError].
extension JsErrorPatterns on JsError {
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
    TResult Function(JsError_Promise value)? promise,
    TResult Function(JsError_Module value)? module,
    TResult Function(JsError_Context value)? context,
    TResult Function(JsError_Storage value)? storage,
    TResult Function(JsError_Io value)? io,
    TResult Function(JsError_Runtime value)? runtime,
    TResult Function(JsError_Generic value)? generic,
    TResult Function(JsError_Engine value)? engine,
    TResult Function(JsError_Bridge value)? bridge,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsError_Promise() when promise != null:
        return promise(_that);
      case JsError_Module() when module != null:
        return module(_that);
      case JsError_Context() when context != null:
        return context(_that);
      case JsError_Storage() when storage != null:
        return storage(_that);
      case JsError_Io() when io != null:
        return io(_that);
      case JsError_Runtime() when runtime != null:
        return runtime(_that);
      case JsError_Generic() when generic != null:
        return generic(_that);
      case JsError_Engine() when engine != null:
        return engine(_that);
      case JsError_Bridge() when bridge != null:
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
    required TResult Function(JsError_Promise value) promise,
    required TResult Function(JsError_Module value) module,
    required TResult Function(JsError_Context value) context,
    required TResult Function(JsError_Storage value) storage,
    required TResult Function(JsError_Io value) io,
    required TResult Function(JsError_Runtime value) runtime,
    required TResult Function(JsError_Generic value) generic,
    required TResult Function(JsError_Engine value) engine,
    required TResult Function(JsError_Bridge value) bridge,
  }) {
    final _that = this;
    switch (_that) {
      case JsError_Promise():
        return promise(_that);
      case JsError_Module():
        return module(_that);
      case JsError_Context():
        return context(_that);
      case JsError_Storage():
        return storage(_that);
      case JsError_Io():
        return io(_that);
      case JsError_Runtime():
        return runtime(_that);
      case JsError_Generic():
        return generic(_that);
      case JsError_Engine():
        return engine(_that);
      case JsError_Bridge():
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
    TResult? Function(JsError_Promise value)? promise,
    TResult? Function(JsError_Module value)? module,
    TResult? Function(JsError_Context value)? context,
    TResult? Function(JsError_Storage value)? storage,
    TResult? Function(JsError_Io value)? io,
    TResult? Function(JsError_Runtime value)? runtime,
    TResult? Function(JsError_Generic value)? generic,
    TResult? Function(JsError_Engine value)? engine,
    TResult? Function(JsError_Bridge value)? bridge,
  }) {
    final _that = this;
    switch (_that) {
      case JsError_Promise() when promise != null:
        return promise(_that);
      case JsError_Module() when module != null:
        return module(_that);
      case JsError_Context() when context != null:
        return context(_that);
      case JsError_Storage() when storage != null:
        return storage(_that);
      case JsError_Io() when io != null:
        return io(_that);
      case JsError_Runtime() when runtime != null:
        return runtime(_that);
      case JsError_Generic() when generic != null:
        return generic(_that);
      case JsError_Engine() when engine != null:
        return engine(_that);
      case JsError_Bridge() when bridge != null:
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
    TResult Function(String field0)? promise,
    TResult Function(String? module, String? method, String message)? module,
    TResult Function(String field0)? context,
    TResult Function(String field0)? storage,
    TResult Function(String? path, String message)? io,
    TResult Function(String field0)? runtime,
    TResult Function(String field0)? generic,
    TResult Function(String field0)? engine,
    TResult Function(String field0)? bridge,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsError_Promise() when promise != null:
        return promise(_that.field0);
      case JsError_Module() when module != null:
        return module(_that.module, _that.method, _that.message);
      case JsError_Context() when context != null:
        return context(_that.field0);
      case JsError_Storage() when storage != null:
        return storage(_that.field0);
      case JsError_Io() when io != null:
        return io(_that.path, _that.message);
      case JsError_Runtime() when runtime != null:
        return runtime(_that.field0);
      case JsError_Generic() when generic != null:
        return generic(_that.field0);
      case JsError_Engine() when engine != null:
        return engine(_that.field0);
      case JsError_Bridge() when bridge != null:
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
    required TResult Function(String field0) promise,
    required TResult Function(String? module, String? method, String message)
        module,
    required TResult Function(String field0) context,
    required TResult Function(String field0) storage,
    required TResult Function(String? path, String message) io,
    required TResult Function(String field0) runtime,
    required TResult Function(String field0) generic,
    required TResult Function(String field0) engine,
    required TResult Function(String field0) bridge,
  }) {
    final _that = this;
    switch (_that) {
      case JsError_Promise():
        return promise(_that.field0);
      case JsError_Module():
        return module(_that.module, _that.method, _that.message);
      case JsError_Context():
        return context(_that.field0);
      case JsError_Storage():
        return storage(_that.field0);
      case JsError_Io():
        return io(_that.path, _that.message);
      case JsError_Runtime():
        return runtime(_that.field0);
      case JsError_Generic():
        return generic(_that.field0);
      case JsError_Engine():
        return engine(_that.field0);
      case JsError_Bridge():
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
    TResult? Function(String field0)? promise,
    TResult? Function(String? module, String? method, String message)? module,
    TResult? Function(String field0)? context,
    TResult? Function(String field0)? storage,
    TResult? Function(String? path, String message)? io,
    TResult? Function(String field0)? runtime,
    TResult? Function(String field0)? generic,
    TResult? Function(String field0)? engine,
    TResult? Function(String field0)? bridge,
  }) {
    final _that = this;
    switch (_that) {
      case JsError_Promise() when promise != null:
        return promise(_that.field0);
      case JsError_Module() when module != null:
        return module(_that.module, _that.method, _that.message);
      case JsError_Context() when context != null:
        return context(_that.field0);
      case JsError_Storage() when storage != null:
        return storage(_that.field0);
      case JsError_Io() when io != null:
        return io(_that.path, _that.message);
      case JsError_Runtime() when runtime != null:
        return runtime(_that.field0);
      case JsError_Generic() when generic != null:
        return generic(_that.field0);
      case JsError_Engine() when engine != null:
        return engine(_that.field0);
      case JsError_Bridge() when bridge != null:
        return bridge(_that.field0);
      case _:
        return null;
    }
  }
}

/// @nodoc

class JsError_Promise extends JsError {
  const JsError_Promise(this.field0) : super._();

  final String field0;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_PromiseCopyWith<JsError_Promise> get copyWith =>
      _$JsError_PromiseCopyWithImpl<JsError_Promise>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_Promise &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);
}

/// @nodoc
abstract mixin class $JsError_PromiseCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_PromiseCopyWith(
          JsError_Promise value, $Res Function(JsError_Promise) _then) =
      _$JsError_PromiseCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsError_PromiseCopyWithImpl<$Res>
    implements $JsError_PromiseCopyWith<$Res> {
  _$JsError_PromiseCopyWithImpl(this._self, this._then);

  final JsError_Promise _self;
  final $Res Function(JsError_Promise) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsError_Promise(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsError_Module extends JsError {
  const JsError_Module({this.module, this.method, required this.message})
      : super._();

  /// Optional module name where the error occurred
  final String? module;

  /// Optional method name where the error occurred
  final String? method;

  /// Error message
  final String message;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_ModuleCopyWith<JsError_Module> get copyWith =>
      _$JsError_ModuleCopyWithImpl<JsError_Module>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_Module &&
            (identical(other.module, module) || other.module == module) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, module, method, message);
}

/// @nodoc
abstract mixin class $JsError_ModuleCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_ModuleCopyWith(
          JsError_Module value, $Res Function(JsError_Module) _then) =
      _$JsError_ModuleCopyWithImpl;
  @useResult
  $Res call({String? module, String? method, String message});
}

/// @nodoc
class _$JsError_ModuleCopyWithImpl<$Res>
    implements $JsError_ModuleCopyWith<$Res> {
  _$JsError_ModuleCopyWithImpl(this._self, this._then);

  final JsError_Module _self;
  final $Res Function(JsError_Module) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? module = freezed,
    Object? method = freezed,
    Object? message = null,
  }) {
    return _then(JsError_Module(
      module: freezed == module
          ? _self.module
          : module // ignore: cast_nullable_to_non_nullable
              as String?,
      method: freezed == method
          ? _self.method
          : method // ignore: cast_nullable_to_non_nullable
              as String?,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsError_Context extends JsError {
  const JsError_Context(this.field0) : super._();

  final String field0;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_ContextCopyWith<JsError_Context> get copyWith =>
      _$JsError_ContextCopyWithImpl<JsError_Context>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_Context &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);
}

/// @nodoc
abstract mixin class $JsError_ContextCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_ContextCopyWith(
          JsError_Context value, $Res Function(JsError_Context) _then) =
      _$JsError_ContextCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsError_ContextCopyWithImpl<$Res>
    implements $JsError_ContextCopyWith<$Res> {
  _$JsError_ContextCopyWithImpl(this._self, this._then);

  final JsError_Context _self;
  final $Res Function(JsError_Context) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsError_Context(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsError_Storage extends JsError {
  const JsError_Storage(this.field0) : super._();

  final String field0;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_StorageCopyWith<JsError_Storage> get copyWith =>
      _$JsError_StorageCopyWithImpl<JsError_Storage>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_Storage &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);
}

/// @nodoc
abstract mixin class $JsError_StorageCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_StorageCopyWith(
          JsError_Storage value, $Res Function(JsError_Storage) _then) =
      _$JsError_StorageCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsError_StorageCopyWithImpl<$Res>
    implements $JsError_StorageCopyWith<$Res> {
  _$JsError_StorageCopyWithImpl(this._self, this._then);

  final JsError_Storage _self;
  final $Res Function(JsError_Storage) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsError_Storage(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsError_Io extends JsError {
  const JsError_Io({this.path, required this.message}) : super._();

  /// Optional file path where the error occurred
  final String? path;

  /// Error message
  final String message;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_IoCopyWith<JsError_Io> get copyWith =>
      _$JsError_IoCopyWithImpl<JsError_Io>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_Io &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, path, message);
}

/// @nodoc
abstract mixin class $JsError_IoCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_IoCopyWith(
          JsError_Io value, $Res Function(JsError_Io) _then) =
      _$JsError_IoCopyWithImpl;
  @useResult
  $Res call({String? path, String message});
}

/// @nodoc
class _$JsError_IoCopyWithImpl<$Res> implements $JsError_IoCopyWith<$Res> {
  _$JsError_IoCopyWithImpl(this._self, this._then);

  final JsError_Io _self;
  final $Res Function(JsError_Io) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? path = freezed,
    Object? message = null,
  }) {
    return _then(JsError_Io(
      path: freezed == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String?,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsError_Runtime extends JsError {
  const JsError_Runtime(this.field0) : super._();

  final String field0;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_RuntimeCopyWith<JsError_Runtime> get copyWith =>
      _$JsError_RuntimeCopyWithImpl<JsError_Runtime>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_Runtime &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);
}

/// @nodoc
abstract mixin class $JsError_RuntimeCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_RuntimeCopyWith(
          JsError_Runtime value, $Res Function(JsError_Runtime) _then) =
      _$JsError_RuntimeCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsError_RuntimeCopyWithImpl<$Res>
    implements $JsError_RuntimeCopyWith<$Res> {
  _$JsError_RuntimeCopyWithImpl(this._self, this._then);

  final JsError_Runtime _self;
  final $Res Function(JsError_Runtime) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsError_Runtime(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsError_Generic extends JsError {
  const JsError_Generic(this.field0) : super._();

  final String field0;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_GenericCopyWith<JsError_Generic> get copyWith =>
      _$JsError_GenericCopyWithImpl<JsError_Generic>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_Generic &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);
}

/// @nodoc
abstract mixin class $JsError_GenericCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_GenericCopyWith(
          JsError_Generic value, $Res Function(JsError_Generic) _then) =
      _$JsError_GenericCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsError_GenericCopyWithImpl<$Res>
    implements $JsError_GenericCopyWith<$Res> {
  _$JsError_GenericCopyWithImpl(this._self, this._then);

  final JsError_Generic _self;
  final $Res Function(JsError_Generic) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsError_Generic(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsError_Engine extends JsError {
  const JsError_Engine(this.field0) : super._();

  final String field0;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_EngineCopyWith<JsError_Engine> get copyWith =>
      _$JsError_EngineCopyWithImpl<JsError_Engine>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_Engine &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);
}

/// @nodoc
abstract mixin class $JsError_EngineCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_EngineCopyWith(
          JsError_Engine value, $Res Function(JsError_Engine) _then) =
      _$JsError_EngineCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsError_EngineCopyWithImpl<$Res>
    implements $JsError_EngineCopyWith<$Res> {
  _$JsError_EngineCopyWithImpl(this._self, this._then);

  final JsError_Engine _self;
  final $Res Function(JsError_Engine) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsError_Engine(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsError_Bridge extends JsError {
  const JsError_Bridge(this.field0) : super._();

  final String field0;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_BridgeCopyWith<JsError_Bridge> get copyWith =>
      _$JsError_BridgeCopyWithImpl<JsError_Bridge>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_Bridge &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);
}

/// @nodoc
abstract mixin class $JsError_BridgeCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_BridgeCopyWith(
          JsError_Bridge value, $Res Function(JsError_Bridge) _then) =
      _$JsError_BridgeCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsError_BridgeCopyWithImpl<$Res>
    implements $JsError_BridgeCopyWith<$Res> {
  _$JsError_BridgeCopyWithImpl(this._self, this._then);

  final JsError_Bridge _self;
  final $Res Function(JsError_Bridge) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsError_Bridge(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$JsEvalOptions {
  bool? get global;
  bool? get strict;
  bool? get backtraceBarrier;
  bool? get promise;

  /// Create a copy of JsEvalOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsEvalOptionsCopyWith<JsEvalOptions> get copyWith =>
      _$JsEvalOptionsCopyWithImpl<JsEvalOptions>(
          this as JsEvalOptions, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsEvalOptions &&
            (identical(other.global, global) || other.global == global) &&
            (identical(other.strict, strict) || other.strict == strict) &&
            (identical(other.backtraceBarrier, backtraceBarrier) ||
                other.backtraceBarrier == backtraceBarrier) &&
            (identical(other.promise, promise) || other.promise == promise));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, global, strict, backtraceBarrier, promise);

  @override
  String toString() {
    return 'JsEvalOptions(global: $global, strict: $strict, backtraceBarrier: $backtraceBarrier, promise: $promise)';
  }
}

/// @nodoc
abstract mixin class $JsEvalOptionsCopyWith<$Res> {
  factory $JsEvalOptionsCopyWith(
          JsEvalOptions value, $Res Function(JsEvalOptions) _then) =
      _$JsEvalOptionsCopyWithImpl;
  @useResult
  $Res call(
      {bool? global, bool? strict, bool? backtraceBarrier, bool? promise});
}

/// @nodoc
class _$JsEvalOptionsCopyWithImpl<$Res>
    implements $JsEvalOptionsCopyWith<$Res> {
  _$JsEvalOptionsCopyWithImpl(this._self, this._then);

  final JsEvalOptions _self;
  final $Res Function(JsEvalOptions) _then;

  /// Create a copy of JsEvalOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? global = freezed,
    Object? strict = freezed,
    Object? backtraceBarrier = freezed,
    Object? promise = freezed,
  }) {
    return _then(_self.copyWith(
      global: freezed == global
          ? _self.global
          : global // ignore: cast_nullable_to_non_nullable
              as bool?,
      strict: freezed == strict
          ? _self.strict
          : strict // ignore: cast_nullable_to_non_nullable
              as bool?,
      backtraceBarrier: freezed == backtraceBarrier
          ? _self.backtraceBarrier
          : backtraceBarrier // ignore: cast_nullable_to_non_nullable
              as bool?,
      promise: freezed == promise
          ? _self.promise
          : promise // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// Adds pattern-matching-related methods to [JsEvalOptions].
extension JsEvalOptionsPatterns on JsEvalOptions {
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
    TResult Function(_JsEvalOptions value)? raw,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JsEvalOptions() when raw != null:
        return raw(_that);
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
    required TResult Function(_JsEvalOptions value) raw,
  }) {
    final _that = this;
    switch (_that) {
      case _JsEvalOptions():
        return raw(_that);
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
    TResult? Function(_JsEvalOptions value)? raw,
  }) {
    final _that = this;
    switch (_that) {
      case _JsEvalOptions() when raw != null:
        return raw(_that);
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
    TResult Function(
            bool? global, bool? strict, bool? backtraceBarrier, bool? promise)?
        raw,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JsEvalOptions() when raw != null:
        return raw(
            _that.global, _that.strict, _that.backtraceBarrier, _that.promise);
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
    required TResult Function(
            bool? global, bool? strict, bool? backtraceBarrier, bool? promise)
        raw,
  }) {
    final _that = this;
    switch (_that) {
      case _JsEvalOptions():
        return raw(
            _that.global, _that.strict, _that.backtraceBarrier, _that.promise);
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
    TResult? Function(
            bool? global, bool? strict, bool? backtraceBarrier, bool? promise)?
        raw,
  }) {
    final _that = this;
    switch (_that) {
      case _JsEvalOptions() when raw != null:
        return raw(
            _that.global, _that.strict, _that.backtraceBarrier, _that.promise);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _JsEvalOptions extends JsEvalOptions {
  const _JsEvalOptions(
      {this.global, this.strict, this.backtraceBarrier, this.promise})
      : super._();

  @override
  final bool? global;
  @override
  final bool? strict;
  @override
  final bool? backtraceBarrier;
  @override
  final bool? promise;

  /// Create a copy of JsEvalOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$JsEvalOptionsCopyWith<_JsEvalOptions> get copyWith =>
      __$JsEvalOptionsCopyWithImpl<_JsEvalOptions>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _JsEvalOptions &&
            (identical(other.global, global) || other.global == global) &&
            (identical(other.strict, strict) || other.strict == strict) &&
            (identical(other.backtraceBarrier, backtraceBarrier) ||
                other.backtraceBarrier == backtraceBarrier) &&
            (identical(other.promise, promise) || other.promise == promise));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, global, strict, backtraceBarrier, promise);

  @override
  String toString() {
    return 'JsEvalOptions.raw(global: $global, strict: $strict, backtraceBarrier: $backtraceBarrier, promise: $promise)';
  }
}

/// @nodoc
abstract mixin class _$JsEvalOptionsCopyWith<$Res>
    implements $JsEvalOptionsCopyWith<$Res> {
  factory _$JsEvalOptionsCopyWith(
          _JsEvalOptions value, $Res Function(_JsEvalOptions) _then) =
      __$JsEvalOptionsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool? global, bool? strict, bool? backtraceBarrier, bool? promise});
}

/// @nodoc
class __$JsEvalOptionsCopyWithImpl<$Res>
    implements _$JsEvalOptionsCopyWith<$Res> {
  __$JsEvalOptionsCopyWithImpl(this._self, this._then);

  final _JsEvalOptions _self;
  final $Res Function(_JsEvalOptions) _then;

  /// Create a copy of JsEvalOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? global = freezed,
    Object? strict = freezed,
    Object? backtraceBarrier = freezed,
    Object? promise = freezed,
  }) {
    return _then(_JsEvalOptions(
      global: freezed == global
          ? _self.global
          : global // ignore: cast_nullable_to_non_nullable
              as bool?,
      strict: freezed == strict
          ? _self.strict
          : strict // ignore: cast_nullable_to_non_nullable
              as bool?,
      backtraceBarrier: freezed == backtraceBarrier
          ? _self.backtraceBarrier
          : backtraceBarrier // ignore: cast_nullable_to_non_nullable
              as bool?,
      promise: freezed == promise
          ? _self.promise
          : promise // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
mixin _$JsModule {
  String get name;
  JsCode get source;

  /// Create a copy of JsModule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsModuleCopyWith<JsModule> get copyWith =>
      _$JsModuleCopyWithImpl<JsModule>(this as JsModule, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsModule &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.source, source) || other.source == source));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, source);

  @override
  String toString() {
    return 'JsModule(name: $name, source: $source)';
  }
}

/// @nodoc
abstract mixin class $JsModuleCopyWith<$Res> {
  factory $JsModuleCopyWith(JsModule value, $Res Function(JsModule) _then) =
      _$JsModuleCopyWithImpl;
  @useResult
  $Res call({String name, JsCode source});

  $JsCodeCopyWith<$Res> get source;
}

/// @nodoc
class _$JsModuleCopyWithImpl<$Res> implements $JsModuleCopyWith<$Res> {
  _$JsModuleCopyWithImpl(this._self, this._then);

  final JsModule _self;
  final $Res Function(JsModule) _then;

  /// Create a copy of JsModule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? source = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as JsCode,
    ));
  }

  /// Create a copy of JsModule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JsCodeCopyWith<$Res> get source {
    return $JsCodeCopyWith<$Res>(_self.source, (value) {
      return _then(_self.copyWith(source: value));
    });
  }
}

/// Adds pattern-matching-related methods to [JsModule].
extension JsModulePatterns on JsModule {
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
    TResult Function(_JsModule value)? raw,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JsModule() when raw != null:
        return raw(_that);
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
    required TResult Function(_JsModule value) raw,
  }) {
    final _that = this;
    switch (_that) {
      case _JsModule():
        return raw(_that);
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
    TResult? Function(_JsModule value)? raw,
  }) {
    final _that = this;
    switch (_that) {
      case _JsModule() when raw != null:
        return raw(_that);
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
    TResult Function(String name, JsCode source)? raw,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JsModule() when raw != null:
        return raw(_that.name, _that.source);
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
    required TResult Function(String name, JsCode source) raw,
  }) {
    final _that = this;
    switch (_that) {
      case _JsModule():
        return raw(_that.name, _that.source);
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
    TResult? Function(String name, JsCode source)? raw,
  }) {
    final _that = this;
    switch (_that) {
      case _JsModule() when raw != null:
        return raw(_that.name, _that.source);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _JsModule extends JsModule {
  const _JsModule({required this.name, required this.source}) : super._();

  @override
  final String name;
  @override
  final JsCode source;

  /// Create a copy of JsModule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$JsModuleCopyWith<_JsModule> get copyWith =>
      __$JsModuleCopyWithImpl<_JsModule>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _JsModule &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.source, source) || other.source == source));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, source);

  @override
  String toString() {
    return 'JsModule.raw(name: $name, source: $source)';
  }
}

/// @nodoc
abstract mixin class _$JsModuleCopyWith<$Res>
    implements $JsModuleCopyWith<$Res> {
  factory _$JsModuleCopyWith(_JsModule value, $Res Function(_JsModule) _then) =
      __$JsModuleCopyWithImpl;
  @override
  @useResult
  $Res call({String name, JsCode source});

  @override
  $JsCodeCopyWith<$Res> get source;
}

/// @nodoc
class __$JsModuleCopyWithImpl<$Res> implements _$JsModuleCopyWith<$Res> {
  __$JsModuleCopyWithImpl(this._self, this._then);

  final _JsModule _self;
  final $Res Function(_JsModule) _then;

  /// Create a copy of JsModule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? source = null,
  }) {
    return _then(_JsModule(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as JsCode,
    ));
  }

  /// Create a copy of JsModule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JsCodeCopyWith<$Res> get source {
    return $JsCodeCopyWith<$Res>(_self.source, (value) {
      return _then(_self.copyWith(source: value));
    });
  }
}

/// @nodoc
mixin _$JsResult {
  Object get field0;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsResult &&
            const DeepCollectionEquality().equals(other.field0, field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(field0));

  @override
  String toString() {
    return 'JsResult(field0: $field0)';
  }
}

/// @nodoc
class $JsResultCopyWith<$Res> {
  $JsResultCopyWith(JsResult _, $Res Function(JsResult) __);
}

/// Adds pattern-matching-related methods to [JsResult].
extension JsResultPatterns on JsResult {
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
    TResult Function(JsResult_Ok value)? ok,
    TResult Function(JsResult_Err value)? err,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsResult_Ok() when ok != null:
        return ok(_that);
      case JsResult_Err() when err != null:
        return err(_that);
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
    required TResult Function(JsResult_Ok value) ok,
    required TResult Function(JsResult_Err value) err,
  }) {
    final _that = this;
    switch (_that) {
      case JsResult_Ok():
        return ok(_that);
      case JsResult_Err():
        return err(_that);
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
    TResult? Function(JsResult_Ok value)? ok,
    TResult? Function(JsResult_Err value)? err,
  }) {
    final _that = this;
    switch (_that) {
      case JsResult_Ok() when ok != null:
        return ok(_that);
      case JsResult_Err() when err != null:
        return err(_that);
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
    TResult Function(JsValue field0)? ok,
    TResult Function(JsError field0)? err,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsResult_Ok() when ok != null:
        return ok(_that.field0);
      case JsResult_Err() when err != null:
        return err(_that.field0);
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
    required TResult Function(JsValue field0) ok,
    required TResult Function(JsError field0) err,
  }) {
    final _that = this;
    switch (_that) {
      case JsResult_Ok():
        return ok(_that.field0);
      case JsResult_Err():
        return err(_that.field0);
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
    TResult? Function(JsValue field0)? ok,
    TResult? Function(JsError field0)? err,
  }) {
    final _that = this;
    switch (_that) {
      case JsResult_Ok() when ok != null:
        return ok(_that.field0);
      case JsResult_Err() when err != null:
        return err(_that.field0);
      case _:
        return null;
    }
  }
}

/// @nodoc

class JsResult_Ok extends JsResult {
  const JsResult_Ok(this.field0) : super._();

  @override
  final JsValue field0;

  /// Create a copy of JsResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsResult_OkCopyWith<JsResult_Ok> get copyWith =>
      _$JsResult_OkCopyWithImpl<JsResult_Ok>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsResult_Ok &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsResult.ok(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsResult_OkCopyWith<$Res>
    implements $JsResultCopyWith<$Res> {
  factory $JsResult_OkCopyWith(
          JsResult_Ok value, $Res Function(JsResult_Ok) _then) =
      _$JsResult_OkCopyWithImpl;
  @useResult
  $Res call({JsValue field0});

  $JsValueCopyWith<$Res> get field0;
}

/// @nodoc
class _$JsResult_OkCopyWithImpl<$Res> implements $JsResult_OkCopyWith<$Res> {
  _$JsResult_OkCopyWithImpl(this._self, this._then);

  final JsResult_Ok _self;
  final $Res Function(JsResult_Ok) _then;

  /// Create a copy of JsResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsResult_Ok(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as JsValue,
    ));
  }

  /// Create a copy of JsResult
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

class JsResult_Err extends JsResult {
  const JsResult_Err(this.field0) : super._();

  @override
  final JsError field0;

  /// Create a copy of JsResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsResult_ErrCopyWith<JsResult_Err> get copyWith =>
      _$JsResult_ErrCopyWithImpl<JsResult_Err>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsResult_Err &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsResult.err(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsResult_ErrCopyWith<$Res>
    implements $JsResultCopyWith<$Res> {
  factory $JsResult_ErrCopyWith(
          JsResult_Err value, $Res Function(JsResult_Err) _then) =
      _$JsResult_ErrCopyWithImpl;
  @useResult
  $Res call({JsError field0});

  $JsErrorCopyWith<$Res> get field0;
}

/// @nodoc
class _$JsResult_ErrCopyWithImpl<$Res> implements $JsResult_ErrCopyWith<$Res> {
  _$JsResult_ErrCopyWithImpl(this._self, this._then);

  final JsResult_Err _self;
  final $Res Function(JsResult_Err) _then;

  /// Create a copy of JsResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsResult_Err(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as JsError,
    ));
  }

  /// Create a copy of JsResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JsErrorCopyWith<$Res> get field0 {
    return $JsErrorCopyWith<$Res>(_self.field0, (value) {
      return _then(_self.copyWith(field0: value));
    });
  }
}

// dart format on
