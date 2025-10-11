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

use flutter_rust_bridge::frb;
use rquickjs::{Ctx, FromAtom, FromJs, IntoJs, Null, Type};
use std::collections::HashMap;

/// Represents a JavaScript value with type-safe conversion.
///
/// This enum provides a comprehensive representation of all JavaScript value types,
/// enabling safe and efficient conversion between JavaScript and Rust/Dart values.
/// Each variant corresponds to a specific JavaScript type.
///
/// ## Variants
///
/// - `None`: Represents `null` or `undefined` in JavaScript
/// - `Boolean`: Represents JavaScript boolean values
/// - `Integer`: Represents JavaScript numbers that fit in 64-bit integers
/// - `Float`: Represents JavaScript floating-point numbers
/// - `Bigint`: Represents JavaScript BigInt values (stored as strings for precision)
/// - `String`: Represents JavaScript string values
/// - `Array`: Represents JavaScript arrays with nested value support
/// - `Object`: Represents JavaScript objects with string keys and arbitrary values
///
/// ## Examples
///
/// ```rust
/// // Creating values
/// let num = JsValue::Integer(42);
/// let str = JsValue::String("hello".to_string());
/// let arr = JsValue::Array(vec![JsValue::Integer(1), JsValue::Integer(2)]);
/// ```
#[derive(Debug, Clone)]
#[frb(dart_metadata = ("freezed"), dart_code = r#"

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

  dynamic get value => when(
        none: () => null,
        boolean: (v) => v,
        integer: (v) => v,
        float: (v) => v,
        bigint: (v) => BigInt.parse(v),
        string: (v) => v,
        array: (v) => v.map((e) => e.value).toList(),
        object: (v) => v.map((key, value) => MapEntry(key, value.value)),
      );

  bool get isNone => this is JsValue_None;

  bool get isBoolean => this is JsValue_Boolean;

  bool get isInteger => this is JsValue_Integer;

  bool get isFloat => this is JsValue_Float;

  bool get isBigint => this is JsValue_Bigint;

  bool get isString => this is JsValue_String;

  bool get isArray => this is JsValue_Array;

  bool get isObject => this is JsValue_Object;
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
    /// Represents arrays with nested value support
    Array(Vec<JsValue>),
    /// Represents objects with string keys and arbitrary values
    Object(HashMap<String, JsValue>),
}

impl<'js> FromJs<'js> for JsValue {
    /// Converts a JavaScript value to a JsValue enum.
    ///
    /// This method handles type conversion from QuickJS values to the FJS
    /// JsValue representation, preserving type information and handling
    /// complex nested structures.
    ///
    /// # Parameters
    ///
    /// - `ctx`: The JavaScript context
    /// - `value`: The QuickJS value to convert
    ///
    /// # Returns
    ///
    /// Returns the converted JsValue or a conversion error.
    ///
    /// # Notes
    ///
    /// - BigInt values are converted to strings to preserve precision
    /// - Function, Symbol, and other unsupported types are converted to None
    /// - Arrays and Objects are recursively converted
    #[frb(ignore)]
    fn from_js(ctx: &Ctx<'js>, value: rquickjs::Value<'js>) -> rquickjs::Result<Self> {
        let v = match value.type_of() {
            Type::String => {
                let s = value.as_string()
                    .ok_or_else(|| rquickjs::Error::new_from_js("value", "String"))?;
                JsValue::String(s.to_string()?)
            }
            Type::Array => {
                let arr = value.as_array()
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
                let obj = value.as_object()
                    .ok_or_else(|| rquickjs::Error::new_from_js("value", "Object"))?;
                let mut map = HashMap::new();
                for prop in obj.props() {
                    let (k, v) = prop?;
                    let value = JsValue::from_js(ctx, v)?;
                    map.insert(String::from_atom(k)?, value);
                }
                JsValue::Object(map)
            }
            Type::Int => {
                let i = value.as_int()
                    .ok_or_else(|| rquickjs::Error::new_from_js("value", "Int"))?;
                JsValue::Integer(i as i64)
            }
            Type::Bool => {
                let b = value.as_bool()
                    .ok_or_else(|| rquickjs::Error::new_from_js("value", "Bool"))?;
                JsValue::Boolean(b)
            }
            Type::Float => {
                let f = value.as_float()
                    .ok_or_else(|| rquickjs::Error::new_from_js("value", "Float"))?;
                JsValue::Float(f)
            }
            Type::BigInt => {
                // Convert BigInt to string to avoid precision loss
                // eval a JS expression to convert BigInt to string
                let bigint_ref = value.as_ref();
                let code = format!("(function(v){{ return String(v); }})");
                let converter: rquickjs::Function = ctx.eval(code)?;
                let result: rquickjs::String = converter.call((bigint_ref,))?;
                JsValue::Bigint(result.to_string()?)
            }
            Type::Uninitialized
            | Type::Undefined
            | Type::Null
            | Type::Symbol
            | Type::Constructor
            | Type::Function
            | Type::Promise
            | Type::Exception
            | Type::Module
            | Type::Unknown => JsValue::None,
        };
        Ok(v)
    }
}

impl<'js> IntoJs<'js> for JsValue {
    /// Converts a JsValue to a JavaScript value.
    ///
    /// This method handles type conversion from the FJS JsValue representation
    /// to QuickJS values, enabling data to be passed to JavaScript code.
    ///
    /// # Parameters
    ///
    /// - `ctx`: The JavaScript context
    ///
    /// # Returns
    ///
    /// Returns the converted JavaScript value or a conversion error.
    ///
    /// # Notes
    ///
    /// - BigInt values are parsed from strings to create proper JavaScript BigInts
    /// - Arrays and Objects are recursively converted
    /// - Null values are converted to JavaScript null
    #[frb(ignore)]
    fn into_js(self, ctx: &Ctx<'js>) -> rquickjs::Result<rquickjs::Value<'js>> {
        match self {
            JsValue::String(v) => rquickjs::String::from_str(ctx.clone(), &v)?.into_js(ctx),
            JsValue::Integer(v) => Ok(rquickjs::Value::new_number(ctx.clone(), v as _)),
            JsValue::Array(v) => {
                let x = rquickjs::Array::new(ctx.clone())?;
                for (i, v) in v.into_iter().enumerate() {
                    x.set(i, v.into_js(ctx)?)?;
                }
                x.into_js(ctx)
            }
            JsValue::Object(v) => {
                let x = rquickjs::Object::new(ctx.clone())?;
                for kv in v.into_iter() {
                    x.set(kv.0, kv.1.into_js(ctx)?)?;
                }
                x.into_js(ctx)
            }
            JsValue::Boolean(v) => Ok(rquickjs::Value::new_bool(ctx.clone(), v)),
            JsValue::Float(v) => Ok(rquickjs::Value::new_float(ctx.clone(), v)),
            JsValue::Bigint(v) => {
                let value = rquickjs::String::from_str(ctx.clone(), &v)?.into_js(ctx)?;
                rquickjs::BigInt::from_value(value).into_js(ctx)
            }
            JsValue::None => Null.into_js(ctx),
        }
    }
}
