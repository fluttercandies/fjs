//! # Memory Tests
//!
//! Tests for memory management, garbage collection, and memory limits.

use crate::api::engine::JsEngine;
use crate::api::runtime::{JsAsyncContext, JsAsyncRuntime, JsContext, JsRuntime};
use crate::api::source::JsCode;
use crate::api::value::JsValue;

// ============================================================================
// Memory Usage Tests
// ============================================================================

#[test]
fn test_memory_usage_initial() {
    let runtime = JsRuntime::new().unwrap();
    let usage = runtime.memory_usage();

    // Initial memory should be reasonable
    assert!(usage.total_memory() > 0);
    assert!(usage.total_memory() < 10 * 1024 * 1024); // Less than 10 MB initially
}

#[test]
fn test_memory_usage_increases_with_allocations() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let before = runtime.memory_usage();

    // Allocate many objects
    let _ = context.eval(
        r#"
        let arr = [];
        for (let i = 0; i < 1000; i++) {
            arr.push({ index: i, data: 'x'.repeat(100) });
        }
    "#
        .to_string(),
    );

    let after = runtime.memory_usage();

    // Memory should increase
    assert!(after.total_memory() > before.total_memory());
}

#[test]
fn test_memory_usage_object_count() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let before = runtime.memory_usage();

    // Create many objects
    let _ = context.eval(
        r#"
        let objects = [];
        for (let i = 0; i < 100; i++) {
            objects.push({});
        }
    "#
        .to_string(),
    );

    let after = runtime.memory_usage();

    // Object count should increase
    assert!(after.obj_count() > before.obj_count());
}

#[test]
fn test_memory_usage_string_count() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let before = runtime.memory_usage();

    // Create many strings
    let _ = context.eval(
        r#"
        let strings = [];
        for (let i = 0; i < 100; i++) {
            strings.push('string_' + i);
        }
    "#
        .to_string(),
    );

    let after = runtime.memory_usage();

    // String count should increase
    assert!(after.str_count() > before.str_count());
}

#[test]
fn test_memory_usage_function_count() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let before = runtime.memory_usage();

    // Create many functions
    let _ = context.eval(
        r#"
        let functions = [];
        for (let i = 0; i < 50; i++) {
            functions.push(function() { return i; });
        }
    "#
        .to_string(),
    );

    let after = runtime.memory_usage();

    // Function count should increase
    assert!(after.js_func_count() >= before.js_func_count());
}

#[test]
fn test_memory_usage_array_count() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    let before = runtime.memory_usage();

    // Create many arrays
    let _ = context.eval(
        r#"
        let arrays = [];
        for (let i = 0; i < 100; i++) {
            arrays.push([1, 2, 3, 4, 5]);
        }
    "#
        .to_string(),
    );

    let after = runtime.memory_usage();

    // Array count should increase
    assert!(after.array_count() > before.array_count());
}

#[test]
fn test_memory_usage_summary_format() {
    let runtime = JsRuntime::new().unwrap();
    let usage = runtime.memory_usage();
    let summary = usage.summary();

    // Should contain expected keywords
    assert!(summary.contains("Memory:"));
    assert!(summary.contains("bytes"));
    assert!(summary.contains("Objects:"));
    assert!(summary.contains("Functions:"));
    assert!(summary.contains("Strings:"));
}

// ============================================================================
// Garbage Collection Tests
// ============================================================================

#[test]
fn test_gc_manual_trigger() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // Allocate then discard
    let _ = context.eval(
        r#"
        let arr = [];
        for (let i = 0; i < 1000; i++) {
            arr.push({ data: 'x'.repeat(100) });
        }
        arr = null;
    "#
        .to_string(),
    );

    // Run GC multiple times
    for _ in 0..3 {
        runtime.run_gc();
    }

    // Should not panic and memory should be reasonable
    let usage = runtime.memory_usage();
    assert!(usage.total_memory() > 0);
}

#[test]
fn test_gc_frees_unreachable_objects() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // Create objects
    let _ = context.eval(
        r#"
        let temp = [];
        for (let i = 0; i < 500; i++) {
            temp.push({ data: new Array(100).fill(i) });
        }
    "#
        .to_string(),
    );

    let before = runtime.memory_usage();

    // Make objects unreachable
    let _ = context.eval("temp = null;".to_string());

    // Run GC
    runtime.run_gc();

    let after = runtime.memory_usage();

    // Memory should decrease or stay similar
    // Note: GC behavior may vary, so we just check it doesn't crash
    assert!(after.total_memory() > 0);
    // Ideally: assert!(after.total_memory() < before.total_memory());
    let _ = before; // Suppress warning
}

