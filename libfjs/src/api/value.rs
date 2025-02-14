use flutter_rust_bridge::frb;
use rquickjs::{Ctx, FromAtom, FromJs, IntoJs, Null, Type};
#[derive(Debug, Clone)]
#[frb(dart_metadata = ("freezed", "immutable"))]
pub struct KeyValue {
    pub key: String,
    pub value: JsValue,
}

#[derive(Debug, Clone)]
#[frb(dart_metadata = ("freezed", "immutable"), dart_code = r#"
  static JsValue from(Object? any) {
    if (any == null) {
      return const JsValue.null_();
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
        any.entries
            .map(
                (e) => KeyValue(key: e.key.toString(), value: from(e.value)))
            .toList(),
      );
    } else {
      throw Exception("Unsupported type: ${any.runtimeType}");
    }
  }
  get value => when(
      null_: () => null,
      boolean: (v) => v,
      integer: (v) => v,
      float: (v) => v,
      bigint: (v) => BigInt.parse(v),
      string: (v) => v,
      array: (v) => v.map((e) => e.value).toList(),
      object: (v) =>
          Map.fromEntries(v.map((e) => MapEntry(e.key, e.value.value))),
  );
"#)]
pub enum JsValue {
    Null,
    Boolean(bool),
    Integer(i64),
    Float(f64),
    Bigint(String),
    String(String),
    Array(Vec<JsValue>),
    Object(Vec<KeyValue>),
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
                let mut vec = vec![];
                for x in value.as_object().unwrap().props() {
                    let (k, v) = x?;
                    let value = JsValue::from_js(ctx, v)?;
                    let pair = KeyValue {
                        key: String::from_atom(k)?,
                        value,
                    };
                    vec.push(pair);
                }
                JsValue::Object(vec)
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
            | Type::Unknown => JsValue::Null,
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
                    x.set(kv.key, kv.value.into_js(ctx)?)?;
                }
                x.into_js(ctx)
            }
            JsValue::Boolean(v) => Ok(rquickjs::Value::new_bool(ctx.clone(), v)),
            JsValue::Float(v) => Ok(rquickjs::Value::new_float(ctx.clone(), v)),
            JsValue::Bigint(v) => {
                let value = rquickjs::String::from_str(ctx.clone(), &v)?.into_js(ctx)?;
                rquickjs::BigInt::from_value(value).into_js(ctx)
            }
            JsValue::Null => Null.into_js(ctx),
        }
    }
}
