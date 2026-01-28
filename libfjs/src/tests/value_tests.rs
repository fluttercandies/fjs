//! # JsValue Conversion Tests
//!
//! Tests for the JsValue type conversion between Rust and JavaScript.
//! Covers all primitive types, collections, and edge cases.

use super::test_utils::test_with;
use crate::api::value::JsValue;
use rquickjs::{FromJs, IntoJs};
use std::collections::HashMap;

// ============================================================================
// Primitive Type Tests
// ============================================================================

#[test]
fn test_jsvalue_none() {
    let v = JsValue::None;
    assert!(v.is_none());
    assert!(!v.is_boolean());
    assert!(!v.is_number());
    assert!(!v.is_string());
    assert!(!v.is_array());
    assert!(!v.is_object());
    assert!(v.is_primitive());
    assert_eq!(v.type_name(), "null");
}

#[test]
fn test_jsvalue_boolean_true() {
    let v = JsValue::Boolean(true);
    assert!(v.is_boolean());
    assert!(!v.is_none());
    assert!(!v.is_number());
    assert!(v.is_primitive());
    assert_eq!(v.type_name(), "boolean");
}

#[test]
fn test_jsvalue_boolean_false() {
    let v = JsValue::Boolean(false);
    assert!(v.is_boolean());
    assert_eq!(v.type_name(), "boolean");
}

#[test]
fn test_jsvalue_integer_positive() {
    let v = JsValue::Integer(42);
    assert!(v.is_number());
    assert!(!v.is_boolean());
    assert!(v.is_primitive());
    assert_eq!(v.type_name(), "number");
}

#[test]
fn test_jsvalue_integer_negative() {
    let v = JsValue::Integer(-42);
    assert!(v.is_number());
    assert_eq!(v.type_name(), "number");
}

#[test]
fn test_jsvalue_integer_zero() {
    let v = JsValue::Integer(0);
    assert!(v.is_number());
}

#[test]
fn test_jsvalue_integer_max() {
    let v = JsValue::Integer(i64::MAX);
    assert!(v.is_number());
}

#[test]
fn test_jsvalue_integer_min() {
    let v = JsValue::Integer(i64::MIN);
    assert!(v.is_number());
}

#[test]
fn test_jsvalue_float_positive() {
    let v = JsValue::Float(3.14159);
    assert!(v.is_number());
    assert!(v.is_primitive());
    assert_eq!(v.type_name(), "number");
}

#[test]
fn test_jsvalue_float_negative() {
    let v = JsValue::Float(-3.14159);
    assert!(v.is_number());
}

#[test]
fn test_jsvalue_float_zero() {
    let v = JsValue::Float(0.0);
    assert!(v.is_number());
}

#[test]
fn test_jsvalue_float_infinity() {
    let v = JsValue::Float(f64::INFINITY);
    assert!(v.is_number());
}

#[test]
fn test_jsvalue_float_neg_infinity() {
    let v = JsValue::Float(f64::NEG_INFINITY);
    assert!(v.is_number());
}

#[test]
fn test_jsvalue_float_nan() {
    let v = JsValue::Float(f64::NAN);
    assert!(v.is_number());
}

#[test]
fn test_jsvalue_bigint() {
    let v = JsValue::Bigint("12345678901234567890".to_string());
    assert!(v.is_number());
    assert!(v.is_primitive());
    assert_eq!(v.type_name(), "bigint");
}

#[test]
fn test_jsvalue_bigint_negative() {
    let v = JsValue::Bigint("-12345678901234567890".to_string());
    assert!(v.is_number());
}

#[test]
fn test_jsvalue_string() {
    let v = JsValue::String("hello".to_string());
    assert!(v.is_string());
    assert!(!v.is_number());
    assert!(v.is_primitive());
    assert_eq!(v.type_name(), "string");
}

#[test]
fn test_jsvalue_string_empty() {
    let v = JsValue::String(String::new());
    assert!(v.is_string());
}

#[test]
fn test_jsvalue_string_unicode() {
    let v = JsValue::String("你好世界🌍".to_string());
    assert!(v.is_string());
}

#[test]
fn test_jsvalue_string_escape_chars() {
    let v = JsValue::String("line1\nline2\ttab".to_string());
    assert!(v.is_string());
}

#[test]
fn test_jsvalue_bytes() {
    let v = JsValue::Bytes(vec![0xCA, 0xFE, 0xBA, 0xBE]);
    assert!(v.is_bytes());
    assert!(!v.is_string());
    assert!(!v.is_primitive());
    assert_eq!(v.type_name(), "ArrayBuffer");
}

#[test]
fn test_jsvalue_bytes_empty() {
    let v = JsValue::Bytes(vec![]);
    assert!(v.is_bytes());
}

