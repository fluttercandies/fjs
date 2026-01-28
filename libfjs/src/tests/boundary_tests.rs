//! # Boundary Tests
//!
//! Comprehensive boundary condition tests for the FJS library.
//! Tests edge cases, limits, and error conditions.

use crate::api::engine::JsEngine;
use crate::api::error::JsResult;
use crate::api::runtime::{JsAsyncContext, JsAsyncRuntime, JsContext, JsRuntime};
use crate::api::source::{JsCode, JsEvalOptions, JsModule};
use crate::api::value::JsValue;
use std::collections::HashMap;

// ============================================================================
// Numeric Boundary Tests
// ============================================================================

#[test]
fn test_integer_max_safe_integer() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // JavaScript's MAX_SAFE_INTEGER
    let result = context.eval("Number.MAX_SAFE_INTEGER".to_string());
    match result {
        JsResult::Ok(v) => {
            assert!(v.is_number());
        }
        _ => panic!("Expected Ok result"),
    }
}

#[test]
fn test_integer_min_safe_integer() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // JavaScript's MIN_SAFE_INTEGER
    let result = context.eval("Number.MIN_SAFE_INTEGER".to_string());
    match result {
        JsResult::Ok(v) => {
            assert!(v.is_number());
        }
        _ => panic!("Expected Ok result"),
    }
}

#[test]
fn test_bigint_very_large() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result =
        context.eval("BigInt('123456789012345678901234567890')".to_string());
    match result {
        JsResult::Ok(v) => {
            assert!(v.is_number()); // BigInt is numeric
        }
        _ => panic!("Expected Ok result"),
    }
}

#[test]
fn test_float_positive_infinity() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("Infinity".to_string());
    match result {
        JsResult::Ok(JsValue::Float(f)) => {
            assert!(f.is_infinite() && f > 0.0);
        }
        _ => panic!("Expected positive infinity"),
    }
}

#[test]
fn test_float_negative_infinity() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("-Infinity".to_string());
    match result {
        JsResult::Ok(JsValue::Float(f)) => {
            assert!(f.is_infinite() && f < 0.0);
        }
        _ => panic!("Expected negative infinity"),
    }
}

#[test]
fn test_float_nan() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("NaN".to_string());
    match result {
        JsResult::Ok(JsValue::Float(f)) => {
            assert!(f.is_nan());
        }
        _ => panic!("Expected NaN"),
    }
}

#[test]
fn test_float_epsilon() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("Number.EPSILON".to_string());
    assert!(result.is_ok());
}

#[test]
fn test_float_max_value() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("Number.MAX_VALUE".to_string());
    assert!(result.is_ok());
}

#[test]
fn test_float_min_value() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("Number.MIN_VALUE".to_string());
    assert!(result.is_ok());
}

#[test]
fn test_division_by_zero() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // JavaScript returns Infinity for division by zero
    let result = context.eval("1 / 0".to_string());
    match result {
        JsResult::Ok(JsValue::Float(f)) => {
            assert!(f.is_infinite() && f > 0.0);
        }
        _ => panic!("Expected Infinity"),
    }
}

#[test]
fn test_zero_divided_by_zero() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // JavaScript returns NaN for 0/0
    let result = context.eval("0 / 0".to_string());
    match result {
        JsResult::Ok(JsValue::Float(f)) => {
            assert!(f.is_nan());
        }
        _ => panic!("Expected NaN"),
    }
}

// ============================================================================
// String Boundary Tests
// ============================================================================

#[test]
fn test_empty_string() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("''".to_string());
    match result {
        JsResult::Ok(JsValue::String(s)) => {
            assert!(s.is_empty());
        }
        _ => panic!("Expected empty string"),
    }
}

#[test]
fn test_very_long_string() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // Create a string of 10000 characters
    let result = context.eval("'a'.repeat(10000)".to_string());
    match result {
        JsResult::Ok(JsValue::String(s)) => {
            assert_eq!(s.len(), 10000);
        }
        _ => panic!("Expected long string"),
    }
}

#[test]
fn test_string_with_null_bytes() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval(r#"'a\u0000b'"#.to_string());
    match result {
        JsResult::Ok(JsValue::String(s)) => {
            assert_eq!(s.len(), 3);
            assert!(s.contains('\0'));
        }
        _ => panic!("Expected string with null byte"),
    }
}

