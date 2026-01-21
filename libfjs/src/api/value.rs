//! # JavaScript Value Conversion
//!
//! This module provides type-safe conversion between JavaScript values and Rust types.
//! It supports all primitive JavaScript types as well as complex structures like
//! arrays and objects, enabling seamless data exchange between Dart and JavaScript.
//!
//! ## Features
//!
//! - **Primitive Types**: Numbers, strings, booleans, null/undefined
//! - **Collections**: Arrays and objects with nested support
//! - **BigInt Support**: Safe handling of large integers
//! - **Type Safety**: Compile-time and runtime type checking
//! - **Zero-copy**: Efficient conversion where possible
//! - **ArrayBuffer/TypedArray**: Binary data support

use flutter_rust_bridge::frb;
use rquickjs::function::Constructor;
use rquickjs::{Ctx, FromAtom, FromJs, IntoJs, Null, Type};
use std::collections::HashMap;

/// Represents a JavaScript value with type-safe conversion.
///
/// This enum provides a comprehensive representation of all JavaScript value types,
/// enabling safe and efficient conversion between JavaScript and Rust/Dart values.
/// Each variant corresponds to a specific JavaScript type.
#[derive(Debug, Clone, PartialEq)]
#[frb(dart_metadata = ("freezed"), dart_code = r#"

  /// Creates a JsValue from any Dart object.
  static JsValue from(Object? any) {
    if (any == null) {
      return const JsValue.none();
    } else if (any is bool) {
      return JsValue.boolean(any);
    } else if (any is int) {
      return JsValue.integer(any);
    } else if (any is double) {
      return JsValue.float(any);
    } else if (any is BigInt) {
      return JsValue.bigint(any.toString());
    } else if (any is String) {
      return JsValue.string(any);
    } else if (any is Uint8List) {
      return JsValue.bytes(any);
    } else if (any is List) {
      return JsValue.array(any.map((e) => from(e)).toList());
    } else if (any is Map) {
      return JsValue.object(
        any.map((key, value) => MapEntry(key.toString(), from(value))),
      );
    } else {
      throw Exception("Unsupported type: ${any.runtimeType}");
    }
  }

  /// Gets the underlying Dart value.
  dynamic get value => when(
        none: () => null,
        boolean: (v) => v,
        integer: (v) => v,
        float: (v) => v,
        bigint: (v) => BigInt.parse(v),
        string: (v) => v,
        bytes: (v) => v,
        array: (v) => v.map((e) => e.value).toList(),
        object: (v) => v.map((key, value) => MapEntry(key, value.value)),
        date: (ms) => DateTime.fromMillisecondsSinceEpoch(ms.toInt()),
        symbol: (v) => v,
        function: (v) => v,
      );

  /// Safe casting methods
  bool? get asBoolean => this is JsValue_Boolean ? (this as JsValue_Boolean).field0 : null;
  int? get asInteger => this is JsValue_Integer ? (this as JsValue_Integer).field0 : null;
  double? get asFloat => this is JsValue_Float ? (this as JsValue_Float).field0 : null;
  String? get asBigint => this is JsValue_Bigint ? (this as JsValue_Bigint).field0 : null;
  String? get asString => this is JsValue_String ? (this as JsValue_String).field0 : null;
  Uint8List? get asBytes => this is JsValue_Bytes ? (this as JsValue_Bytes).field0 : null;
  List<JsValue>? get asArray => this is JsValue_Array ? (this as JsValue_Array).field0 : null;
  Map<String, JsValue>? get asObject => this is JsValue_Object ? (this as JsValue_Object).field0 : null;

  /// Converts to num if possible.
  num? get asNum {
    if (this is JsValue_Integer) return (this as JsValue_Integer).field0;
    if (this is JsValue_Float) return (this as JsValue_Float).field0;
    if (this is JsValue_Bigint) {
      final bigint = BigInt.parse((this as JsValue_Bigint).field0);
      if (bigint >= BigInt.from(-9007199254740991) && bigint <= BigInt.from(9007199254740991)) {
        return bigint.toInt();
      }
    }
    return null;
  }