// ============================================================================
// Collection Type Tests
// ============================================================================

#[test]
fn test_jsvalue_array_empty() {
    let v = JsValue::Array(vec![]);
    assert!(v.is_array());
    assert!(!v.is_object());
    assert!(!v.is_primitive());
    assert_eq!(v.type_name(), "Array");
}

#[test]
fn test_jsvalue_array_integers() {
    let v = JsValue::Array(vec![
        JsValue::Integer(1),
        JsValue::Integer(2),
        JsValue::Integer(3),
    ]);
    assert!(v.is_array());
}

#[test]
fn test_jsvalue_array_mixed() {
    let v = JsValue::Array(vec![
        JsValue::Integer(1),
        JsValue::String("two".to_string()),
        JsValue::Boolean(true),
        JsValue::None,
    ]);
    assert!(v.is_array());
}

#[test]
fn test_jsvalue_array_nested() {
    let inner = JsValue::Array(vec![JsValue::Integer(1), JsValue::Integer(2)]);
    let v = JsValue::Array(vec![inner, JsValue::Integer(3)]);
    assert!(v.is_array());
}

#[test]
fn test_jsvalue_object_empty() {
    let v = JsValue::Object(HashMap::new());
    assert!(v.is_object());
    assert!(!v.is_array());
    assert!(!v.is_primitive());
    assert_eq!(v.type_name(), "Object");
}

#[test]
fn test_jsvalue_object_simple() {
    let mut map = HashMap::new();
    map.insert("name".to_string(), JsValue::String("test".to_string()));
    map.insert("value".to_string(), JsValue::Integer(42));
    let v = JsValue::Object(map);
    assert!(v.is_object());
}

#[test]
fn test_jsvalue_object_nested() {
    let mut inner = HashMap::new();
    inner.insert("x".to_string(), JsValue::Integer(1));
    inner.insert("y".to_string(), JsValue::Integer(2));

    let mut outer = HashMap::new();
    outer.insert("point".to_string(), JsValue::Object(inner));
    outer.insert("name".to_string(), JsValue::String("origin".to_string()));

    let v = JsValue::Object(outer);
    assert!(v.is_object());
}

#[test]
fn test_jsvalue_date() {
    let v = JsValue::Date(1609459200000); // 2021-01-01 00:00:00 UTC
    assert!(v.is_date());
    assert!(!v.is_number());
    assert_eq!(v.type_name(), "Date");
}

#[test]
fn test_jsvalue_symbol() {
    let v = JsValue::Symbol("my_symbol".to_string());
    assert_eq!(v.type_name(), "symbol");
}

#[test]
fn test_jsvalue_function() {
    let v = JsValue::Function("myFunction".to_string());
    assert_eq!(v.type_name(), "function");
}

// ============================================================================
// From Trait Tests
// ============================================================================

#[test]
fn test_from_bool() {
    let v: JsValue = true.into();
    assert!(matches!(v, JsValue::Boolean(true)));

    let v: JsValue = false.into();
    assert!(matches!(v, JsValue::Boolean(false)));
}

#[test]
fn test_from_i32() {
    let v: JsValue = 42i32.into();
    assert!(matches!(v, JsValue::Integer(42)));
}

#[test]
fn test_from_i64() {
    let v: JsValue = 42i64.into();
    assert!(matches!(v, JsValue::Integer(42)));
}

#[test]
fn test_from_f64() {
    let v: JsValue = 3.14f64.into();
    assert!(matches!(v, JsValue::Float(f) if (f - 3.14).abs() < f64::EPSILON));
}

#[test]
fn test_from_string() {
    let v: JsValue = String::from("hello").into();
    assert!(matches!(v, JsValue::String(s) if s == "hello"));
}

#[test]
fn test_from_str() {
    let v: JsValue = "hello".into();
    assert!(matches!(v, JsValue::String(s) if s == "hello"));
}

#[test]
fn test_from_vec_u8() {
    let v: JsValue = vec![1u8, 2, 3].into();
    assert!(matches!(v, JsValue::Bytes(b) if b == vec![1, 2, 3]));
}

#[test]
fn test_from_vec_jsvalue() {
    let items = vec![JsValue::Integer(1), JsValue::Integer(2)];
    let v: JsValue = items.into();
    assert!(v.is_array());
}

#[test]
fn test_from_option_some() {
    let v: JsValue = Some(42i32).into();
    assert!(matches!(v, JsValue::Integer(42)));
}

#[test]
fn test_from_option_none() {
    let v: JsValue = Option::<i32>::None.into();
    assert!(v.is_none());
}

#[test]
fn test_from_unit() {
    let v: JsValue = ().into();
    assert!(v.is_none());
}