#[test]
fn test_string_unicode_surrogate_pairs() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // Emoji that requires surrogate pairs
    let result = context.eval(r#"'😀'"#.to_string());
    match result {
        JsResult::Ok(JsValue::String(s)) => {
            assert!(!s.is_empty());
            assert!(s.contains("😀"));
        }
        _ => panic!("Expected emoji string"),
    }
}

#[test]
fn test_string_all_unicode_escapes() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval(r#"'\u0041\u0042\u0043'"#.to_string());
    match result {
        JsResult::Ok(JsValue::String(s)) => {
            assert_eq!(s, "ABC");
        }
        _ => panic!("Expected ABC"),
    }
}

#[test]
fn test_string_special_characters() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // Test various special characters
    let result = context.eval(r#"'\n\r\t\\\'\"'"#.to_string());
    assert!(result.is_ok());
}

// ============================================================================
// Array Boundary Tests
// ============================================================================

#[test]
fn test_empty_array() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("[]".to_string());
    match result {
        JsResult::Ok(JsValue::Array(arr)) => {
            assert!(arr.is_empty());
        }
        _ => panic!("Expected empty array"),
    }
}

#[test]
fn test_array_with_holes() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("[1, , 3]".to_string());
    match result {
        JsResult::Ok(JsValue::Array(arr)) => {
            assert_eq!(arr.len(), 3);
            // The hole should be undefined/none
            assert!(arr[1].is_none());
        }
        _ => panic!("Expected sparse array"),
    }
}

#[test]
fn test_large_array() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("new Array(1000).fill(1)".to_string());
    match result {
        JsResult::Ok(JsValue::Array(arr)) => {
            assert_eq!(arr.len(), 1000);
        }
        _ => panic!("Expected large array"),
    }
}

#[test]
fn test_nested_array() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("[[1, 2], [3, [4, 5]]]".to_string());
    match result {
        JsResult::Ok(JsValue::Array(arr)) => {
            assert_eq!(arr.len(), 2);
            assert!(arr[0].is_array());
            assert!(arr[1].is_array());
        }
        _ => panic!("Expected nested array"),
    }
}

#[test]
fn test_array_with_mixed_types() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("[1, 'two', true, null, {a: 1}]".to_string());
    match result {
        JsResult::Ok(JsValue::Array(arr)) => {
            assert_eq!(arr.len(), 5);
            assert!(arr[0].is_number());
            assert!(arr[1].is_string());
            assert!(arr[2].is_boolean());
            assert!(arr[3].is_none());
            assert!(arr[4].is_object());
        }
        _ => panic!("Expected mixed array"),
    }
}

// ============================================================================
// Object Boundary Tests
// ============================================================================

#[test]
fn test_empty_object() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("({})".to_string());
    match result {
        JsResult::Ok(JsValue::Object(obj)) => {
            assert!(obj.is_empty());
        }
        _ => panic!("Expected empty object"),
    }
}

#[test]
fn test_deeply_nested_object() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("({a: {b: {c: {d: {e: 1}}}}})".to_string());
    match result {
        JsResult::Ok(JsValue::Object(obj)) => {
            assert!(obj.contains_key("a"));
        }
        _ => panic!("Expected nested object"),
    }
}

#[test]
fn test_object_with_special_keys() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval(r#"({"key with spaces": 1, "123": 2, "": 3})"#.to_string());
    match result {
        JsResult::Ok(JsValue::Object(obj)) => {
            assert!(obj.contains_key("key with spaces"));
            assert!(obj.contains_key("123"));
            assert!(obj.contains_key(""));
        }
        _ => panic!("Expected object with special keys"),
    }
}

#[test]
fn test_object_with_numeric_keys() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("({0: 'a', 1: 'b', 2: 'c'})".to_string());
    match result {
        JsResult::Ok(JsValue::Object(obj)) => {
            assert!(obj.contains_key("0"));
            assert!(obj.contains_key("1"));
            assert!(obj.contains_key("2"));
        }
        _ => panic!("Expected object with numeric keys"),
    }
}

