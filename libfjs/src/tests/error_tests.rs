//! # Error Tests
//!
//! Tests for error types and error handling in the FJS library.

use crate::api::error::{JsError, JsResult};
use crate::api::value::JsValue;

// ============================================================================
// JsError Creation Tests
// ============================================================================

#[test]
fn test_error_promise() {
    let err = JsError::promise("Promise failed");
    assert_eq!(err.code(), "PROMISE_ERROR");
    assert!(err.is_recoverable());
    assert!(err.to_string().contains("Promise"));
}

#[test]
fn test_error_module() {
    let err = JsError::module(
        Some("test-module".to_string()),
        Some("testMethod".to_string()),
        "Module error",
    );
    assert_eq!(err.code(), "MODULE_ERROR");
    assert!(err.is_recoverable());
    let msg = err.to_string();
    assert!(msg.contains("test-module"));
    assert!(msg.contains("testMethod"));
}

#[test]
fn test_error_module_no_module_name() {
    let err = JsError::module(None, Some("method".to_string()), "error");
    let msg = err.to_string();
    assert!(msg.contains("method"));
}

#[test]
fn test_error_module_no_method_name() {
    let err = JsError::module(Some("module".to_string()), None, "error");
    let msg = err.to_string();
    assert!(msg.contains("module"));
}

#[test]
fn test_error_context() {
    let err = JsError::context("Context error");
    assert_eq!(err.code(), "CONTEXT_ERROR");
    assert!(!err.is_recoverable());
}

#[test]
fn test_error_storage() {
    let err = JsError::storage("Storage error");
    assert_eq!(err.code(), "STORAGE_ERROR");
    assert!(!err.is_recoverable());
}

#[test]
fn test_error_io() {
    let err = JsError::io(Some("/path/to/file".to_string()), "File not found");
    assert_eq!(err.code(), "IO_ERROR");
    assert!(err.is_recoverable());
    let msg = err.to_string();
    assert!(msg.contains("/path/to/file"));
}

#[test]
fn test_error_io_no_path() {
    let err = JsError::io(None, "IO error occurred");
    let msg = err.to_string();
    assert!(msg.contains("IO error"));
}

#[test]
fn test_error_runtime() {
    let err = JsError::runtime("Runtime error");
    assert_eq!(err.code(), "RUNTIME_ERROR");
    assert!(err.is_recoverable());
}

#[test]
fn test_error_generic() {
    let err = JsError::generic("Generic error");
    assert_eq!(err.code(), "GENERIC_ERROR");
    assert!(err.is_recoverable());
}

#[test]
fn test_error_engine() {
    let err = JsError::engine("Engine error");
    assert_eq!(err.code(), "ENGINE_ERROR");
    assert!(!err.is_recoverable());
}

#[test]
fn test_error_bridge() {
    let err = JsError::bridge("Bridge error");
    assert_eq!(err.code(), "BRIDGE_ERROR");
    assert!(err.is_recoverable());
}

#[test]
fn test_error_conversion() {
    let err = JsError::conversion("String", "Number", "Cannot convert");
    assert_eq!(err.code(), "CONVERSION_ERROR");
    assert!(err.is_recoverable());
    let msg = err.to_string();
    assert!(msg.contains("String"));
    assert!(msg.contains("Number"));
}

#[test]
fn test_error_timeout() {
    let err = JsError::timeout("eval", 5000);
    assert_eq!(err.code(), "TIMEOUT_ERROR");
    assert!(err.is_recoverable());
    let msg = err.to_string();
    assert!(msg.contains("eval"));
    assert!(msg.contains("5000"));
}

#[test]
fn test_error_memory_limit() {
    let err = JsError::memory_limit(16 * 1024 * 1024, 8 * 1024 * 1024);
    assert_eq!(err.code(), "MEMORY_LIMIT_ERROR");
    assert!(!err.is_recoverable());
}

#[test]
fn test_error_stack_overflow() {
    let err = JsError::StackOverflow("Too many recursions".to_string());
    assert_eq!(err.code(), "STACK_OVERFLOW_ERROR");
    assert!(!err.is_recoverable());
}

#[test]
fn test_error_syntax() {
    let err = JsError::syntax(Some(10), Some(5), "Unexpected token");
    assert_eq!(err.code(), "SYNTAX_ERROR");
    assert!(err.is_recoverable());
    let msg = err.to_string();
    assert!(msg.contains("line 10"));
    assert!(msg.contains("column 5"));
}

#[test]
fn test_error_syntax_no_location() {
    let err = JsError::syntax(None, None, "Syntax error");
    let msg = err.to_string();
    assert!(msg.contains("Syntax error"));
}

#[test]
fn test_error_reference() {
    let err = JsError::reference("undefined is not defined");
    assert_eq!(err.code(), "REFERENCE_ERROR");
    assert!(err.is_recoverable());
}

#[test]
fn test_error_type() {
    let err = JsError::type_error("null is not an object");
    assert_eq!(err.code(), "TYPE_ERROR");
    assert!(err.is_recoverable());
}

#[test]
fn test_error_cancelled() {
    let err = JsError::cancelled("Operation cancelled");
    assert_eq!(err.code(), "CANCELLED_ERROR");
    assert!(!err.is_recoverable());
}

// ============================================================================
// JsError Display Tests
// ============================================================================

#[test]
fn test_error_display_promise() {
    let err = JsError::Promise("test".to_string());
    assert_eq!(format!("{}", err), "Promise error: test");
}

#[test]
fn test_error_display_generic() {
    let err = JsError::Generic("simple error".to_string());
    assert_eq!(format!("{}", err), "simple error");
}

