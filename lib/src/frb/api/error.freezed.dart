// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

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
    TResult Function(JsError_Conversion value)? conversion,
    TResult Function(JsError_Timeout value)? timeout,
    TResult Function(JsError_MemoryLimit value)? memoryLimit,
    TResult Function(JsError_StackOverflow value)? stackOverflow,
    TResult Function(JsError_Syntax value)? syntax,
    TResult Function(JsError_Reference value)? reference,
    TResult Function(JsError_Type value)? type,
    TResult Function(JsError_Cancelled value)? cancelled,
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
      case JsError_Conversion() when conversion != null:
        return conversion(_that);
      case JsError_Timeout() when timeout != null:
        return timeout(_that);
      case JsError_MemoryLimit() when memoryLimit != null:
        return memoryLimit(_that);
      case JsError_StackOverflow() when stackOverflow != null:
        return stackOverflow(_that);
      case JsError_Syntax() when syntax != null:
        return syntax(_that);
      case JsError_Reference() when reference != null:
        return reference(_that);
      case JsError_Type() when type != null:
        return type(_that);
      case JsError_Cancelled() when cancelled != null:
        return cancelled(_that);
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
    required TResult Function(JsError_Conversion value) conversion,
    required TResult Function(JsError_Timeout value) timeout,
    required TResult Function(JsError_MemoryLimit value) memoryLimit,
    required TResult Function(JsError_StackOverflow value) stackOverflow,
    required TResult Function(JsError_Syntax value) syntax,
    required TResult Function(JsError_Reference value) reference,
    required TResult Function(JsError_Type value) type,
    required TResult Function(JsError_Cancelled value) cancelled,
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
      case JsError_Conversion():
        return conversion(_that);
      case JsError_Timeout():
        return timeout(_that);
      case JsError_MemoryLimit():
        return memoryLimit(_that);
      case JsError_StackOverflow():
        return stackOverflow(_that);
      case JsError_Syntax():
        return syntax(_that);
      case JsError_Reference():
        return reference(_that);
      case JsError_Type():
        return type(_that);
      case JsError_Cancelled():
        return cancelled(_that);
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
    TResult? Function(JsError_Conversion value)? conversion,
    TResult? Function(JsError_Timeout value)? timeout,
    TResult? Function(JsError_MemoryLimit value)? memoryLimit,
    TResult? Function(JsError_StackOverflow value)? stackOverflow,
    TResult? Function(JsError_Syntax value)? syntax,
    TResult? Function(JsError_Reference value)? reference,
    TResult? Function(JsError_Type value)? type,
    TResult? Function(JsError_Cancelled value)? cancelled,
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
      case JsError_Conversion() when conversion != null:
        return conversion(_that);
      case JsError_Timeout() when timeout != null:
        return timeout(_that);
      case JsError_MemoryLimit() when memoryLimit != null:
        return memoryLimit(_that);
      case JsError_StackOverflow() when stackOverflow != null:
        return stackOverflow(_that);
      case JsError_Syntax() when syntax != null:
        return syntax(_that);
      case JsError_Reference() when reference != null:
        return reference(_that);
      case JsError_Type() when type != null:
        return type(_that);
      case JsError_Cancelled() when cancelled != null:
        return cancelled(_that);
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
    TResult Function(String from, String to, String message)? conversion,
    TResult Function(String operation, BigInt timeoutMs)? timeout,
    TResult Function(BigInt current, BigInt limit)? memoryLimit,
    TResult Function(String field0)? stackOverflow,
    TResult Function(int? line, int? column, String message)? syntax,
    TResult Function(String field0)? reference,
    TResult Function(String field0)? type,
    TResult Function(String field0)? cancelled,
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
      case JsError_Conversion() when conversion != null:
        return conversion(_that.from, _that.to, _that.message);
      case JsError_Timeout() when timeout != null:
        return timeout(_that.operation, _that.timeoutMs);
      case JsError_MemoryLimit() when memoryLimit != null:
        return memoryLimit(_that.current, _that.limit);
      case JsError_StackOverflow() when stackOverflow != null:
        return stackOverflow(_that.field0);
      case JsError_Syntax() when syntax != null:
        return syntax(_that.line, _that.column, _that.message);
      case JsError_Reference() when reference != null:
        return reference(_that.field0);
      case JsError_Type() when type != null:
        return type(_that.field0);
      case JsError_Cancelled() when cancelled != null:
        return cancelled(_that.field0);
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
    required TResult Function(String from, String to, String message)
        conversion,
    required TResult Function(String operation, BigInt timeoutMs) timeout,
    required TResult Function(BigInt current, BigInt limit) memoryLimit,
    required TResult Function(String field0) stackOverflow,
    required TResult Function(int? line, int? column, String message) syntax,
    required TResult Function(String field0) reference,
    required TResult Function(String field0) type,
    required TResult Function(String field0) cancelled,
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
      case JsError_Conversion():
        return conversion(_that.from, _that.to, _that.message);
      case JsError_Timeout():
        return timeout(_that.operation, _that.timeoutMs);
      case JsError_MemoryLimit():
        return memoryLimit(_that.current, _that.limit);
      case JsError_StackOverflow():
        return stackOverflow(_that.field0);
      case JsError_Syntax():
        return syntax(_that.line, _that.column, _that.message);
      case JsError_Reference():
        return reference(_that.field0);
      case JsError_Type():
        return type(_that.field0);
      case JsError_Cancelled():
        return cancelled(_that.field0);
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
    TResult? Function(String from, String to, String message)? conversion,
    TResult? Function(String operation, BigInt timeoutMs)? timeout,
    TResult? Function(BigInt current, BigInt limit)? memoryLimit,
    TResult? Function(String field0)? stackOverflow,
    TResult? Function(int? line, int? column, String message)? syntax,
    TResult? Function(String field0)? reference,
    TResult? Function(String field0)? type,
    TResult? Function(String field0)? cancelled,
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
      case JsError_Conversion() when conversion != null:
        return conversion(_that.from, _that.to, _that.message);
      case JsError_Timeout() when timeout != null:
        return timeout(_that.operation, _that.timeoutMs);
      case JsError_MemoryLimit() when memoryLimit != null:
        return memoryLimit(_that.current, _that.limit);
      case JsError_StackOverflow() when stackOverflow != null:
        return stackOverflow(_that.field0);
      case JsError_Syntax() when syntax != null:
        return syntax(_that.line, _that.column, _that.message);
      case JsError_Reference() when reference != null:
        return reference(_that.field0);
      case JsError_Type() when type != null:
        return type(_that.field0);
      case JsError_Cancelled() when cancelled != null:
        return cancelled(_that.field0);
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

