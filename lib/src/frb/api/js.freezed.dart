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
    TResult Function(JsAction_DeclareModule value)? declareModule,
    TResult Function(JsAction_EvaluateModule value)? evaluateModule,
    TResult Function(JsAction_ImportModule value)? importModule,
    TResult Function(JsAction_EnableBuiltinModule value)? enableBuiltinModule,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsAction_Eval() when eval != null:
        return eval(_that);
      case JsAction_DeclareModule() when declareModule != null:
        return declareModule(_that);
      case JsAction_EvaluateModule() when evaluateModule != null:
        return evaluateModule(_that);
      case JsAction_ImportModule() when importModule != null:
        return importModule(_that);
      case JsAction_EnableBuiltinModule() when enableBuiltinModule != null:
        return enableBuiltinModule(_that);
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
    required TResult Function(JsAction_DeclareModule value) declareModule,
    required TResult Function(JsAction_EvaluateModule value) evaluateModule,
    required TResult Function(JsAction_ImportModule value) importModule,
    required TResult Function(JsAction_EnableBuiltinModule value)
        enableBuiltinModule,
  }) {
    final _that = this;
    switch (_that) {
      case JsAction_Eval():
        return eval(_that);
      case JsAction_DeclareModule():
        return declareModule(_that);
      case JsAction_EvaluateModule():
        return evaluateModule(_that);
      case JsAction_ImportModule():
        return importModule(_that);
      case JsAction_EnableBuiltinModule():
        return enableBuiltinModule(_that);
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
    TResult? Function(JsAction_DeclareModule value)? declareModule,
    TResult? Function(JsAction_EvaluateModule value)? evaluateModule,
    TResult? Function(JsAction_ImportModule value)? importModule,
    TResult? Function(JsAction_EnableBuiltinModule value)? enableBuiltinModule,
  }) {
    final _that = this;
    switch (_that) {
      case JsAction_Eval() when eval != null:
        return eval(_that);
      case JsAction_DeclareModule() when declareModule != null:
        return declareModule(_that);
      case JsAction_EvaluateModule() when evaluateModule != null:
        return evaluateModule(_that);
      case JsAction_ImportModule() when importModule != null:
        return importModule(_that);
      case JsAction_EnableBuiltinModule() when enableBuiltinModule != null:
        return enableBuiltinModule(_that);
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
    TResult Function(int id, JsModule module)? declareModule,
    TResult Function(int id, JsModule module)? evaluateModule,
    TResult Function(int id, String specifier)? importModule,
    TResult Function(int id, JsBuiltinOptions builtinOptions)?
        enableBuiltinModule,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsAction_Eval() when eval != null:
        return eval(_that.id, _that.source, _that.options);
      case JsAction_DeclareModule() when declareModule != null:
        return declareModule(_that.id, _that.module);
      case JsAction_EvaluateModule() when evaluateModule != null:
        return evaluateModule(_that.id, _that.module);
      case JsAction_ImportModule() when importModule != null:
        return importModule(_that.id, _that.specifier);
      case JsAction_EnableBuiltinModule() when enableBuiltinModule != null:
        return enableBuiltinModule(_that.id, _that.builtinOptions);
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
    required TResult Function(int id, JsModule module) declareModule,
    required TResult Function(int id, JsModule module) evaluateModule,
    required TResult Function(int id, String specifier) importModule,
    required TResult Function(int id, JsBuiltinOptions builtinOptions)
        enableBuiltinModule,
  }) {
    final _that = this;
    switch (_that) {
      case JsAction_Eval():
        return eval(_that.id, _that.source, _that.options);
      case JsAction_DeclareModule():
        return declareModule(_that.id, _that.module);
      case JsAction_EvaluateModule():
        return evaluateModule(_that.id, _that.module);
      case JsAction_ImportModule():
        return importModule(_that.id, _that.specifier);
      case JsAction_EnableBuiltinModule():
        return enableBuiltinModule(_that.id, _that.builtinOptions);
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
    TResult? Function(int id, JsModule module)? declareModule,
    TResult? Function(int id, JsModule module)? evaluateModule,
    TResult? Function(int id, String specifier)? importModule,
    TResult? Function(int id, JsBuiltinOptions builtinOptions)?
        enableBuiltinModule,
  }) {
    final _that = this;
    switch (_that) {
      case JsAction_Eval() when eval != null:
        return eval(_that.id, _that.source, _that.options);
      case JsAction_DeclareModule() when declareModule != null:
        return declareModule(_that.id, _that.module);
      case JsAction_EvaluateModule() when evaluateModule != null:
        return evaluateModule(_that.id, _that.module);
      case JsAction_ImportModule() when importModule != null:
        return importModule(_that.id, _that.specifier);
      case JsAction_EnableBuiltinModule() when enableBuiltinModule != null:
        return enableBuiltinModule(_that.id, _that.builtinOptions);
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

class JsAction_DeclareModule extends JsAction {
  const JsAction_DeclareModule({required this.id, required this.module})
      : super._();

  @override
  final int id;
  final JsModule module;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsAction_DeclareModuleCopyWith<JsAction_DeclareModule> get copyWith =>
      _$JsAction_DeclareModuleCopyWithImpl<JsAction_DeclareModule>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsAction_DeclareModule &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.module, module) || other.module == module));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, module);

  @override
  String toString() {
    return 'JsAction.declareModule(id: $id, module: $module)';
  }
}

