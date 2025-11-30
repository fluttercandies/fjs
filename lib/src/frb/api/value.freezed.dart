// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JsValue {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is JsValue);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'JsValue()';
  }
}

/// @nodoc
class $JsValueCopyWith<$Res> {
  $JsValueCopyWith(JsValue _, $Res Function(JsValue) __);
}

/// Adds pattern-matching-related methods to [JsValue].
extension JsValuePatterns on JsValue {
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
    TResult Function(JsValue_None value)? none,
    TResult Function(JsValue_Boolean value)? boolean,
    TResult Function(JsValue_Integer value)? integer,
    TResult Function(JsValue_Float value)? float,
    TResult Function(JsValue_Bigint value)? bigint,
    TResult Function(JsValue_String value)? string,
    TResult Function(JsValue_Bytes value)? bytes,
    TResult Function(JsValue_Array value)? array,
    TResult Function(JsValue_Object value)? object,
    TResult Function(JsValue_Date value)? date,
    TResult Function(JsValue_Symbol value)? symbol,
    TResult Function(JsValue_Function value)? function,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsValue_None() when none != null:
        return none(_that);
      case JsValue_Boolean() when boolean != null:
        return boolean(_that);
      case JsValue_Integer() when integer != null:
        return integer(_that);
      case JsValue_Float() when float != null:
        return float(_that);
      case JsValue_Bigint() when bigint != null:
        return bigint(_that);
      case JsValue_String() when string != null:
        return string(_that);
      case JsValue_Bytes() when bytes != null:
        return bytes(_that);
      case JsValue_Array() when array != null:
        return array(_that);
      case JsValue_Object() when object != null:
        return object(_that);
      case JsValue_Date() when date != null:
        return date(_that);
      case JsValue_Symbol() when symbol != null:
        return symbol(_that);
      case JsValue_Function() when function != null:
        return function(_that);
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
    required TResult Function(JsValue_None value) none,
    required TResult Function(JsValue_Boolean value) boolean,
    required TResult Function(JsValue_Integer value) integer,
    required TResult Function(JsValue_Float value) float,
    required TResult Function(JsValue_Bigint value) bigint,
    required TResult Function(JsValue_String value) string,
    required TResult Function(JsValue_Bytes value) bytes,
    required TResult Function(JsValue_Array value) array,
    required TResult Function(JsValue_Object value) object,
    required TResult Function(JsValue_Date value) date,
    required TResult Function(JsValue_Symbol value) symbol,
    required TResult Function(JsValue_Function value) function,
  }) {
    final _that = this;
    switch (_that) {
      case JsValue_None():
        return none(_that);
      case JsValue_Boolean():
        return boolean(_that);
      case JsValue_Integer():
        return integer(_that);
      case JsValue_Float():
        return float(_that);
      case JsValue_Bigint():
        return bigint(_that);
      case JsValue_String():
        return string(_that);
      case JsValue_Bytes():
        return bytes(_that);
      case JsValue_Array():
        return array(_that);
      case JsValue_Object():
        return object(_that);
      case JsValue_Date():
        return date(_that);
      case JsValue_Symbol():
        return symbol(_that);
      case JsValue_Function():
        return function(_that);
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
    TResult? Function(JsValue_None value)? none,
    TResult? Function(JsValue_Boolean value)? boolean,
    TResult? Function(JsValue_Integer value)? integer,
    TResult? Function(JsValue_Float value)? float,
    TResult? Function(JsValue_Bigint value)? bigint,
    TResult? Function(JsValue_String value)? string,
    TResult? Function(JsValue_Bytes value)? bytes,
    TResult? Function(JsValue_Array value)? array,
    TResult? Function(JsValue_Object value)? object,
    TResult? Function(JsValue_Date value)? date,
    TResult? Function(JsValue_Symbol value)? symbol,
    TResult? Function(JsValue_Function value)? function,
  }) {
    final _that = this;
    switch (_that) {
      case JsValue_None() when none != null:
        return none(_that);
      case JsValue_Boolean() when boolean != null:
        return boolean(_that);
      case JsValue_Integer() when integer != null:
        return integer(_that);
      case JsValue_Float() when float != null:
        return float(_that);
      case JsValue_Bigint() when bigint != null:
        return bigint(_that);
      case JsValue_String() when string != null:
        return string(_that);
      case JsValue_Bytes() when bytes != null:
        return bytes(_that);
      case JsValue_Array() when array != null:
        return array(_that);
      case JsValue_Object() when object != null:
        return object(_that);
      case JsValue_Date() when date != null:
        return date(_that);
      case JsValue_Symbol() when symbol != null:
        return symbol(_that);
      case JsValue_Function() when function != null:
        return function(_that);
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
    TResult Function()? none,
    TResult Function(bool field0)? boolean,
    TResult Function(PlatformInt64 field0)? integer,
    TResult Function(double field0)? float,
    TResult Function(String field0)? bigint,
    TResult Function(String field0)? string,
    TResult Function(Uint8List field0)? bytes,
    TResult Function(List<JsValue> field0)? array,
    TResult Function(Map<String, JsValue> field0)? object,
    TResult Function(PlatformInt64 field0)? date,
    TResult Function(String field0)? symbol,
    TResult Function(String field0)? function,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JsValue_None() when none != null:
        return none();
      case JsValue_Boolean() when boolean != null:
        return boolean(_that.field0);
      case JsValue_Integer() when integer != null:
        return integer(_that.field0);
      case JsValue_Float() when float != null:
        return float(_that.field0);
      case JsValue_Bigint() when bigint != null:
        return bigint(_that.field0);
      case JsValue_String() when string != null:
        return string(_that.field0);
      case JsValue_Bytes() when bytes != null:
        return bytes(_that.field0);
      case JsValue_Array() when array != null:
        return array(_that.field0);
      case JsValue_Object() when object != null:
        return object(_that.field0);
      case JsValue_Date() when date != null:
        return date(_that.field0);
      case JsValue_Symbol() when symbol != null:
        return symbol(_that.field0);
      case JsValue_Function() when function != null:
        return function(_that.field0);
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
    required TResult Function() none,
    required TResult Function(bool field0) boolean,
    required TResult Function(PlatformInt64 field0) integer,
    required TResult Function(double field0) float,
    required TResult Function(String field0) bigint,
    required TResult Function(String field0) string,
    required TResult Function(Uint8List field0) bytes,
    required TResult Function(List<JsValue> field0) array,
    required TResult Function(Map<String, JsValue> field0) object,
    required TResult Function(PlatformInt64 field0) date,
    required TResult Function(String field0) symbol,
    required TResult Function(String field0) function,
  }) {
    final _that = this;
    switch (_that) {
      case JsValue_None():
        return none();
      case JsValue_Boolean():
        return boolean(_that.field0);
      case JsValue_Integer():
        return integer(_that.field0);
      case JsValue_Float():
        return float(_that.field0);
      case JsValue_Bigint():
        return bigint(_that.field0);
      case JsValue_String():
        return string(_that.field0);
      case JsValue_Bytes():
        return bytes(_that.field0);
      case JsValue_Array():
        return array(_that.field0);
      case JsValue_Object():
        return object(_that.field0);
      case JsValue_Date():
        return date(_that.field0);
      case JsValue_Symbol():
        return symbol(_that.field0);
      case JsValue_Function():
        return function(_that.field0);
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
    TResult? Function()? none,
    TResult? Function(bool field0)? boolean,
    TResult? Function(PlatformInt64 field0)? integer,
    TResult? Function(double field0)? float,
    TResult? Function(String field0)? bigint,
    TResult? Function(String field0)? string,
    TResult? Function(Uint8List field0)? bytes,
    TResult? Function(List<JsValue> field0)? array,
    TResult? Function(Map<String, JsValue> field0)? object,
    TResult? Function(PlatformInt64 field0)? date,
    TResult? Function(String field0)? symbol,
    TResult? Function(String field0)? function,
  }) {
    final _that = this;
    switch (_that) {
      case JsValue_None() when none != null:
        return none();
      case JsValue_Boolean() when boolean != null:
        return boolean(_that.field0);
      case JsValue_Integer() when integer != null:
        return integer(_that.field0);
      case JsValue_Float() when float != null:
        return float(_that.field0);
      case JsValue_Bigint() when bigint != null:
        return bigint(_that.field0);
      case JsValue_String() when string != null:
        return string(_that.field0);
      case JsValue_Bytes() when bytes != null:
        return bytes(_that.field0);
      case JsValue_Array() when array != null:
        return array(_that.field0);
      case JsValue_Object() when object != null:
        return object(_that.field0);
      case JsValue_Date() when date != null:
        return date(_that.field0);
      case JsValue_Symbol() when symbol != null:
        return symbol(_that.field0);
      case JsValue_Function() when function != null:
        return function(_that.field0);
      case _:
        return null;
    }
  }
}