class JsError_Conversion extends JsError {
  const JsError_Conversion(
      {required this.from, required this.to, required this.message})
      : super._();

  /// The source type
  final String from;

  /// The target type
  final String to;

  /// Error message
  final String message;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_ConversionCopyWith<JsError_Conversion> get copyWith =>
      _$JsError_ConversionCopyWithImpl<JsError_Conversion>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_Conversion &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, from, to, message);
}

/// @nodoc
abstract mixin class $JsError_ConversionCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_ConversionCopyWith(
          JsError_Conversion value, $Res Function(JsError_Conversion) _then) =
      _$JsError_ConversionCopyWithImpl;
  @useResult
  $Res call({String from, String to, String message});
}

/// @nodoc
class _$JsError_ConversionCopyWithImpl<$Res>
    implements $JsError_ConversionCopyWith<$Res> {
  _$JsError_ConversionCopyWithImpl(this._self, this._then);

  final JsError_Conversion _self;
  final $Res Function(JsError_Conversion) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? from = null,
    Object? to = null,
    Object? message = null,
  }) {
    return _then(JsError_Conversion(
      from: null == from
          ? _self.from
          : from // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _self.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsError_Timeout extends JsError {
  const JsError_Timeout({required this.operation, required this.timeoutMs})
      : super._();

  /// Operation that timed out
  final String operation;

  /// Timeout duration in milliseconds
  final BigInt timeoutMs;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_TimeoutCopyWith<JsError_Timeout> get copyWith =>
      _$JsError_TimeoutCopyWithImpl<JsError_Timeout>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_Timeout &&
            (identical(other.operation, operation) ||
                other.operation == operation) &&
            (identical(other.timeoutMs, timeoutMs) ||
                other.timeoutMs == timeoutMs));
  }

  @override
  int get hashCode => Object.hash(runtimeType, operation, timeoutMs);
}