/// @nodoc
abstract mixin class $JsAction_DeclareModuleCopyWith<$Res>
    implements $JsActionCopyWith<$Res> {
  factory $JsAction_DeclareModuleCopyWith(JsAction_DeclareModule value,
          $Res Function(JsAction_DeclareModule) _then) =
      _$JsAction_DeclareModuleCopyWithImpl;
  @override
  @useResult
  $Res call({int id, JsModule module});

  $JsModuleCopyWith<$Res> get module;
}

/// @nodoc
class _$JsAction_DeclareModuleCopyWithImpl<$Res>
    implements $JsAction_DeclareModuleCopyWith<$Res> {
  _$JsAction_DeclareModuleCopyWithImpl(this._self, this._then);

  final JsAction_DeclareModule _self;
  final $Res Function(JsAction_DeclareModule) _then;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? module = null,
  }) {
    return _then(JsAction_DeclareModule(
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

class JsAction_ImportModule extends JsAction {
  const JsAction_ImportModule({required this.id, required this.specifier})
      : super._();

  @override
  final int id;
  final String specifier;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsAction_ImportModuleCopyWith<JsAction_ImportModule> get copyWith =>
      _$JsAction_ImportModuleCopyWithImpl<JsAction_ImportModule>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsAction_ImportModule &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.specifier, specifier) ||
                other.specifier == specifier));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, specifier);

  @override
  String toString() {
    return 'JsAction.importModule(id: $id, specifier: $specifier)';
  }
}

/// @nodoc
abstract mixin class $JsAction_ImportModuleCopyWith<$Res>
    implements $JsActionCopyWith<$Res> {
  factory $JsAction_ImportModuleCopyWith(JsAction_ImportModule value,
          $Res Function(JsAction_ImportModule) _then) =
      _$JsAction_ImportModuleCopyWithImpl;
  @override
  @useResult
  $Res call({int id, String specifier});
}