// ============================================================================
// Default Trait Test
// ============================================================================

#[test]
fn test_default() {
    let v = JsValue::default();
    assert!(v.is_none());
}

// ============================================================================
// JavaScript Roundtrip Tests
// ============================================================================

#[test]
fn test_js_roundtrip_none() {
    test_with(|ctx| {
        let original = JsValue::None;
        let js_val = original.clone().into_js(&ctx).unwrap();
        let recovered = JsValue::from_js(&ctx, js_val).unwrap();
        assert!(recovered.is_none());
    });
}

#[test]
fn test_js_roundtrip_boolean() {
    test_with(|ctx| {
        for val in [true, false] {
            let original = JsValue::Boolean(val);
            let js_val = original.clone().into_js(&ctx).unwrap();
            let recovered = JsValue::from_js(&ctx, js_val).unwrap();
            assert_eq!(original, recovered);
        }
    });
}

#[test]
fn test_js_roundtrip_integer() {
    test_with(|ctx| {
        for val in [0i64, 42, -42, i32::MAX as i64, i32::MIN as i64] {
            let original = JsValue::Integer(val);
            let js_val = original.clone().into_js(&ctx).unwrap();
            let recovered = JsValue::from_js(&ctx, js_val).unwrap();
            // Note: JS may convert to float for some values
            match recovered {
                JsValue::Integer(v) => assert_eq!(v, val),
                JsValue::Float(v) => assert!((v - val as f64).abs() < 1.0),
                _ => panic!("Unexpected type: {:?}", recovered),
            }
        }
    });
}

#[test]
fn test_js_roundtrip_float() {
    test_with(|ctx| {
        for val in [0.0f64, 3.14159, -3.14159] {
            let original = JsValue::Float(val);
            let js_val = original.clone().into_js(&ctx).unwrap();
            let recovered = JsValue::from_js(&ctx, js_val).unwrap();
            match recovered {
                JsValue::Float(v) => assert!((v - val).abs() < f64::EPSILON),
                JsValue::Integer(v) => assert!((v as f64 - val).abs() < 1.0),
                _ => panic!("Unexpected type: {:?}", recovered),
            }
        }
    });
}

#[test]
fn test_js_roundtrip_string() {
    test_with(|ctx| {
        for val in ["", "hello", "你好世界🌍", "line1\nline2"] {
            let original = JsValue::String(val.to_string());
            let js_val = original.clone().into_js(&ctx).unwrap();
            let recovered = JsValue::from_js(&ctx, js_val).unwrap();
            assert_eq!(original, recovered);
        }
    });
}

#[test]
fn test_js_roundtrip_bytes() {
    test_with(|ctx| {
        let data = vec![0xCA, 0xFE, 0xBA, 0xBE];
        let original = JsValue::Bytes(data.clone());
        let js_val = original.clone().into_js(&ctx).unwrap();
        let recovered = JsValue::from_js(&ctx, js_val).unwrap();
        assert_eq!(original, recovered);
    });
}

#[test]
fn test_js_roundtrip_array() {
    test_with(|ctx| {
        let original = JsValue::Array(vec![
            JsValue::Integer(1),
            JsValue::String("two".to_string()),
            JsValue::Boolean(true),
        ]);
        let js_val = original.clone().into_js(&ctx).unwrap();
        let recovered = JsValue::from_js(&ctx, js_val).unwrap();
        assert!(recovered.is_array());
    });
}

#[test]
fn test_js_roundtrip_object() {
    test_with(|ctx| {
        let mut map = HashMap::new();
        map.insert("name".to_string(), JsValue::String("test".to_string()));
        map.insert("value".to_string(), JsValue::Integer(42));
        let original = JsValue::Object(map);
        let js_val = original.clone().into_js(&ctx).unwrap();
        let recovered = JsValue::from_js(&ctx, js_val).unwrap();
        assert!(recovered.is_object());
    });
}

#[test]
fn test_js_roundtrip_date() {
    test_with(|ctx| {
        let ms = 1609459200000i64;
        let original = JsValue::Date(ms);
        let js_val = original.clone().into_js(&ctx).unwrap();
        let recovered = JsValue::from_js(&ctx, js_val).unwrap();
        assert!(matches!(recovered, JsValue::Date(v) if v == ms));
    });
}

// ============================================================================
// FromJs Tests (JavaScript to Rust)
// ============================================================================

#[test]
fn test_from_js_null() {
    test_with(|ctx| {
        let val: rquickjs::Value = ctx.eval("null").unwrap();
        let js_val = JsValue::from_js(&ctx, val).unwrap();
        assert!(js_val.is_none());
    });
}