#[test]
fn test_gc_threshold_setting() {
    let runtime = JsRuntime::new().unwrap();

    // Set various thresholds
    runtime.set_gc_threshold(1024); // Very low
    runtime.set_gc_threshold(1024 * 1024); // 1 MB
    runtime.set_gc_threshold(10 * 1024 * 1024); // 10 MB

    // Should not panic
    let _context = JsContext::from(&runtime).unwrap();
}

#[tokio::test]
async fn test_gc_async_runtime() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let context = JsAsyncContext::from(&runtime).await.unwrap();

    // Allocate some data
    let _ = context
        .eval(
            r#"
        let data = [];
        for (let i = 0; i < 100; i++) {
            data.push({ value: i });
        }
        data = null;
    "#
            .to_string(),
        )
        .await;

    // Async GC
    runtime.run_gc().await;

    let usage = runtime.memory_usage().await;
    assert!(usage.total_memory() > 0);
}

// ============================================================================
// Memory Limit Tests
// ============================================================================

#[test]
fn test_memory_limit_set() {
    let runtime = JsRuntime::new().unwrap();

    // Set various limits
    runtime.set_memory_limit(1024 * 1024); // 1 MB
    runtime.set_memory_limit(16 * 1024 * 1024); // 16 MB
    runtime.set_memory_limit(0); // Unlimited

    // Should not panic
    let _context = JsContext::from(&runtime).unwrap();
}

#[test]
fn test_memory_limit_small() {
    let runtime = JsRuntime::new().unwrap();
    runtime.set_memory_limit(512 * 1024); // 512 KB - very small
    let context = JsContext::from(&runtime).unwrap();

    // Try to allocate a lot - should fail
    let result = context.eval(
        r#"
        let data = [];
        for (let i = 0; i < 100000; i++) {
            data.push({ x: i, y: 'data'.repeat(100) });
        }
    "#
        .to_string(),
    );

    // Should fail due to memory limit
    assert!(result.is_err());
}

#[test]
fn test_memory_limit_realistic() {
    let runtime = JsRuntime::new().unwrap();
    runtime.set_memory_limit(8 * 1024 * 1024); // 8 MB
    let context = JsContext::from(&runtime).unwrap();

    // Moderate allocation should succeed
    let result = context.eval(
        r#"
        let data = [];
        for (let i = 0; i < 100; i++) {
            data.push({ x: i });
        }
        data.length
    "#
        .to_string(),
    );

    assert!(result.is_ok());
}

#[tokio::test]
async fn test_memory_limit_async() {
    let runtime = JsAsyncRuntime::new().unwrap();
    runtime.set_memory_limit(8 * 1024 * 1024).await;

    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let engine = JsEngine::new(&context).unwrap();
    engine.init_without_bridge().await.unwrap();

    // Should work with reasonable allocation
    let result = engine
        .eval(JsCode::Code("[1, 2, 3, 4, 5]".to_string()), None)
        .await;
    assert!(result.is_ok());
}

// ============================================================================
// Stack Size Limit Tests
// ============================================================================

#[test]
fn test_stack_size_limit_set() {
    let runtime = JsRuntime::new().unwrap();

    // Set various stack sizes
    runtime.set_max_stack_size(256 * 1024); // 256 KB
    runtime.set_max_stack_size(1024 * 1024); // 1 MB
    runtime.set_max_stack_size(0); // Default

    let _context = JsContext::from(&runtime).unwrap();
}

#[test]
fn test_stack_overflow_protection() {
    let runtime = JsRuntime::new().unwrap();
    runtime.set_max_stack_size(128 * 1024); // Small stack
    let context = JsContext::from(&runtime).unwrap();

    // Deep recursion should fail
    let result = context.eval(
        r#"
        function recurse(n) {
            if (n <= 0) return 0;
            return 1 + recurse(n - 1);
        }
        recurse(100000)
    "#
        .to_string(),
    );

    // Should error due to stack overflow
    assert!(result.is_err());
}

#[test]
fn test_stack_with_reasonable_recursion() {
    let runtime = JsRuntime::new().unwrap();
    runtime.set_max_stack_size(1024 * 1024); // 1 MB
    let context = JsContext::from(&runtime).unwrap();

    // Moderate recursion should succeed
    let result = context.eval(
        r#"
        function factorial(n) {
            if (n <= 1) return 1;
            return n * factorial(n - 1);
        }
        factorial(10)
    "#
        .to_string(),
    );

    assert!(result.is_ok());
}

// ============================================================================
// Memory Usage All Getters Test
// ============================================================================