/// @nodoc
abstract mixin class $JsError_TimeoutCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_TimeoutCopyWith(
          JsError_Timeout value, $Res Function(JsError_Timeout) _then) =
      _$JsError_TimeoutCopyWithImpl;
  @useResult
  $Res call({String operation, BigInt timeoutMs});
}

/// @nodoc
class _$JsError_TimeoutCopyWithImpl<$Res>
    implements $JsError_TimeoutCopyWith<$Res> {
  _$JsError_TimeoutCopyWithImpl(this._self, this._then);

  final JsError_Timeout _self;
  final $Res Function(JsError_Timeout) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? operation = null,
    Object? timeoutMs = null,
  }) {
    return _then(JsError_Timeout(
      operation: null == operation
          ? _self.operation
          : operation // ignore: cast_nullable_to_non_nullable
              as String,
      timeoutMs: null == timeoutMs
          ? _self.timeoutMs
          : timeoutMs // ignore: cast_nullable_to_non_nullable
              as BigInt,
    ));
  }
}

/// @nodoc

class JsError_MemoryLimit extends JsError {
  const JsError_MemoryLimit({required this.current, required this.limit})
      : super._();

  /// Current memory usage in bytes
  final BigInt current;

  /// Memory limit in bytes
  final BigInt limit;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_MemoryLimitCopyWith<JsError_MemoryLimit> get copyWith =>
      _$JsError_MemoryLimitCopyWithImpl<JsError_MemoryLimit>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_MemoryLimit &&
            (identical(other.current, current) || other.current == current) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @override
  int get hashCode => Object.hash(runtimeType, current, limit);
}

/// @nodoc
abstract mixin class $JsError_MemoryLimitCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_MemoryLimitCopyWith(
          JsError_MemoryLimit value, $Res Function(JsError_MemoryLimit) _then) =
      _$JsError_MemoryLimitCopyWithImpl;
  @useResult
  $Res call({BigInt current, BigInt limit});
}

/// @nodoc
class _$JsError_MemoryLimitCopyWithImpl<$Res>
    implements $JsError_MemoryLimitCopyWith<$Res> {
  _$JsError_MemoryLimitCopyWithImpl(this._self, this._then);

  final JsError_MemoryLimit _self;
  final $Res Function(JsError_MemoryLimit) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? current = null,
    Object? limit = null,
  }) {
    return _then(JsError_MemoryLimit(
      current: null == current
          ? _self.current
          : current // ignore: cast_nullable_to_non_nullable
              as BigInt,
      limit: null == limit
          ? _self.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as BigInt,
    ));
  }
}

/// @nodoc

class JsError_StackOverflow extends JsError {
  const JsError_StackOverflow(this.field0) : super._();

  final String field0;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_StackOverflowCopyWith<JsError_StackOverflow> get copyWith =>
      _$JsError_StackOverflowCopyWithImpl<JsError_StackOverflow>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_StackOverflow &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);
}