/// @nodoc

class JsValue_None extends JsValue {
  const JsValue_None() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is JsValue_None);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'JsValue.none()';
  }
}

/// @nodoc

class JsValue_Boolean extends JsValue {
  const JsValue_Boolean(this.field0) : super._();

  final bool field0;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsValue_BooleanCopyWith<JsValue_Boolean> get copyWith =>
      _$JsValue_BooleanCopyWithImpl<JsValue_Boolean>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsValue_Boolean &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsValue.boolean(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsValue_BooleanCopyWith<$Res>
    implements $JsValueCopyWith<$Res> {
  factory $JsValue_BooleanCopyWith(
          JsValue_Boolean value, $Res Function(JsValue_Boolean) _then) =
      _$JsValue_BooleanCopyWithImpl;
  @useResult
  $Res call({bool field0});
}

/// @nodoc
class _$JsValue_BooleanCopyWithImpl<$Res>
    implements $JsValue_BooleanCopyWith<$Res> {
  _$JsValue_BooleanCopyWithImpl(this._self, this._then);

  final JsValue_Boolean _self;
  final $Res Function(JsValue_Boolean) _then;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsValue_Boolean(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class JsValue_Integer extends JsValue {
  const JsValue_Integer(this.field0) : super._();

  final PlatformInt64 field0;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsValue_IntegerCopyWith<JsValue_Integer> get copyWith =>
      _$JsValue_IntegerCopyWithImpl<JsValue_Integer>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsValue_Integer &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsValue.integer(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsValue_IntegerCopyWith<$Res>
    implements $JsValueCopyWith<$Res> {
  factory $JsValue_IntegerCopyWith(
          JsValue_Integer value, $Res Function(JsValue_Integer) _then) =
      _$JsValue_IntegerCopyWithImpl;
  @useResult
  $Res call({PlatformInt64 field0});
}

/// @nodoc
class _$JsValue_IntegerCopyWithImpl<$Res>
    implements $JsValue_IntegerCopyWith<$Res> {
  _$JsValue_IntegerCopyWithImpl(this._self, this._then);

  final JsValue_Integer _self;
  final $Res Function(JsValue_Integer) _then;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsValue_Integer(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as PlatformInt64,
    ));
  }
}

/// @nodoc

class JsValue_Float extends JsValue {
  const JsValue_Float(this.field0) : super._();

  final double field0;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsValue_FloatCopyWith<JsValue_Float> get copyWith =>
      _$JsValue_FloatCopyWithImpl<JsValue_Float>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsValue_Float &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsValue.float(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsValue_FloatCopyWith<$Res>
    implements $JsValueCopyWith<$Res> {
  factory $JsValue_FloatCopyWith(
          JsValue_Float value, $Res Function(JsValue_Float) _then) =
      _$JsValue_FloatCopyWithImpl;
  @useResult
  $Res call({double field0});
}

/// @nodoc
class _$JsValue_FloatCopyWithImpl<$Res>
    implements $JsValue_FloatCopyWith<$Res> {
  _$JsValue_FloatCopyWithImpl(this._self, this._then);

  final JsValue_Float _self;
  final $Res Function(JsValue_Float) _then;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsValue_Float(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class JsValue_Bigint extends JsValue {
  const JsValue_Bigint(this.field0) : super._();

  final String field0;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsValue_BigintCopyWith<JsValue_Bigint> get copyWith =>
      _$JsValue_BigintCopyWithImpl<JsValue_Bigint>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsValue_Bigint &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsValue.bigint(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsValue_BigintCopyWith<$Res>
    implements $JsValueCopyWith<$Res> {
  factory $JsValue_BigintCopyWith(
          JsValue_Bigint value, $Res Function(JsValue_Bigint) _then) =
      _$JsValue_BigintCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsValue_BigintCopyWithImpl<$Res>
    implements $JsValue_BigintCopyWith<$Res> {
  _$JsValue_BigintCopyWithImpl(this._self, this._then);

  final JsValue_Bigint _self;
  final $Res Function(JsValue_Bigint) _then;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsValue_Bigint(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsValue_String extends JsValue {
  const JsValue_String(this.field0) : super._();

  final String field0;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsValue_StringCopyWith<JsValue_String> get copyWith =>
      _$JsValue_StringCopyWithImpl<JsValue_String>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsValue_String &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsValue.string(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsValue_StringCopyWith<$Res>
    implements $JsValueCopyWith<$Res> {
  factory $JsValue_StringCopyWith(
          JsValue_String value, $Res Function(JsValue_String) _then) =
      _$JsValue_StringCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsValue_StringCopyWithImpl<$Res>
    implements $JsValue_StringCopyWith<$Res> {
  _$JsValue_StringCopyWithImpl(this._self, this._then);

  final JsValue_String _self;
  final $Res Function(JsValue_String) _then;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsValue_String(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsValue_Bytes extends JsValue {
  const JsValue_Bytes(this.field0) : super._();

  final Uint8List field0;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsValue_BytesCopyWith<JsValue_Bytes> get copyWith =>
      _$JsValue_BytesCopyWithImpl<JsValue_Bytes>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsValue_Bytes &&
            const DeepCollectionEquality().equals(other.field0, field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(field0));

  @override
  String toString() {
    return 'JsValue.bytes(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsValue_BytesCopyWith<$Res>
    implements $JsValueCopyWith<$Res> {
  factory $JsValue_BytesCopyWith(
          JsValue_Bytes value, $Res Function(JsValue_Bytes) _then) =
      _$JsValue_BytesCopyWithImpl;
  @useResult
  $Res call({Uint8List field0});
}

/// @nodoc
class _$JsValue_BytesCopyWithImpl<$Res>
    implements $JsValue_BytesCopyWith<$Res> {
  _$JsValue_BytesCopyWithImpl(this._self, this._then);

  final JsValue_Bytes _self;
  final $Res Function(JsValue_Bytes) _then;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsValue_Bytes(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as Uint8List,
    ));
  }
}

/// @nodoc

class JsValue_Array extends JsValue {
  const JsValue_Array(final List<JsValue> field0)
      : _field0 = field0,
        super._();

  final List<JsValue> _field0;
  List<JsValue> get field0 {
    if (_field0 is EqualUnmodifiableListView) return _field0;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_field0);
  }

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsValue_ArrayCopyWith<JsValue_Array> get copyWith =>
      _$JsValue_ArrayCopyWithImpl<JsValue_Array>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsValue_Array &&
            const DeepCollectionEquality().equals(other._field0, _field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_field0));

  @override
  String toString() {
    return 'JsValue.array(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsValue_ArrayCopyWith<$Res>
    implements $JsValueCopyWith<$Res> {
  factory $JsValue_ArrayCopyWith(
          JsValue_Array value, $Res Function(JsValue_Array) _then) =
      _$JsValue_ArrayCopyWithImpl;
  @useResult
  $Res call({List<JsValue> field0});
}

/// @nodoc
class _$JsValue_ArrayCopyWithImpl<$Res>
    implements $JsValue_ArrayCopyWith<$Res> {
  _$JsValue_ArrayCopyWithImpl(this._self, this._then);

  final JsValue_Array _self;
  final $Res Function(JsValue_Array) _then;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsValue_Array(
      null == field0
          ? _self._field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as List<JsValue>,
    ));
  }
}

/// @nodoc

class JsValue_Object extends JsValue {
  const JsValue_Object(final Map<String, JsValue> field0)
      : _field0 = field0,
        super._();

  final Map<String, JsValue> _field0;
  Map<String, JsValue> get field0 {
    if (_field0 is EqualUnmodifiableMapView) return _field0;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_field0);
  }

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsValue_ObjectCopyWith<JsValue_Object> get copyWith =>
      _$JsValue_ObjectCopyWithImpl<JsValue_Object>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsValue_Object &&
            const DeepCollectionEquality().equals(other._field0, _field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_field0));

  @override
  String toString() {
    return 'JsValue.object(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsValue_ObjectCopyWith<$Res>
    implements $JsValueCopyWith<$Res> {
  factory $JsValue_ObjectCopyWith(
          JsValue_Object value, $Res Function(JsValue_Object) _then) =
      _$JsValue_ObjectCopyWithImpl;
  @useResult
  $Res call({Map<String, JsValue> field0});
}

/// @nodoc
class _$JsValue_ObjectCopyWithImpl<$Res>
    implements $JsValue_ObjectCopyWith<$Res> {
  _$JsValue_ObjectCopyWithImpl(this._self, this._then);

  final JsValue_Object _self;
  final $Res Function(JsValue_Object) _then;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsValue_Object(
      null == field0
          ? _self._field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as Map<String, JsValue>,
    ));
  }
}

/// @nodoc

class JsValue_Date extends JsValue {
  const JsValue_Date(this.field0) : super._();

  final PlatformInt64 field0;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsValue_DateCopyWith<JsValue_Date> get copyWith =>
      _$JsValue_DateCopyWithImpl<JsValue_Date>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsValue_Date &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsValue.date(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsValue_DateCopyWith<$Res>
    implements $JsValueCopyWith<$Res> {
  factory $JsValue_DateCopyWith(
          JsValue_Date value, $Res Function(JsValue_Date) _then) =
      _$JsValue_DateCopyWithImpl;
  @useResult
  $Res call({PlatformInt64 field0});
}

/// @nodoc
class _$JsValue_DateCopyWithImpl<$Res> implements $JsValue_DateCopyWith<$Res> {
  _$JsValue_DateCopyWithImpl(this._self, this._then);

  final JsValue_Date _self;
  final $Res Function(JsValue_Date) _then;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsValue_Date(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as PlatformInt64,
    ));
  }
}

/// @nodoc

class JsValue_Symbol extends JsValue {
  const JsValue_Symbol(this.field0) : super._();

  final String field0;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsValue_SymbolCopyWith<JsValue_Symbol> get copyWith =>
      _$JsValue_SymbolCopyWithImpl<JsValue_Symbol>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsValue_Symbol &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsValue.symbol(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsValue_SymbolCopyWith<$Res>
    implements $JsValueCopyWith<$Res> {
  factory $JsValue_SymbolCopyWith(
          JsValue_Symbol value, $Res Function(JsValue_Symbol) _then) =
      _$JsValue_SymbolCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsValue_SymbolCopyWithImpl<$Res>
    implements $JsValue_SymbolCopyWith<$Res> {
  _$JsValue_SymbolCopyWithImpl(this._self, this._then);

  final JsValue_Symbol _self;
  final $Res Function(JsValue_Symbol) _then;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsValue_Symbol(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class JsValue_Function extends JsValue {
  const JsValue_Function(this.field0) : super._();

  final String field0;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JsValue_FunctionCopyWith<JsValue_Function> get copyWith =>
      _$JsValue_FunctionCopyWithImpl<JsValue_Function>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JsValue_Function &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'JsValue.function(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $JsValue_FunctionCopyWith<$Res>
    implements $JsValueCopyWith<$Res> {
  factory $JsValue_FunctionCopyWith(
          JsValue_Function value, $Res Function(JsValue_Function) _then) =
      _$JsValue_FunctionCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$JsValue_FunctionCopyWithImpl<$Res>
    implements $JsValue_FunctionCopyWith<$Res> {
  _$JsValue_FunctionCopyWithImpl(this._self, this._then);

  final JsValue_Function _self;
  final $Res Function(JsValue_Function) _then;

  /// Create a copy of JsValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(JsValue_Function(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