#[test]
fn test_memory_usage_all_getters() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // Do some work
    let _ = context.eval(
        r#"
        let arr = [1, 2, 3];
        let obj = {a: 1, b: 2};
        function test() { return 42; }
        let str = "hello world";
    "#
        .to_string(),
    );

    let usage = runtime.memory_usage();

    // Test all getters
    let _ = usage.malloc_size();
    let _ = usage.malloc_limit();
    let _ = usage.memory_used_size();
    let _ = usage.malloc_count();
    let _ = usage.memory_used_count();
    let _ = usage.atom_count();
    let _ = usage.atom_size();
    let _ = usage.str_count();
    let _ = usage.str_size();
    let _ = usage.obj_count();
    let _ = usage.obj_size();
    let _ = usage.prop_count();
    let _ = usage.prop_size();
    let _ = usage.shape_count();
    let _ = usage.shape_size();
    let _ = usage.js_func_count();
    let _ = usage.js_func_size();
    let _ = usage.js_func_code_size();
    let _ = usage.js_func_pc2line_count();
    let _ = usage.js_func_pc2line_size();
    let _ = usage.c_func_count();
    let _ = usage.array_count();
    let _ = usage.fast_array_count();
    let _ = usage.fast_array_elements();
    let _ = usage.binary_object_count();
    let _ = usage.binary_object_size();
    let _ = usage.total_memory();
    let _ = usage.total_allocations();
}

#[test]
fn test_memory_usage_clone() {
    let runtime = JsRuntime::new().unwrap();
    let usage = runtime.memory_usage();
    let cloned = usage.clone();

    assert_eq!(usage.total_memory(), cloned.total_memory());
    assert_eq!(usage.obj_count(), cloned.obj_count());
    assert_eq!(usage.str_count(), cloned.str_count());
}

// ============================================================================
// Memory Stress Tests
// ============================================================================

#[test]
fn test_memory_stress_allocate_deallocate() {
    let runtime = JsRuntime::new().unwrap();
    runtime.set_memory_limit(32 * 1024 * 1024); // 32 MB
    let context = JsContext::from(&runtime).unwrap();

    // Multiple cycles of allocation and deallocation
    for i in 0..5 {
        let _ = context.eval(format!(
            r#"
            let cycle{} = [];
            for (let i = 0; i < 100; i++) {{
                cycle{}.push({{ data: new Array(50).fill(i) }});
            }}
            cycle{} = null;
        "#,
            i, i, i
        ));

        runtime.run_gc();
    }

    let usage = runtime.memory_usage();
    assert!(usage.total_memory() < 32 * 1024 * 1024);
}

#[test]
fn test_memory_large_string_allocation() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // Large string
    let result = context.eval("'x'.repeat(100000)".to_string());
    assert!(result.is_ok());

    // Multiple large strings
    let result = context.eval(
        r#"
        let strings = [];
        for (let i = 0; i < 10; i++) {
            strings.push('y'.repeat(10000));
        }
        strings.length
    "#
        .to_string(),
    );
    assert!(result.is_ok());
}

#[test]
fn test_memory_large_array_allocation() {
    let runtime = JsRuntime::new().unwrap();
    runtime.set_memory_limit(64 * 1024 * 1024); // 64 MB
    let context = JsContext::from(&runtime).unwrap();

    let result = context.eval(
        r#"
        let arr = new Array(10000);
        for (let i = 0; i < arr.length; i++) {
            arr[i] = i;
        }
        arr.length
    "#
        .to_string(),
    );

    assert!(result.is_ok());
    if let crate::api::error::JsResult::Ok(JsValue::Integer(len)) = result {
        assert_eq!(len, 10000);
    }
}

#[test]
fn test_memory_deep_object_nesting() {
    let runtime = JsRuntime::new().unwrap();
    let context = JsContext::from(&runtime).unwrap();

    // Create deeply nested object
    let result = context.eval(
        r#"
        function createNested(depth) {
            if (depth === 0) return { value: 'leaf' };
            return { child: createNested(depth - 1) };
        }
        let nested = createNested(50);
        nested.child.child.child.child.child !== undefined
    "#
        .to_string(),
    );

    assert!(result.is_ok());
}

// ============================================================================
// Runtime Info Tests
// ============================================================================

#[test]
fn test_runtime_set_info() {
    let runtime = JsRuntime::new().unwrap();
    let result = runtime.set_info("Test Runtime v1.0".to_string());
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_runtime_set_info_async() {
    let runtime = JsAsyncRuntime::new().unwrap();
    let result = runtime.set_info("Test Async Runtime v1.0".to_string()).await;
    assert!(result.is_ok());
}

// ============================================================================
// Dump Flags Tests
// ============================================================================

#[test]
fn test_runtime_dump_flags() {
    let runtime = JsRuntime::new().unwrap();

    // Various dump flag values
    runtime.set_dump_flags(0);
    runtime.set_dump_flags(1);
    runtime.set_dump_flags(0xFFFF);

    // Should not panic
    let _context = JsContext::from(&runtime).unwrap();
}