#[test]
fn test_large_object() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval(
        r#"
        let obj = {};
        for (let i = 0; i < 100; i++) {
            obj['key' + i] = i;
        }
        obj
    "#
        .to_string(),
    );
    match result {
        JsResult::Ok(JsValue::Object(obj)) => {
            assert_eq!(obj.len(), 100);
        }
        _ => panic!("Expected large object"),
    }
}

// ============================================================================
// Error Boundary Tests
// ============================================================================

#[test]
fn test_syntax_error_missing_bracket() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("[1, 2, 3".to_string());
    assert!(result.is_err());
}

#[test]
fn test_syntax_error_invalid_token() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("@#$%".to_string());
    assert!(result.is_err());
}

#[test]
fn test_reference_error_undefined_variable() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("nonExistentVariable".to_string());
    assert!(result.is_err());
}

#[test]
fn test_type_error_call_non_function() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("let x = 5; x()".to_string());
    assert!(result.is_err());
}

#[test]
fn test_type_error_property_on_null() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("null.property".to_string());
    assert!(result.is_err());
}

#[test]
fn test_type_error_property_on_undefined() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("undefined.property".to_string());
    assert!(result.is_err());
}

#[test]
fn test_range_error_recursion() {
    let runtime = JsRuntime::new().unwrap();
    runtime.set_max_stack_size(256 * 1024); // 256 KB
    let context = JsContext::from(&runtime).unwrap();

    // Deep recursion should cause stack overflow
    let result = context.eval(
        r#"
        function recurse() { recurse(); }
        recurse();
    "#
        .to_string(),
    );
    assert!(result.is_err());
}

#[test]
fn test_range_error_invalid_array_length() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("new Array(-1)".to_string());
    assert!(result.is_err());
}

// ============================================================================
// Memory Boundary Tests
// ============================================================================

#[test]
fn test_memory_limit() {
    let runtime = JsRuntime::new().unwrap();
    runtime.set_memory_limit(1024 * 1024); // 1 MB
    let context = JsContext::from(&runtime).unwrap();

    // Try to allocate very large array (should fail due to memory limit)
    let result = context.eval("new Array(10000000).fill({})".to_string());

    // Should fail due to memory limit
    assert!(result.is_err());
}

#[test]
fn test_gc_releases_memory() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // Allocate then discard
    let _ = context.eval(
        r#"
        let arr = [];
        for (let i = 0; i < 1000; i++) {
            arr.push({x: i});
        }
        arr = null;
    "#
        .to_string(),
    );

    let before = runtime.memory_usage();
    runtime.run_gc();
    let after = runtime.memory_usage();

    // Memory should decrease or stay same after GC
    assert!(after.total_memory() <= before.total_memory() + 1024);
}

// ============================================================================
// Async Boundary Tests
// ============================================================================

#[tokio::test]
async fn test_promise_resolve_immediately() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(JsCode::Code("Promise.resolve(42)".to_string()), None)
        .await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_promise_reject_immediately() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code("Promise.reject(new Error('rejected'))".to_string()),
            None,
        )
        .await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_promise_chain() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                "Promise.resolve(1).then(x => x + 1).then(x => x + 1)".to_string(),
            ),
            None,
        )
        .await;
    assert!(result.is_ok());
    let value = result.unwrap();
    assert!(matches!(value, JsValue::Integer(3)));
}

#[tokio::test]
async fn test_promise_all() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                "Promise.all([Promise.resolve(1), Promise.resolve(2), Promise.resolve(3)])"
                    .to_string(),
            ),
            None,
        )
        .await;
    assert!(result.is_ok());
    let value = result.unwrap();
    assert!(value.is_array());
}

#[tokio::test]
async fn test_promise_race() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                "Promise.race([Promise.resolve(1), Promise.resolve(2)])".to_string(),
            ),
            None,
        )
        .await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_async_await() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                r#"
                async function test() {
                    const a = await Promise.resolve(1);
                    const b = await Promise.resolve(2);
                    return a + b;
                }
                test()
            "#
                .to_string(),
            ),
            None,
        )
        .await;
    assert!(result.is_ok());
    let value = result.unwrap();
    assert!(matches!(value, JsValue::Integer(3)));
}

