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
mixin _$JsEngineRuntimeOptions {
  BigInt? get memoryLimit;
  BigInt? get gcThreshold;
  BigInt? get maxStackSize;
  String? get info;

  /// Create a copy of JsEngineRuntimeOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsEngineRuntimeOptionsCopyWith<JsEngineRuntimeOptions> get copyWith =>
      _$JsEngineRuntimeOptionsCopyWithImpl<JsEngineRuntimeOptions>(
          this as JsEngineRuntimeOptions, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsEngineRuntimeOptions &&
            (identical(other.memoryLimit, memoryLimit) ||
                other.memoryLimit == memoryLimit) &&
            (identical(other.gcThreshold, gcThreshold) ||
                other.gcThreshold == gcThreshold) &&
            (identical(other.maxStackSize, maxStackSize) ||
                other.maxStackSize == maxStackSize) &&
            (identical(other.info, info) || other.info == info));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, memoryLimit, gcThreshold, maxStackSize, info);

  @override
  String toString() {
    return 'JsEngineRuntimeOptions(memoryLimit: $memoryLimit, gcThreshold: $gcThreshold, maxStackSize: $maxStackSize, info: $info)';
  }
}

/// @nodoc
abstract mixin class $JsEngineRuntimeOptionsCopyWith<$Res> {
  factory $JsEngineRuntimeOptionsCopyWith(JsEngineRuntimeOptions value,
          $Res Function(JsEngineRuntimeOptions) _then) =
      _$JsEngineRuntimeOptionsCopyWithImpl;
  @useResult
  $Res call(
      {BigInt? memoryLimit,
      BigInt? gcThreshold,
      BigInt? maxStackSize,
      String? info});
}

/// @nodoc
class _$JsEngineRuntimeOptionsCopyWithImpl<$Res>
    implements $JsEngineRuntimeOptionsCopyWith<$Res> {
  _$JsEngineRuntimeOptionsCopyWithImpl(this._self, this._then);

  final JsEngineRuntimeOptions _self;
  final $Res Function(JsEngineRuntimeOptions) _then;

  /// Create a copy of JsEngineRuntimeOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memoryLimit = freezed,
    Object? gcThreshold = freezed,
    Object? maxStackSize = freezed,
    Object? info = freezed,
  }) {
    return _then(_self.copyWith(
      memoryLimit: freezed == memoryLimit
          ? _self.memoryLimit
          : memoryLimit // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      gcThreshold: freezed == gcThreshold
          ? _self.gcThreshold
          : gcThreshold // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      maxStackSize: freezed == maxStackSize
          ? _self.maxStackSize
          : maxStackSize // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      info: freezed == info
          ? _self.info
          : info // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [JsEngineRuntimeOptions].
extension JsEngineRuntimeOptionsPatterns on JsEngineRuntimeOptions {
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
    TResult Function(_JsEngineRuntimeOptions value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JsEngineRuntimeOptions() when $default != null:
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
    TResult Function(_JsEngineRuntimeOptions value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JsEngineRuntimeOptions():
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
    TResult? Function(_JsEngineRuntimeOptions value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JsEngineRuntimeOptions() when $default != null:
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
    TResult Function(BigInt? memoryLimit, BigInt? gcThreshold,
            BigInt? maxStackSize, String? info)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JsEngineRuntimeOptions() when $default != null:
        return $default(_that.memoryLimit, _that.gcThreshold,
            _that.maxStackSize, _that.info);
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
    TResult Function(BigInt? memoryLimit, BigInt? gcThreshold,
            BigInt? maxStackSize, String? info)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JsEngineRuntimeOptions():
        return $default(_that.memoryLimit, _that.gcThreshold,
            _that.maxStackSize, _that.info);
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
    TResult? Function(BigInt? memoryLimit, BigInt? gcThreshold,
            BigInt? maxStackSize, String? info)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JsEngineRuntimeOptions() when $default != null:
        return $default(_that.memoryLimit, _that.gcThreshold,
            _that.maxStackSize, _that.info);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _JsEngineRuntimeOptions extends JsEngineRuntimeOptions {
  const _JsEngineRuntimeOptions(
      {this.memoryLimit, this.gcThreshold, this.maxStackSize, this.info})
      : super._();

  @override
  final BigInt? memoryLimit;
  @override
  final BigInt? gcThreshold;
  @override
  final BigInt? maxStackSize;
  @override
  final String? info;

  /// Create a copy of JsEngineRuntimeOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$JsEngineRuntimeOptionsCopyWith<_JsEngineRuntimeOptions> get copyWith =>
      __$JsEngineRuntimeOptionsCopyWithImpl<_JsEngineRuntimeOptions>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _JsEngineRuntimeOptions &&
            (identical(other.memoryLimit, memoryLimit) ||
                other.memoryLimit == memoryLimit) &&
            (identical(other.gcThreshold, gcThreshold) ||
                other.gcThreshold == gcThreshold) &&
            (identical(other.maxStackSize, maxStackSize) ||
                other.maxStackSize == maxStackSize) &&
            (identical(other.info, info) || other.info == info));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, memoryLimit, gcThreshold, maxStackSize, info);

  @override
  String toString() {
    return 'JsEngineRuntimeOptions(memoryLimit: $memoryLimit, gcThreshold: $gcThreshold, maxStackSize: $maxStackSize, info: $info)';
  }
}

/// @nodoc
abstract mixin class _$JsEngineRuntimeOptionsCopyWith<$Res>
    implements $JsEngineRuntimeOptionsCopyWith<$Res> {
  factory _$JsEngineRuntimeOptionsCopyWith(_JsEngineRuntimeOptions value,
          $Res Function(_JsEngineRuntimeOptions) _then) =
      __$JsEngineRuntimeOptionsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {BigInt? memoryLimit,
      BigInt? gcThreshold,
      BigInt? maxStackSize,
      String? info});
}

/// @nodoc
class __$JsEngineRuntimeOptionsCopyWithImpl<$Res>
    implements _$JsEngineRuntimeOptionsCopyWith<$Res> {
  __$JsEngineRuntimeOptionsCopyWithImpl(this._self, this._then);

  final _JsEngineRuntimeOptions _self;
  final $Res Function(_JsEngineRuntimeOptions) _then;

  /// Create a copy of JsEngineRuntimeOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? memoryLimit = freezed,
    Object? gcThreshold = freezed,
    Object? maxStackSize = freezed,
    Object? info = freezed,
  }) {
    return _then(_JsEngineRuntimeOptions(
      memoryLimit: freezed == memoryLimit
          ? _self.memoryLimit
          : memoryLimit // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      gcThreshold: freezed == gcThreshold
          ? _self.gcThreshold
          : gcThreshold // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      maxStackSize: freezed == maxStackSize
          ? _self.maxStackSize
          : maxStackSize // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      info: freezed == info
          ? _self.info
          : info // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