// ============================================================================
// JsError From Trait Tests
// ============================================================================

#[test]
fn test_error_from_anyhow() {
    let anyhow_err = anyhow::anyhow!("anyhow error");
    let js_err: JsError = anyhow_err.into();
    assert!(matches!(js_err, JsError::Generic(_)));
}

#[test]
fn test_error_from_io() {
    let io_err = std::io::Error::new(std::io::ErrorKind::NotFound, "file not found");
    let js_err: JsError = io_err.into();
    assert!(matches!(js_err, JsError::Io { .. }));
}

// ============================================================================
// JsResult Tests
// ============================================================================

#[test]
fn test_result_ok() {
    let result = JsResult::ok(JsValue::Integer(42));
    assert!(result.is_ok());
    assert!(!result.is_err());
}

#[test]
fn test_result_err() {
    let result = JsResult::err(JsError::runtime("error"));
    assert!(result.is_err());
    assert!(!result.is_ok());
}

#[test]
fn test_result_map() {
    let result = JsResult::ok(JsValue::Integer(42));
    let mapped = result.map(|v| {
        if let JsValue::Integer(n) = v {
            n * 2
        } else {
            0
        }
    });
    assert_eq!(mapped.unwrap(), 84);
}

#[test]
fn test_result_map_err() {
    let result = JsResult::ok(JsValue::Integer(42));
    let mapped = result.map_err(|_e| JsError::generic("mapped error"));
    assert!(mapped.is_ok());
}

#[test]
fn test_result_into_result() {
    let result = JsResult::ok(JsValue::Integer(42));
    let anyhow_result = result.into_result();
    assert!(anyhow_result.is_ok());
}

#[test]
fn test_result_into_result_err() {
    let result = JsResult::err(JsError::runtime("error"));
    let anyhow_result = result.into_result();
    assert!(anyhow_result.is_err());
}

#[test]
fn test_result_from_rust_result_ok() {
    let rust_result: Result<JsValue, JsError> = Ok(JsValue::Integer(42));
    let js_result: JsResult = rust_result.into();
    assert!(js_result.is_ok());
}

#[test]
fn test_result_from_rust_result_err() {
    let rust_result: Result<JsValue, JsError> = Err(JsError::runtime("error"));
    let js_result: JsResult = rust_result.into();
    assert!(js_result.is_err());
}

#[test]
fn test_result_into_rust_result() {
    let js_result = JsResult::ok(JsValue::Integer(42));
    let rust_result: Result<JsValue, JsError> = js_result.into();
    assert!(rust_result.is_ok());
}

// ============================================================================
// Error Clone Tests
// ============================================================================

#[test]
fn test_error_clone() {
    let err = JsError::runtime("test error");
    let cloned = err.clone();
    assert_eq!(err.code(), cloned.code());
    assert_eq!(err.to_string(), cloned.to_string());
}

#[test]
fn test_result_clone() {
    let result = JsResult::ok(JsValue::Integer(42));
    let cloned = result.clone();
    assert!(cloned.is_ok());
}

// ============================================================================
// Error Debug Tests
// ============================================================================

#[test]
fn test_error_debug() {
    let err = JsError::runtime("test");
    let debug_str = format!("{:?}", err);
    assert!(debug_str.contains("Runtime"));
}

#[test]
fn test_result_debug() {
    let result = JsResult::ok(JsValue::Integer(42));
    let debug_str = format!("{:?}", result);
    assert!(debug_str.contains("Ok"));
}

// ============================================================================
// All Error Codes Test
// ============================================================================

#[test]
fn test_all_error_codes_unique() {
    let errors = vec![
        JsError::promise(""),
        JsError::module(None, None, ""),
        JsError::context(""),
        JsError::storage(""),
        JsError::io(None, ""),
        JsError::runtime(""),
        JsError::generic(""),
        JsError::engine(""),
        JsError::bridge(""),
        JsError::conversion("", "", ""),
        JsError::timeout("", 0),
        JsError::memory_limit(0, 0),
        JsError::StackOverflow("".to_string()),
        JsError::syntax(None, None, ""),
        JsError::reference(""),
        JsError::type_error(""),
        JsError::cancelled(""),
    ];

    let codes: Vec<String> = errors.iter().map(|e| e.code()).collect();
    let unique_codes: std::collections::HashSet<_> = codes.iter().collect();

    // All codes should be unique
    assert_eq!(codes.len(), unique_codes.len());
}

// ============================================================================
// Recoverable Classification Test
// ============================================================================

#[test]
fn test_recoverable_errors() {
    // Recoverable errors
    assert!(JsError::promise("").is_recoverable());
    assert!(JsError::module(None, None, "").is_recoverable());
    assert!(JsError::io(None, "").is_recoverable());
    assert!(JsError::runtime("").is_recoverable());
    assert!(JsError::generic("").is_recoverable());
    assert!(JsError::bridge("").is_recoverable());
    assert!(JsError::conversion("", "", "").is_recoverable());
    assert!(JsError::timeout("", 0).is_recoverable());
    assert!(JsError::syntax(None, None, "").is_recoverable());
    assert!(JsError::reference("").is_recoverable());
    assert!(JsError::type_error("").is_recoverable());
}

#[test]
fn test_non_recoverable_errors() {
    // Non-recoverable errors
    assert!(!JsError::context("").is_recoverable());
    assert!(!JsError::storage("").is_recoverable());
    assert!(!JsError::engine("").is_recoverable());
    assert!(!JsError::memory_limit(0, 0).is_recoverable());
    assert!(!JsError::StackOverflow("".to_string()).is_recoverable());
    assert!(!JsError::cancelled("").is_recoverable());
}