#[tokio::test]
async fn test_async_error_in_chain() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                r#"
                Promise.resolve(1)
                    .then(() => { throw new Error('middle error'); })
                    .then(() => 2)
            "#
                .to_string(),
            ),
            None,
        )
        .await;
    assert!(result.is_err());
}

// ============================================================================
// Module Boundary Tests
// ============================================================================

#[tokio::test]
async fn test_module_circular_import() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    // Module A imports B, B imports A
    let module_a = JsModule::code(
        "module-a".to_string(),
        r#"
        import { b } from 'module-b';
        export const a = 1;
        export const ab = a + (b || 0);
    "#
        .to_string(),
    );
    let module_b = JsModule::code(
        "module-b".to_string(),
        r#"
        import { a } from 'module-a';
        export const b = 2;
        export const ba = (a || 0) + b;
    "#
        .to_string(),
    );

    engine.declare_new_module(module_a).await.unwrap();
    engine.declare_new_module(module_b).await.unwrap();

    // This might fail or succeed depending on circular import handling
    // The important thing is it doesn't hang
    let _result = engine
        .eval(
            JsCode::Code("import { a } from 'module-a'; a".to_string()),
            None,
        )
        .await;
}

#[tokio::test]
async fn test_module_non_existent_export() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let module = JsModule::code(
        "my-module".to_string(),
        "export const a = 1;".to_string(),
    );
    engine.declare_new_module(module).await.unwrap();

    // Try to import non-existent export
    let result = engine
        .eval(
            JsCode::Code("import { nonExistent } from 'my-module'; nonExistent".to_string()),
            None,
        )
        .await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_module_default_and_named_exports() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let module = JsModule::code(
        "exports-module".to_string(),
        r#"
        export const a = 1;
        export const b = 2;
        export default 'default';
    "#
        .to_string(),
    );
    engine.declare_new_module(module).await.unwrap();

    let result = engine
        .eval(
            JsCode::Code(
                "import def, { a, b } from 'exports-module'; [def, a, b]".to_string(),
            ),
            None,
        )
        .await;
    assert!(result.is_ok());
    let value = result.unwrap();
    assert!(value.is_array());
}

#[tokio::test]
async fn test_module_re_export() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    let original = JsModule::code(
        "original".to_string(),
        "export const x = 42;".to_string(),
    );
    let reexport = JsModule::code(
        "reexport".to_string(),
        "export { x } from 'original';".to_string(),
    );

    engine.declare_new_module(original).await.unwrap();
    engine.declare_new_module(reexport).await.unwrap();

    let result = engine
        .eval(
            JsCode::Code("import { x } from 'reexport'; x".to_string()),
            None,
        )
        .await;
    assert!(result.is_ok());
    let value = result.unwrap();
    assert!(matches!(value, JsValue::Integer(42)));
}

// ============================================================================
// Type Coercion Boundary Tests
// ============================================================================

#[test]
fn test_type_coercion_addition() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // String + Number
    let result = context.eval("'3' + 2".to_string());
    match result {
        JsResult::Ok(JsValue::String(s)) => assert_eq!(s, "32"),
        _ => panic!("Expected string '32'"),
    }
}

#[test]
fn test_type_coercion_subtraction() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // String - Number coerces to number
    let result = context.eval("'5' - 2".to_string());
    assert!(result.is_ok());
}

#[test]
fn test_type_coercion_equality() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // Loose equality
    let result = context.eval("'1' == 1".to_string());
    match result {
        JsResult::Ok(JsValue::Boolean(b)) => assert!(b),
        _ => panic!("Expected true"),
    }

    // Strict equality
    let result = context.eval("'1' === 1".to_string());
    match result {
        JsResult::Ok(JsValue::Boolean(b)) => assert!(!b),
        _ => panic!("Expected false"),
    }
}

#[test]
fn test_truthiness() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // Falsy values
    for falsy in ["false", "0", "''", "null", "undefined", "NaN"] {
        let result = context.eval(format!("Boolean({})", falsy));
        match result {
            JsResult::Ok(JsValue::Boolean(b)) => assert!(!b, "{} should be falsy", falsy),
            _ => panic!("Expected boolean"),
        }
    }

    // Truthy values
    for truthy in ["true", "1", "'hello'", "[]", "{}", "-1"] {
        let result = context.eval(format!("Boolean({})", truthy));
        match result {
            JsResult::Ok(JsValue::Boolean(b)) => assert!(b, "{} should be truthy", truthy),
            _ => panic!("Expected boolean"),
        }
    }
}