/// @nodoc
abstract mixin class $JsError_StackOverflowCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_StackOverflowCopyWith(JsError_StackOverflow value,
          $Res Function(JsError_StackOverflow) _then) =
      _$JsError_StackOverflowCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsError_StackOverflowCopyWithImpl<$Res>
    implements $JsError_StackOverflowCopyWith<$Res> {
  _$JsError_StackOverflowCopyWithImpl(this._self, this._then);

  final JsError_StackOverflow _self;
  final $Res Function(JsError_StackOverflow) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsError_StackOverflow(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsError_Syntax extends JsError {
  const JsError_Syntax({this.line, this.column, required this.message})
      : super._();

  /// Line number where the error occurred
  final int? line;

  /// Column number where the error occurred
  final int? column;

  /// Error message
  final String message;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_SyntaxCopyWith<JsError_Syntax> get copyWith =>
      _$JsError_SyntaxCopyWithImpl<JsError_Syntax>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_Syntax &&
            (identical(other.line, line) || other.line == line) &&
            (identical(other.column, column) || other.column == column) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, line, column, message);
}

/// @nodoc
abstract mixin class $JsError_SyntaxCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_SyntaxCopyWith(
          JsError_Syntax value, $Res Function(JsError_Syntax) _then) =
      _$JsError_SyntaxCopyWithImpl;
  @useResult
  $Res call({int? line, int? column, String message});
}

/// @nodoc
class _$JsError_SyntaxCopyWithImpl<$Res>
    implements $JsError_SyntaxCopyWith<$Res> {
  _$JsError_SyntaxCopyWithImpl(this._self, this._then);

  final JsError_Syntax _self;
  final $Res Function(JsError_Syntax) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? line = freezed,
    Object? column = freezed,
    Object? message = null,
  }) {
    return _then(JsError_Syntax(
      line: freezed == line
          ? _self.line
          : line // ignore: cast_nullable_to_non_nullable
              as int?,
      column: freezed == column
          ? _self.column
          : column // ignore: cast_nullable_to_non_nullable
              as int?,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsError_Reference extends JsError {
  const JsError_Reference(this.field0) : super._();

  final String field0;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_ReferenceCopyWith<JsError_Reference> get copyWith =>
      _$JsError_ReferenceCopyWithImpl<JsError_Reference>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_Reference &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);
}

/// @nodoc
abstract mixin class $JsError_ReferenceCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_ReferenceCopyWith(
          JsError_Reference value, $Res Function(JsError_Reference) _then) =
      _$JsError_ReferenceCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsError_ReferenceCopyWithImpl<$Res>
    implements $JsError_ReferenceCopyWith<$Res> {
  _$JsError_ReferenceCopyWithImpl(this._self, this._then);

  final JsError_Reference _self;
  final $Res Function(JsError_Reference) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsError_Reference(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsError_Type extends JsError {
  const JsError_Type(this.field0) : super._();

  final String field0;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_TypeCopyWith<JsError_Type> get copyWith =>
      _$JsError_TypeCopyWithImpl<JsError_Type>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_Type &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);
}

/// @nodoc
abstract mixin class $JsError_TypeCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_TypeCopyWith(
          JsError_Type value, $Res Function(JsError_Type) _then) =
      _$JsError_TypeCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsError_TypeCopyWithImpl<$Res> implements $JsError_TypeCopyWith<$Res> {
  _$JsError_TypeCopyWithImpl(this._self, this._then);

  final JsError_Type _self;
  final $Res Function(JsError_Type) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsError_Type(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsError_Cancelled extends JsError {
  const JsError_Cancelled(this.field0) : super._();

  final String field0;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsError_CancelledCopyWith<JsError_Cancelled> get copyWith =>
      _$JsError_CancelledCopyWithImpl<JsError_Cancelled>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsError_Cancelled &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);
}

/// @nodoc
abstract mixin class $JsError_CancelledCopyWith<$Res>
    implements $JsErrorCopyWith<$Res> {
  factory $JsError_CancelledCopyWith(
          JsError_Cancelled value, $Res Function(JsError_Cancelled) _then) =
      _$JsError_CancelledCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsError_CancelledCopyWithImpl<$Res>
    implements $JsError_CancelledCopyWith<$Res> {
  _$JsError_CancelledCopyWithImpl(this._self, this._then);

  final JsError_Cancelled _self;
  final $Res Function(JsError_Cancelled) _then;

  /// Create a copy of JsError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsError_Cancelled(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
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