"#)]
pub enum JsValue {
    /// Represents null or undefined values in JavaScript
    None,
    /// Represents boolean values (true/false)
    Boolean(bool),
    /// Represents 64-bit integer values
    Integer(i64),
    /// Represents floating-point number values
    Float(f64),
    /// Represents BigInt values stored as strings for precision
    Bigint(String),
    /// Represents string values
    String(String),
    /// Represents binary data (ArrayBuffer/TypedArray)
    Bytes(Vec<u8>),
    /// Represents arrays with nested value support
    Array(Vec<JsValue>),
    /// Represents objects with string keys and arbitrary values
    Object(HashMap<String, JsValue>),
    /// Represents Date objects (milliseconds since epoch)
    Date(i64),
    /// Represents Symbol values (description)
    Symbol(String),
    /// Represents function references (serialized name/id)
    Function(String),
}

impl Default for JsValue {
    fn default() -> Self {
        JsValue::None
    }
}

impl JsValue {
    /// Creates a None value.
    ///
    /// Represents null or undefined in JavaScript.
    ///
    /// ## Returns
    ///
    /// A `JsValue::None` instance
    #[frb(ignore)]
    pub fn none() -> Self {
        JsValue::None
    }

    /// Creates a boolean value.
    ///
    /// ## Parameters
    ///
    /// - `v`: The boolean value
    ///
    /// ## Returns
    ///
    /// A `JsValue::Boolean` instance
    #[frb(ignore)]
    pub fn boolean(v: bool) -> Self {
        JsValue::Boolean(v)
    }

    /// Creates an integer value.
    ///
    /// ## Parameters
    ///
    /// - `v`: The integer value
    ///
    /// ## Returns
    ///
    /// A `JsValue::Integer` instance
    #[frb(ignore)]
    pub fn integer(v: i64) -> Self {
        JsValue::Integer(v)
    }

    /// Creates a float value.
    ///
    /// ## Parameters
    ///
    /// - `v`: The floating-point value
    ///
    /// ## Returns
    ///
    /// A `JsValue::Float` instance
    #[frb(ignore)]
    pub fn float(v: f64) -> Self {
        JsValue::Float(v)
    }

    /// Creates a bigint value from a string.
    ///
    /// BigInt values are stored as strings to preserve precision
    /// for arbitrarily large integers.
    ///
    /// ## Parameters
    ///
    /// - `v`: The bigint value as a string
    ///
    /// ## Returns
    ///
    /// A `JsValue::Bigint` instance
    #[frb(ignore)]
    pub fn bigint<S: Into<String>>(v: S) -> Self {
        JsValue::Bigint(v.into())
    }

    /// Creates a string value.
    ///
    /// ## Parameters
    ///
    /// - `v`: The string value
    ///
    /// ## Returns
    ///
    /// A `JsValue::String` instance
    #[frb(ignore)]
    pub fn string<S: Into<String>>(v: S) -> Self {
        JsValue::String(v.into())
    }

    /// Creates a bytes value.
    ///
    /// Represents binary data (ArrayBuffer/TypedArray in JavaScript).
    ///
    /// ## Parameters
    ///
    /// - `v`: The byte array
    ///
    /// ## Returns
    ///
    /// A `JsValue::Bytes` instance
    #[frb(ignore)]
    pub fn bytes(v: Vec<u8>) -> Self {
        JsValue::Bytes(v)
    }

    /// Creates an array value.
    ///
    /// ## Parameters
    ///
    /// - `v`: The array of `JsValue` elements
    ///
    /// ## Returns
    ///
    /// A `JsValue::Array` instance
    #[frb(ignore)]
    pub fn array(v: Vec<JsValue>) -> Self {
        JsValue::Array(v)
    }

    /// Creates an object value.
    ///
    /// ## Parameters
    ///
    /// - `v`: The object as a HashMap with string keys
    ///
    /// ## Returns
    ///
    /// A `JsValue::Object` instance
    #[frb(ignore)]
    pub fn object(v: HashMap<String, JsValue>) -> Self {
        JsValue::Object(v)
    }

    /// Creates a date value from milliseconds since epoch.
    ///
    /// ## Parameters
    ///
    /// - `ms`: Milliseconds since January 1, 1970, 00:00:00 UTC
    ///
    /// ## Returns
    ///
    /// A `JsValue::Date` instance
    #[frb(ignore)]
    pub fn date(ms: i64) -> Self {
        JsValue::Date(ms)
    }