#[test]
fn test_from_js_undefined() {
    test_with(|ctx| {
        let val: rquickjs::Value = ctx.eval("undefined").unwrap();
        let js_val = JsValue::from_js(&ctx, val).unwrap();
        assert!(js_val.is_none());
    });
}

#[test]
fn test_from_js_boolean() {
    test_with(|ctx| {
        let val: rquickjs::Value = ctx.eval("true").unwrap();
        let js_val = JsValue::from_js(&ctx, val).unwrap();
        assert!(matches!(js_val, JsValue::Boolean(true)));

        let val: rquickjs::Value = ctx.eval("false").unwrap();
        let js_val = JsValue::from_js(&ctx, val).unwrap();
        assert!(matches!(js_val, JsValue::Boolean(false)));
    });
}

#[test]
fn test_from_js_integer() {
    test_with(|ctx| {
        let val: rquickjs::Value = ctx.eval("42").unwrap();
        let js_val = JsValue::from_js(&ctx, val).unwrap();
        assert!(matches!(js_val, JsValue::Integer(42)));
    });
}

#[test]
fn test_from_js_float() {
    test_with(|ctx| {
        let val: rquickjs::Value = ctx.eval("3.14").unwrap();
        let js_val = JsValue::from_js(&ctx, val).unwrap();
        assert!(matches!(js_val, JsValue::Float(f) if (f - 3.14).abs() < f64::EPSILON));
    });
}

#[test]
fn test_from_js_string() {
    test_with(|ctx| {
        let val: rquickjs::Value = ctx.eval("'hello world'").unwrap();
        let js_val = JsValue::from_js(&ctx, val).unwrap();
        assert!(matches!(js_val, JsValue::String(s) if s == "hello world"));
    });
}

#[test]
fn test_from_js_array() {
    test_with(|ctx| {
        let val: rquickjs::Value = ctx.eval("[1, 2, 3]").unwrap();
        let js_val = JsValue::from_js(&ctx, val).unwrap();
        assert!(js_val.is_array());
        if let JsValue::Array(arr) = js_val {
            assert_eq!(arr.len(), 3);
        }
    });
}

#[test]
fn test_from_js_object() {
    test_with(|ctx| {
        let val: rquickjs::Value = ctx.eval("({a: 1, b: 2})").unwrap();
        let js_val = JsValue::from_js(&ctx, val).unwrap();
        assert!(js_val.is_object());
        if let JsValue::Object(obj) = js_val {
            assert_eq!(obj.len(), 2);
        }
    });
}

#[test]
fn test_from_js_bigint() {
    test_with(|ctx| {
        let val: rquickjs::Value = ctx.eval("BigInt('12345678901234567890')").unwrap();
        let js_val = JsValue::from_js(&ctx, val).unwrap();
        assert!(matches!(js_val, JsValue::Bigint(_)));
    });
}

#[test]
fn test_from_js_date() {
    test_with(|ctx| {
        let val: rquickjs::Value = ctx.eval("new Date(1609459200000)").unwrap();
        let js_val = JsValue::from_js(&ctx, val).unwrap();
        assert!(js_val.is_date());
        assert!(matches!(js_val, JsValue::Date(1609459200000)));
    });
}

#[test]
fn test_from_js_arraybuffer() {
    test_with(|ctx| {
        let val: rquickjs::Value = ctx.eval("new Uint8Array([1, 2, 3, 4]).buffer").unwrap();
        let js_val = JsValue::from_js(&ctx, val).unwrap();
        assert!(js_val.is_bytes());
        if let JsValue::Bytes(bytes) = js_val {
            assert_eq!(bytes, vec![1, 2, 3, 4]);
        }
    });
}

#[test]
fn test_from_js_symbol() {
    test_with(|ctx| {
        let val: rquickjs::Value = ctx.eval("Symbol('test')").unwrap();
        let js_val = JsValue::from_js(&ctx, val).unwrap();
        assert!(matches!(js_val, JsValue::Symbol(s) if s == "test"));
    });
}

#[test]
fn test_from_js_function() {
    test_with(|ctx| {
        let val: rquickjs::Value = ctx.eval("function myFunc() {}; myFunc").unwrap();
        let js_val = JsValue::from_js(&ctx, val).unwrap();
        assert!(matches!(js_val, JsValue::Function(s) if s == "myFunc"));
    });
}

#[test]
fn test_from_js_anonymous_function() {
    test_with(|ctx| {
        let val: rquickjs::Value = ctx.eval("(() => {})").unwrap();
        let js_val = JsValue::from_js(&ctx, val).unwrap();
        // Anonymous arrow functions have empty name
        assert!(matches!(js_val, JsValue::Function(_)));
    });
}