/// @nodoc
class _$JsAction_ImportModuleCopyWithImpl<$Res>
    implements $JsAction_ImportModuleCopyWith<$Res> {
  _$JsAction_ImportModuleCopyWithImpl(this._self, this._then);

  final JsAction_ImportModule _self;
  final $Res Function(JsAction_ImportModule) _then;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? specifier = null,
  }) {
    return _then(JsAction_ImportModule(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      specifier: null == specifier
          ? _self.specifier
          : specifier // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsAction_EnableBuiltinModule extends JsAction {
  const JsAction_EnableBuiltinModule(
      {required this.id, required this.builtinOptions})
      : super._();

  @override
  final int id;
  final JsBuiltinOptions builtinOptions;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsAction_EnableBuiltinModuleCopyWith<JsAction_EnableBuiltinModule>
      get copyWith => _$JsAction_EnableBuiltinModuleCopyWithImpl<
          JsAction_EnableBuiltinModule>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsAction_EnableBuiltinModule &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.builtinOptions, builtinOptions) ||
                other.builtinOptions == builtinOptions));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, builtinOptions);

  @override
  String toString() {
    return 'JsAction.enableBuiltinModule(id: $id, builtinOptions: $builtinOptions)';
  }
}

/// @nodoc
abstract mixin class $JsAction_EnableBuiltinModuleCopyWith<$Res>
    implements $JsActionCopyWith<$Res> {
  factory $JsAction_EnableBuiltinModuleCopyWith(
          JsAction_EnableBuiltinModule value,
          $Res Function(JsAction_EnableBuiltinModule) _then) =
      _$JsAction_EnableBuiltinModuleCopyWithImpl;
  @override
  @useResult
  $Res call({int id, JsBuiltinOptions builtinOptions});

  $JsBuiltinOptionsCopyWith<$Res> get builtinOptions;
}

/// @nodoc
class _$JsAction_EnableBuiltinModuleCopyWithImpl<$Res>
    implements $JsAction_EnableBuiltinModuleCopyWith<$Res> {
  _$JsAction_EnableBuiltinModuleCopyWithImpl(this._self, this._then);

  final JsAction_EnableBuiltinModule _self;
  final $Res Function(JsAction_EnableBuiltinModule) _then;

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? builtinOptions = null,
  }) {
    return _then(JsAction_EnableBuiltinModule(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      builtinOptions: null == builtinOptions
          ? _self.builtinOptions
          : builtinOptions // ignore: cast_nullable_to_non_nullable
              as JsBuiltinOptions,
    ));
  }

  /// Create a copy of JsAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JsBuiltinOptionsCopyWith<$Res> get builtinOptions {
    return $JsBuiltinOptionsCopyWith<$Res>(_self.builtinOptions, (value) {
      return _then(_self.copyWith(builtinOptions: value));
    });
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
  bool? get fetch;
  bool? get console;
  bool? get buffer;
  bool? get stringDecoder;
  bool? get timers;
  bool? get stream;
  bool? get crypto;
  bool? get abort;
  bool? get url;
  bool? get events;
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
            (identical(other.fetch, fetch) || other.fetch == fetch) &&
            (identical(other.console, console) || other.console == console) &&
            (identical(other.buffer, buffer) || other.buffer == buffer) &&
            (identical(other.stringDecoder, stringDecoder) ||
                other.stringDecoder == stringDecoder) &&
            (identical(other.timers, timers) || other.timers == timers) &&
            (identical(other.stream, stream) || other.stream == stream) &&
            (identical(other.crypto, crypto) || other.crypto == crypto) &&
            (identical(other.abort, abort) || other.abort == abort) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.events, events) || other.events == events) &&
            (identical(other.json, json) || other.json == json));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fetch, console, buffer,
      stringDecoder, timers, stream, crypto, abort, url, events, json);

  @override
  String toString() {
    return 'JsBuiltinOptions(fetch: $fetch, console: $console, buffer: $buffer, stringDecoder: $stringDecoder, timers: $timers, stream: $stream, crypto: $crypto, abort: $abort, url: $url, events: $events, json: $json)';
  }
}

