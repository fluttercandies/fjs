use std::fmt;

use itertools::Itertools;
use rquickjs::{Array, Ctx, FromAtom, FromJs, IntoJs, Null, Object, Type};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct JsonValue(pub Value);

impl<'js> FromJs<'js> for JsonValue {
    fn from_js(ctx: &Ctx<'js>, value: rquickjs::Value<'js>) -> rquickjs::Result<Self> {
        let v = match value.type_of() {
            Type::Bool => value.as_bool().expect("checked bool").into(),
            Type::Int => value.as_int().expect("checked int").into(),
            Type::Float => value.as_float().expect("checked float").into(),
            Type::String => {
                let str = value.as_string().expect("check string").to_string()?;
                Value::String(str)
            }
            Type::Array => {
                let v = value.as_array().expect("checked array");
                let mut x = Vec::with_capacity(v.len());
                for i in v.iter() {
                    let v = i?;
                    let v = JsonValue::from_js(ctx, v)?;
                    x.push(v.into());
                }
                Value::Array(x)
            }
            Type::Object => {
                let v = value.into_object().expect("checked object");
                let mut x = json!({});
                for i in v.props() {
                    let (k, v) = i?;
                    let k = String::from_atom(k)?;
                    let v = JsonValue::from_js(ctx, v)?;
                    x[k] = v.into();
                }
                x
            }
            _ => Value::Null,
            // Type::Symbol => Value::Null,
            // Type::Function => Value::Null,
            // Type::Uninitialized => Value::Null,
            // Type::Undefined => Value::Null,
            // Type::Null => Value::Null,
            // Type::Module => Value::Null,
            // Type::Unknown => Value::Null,
        };
        Ok(v.into())
    }
}


impl<'js> IntoJs<'js> for JsonValue {
    fn into_js(self, ctx: &Ctx<'js>) -> rquickjs::Result<rquickjs::Value<'js>> {
        match self.0 {
            Value::Null => Null.into_js(ctx),
            Value::Bool(v) => Ok(rquickjs::Value::new_bool(ctx.clone(), v)),
            Value::Number(num) => {
                if num.is_f64() {
                    Ok(rquickjs::Value::new_float(
                        ctx.clone(),
                        num.as_f64().expect("checked f64"),
                    ))
                } else if num.is_i64() {
                    Ok(rquickjs::Value::new_number(
                        ctx.clone(),
                        num.as_i64().expect("checked f64") as _,
                    ))
                } else {
                    Ok(rquickjs::Value::new_number(
                        ctx.clone(),
                        num.as_u64().expect("checked f64") as _,
                    ))
                }
            }
            Value::String(v) => rquickjs::String::from_str(ctx.clone(), &v)?.into_js(ctx),
            Value::Array(v) => {
                let x = Array::new(ctx.clone())?;
                for (i, v) in v.into_iter().enumerate() {
                    x.set(i, JsonValue(v).into_js(ctx)?)?;
                }
                x.into_js(ctx)
            }
            Value::Object(v) => {
                let x = Object::new(ctx.clone())?;
                for (k, v) in v.into_iter() {
                    x.set(k, JsonValue(v).into_js(ctx)?)?;
                }
                x.into_js(ctx)
            }
        }
    }
}


impl From<Value> for JsonValue {
    fn from(v: Value) -> Self {
        Self(v)
    }
}

impl From<JsonValue> for Value {
    fn from(v: JsonValue) -> Self {
        v.0
    }
}

impl Default for JsonValue {
    fn default() -> Self {
        Self(json!({}))
    }
}

impl JsonValue {
    pub fn null() -> Self {
        Self(Value::Null)
    }

    pub fn array<T: Serialize>(arr: Vec<T>) -> Self {
        Self(json!(arr))
    }

    pub fn object<T: Serialize>(obj: T) -> Self {
        Self(json!(obj))
    }
}

impl fmt::Display for JsonValue {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match &self.0 {
            Value::Null => write!(f, "null"),
            Value::Bool(v) => write!(f, "{}", v),
            Value::Number(v) => write!(f, "{}", v),
            Value::String(v) => write!(f, "{}", v),
            Value::Array(v) => {
                write!(f, "[")?;
                write!(f, "{}", v.iter().join(", "))?;
                write!(f, "]")
            }
            Value::Object(_) => {
                let s = serde_json::to_string_pretty(&self.0).map_err(|_| fmt::Error)?;
                write!(f, "{}", s)
            }
        }
    }
}