// ============================================================================
// JsValue Boundary Tests
// ============================================================================

#[test]
fn test_jsvalue_nested_object_deep() {
    let mut deepest = HashMap::new();
    deepest.insert("value".to_string(), JsValue::Integer(42));

    let mut level4 = HashMap::new();
    level4.insert("level5".to_string(), JsValue::Object(deepest));

    let mut level3 = HashMap::new();
    level3.insert("level4".to_string(), JsValue::Object(level4));

    let mut level2 = HashMap::new();
    level2.insert("level3".to_string(), JsValue::Object(level3));

    let mut level1 = HashMap::new();
    level1.insert("level2".to_string(), JsValue::Object(level2));

    let root = JsValue::Object(level1);
    assert!(root.is_object());
}

#[test]
fn test_jsvalue_large_array() {
    let arr: Vec<JsValue> = (0..1000).map(|i| JsValue::Integer(i)).collect();
    let value = JsValue::Array(arr);
    assert!(value.is_array());
}

#[test]
fn test_jsvalue_empty_bytes() {
    let value = JsValue::Bytes(vec![]);
    assert!(value.is_bytes());
}

#[test]
fn test_jsvalue_large_bytes() {
    let data: Vec<u8> = (0..10000).map(|i| (i % 256) as u8).collect();
    let value = JsValue::Bytes(data);
    assert!(value.is_bytes());
}

// ============================================================================
// Date Boundary Tests
// ============================================================================

#[test]
fn test_date_epoch() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("new Date(0).getTime()".to_string());
    match result {
        JsResult::Ok(JsValue::Integer(ms)) => assert_eq!(ms, 0),
        JsResult::Ok(JsValue::Float(ms)) => assert!((ms - 0.0).abs() < f64::EPSILON),
        _ => panic!("Expected zero"),
    }
}

#[test]
fn test_date_negative_timestamp() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // Date before epoch
    let result = context.eval("new Date(-86400000).getTime()".to_string());
    assert!(result.is_ok());
}

#[test]
fn test_date_invalid() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval("new Date('invalid').getTime()".to_string());
    match result {
        JsResult::Ok(JsValue::Float(f)) => assert!(f.is_nan()),
        _ => panic!("Expected NaN for invalid date"),
    }
}

// ============================================================================
// Context Isolation Tests
// ============================================================================

#[test]
fn test_context_isolation_globals() {
    let runtime = JsRuntime::new().unwrap();

    // Create two contexts
    let context1 = JsContext::from(&runtime).unwrap();
    let context2 = JsContext::from(&runtime).unwrap();

    // Set a global in context1
    let _ = context1.eval("globalThis.x = 42".to_string());

    // It should not be visible in context2
    let result = context2.eval("typeof globalThis.x".to_string());
    match result {
        JsResult::Ok(JsValue::String(s)) => assert_eq!(s, "undefined"),
        _ => panic!("Expected undefined"),
    }
}

#[test]
fn test_context_isolation_functions() {
    let runtime = JsRuntime::new().unwrap();

    let context1 = JsContext::from(&runtime).unwrap();
    let context2 = JsContext::from(&runtime).unwrap();

    // Define a function in context1
    let _ = context1.eval("function myFunc() { return 42; }".to_string());

    // It should not be visible in context2
    let result = context2.eval("myFunc".to_string());
    assert!(result.is_err());
}

// ============================================================================
// Eval Options Boundary Tests
// ============================================================================

#[test]
fn test_eval_strict_mode() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let options = JsEvalOptions::new(Some(true), Some(true), None, None);

    // This code should fail in strict mode
    let result = context.eval_with_options("x = 5".to_string(), options);
    assert!(result.is_err());
}

#[test]
fn test_eval_non_strict_mode() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let options = JsEvalOptions::new(Some(true), Some(false), None, None);

    // This code should succeed in non-strict mode (creates global)
    let result = context.eval_with_options("x = 5; x".to_string(), options);
    assert!(result.is_ok());
}