/// @nodoc
abstract mixin class $JsBuiltinOptionsCopyWith<$Res> {
  factory $JsBuiltinOptionsCopyWith(
          JsBuiltinOptions value, $Res Function(JsBuiltinOptions) _then) =
      _$JsBuiltinOptionsCopyWithImpl;
  @useResult
  $Res call(
      {bool? fetch,
      bool? console,
      bool? buffer,
      bool? stringDecoder,
      bool? timers,
      bool? stream,
      bool? crypto,
      bool? abort,
      bool? url,
      bool? events,
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
    Object? fetch = freezed,
    Object? console = freezed,
    Object? buffer = freezed,
    Object? stringDecoder = freezed,
    Object? timers = freezed,
    Object? stream = freezed,
    Object? crypto = freezed,
    Object? abort = freezed,
    Object? url = freezed,
    Object? events = freezed,
    Object? json = freezed,
  }) {
    return _then(_self.copyWith(
      fetch: freezed == fetch
          ? _self.fetch
          : fetch // ignore: cast_nullable_to_non_nullable
              as bool?,
      console: freezed == console
          ? _self.console
          : console // ignore: cast_nullable_to_non_nullable
              as bool?,
      buffer: freezed == buffer
          ? _self.buffer
          : buffer // ignore: cast_nullable_to_non_nullable
              as bool?,
      stringDecoder: freezed == stringDecoder
          ? _self.stringDecoder
          : stringDecoder // ignore: cast_nullable_to_non_nullable
              as bool?,
      timers: freezed == timers
          ? _self.timers
          : timers // ignore: cast_nullable_to_non_nullable
              as bool?,
      stream: freezed == stream
          ? _self.stream
          : stream // ignore: cast_nullable_to_non_nullable
              as bool?,
      crypto: freezed == crypto
          ? _self.crypto
          : crypto // ignore: cast_nullable_to_non_nullable
              as bool?,
      abort: freezed == abort
          ? _self.abort
          : abort // ignore: cast_nullable_to_non_nullable
              as bool?,
      url: freezed == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as bool?,
      events: freezed == events
          ? _self.events
          : events // ignore: cast_nullable_to_non_nullable
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
            bool? fetch,
            bool? console,
            bool? buffer,
            bool? stringDecoder,
            bool? timers,
            bool? stream,
            bool? crypto,
            bool? abort,
            bool? url,
            bool? events,
            bool? json)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JsBuiltinOptions() when $default != null:
        return $default(
            _that.fetch,
            _that.console,
            _that.buffer,
            _that.stringDecoder,
            _that.timers,
            _that.stream,
            _that.crypto,
            _that.abort,
            _that.url,
            _that.events,
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
            bool? fetch,
            bool? console,
            bool? buffer,
            bool? stringDecoder,
            bool? timers,
            bool? stream,
            bool? crypto,
            bool? abort,
            bool? url,
            bool? events,
            bool? json)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JsBuiltinOptions():
        return $default(
            _that.fetch,
            _that.console,
            _that.buffer,
            _that.stringDecoder,
            _that.timers,
            _that.stream,
            _that.crypto,
            _that.abort,
            _that.url,
            _that.events,
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
            bool? fetch,
            bool? console,
            bool? buffer,
            bool? stringDecoder,
            bool? timers,
            bool? stream,
            bool? crypto,
            bool? abort,
            bool? url,
            bool? events,
            bool? json)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JsBuiltinOptions() when $default != null:
        return $default(
            _that.fetch,
            _that.console,
            _that.buffer,
            _that.stringDecoder,
            _that.timers,
            _that.stream,
            _that.crypto,
            _that.abort,
            _that.url,
            _that.events,
            _that.json);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _JsBuiltinOptions extends JsBuiltinOptions {
  const _JsBuiltinOptions(
      {this.fetch,
      this.console,
      this.buffer,
      this.stringDecoder,
      this.timers,
      this.stream,
      this.crypto,
      this.abort,
      this.url,
      this.events,
      this.json})
      : super._();

  @override
  final bool? fetch;
  @override
  final bool? console;
  @override
  final bool? buffer;
  @override
  final bool? stringDecoder;
  @override
  final bool? timers;
  @override
  final bool? stream;
  @override
  final bool? crypto;
  @override
  final bool? abort;
  @override
  final bool? url;
  @override
  final bool? events;
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
            (identical(other.fetch, fetch) || other.fetch == fetch) &&
            (identical(other.console, console) || other.console == console) &&
            (identical(other.buffer, buffer) || other.buffer == buffer) &&
            (identical(other.stringDecoder, stringDecoder) ||
                other.stringDecoder == stringDecoder) &&
            (identical(other.timers, timers) || other.timers == timers) &&
            (identical(other.stream, stream) || other.stream == stream) &&
            (identical(other.crypto, crypto) || other.crypto == crypto) &&
            (identical(other.abort, abort) || other.abort == abort) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.events, events) || other.events == events) &&
            (identical(other.json, json) || other.json == json));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fetch, console, buffer,
      stringDecoder, timers, stream, crypto, abort, url, events, json);

  @override
  String toString() {
    return 'JsBuiltinOptions(fetch: $fetch, console: $console, buffer: $buffer, stringDecoder: $stringDecoder, timers: $timers, stream: $stream, crypto: $crypto, abort: $abort, url: $url, events: $events, json: $json)';
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
      {bool? fetch,
      bool? console,
      bool? buffer,
      bool? stringDecoder,
      bool? timers,
      bool? stream,
      bool? crypto,
      bool? abort,
      bool? url,
      bool? events,
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
    Object? fetch = freezed,
    Object? console = freezed,
    Object? buffer = freezed,
    Object? stringDecoder = freezed,
    Object? timers = freezed,
    Object? stream = freezed,
    Object? crypto = freezed,
    Object? abort = freezed,
    Object? url = freezed,
    Object? events = freezed,
    Object? json = freezed,
  }) {
    return _then(_JsBuiltinOptions(
      fetch: freezed == fetch
          ? _self.fetch
          : fetch // ignore: cast_nullable_to_non_nullable
              as bool?,
      console: freezed == console
          ? _self.console
          : console // ignore: cast_nullable_to_non_nullable
              as bool?,
      buffer: freezed == buffer
          ? _self.buffer
          : buffer // ignore: cast_nullable_to_non_nullable
              as bool?,
      stringDecoder: freezed == stringDecoder
          ? _self.stringDecoder
          : stringDecoder // ignore: cast_nullable_to_non_nullable
              as bool?,
      timers: freezed == timers
          ? _self.timers
          : timers // ignore: cast_nullable_to_non_nullable
              as bool?,
      stream: freezed == stream
          ? _self.stream
          : stream // ignore: cast_nullable_to_non_nullable
              as bool?,
      crypto: freezed == crypto
          ? _self.crypto
          : crypto // ignore: cast_nullable_to_non_nullable
              as bool?,
      abort: freezed == abort
          ? _self.abort
          : abort // ignore: cast_nullable_to_non_nullable
              as bool?,
      url: freezed == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as bool?,
      events: freezed == events
          ? _self.events
          : events // ignore: cast_nullable_to_non_nullable
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
mixin _$JsEvalOptions {
  bool? get global;
  bool? get strict;
  bool? get backtraceBarrier;
  bool? get promise;
  JsBuiltinOptions? get builtinOptions;

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
            (identical(other.promise, promise) || other.promise == promise) &&
            (identical(other.builtinOptions, builtinOptions) ||
                other.builtinOptions == builtinOptions));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, global, strict, backtraceBarrier, promise, builtinOptions);

  @override
  String toString() {
    return 'JsEvalOptions(global: $global, strict: $strict, backtraceBarrier: $backtraceBarrier, promise: $promise, builtinOptions: $builtinOptions)';
  }
}

/// @nodoc
abstract mixin class $JsEvalOptionsCopyWith<$Res> {
  factory $JsEvalOptionsCopyWith(
          JsEvalOptions value, $Res Function(JsEvalOptions) _then) =
      _$JsEvalOptionsCopyWithImpl;
  @useResult
  $Res call(
      {bool? global,
      bool? strict,
      bool? backtraceBarrier,
      bool? promise,
      JsBuiltinOptions? builtinOptions});

  $JsBuiltinOptionsCopyWith<$Res>? get builtinOptions;
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
    Object? builtinOptions = freezed,
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
      builtinOptions: freezed == builtinOptions
          ? _self.builtinOptions
          : builtinOptions // ignore: cast_nullable_to_non_nullable
              as JsBuiltinOptions?,
    ));
  }

  /// Create a copy of JsEvalOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JsBuiltinOptionsCopyWith<$Res>? get builtinOptions {
    if (_self.builtinOptions == null) {
      return null;
    }

    return $JsBuiltinOptionsCopyWith<$Res>(_self.builtinOptions!, (value) {
      return _then(_self.copyWith(builtinOptions: value));
    });
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
    TResult Function(bool? global, bool? strict, bool? backtraceBarrier,
            bool? promise, JsBuiltinOptions? builtinOptions)?
        raw,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JsEvalOptions() when raw != null:
        return raw(_that.global, _that.strict, _that.backtraceBarrier,
            _that.promise, _that.builtinOptions);
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
            bool? global,
            bool? strict,
            bool? backtraceBarrier,
            bool? promise,
            JsBuiltinOptions? builtinOptions)
        raw,
  }) {
    final _that = this;
    switch (_that) {
      case _JsEvalOptions():
        return raw(_that.global, _that.strict, _that.backtraceBarrier,
            _that.promise, _that.builtinOptions);
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
    TResult? Function(bool? global, bool? strict, bool? backtraceBarrier,
            bool? promise, JsBuiltinOptions? builtinOptions)?
        raw,
  }) {
    final _that = this;
    switch (_that) {
      case _JsEvalOptions() when raw != null:
        return raw(_that.global, _that.strict, _that.backtraceBarrier,
            _that.promise, _that.builtinOptions);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _JsEvalOptions extends JsEvalOptions {
  const _JsEvalOptions(
      {this.global,
      this.strict,
      this.backtraceBarrier,
      this.promise,
      this.builtinOptions})
      : super._();

  @override
  final bool? global;
  @override
  final bool? strict;
  @override
  final bool? backtraceBarrier;
  @override
  final bool? promise;
  @override
  final JsBuiltinOptions? builtinOptions;

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
            (identical(other.promise, promise) || other.promise == promise) &&
            (identical(other.builtinOptions, builtinOptions) ||
                other.builtinOptions == builtinOptions));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, global, strict, backtraceBarrier, promise, builtinOptions);

  @override
  String toString() {
    return 'JsEvalOptions.raw(global: $global, strict: $strict, backtraceBarrier: $backtraceBarrier, promise: $promise, builtinOptions: $builtinOptions)';
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
      {bool? global,
      bool? strict,
      bool? backtraceBarrier,
      bool? promise,
      JsBuiltinOptions? builtinOptions});

  @override
  $JsBuiltinOptionsCopyWith<$Res>? get builtinOptions;
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
    Object? builtinOptions = freezed,
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
      builtinOptions: freezed == builtinOptions
          ? _self.builtinOptions
          : builtinOptions // ignore: cast_nullable_to_non_nullable
              as JsBuiltinOptions?,
    ));
  }

  /// Create a copy of JsEvalOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JsBuiltinOptionsCopyWith<$Res>? get builtinOptions {
    if (_self.builtinOptions == null) {
      return null;
    }

    return $JsBuiltinOptionsCopyWith<$Res>(_self.builtinOptions!, (value) {
      return _then(_self.copyWith(builtinOptions: value));
    });
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
    TResult Function(String field0)? err,
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
    required TResult Function(String field0) err,
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
    TResult? Function(String field0)? err,
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
  final String field0;

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
  $Res call({String field0});
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
              as String,
    ));
  }
}

// dart format on