    /// Returns true if the value is None.
    ///
    /// ## Returns
    ///
    /// `true` if the value is `JsValue::None`, `false` otherwise
    #[frb(sync)]
    pub fn is_none(&self) -> bool {
        matches!(self, JsValue::None)
    }

    /// Returns true if the value is a boolean.
    ///
    /// ## Returns
    ///
    /// `true` if the value is `JsValue::Boolean`, `false` otherwise
    #[frb(sync)]
    pub fn is_boolean(&self) -> bool {
        matches!(self, JsValue::Boolean(_))
    }

    /// Returns true if the value is a number (integer, float, or bigint).
    ///
    /// ## Returns
    ///
    /// `true` if the value is any numeric type, `false` otherwise
    #[frb(sync)]
    pub fn is_number(&self) -> bool {
        matches!(
            self,
            JsValue::Integer(_) | JsValue::Float(_) | JsValue::Bigint(_)
        )
    }

    /// Returns true if the value is a string.
    ///
    /// ## Returns
    ///
    /// `true` if the value is `JsValue::String`, `false` otherwise
    #[frb(sync)]
    pub fn is_string(&self) -> bool {
        matches!(self, JsValue::String(_))
    }

    /// Returns true if the value is an array.
    ///
    /// ## Returns
    ///
    /// `true` if the value is `JsValue::Array`, `false` otherwise
    #[frb(sync)]
    pub fn is_array(&self) -> bool {
        matches!(self, JsValue::Array(_))
    }

    /// Returns true if the value is an object.
    ///
    /// ## Returns
    ///
    /// `true` if the value is `JsValue::Object`, `false` otherwise
    #[frb(sync)]
    pub fn is_object(&self) -> bool {
        matches!(self, JsValue::Object(_))
    }

    /// Returns true if the value is a Date.
    ///
    /// ## Returns
    ///
    /// `true` if the value is `JsValue::Date`, `false` otherwise
    #[frb(sync)]
    pub fn is_date(&self) -> bool {
        matches!(self, JsValue::Date(_))
    }

    /// Returns true if the value is bytes (binary data).
    ///
    /// ## Returns
    ///
    /// `true` if the value is `JsValue::Bytes`, `false` otherwise
    #[frb(sync)]
    pub fn is_bytes(&self) -> bool {
        matches!(self, JsValue::Bytes(_))
    }

    /// Returns true if the value is a primitive type.
    ///
    /// Primitive types include: None, Boolean, Integer, Float, Bigint, and String.
    ///
    /// ## Returns
    ///
    /// `true` if the value is a primitive type, `false` otherwise
    #[frb(sync)]
    pub fn is_primitive(&self) -> bool {
        matches!(
            self,
            JsValue::None
                | JsValue::Boolean(_)
                | JsValue::Integer(_)
                | JsValue::Float(_)
                | JsValue::Bigint(_)
                | JsValue::String(_)
        )
    }

    /// Returns the type name of this value.
    ///
    /// Returns a string representation of the JavaScript type name.
    ///
    /// ## Returns
    ///
    /// The type name as a string (e.g., "null", "boolean", "number", "string", "Array", "Object", etc.)
    ///
    /// ## Example
    ///
    /// ```dart
    /// final value = JsValue.string("hello");
    /// print(value.typeName()); // "string"
    /// ```
    #[frb(sync)]
    pub fn type_name(&self) -> String {
        match self {
            JsValue::None => "null".to_string(),
            JsValue::Boolean(_) => "boolean".to_string(),
            JsValue::Integer(_) => "number".to_string(),
            JsValue::Float(_) => "number".to_string(),
            JsValue::Bigint(_) => "bigint".to_string(),
            JsValue::String(_) => "string".to_string(),
            JsValue::Bytes(_) => "ArrayBuffer".to_string(),
            JsValue::Array(_) => "Array".to_string(),
            JsValue::Object(_) => "Object".to_string(),
            JsValue::Date(_) => "Date".to_string(),
            JsValue::Symbol(_) => "symbol".to_string(),
            JsValue::Function(_) => "function".to_string(),
        }
    }
}

