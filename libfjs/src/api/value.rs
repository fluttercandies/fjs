use flutter_rust_bridge::frb;
use rquickjs::{Ctx, FromAtom, FromJs, IntoJs, Null, Type};
use std::collections::HashMap;

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
    None,
    Boolean(bool),
    Integer(i64),
    Float(f64),
    Bigint(String),
    String(String),
    Array(Vec<JsValue>),
    Object(HashMap<String, JsValue>),
}

impl<'js> FromJs<'js> for JsValue {
    #[frb(ignore)]
    fn from_js(ctx: &Ctx<'js>, value: rquickjs::Value<'js>) -> rquickjs::Result<Self> {
        let v = match value.type_of() {
            Type::String => JsValue::String(value.as_string().unwrap().to_string()?.into()),
            Type::Array => {
                let mut vec = vec![];
                let x1 = value.as_array().unwrap();
                for x in x1.iter() {
                    let value = JsValue::from_js(ctx, x.unwrap())?;
                    vec.push(value);
                }
                JsValue::Array(vec)
            }
            Type::Object => {
                let mut map = HashMap::new();
                for x in value.as_object().unwrap().props() {
                    let (k, v) = x?;
                    let value = JsValue::from_js(ctx, v)?;
                    map.insert(String::from_atom(k)?, value);
                }
                JsValue::Object(map)
            }
            Type::Int => JsValue::Integer((value.as_int().unwrap() as i64).into()),
            Type::Bool => JsValue::Boolean(value.as_bool().unwrap().into()),
            Type::Float => JsValue::Float(value.as_float().unwrap().into()),
            Type::BigInt => JsValue::Bigint(value.into_big_int().unwrap().to_i64()?.to_string()),
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