impl<'js> FromJs<'js> for JsValue {
    /// Converts a JavaScript value to a JsValue enum.
    fn from_js(ctx: &Ctx<'js>, value: rquickjs::Value<'js>) -> rquickjs::Result<Self> {
        let v = match value.type_of() {
            Type::String => {
                let s = value
                    .as_string()
                    .ok_or_else(|| rquickjs::Error::new_from_js("value", "String"))?;
                JsValue::String(s.to_string()?)
            }
            Type::Array => {
                let arr = value
                    .as_array()
                    .ok_or_else(|| rquickjs::Error::new_from_js("value", "Array"))?;
                let mut vec = Vec::with_capacity(arr.len());
                for item in arr.iter() {
                    let item = item?;
                    let value = JsValue::from_js(ctx, item)?;
                    vec.push(value);
                }
                JsValue::Array(vec)
            }
            Type::Object => {
                let obj = value
                    .as_object()
                    .ok_or_else(|| rquickjs::Error::new_from_js("value", "Object"))?;

                // Check for ArrayBuffer
                if let Some(ab) = rquickjs::ArrayBuffer::from_object(obj.clone()) {
                    let bytes: Vec<u8> = ab.as_bytes().map(|b| b.to_vec()).unwrap_or_default();
                    return Ok(JsValue::Bytes(bytes));
                }

                // Check for Date object by looking at constructor name
                if let Ok(constructor) = obj.get::<_, rquickjs::Function>("constructor") {
                    if let Ok(name) = constructor.get::<_, String>("name") {
                        if name == "Date" {
                            if let Ok(get_time) = obj.get::<_, rquickjs::Function>("getTime") {
                                if let Ok(ms) = get_time.call::<_, f64>(()) {
                                    return Ok(JsValue::Date(ms as i64));
                                }
                            }
                        }
                    }
                }

                // Regular object
                let mut map = HashMap::new();
                for prop in obj.props() {
                    let (k, v) = prop?;
                    let value = JsValue::from_js(ctx, v)?;
                    map.insert(String::from_atom(k)?, value);
                }
                JsValue::Object(map)
            }
            Type::Int => {
                let i = value
                    .as_int()
                    .ok_or_else(|| rquickjs::Error::new_from_js("value", "Int"))?;
                JsValue::Integer(i as i64)
            }
            Type::Bool => {
                let b = value
                    .as_bool()
                    .ok_or_else(|| rquickjs::Error::new_from_js("value", "Bool"))?;
                JsValue::Boolean(b)
            }
            Type::Float => {
                let f = value
                    .as_float()
                    .ok_or_else(|| rquickjs::Error::new_from_js("value", "Float"))?;
                JsValue::Float(f)
            }
            Type::BigInt => {
                // Convert BigInt using native rquickjs API
                if let Some(bigint) = value.as_big_int() {
                    // Try to convert to i64 first, if it fails, use string representation
                    match bigint.clone().to_i64() {
                        Ok(v) => JsValue::Bigint(v.to_string()),
                        Err(_) => {
                            // For very large BigInts, use JSON.stringify approach
                            let global = ctx.globals();
                            if let Ok(json) = global.get::<_, rquickjs::Object>("JSON") {
                                if let Ok(stringify) =
                                    json.get::<_, rquickjs::Function>("stringify")
                                {
                                    if let Ok(s) = stringify.call::<_, rquickjs::String>((value,))
                                    {
                                        return Ok(JsValue::Bigint(s.to_string()?));
                                    }
                                }
                            }
                            // Fallback
                            JsValue::Bigint("0".to_string())
                        }
                    }
                } else {
                    JsValue::None
                }
            }
            Type::Symbol => {
                // Get symbol description using native rquickjs Symbol API
                if let Some(symbol) = value.as_symbol() {
                    match symbol.description() {
                        Ok(desc) => {
                            if desc.is_undefined() {
                                JsValue::Symbol(String::new())
                            } else if let Some(s) = desc.as_string() {
                                JsValue::Symbol(s.to_string().unwrap_or_default())
                            } else {
                                JsValue::Symbol(String::new())
                            }
                        }
                        Err(_) => JsValue::Symbol(String::new()),
                    }
                } else {
                    JsValue::Symbol(String::new())
                }
            }
            Type::Function => {
                // Serialize function name if available
                if let Some(func) = value.as_function() {
                    if let Ok(name) = func.get::<_, String>("name") {
                        JsValue::Function(name)
                    } else {
                        JsValue::Function("<anonymous>".to_string())
                    }
                } else {
                    JsValue::None
                }
            }
            Type::Uninitialized
            | Type::Undefined
            | Type::Null
            | Type::Constructor
            | Type::Promise
            | Type::Exception
            | Type::Module
            | Type::Proxy
            | Type::Unknown => JsValue::None,
        };
        Ok(v)
    }
}

impl<'js> IntoJs<'js> for JsValue {
    /// Converts a JsValue to a JavaScript value.
    fn into_js(self, ctx: &Ctx<'js>) -> rquickjs::Result<rquickjs::Value<'js>> {
        match self {
            JsValue::None => Null.into_js(ctx),
            JsValue::Boolean(v) => Ok(rquickjs::Value::new_bool(ctx.clone(), v)),
            JsValue::Integer(v) => Ok(rquickjs::Value::new_number(ctx.clone(), v as _)),
            JsValue::Float(v) => Ok(rquickjs::Value::new_float(ctx.clone(), v)),
            JsValue::Bigint(v) => {
                let value = rquickjs::String::from_str(ctx.clone(), &v)?.into_js(ctx)?;
                rquickjs::BigInt::from_value(value).into_js(ctx)
            }
            JsValue::String(v) => rquickjs::String::from_str(ctx.clone(), &v)?.into_js(ctx),
            JsValue::Bytes(v) => {
                let ab = rquickjs::ArrayBuffer::new(ctx.clone(), v)?;
                ab.into_js(ctx)
            }
            JsValue::Array(v) => {
                let arr = rquickjs::Array::new(ctx.clone())?;
                for (i, item) in v.into_iter().enumerate() {
                    arr.set(i, item.into_js(ctx)?)?;
                }
                arr.into_js(ctx)
            }
            JsValue::Object(v) => {
                let obj = rquickjs::Object::new(ctx.clone())?;
                for (k, val) in v.into_iter() {
                    obj.set(k, val.into_js(ctx)?)?;
                }
                obj.into_js(ctx)
            }
            JsValue::Date(ms) => {
                // Create a Date object using the constructor
                let global = ctx.globals();
                let date_constructor: Constructor = global.get("Date")?;
                let date = date_constructor.construct::<_, rquickjs::Value>((ms as f64,))?;
                Ok(date)
            }
            JsValue::Symbol(desc) => {
                let global = ctx.globals();
                let symbol_constructor: rquickjs::Function = global.get("Symbol")?;
                let symbol = symbol_constructor.call::<_, rquickjs::Value>((desc,))?;
                Ok(symbol)
            }
            JsValue::Function(_) => {
                // Cannot recreate functions, return undefined
                Ok(rquickjs::Value::new_undefined(ctx.clone()))
            }
        }
    }
}

// Implement From traits for common types
impl From<bool> for JsValue {
    fn from(v: bool) -> Self {
        JsValue::Boolean(v)
    }
}

impl From<i32> for JsValue {
    fn from(v: i32) -> Self {
        JsValue::Integer(v as i64)
    }
}

impl From<i64> for JsValue {
    fn from(v: i64) -> Self {
        JsValue::Integer(v)
    }
}

impl From<f64> for JsValue {
    fn from(v: f64) -> Self {
        JsValue::Float(v)
    }
}

impl From<String> for JsValue {
    fn from(v: String) -> Self {
        JsValue::String(v)
    }
}

impl From<&str> for JsValue {
    fn from(v: &str) -> Self {
        JsValue::String(v.to_string())
    }
}

impl From<Vec<u8>> for JsValue {
    fn from(v: Vec<u8>) -> Self {
        JsValue::Bytes(v)
    }
}

impl<T: Into<JsValue>> From<Vec<T>> for JsValue {
    fn from(v: Vec<T>) -> Self {
        JsValue::Array(v.into_iter().map(|x| x.into()).collect())
    }
}

impl<T: Into<JsValue>> From<Option<T>> for JsValue {
    fn from(v: Option<T>) -> Self {
        match v {
            Some(v) => v.into(),
            None => JsValue::None,
        }
    }
}

impl From<()> for JsValue {
    fn from(_: ()) -> Self {
        JsValue::None
    }
}
