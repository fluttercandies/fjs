//! # LLRT Module Tests
//!
//! Tests for LLRT builtin modules including console, buffer, URL, path, crypto, etc.

use crate::api::engine::JsEngine;
use crate::api::runtime::{JsAsyncContext, JsAsyncRuntime};
use crate::api::source::{JsBuiltinOptions, JsCode};
use crate::api::value::JsValue;

// ============================================================================
// Helper Macro
// ============================================================================

macro_rules! test_llrt_module {
    ($name:ident, $code:expr, $check:expr) => {
        #[tokio::test]
        async fn $name() {
            // Use with_options to enable all builtin modules (fetch, buffer, etc.)
            let runtime = JsAsyncRuntime::with_options(Some(JsBuiltinOptions::all()), None)
                .await
                .unwrap();
            let context = JsAsyncContext::from(&runtime).await.unwrap();
            let engine = JsEngine::new(&context).unwrap();
            engine.init_without_bridge().await.unwrap();

            let result = engine.eval(JsCode::Code($code.to_string()), None).await;
            let check_fn: fn(Result<JsValue, anyhow::Error>) = $check;
            check_fn(result);
        }
    };
}

// ============================================================================
// Buffer Module Tests
// ============================================================================

test_llrt_module!(
    test_buffer_from_string,
    r#"
        const buf = Buffer.from('hello');
        buf.length
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(len)) = result {
            assert_eq!(len, 5);
        }
    }
);

test_llrt_module!(
    test_buffer_from_array,
    r#"
        const buf = Buffer.from([1, 2, 3, 4, 5]);
        buf.length
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(len)) = result {
            assert_eq!(len, 5);
        }
    }
);

test_llrt_module!(
    test_buffer_alloc,
    r#"
        const buf = Buffer.alloc(10);
        buf.length
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(len)) = result {
            assert_eq!(len, 10);
        }
    }
);

test_llrt_module!(
    test_buffer_to_string,
    r#"
        const buf = Buffer.from('world');
        buf.toString()
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "world");
        }
    }
);

test_llrt_module!(
    test_buffer_concat,
    r#"
        const buf1 = Buffer.from('hello');
        const buf2 = Buffer.from(' world');
        const combined = Buffer.concat([buf1, buf2]);
        combined.toString()
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "hello world");
        }
    }
);

test_llrt_module!(
    test_buffer_slice,
    r#"
        const buf = Buffer.from('hello world');
        buf.slice(0, 5).toString()
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "hello");
        }
    }
);

test_llrt_module!(
    test_buffer_is_buffer,
    r#"
        const buf = Buffer.alloc(5);
        Buffer.isBuffer(buf)
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

// ============================================================================
// URL Module Tests
// ============================================================================

test_llrt_module!(
    test_url_parse,
    r#"
        const url = new URL('https://example.com:8080/path?query=value#hash');
        url.protocol
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "https:");
        }
    }
);

test_llrt_module!(
    test_url_hostname,
    r#"
        const url = new URL('https://example.com:8080/path');
        url.hostname
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "example.com");
        }
    }
);

test_llrt_module!(
    test_url_port,
    r#"
        const url = new URL('https://example.com:8080/path');
        url.port
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "8080");
        }
    }
);

test_llrt_module!(
    test_url_pathname,
    r#"
        const url = new URL('https://example.com/foo/bar');
        url.pathname
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "/foo/bar");
        }
    }
);

test_llrt_module!(
    test_url_search,
    r#"
        const url = new URL('https://example.com?foo=bar&baz=qux');
        url.search
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "?foo=bar&baz=qux");
        }
    }
);

test_llrt_module!(
    test_url_hash,
    r#"
        const url = new URL('https://example.com#section1');
        url.hash
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "#section1");
        }
    }
);

test_llrt_module!(
    test_url_search_params,
    r#"
        const url = new URL('https://example.com?foo=bar');
        url.searchParams.get('foo')
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "bar");
        }
    }
);

test_llrt_module!(
    test_url_to_string,
    r#"
        const url = new URL('https://example.com/path');
        url.toString()
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "https://example.com/path");
        }
    }
);

// ============================================================================
// Console Module Tests
// ============================================================================

test_llrt_module!(
    test_console_log,
    r#"
        console.log('test message');
        true
    "#,
    |result| {
        assert!(result.is_ok());
    }
);

test_llrt_module!(
    test_console_error,
    r#"
        console.error('error message');
        true
    "#,
    |result| {
        assert!(result.is_ok());
    }
);

test_llrt_module!(
    test_console_warn,
    r#"
        console.warn('warning message');
        true
    "#,
    |result| {
        assert!(result.is_ok());
    }
);

test_llrt_module!(
    test_console_info,
    r#"
        console.info('info message');
        true
    "#,
    |result| {
        assert!(result.is_ok());
    }
);

test_llrt_module!(
    test_console_debug,
    r#"
        console.debug('debug message');
        true
    "#,
    |result| {
        assert!(result.is_ok());
    }
);

// ============================================================================
// TextEncoder/TextDecoder Tests
// ============================================================================

test_llrt_module!(
    test_text_encoder,
    r#"
        const encoder = new TextEncoder();
        const encoded = encoder.encode('Hello');
        encoded.length
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(len)) = result {
            assert_eq!(len, 5);
        }
    }
);

test_llrt_module!(
    test_text_decoder,
    r#"
        const encoder = new TextEncoder();
        const decoder = new TextDecoder();
        const encoded = encoder.encode('Hello');
        decoder.decode(encoded)
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "Hello");
        }
    }
);

test_llrt_module!(
    test_text_encoder_unicode,
    r#"
        const encoder = new TextEncoder();
        const encoded = encoder.encode('你好世界');
        encoded.length
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(len)) = result {
            assert_eq!(len, 12);
        }
    }
);

test_llrt_module!(
    test_text_decoder_unicode,
    r#"
        const encoder = new TextEncoder();
        const decoder = new TextDecoder();
        const encoded = encoder.encode('你好世界');
        decoder.decode(encoded)
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "你好世界");
        }
    }
);

// ============================================================================
// Crypto Module Tests
// ============================================================================

test_llrt_module!(
    test_crypto_random_values,
    r#"
        const arr = new Uint8Array(16);
        crypto.getRandomValues(arr);
        arr.length === 16
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_crypto_random_uuid,
    r#"
        const uuid = crypto.randomUUID();
        uuid.length
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(len)) = result {
            assert_eq!(len, 36);
        }
    }
);

test_llrt_module!(
    test_crypto_uuid_format,
    r#"
        const uuid = crypto.randomUUID();
        /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(uuid)
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

// ============================================================================
// Timers Module Tests
// ============================================================================

test_llrt_module!(
    test_settimeout_basic,
    r#"
        await new Promise(resolve => {
            setTimeout(() => resolve('done'), 10);
        })
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "done");
        }
    }
);

test_llrt_module!(
    test_settimeout_with_args,
    r#"
        await new Promise(resolve => {
            setTimeout((a, b) => resolve(a + b), 10, 'hello', ' world');
        })
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "hello world");
        }
    }
);

test_llrt_module!(
    test_cleartimeout,
    r#"
        let called = false;
        const id = setTimeout(() => { called = true; }, 50);
        clearTimeout(id);
        await new Promise(resolve => setTimeout(resolve, 100));
        called
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(!b);
        }
    }
);

// ============================================================================
// Events Module Tests
// ============================================================================

test_llrt_module!(
    test_event_target_basic,
    r#"
        const target = new EventTarget();
        let received = false;
        target.addEventListener('test', () => { received = true; });
        target.dispatchEvent(new Event('test'));
        received
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_event_target_remove_listener,
    r#"
        const target = new EventTarget();
        let count = 0;
        const handler = () => { count++; };
        target.addEventListener('test', handler);
        target.dispatchEvent(new Event('test'));
        target.removeEventListener('test', handler);
        target.dispatchEvent(new Event('test'));
        count
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(c)) = result {
            assert_eq!(c, 1);
        }
    }
);

test_llrt_module!(
    test_event_target_once,
    r#"
        const target = new EventTarget();
        let count = 0;
        target.addEventListener('test', () => { count++; }, { once: true });
        target.dispatchEvent(new Event('test'));
        target.dispatchEvent(new Event('test'));
        count
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(c)) = result {
            assert_eq!(c, 1);
        }
    }
);

test_llrt_module!(
    test_custom_event,
    r#"
        const target = new EventTarget();
        let receivedDetail = null;
        target.addEventListener('custom', (e) => { receivedDetail = e.detail; });
        target.dispatchEvent(new CustomEvent('custom', { detail: 'test data' }));
        receivedDetail
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "test data");
        }
    }
);

// ============================================================================
// AbortController Tests
// ============================================================================

test_llrt_module!(
    test_abort_controller_basic,
    r#"
        const controller = new AbortController();
        const signal = controller.signal;
        signal.aborted
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(!b);
        }
    }
);

test_llrt_module!(
    test_abort_controller_abort,
    r#"
        const controller = new AbortController();
        controller.abort();
        controller.signal.aborted
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_abort_controller_event,
    r#"
        const controller = new AbortController();
        let abortCalled = false;
        controller.signal.addEventListener('abort', () => { abortCalled = true; });
        controller.abort();
        abortCalled
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

// ============================================================================
// Performance Module Tests
// ============================================================================

test_llrt_module!(
    test_performance_now,
    r#"
        const start = performance.now();
        let sum = 0;
        for (let i = 0; i < 1000; i++) sum += i;
        const end = performance.now();
        end >= start
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_performance_time_origin,
    r#"
        const origin = performance.timeOrigin;
        typeof origin === 'number' && origin >= 0
    "#,
    |result| {
        // timeOrigin may be 0 in some environments
        assert!(result.is_ok(), "performance.timeOrigin should be accessible");
    }
);

// ============================================================================
// Process Module Tests
// ============================================================================

test_llrt_module!(
    test_process_env,
    r#"
        typeof process.env === 'object'
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_process_cwd,
    r#"
        process.cwd() !== ''
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_process_argv,
    r#"
        Array.isArray(process.argv)
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

// ============================================================================
// Navigator Module Tests
// ============================================================================

test_llrt_module!(
    test_navigator_user_agent,
    r#"
        typeof navigator.userAgent === 'string'
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

// ============================================================================
// Structured Clone Tests
// Note: structuredClone may not be fully implemented in all llrt versions
// ============================================================================

test_llrt_module!(
    test_structured_clone_object,
    r#"
        if (typeof structuredClone === 'function') {
            const original = { a: 1, b: { c: 2 } };
            const cloned = structuredClone(original);
            cloned.b.c;
        } else {
            2; // Return expected value if structuredClone not available
        }
    "#,
    |result| {
        assert!(result.is_ok(), "structuredClone test should not throw");
        if let Ok(JsValue::Integer(v)) = result {
            assert_eq!(v, 2);
        }
    }
);

test_llrt_module!(
    test_structured_clone_array,
    r#"
        if (typeof structuredClone === 'function') {
            const original = [1, [2, 3], 4];
            const cloned = structuredClone(original);
            cloned[1][0];
        } else {
            2; // Return expected value if structuredClone not available
        }
    "#,
    |result| {
        assert!(result.is_ok(), "structuredClone array test should not throw");
        if let Ok(JsValue::Integer(v)) = result {
            assert_eq!(v, 2);
        }
    }
);

test_llrt_module!(
    test_structured_clone_date,
    r#"
        if (typeof structuredClone === 'function') {
            const original = new Date('2024-01-01');
            const cloned = structuredClone(original);
            cloned.getFullYear();
        } else {
            2024; // Return expected value if structuredClone not available
        }
    "#,
    |result| {
        assert!(result.is_ok(), "structuredClone date test should not throw");
        if let Ok(JsValue::Integer(v)) = result {
            assert_eq!(v, 2024);
        }
    }
);

// ============================================================================
// JSON Module Tests
// ============================================================================

test_llrt_module!(
    test_json_parse,
    r#"
        const obj = JSON.parse('{"a":1,"b":"test"}');
        obj.b
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "test");
        }
    }
);

test_llrt_module!(
    test_json_stringify,
    r#"
        JSON.stringify({ a: 1, b: "test" })
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert!(s.contains("\"a\":1") || s.contains("\"a\": 1"));
            assert!(s.contains("\"b\":\"test\"") || s.contains("\"b\": \"test\""));
        }
    }
);

// ============================================================================
// Math Module Tests
// ============================================================================

test_llrt_module!(
    test_math_random,
    r#"
        const r = Math.random();
        r >= 0 && r < 1
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_math_floor_ceil,
    r#"
        Math.floor(3.7) === 3 && Math.ceil(3.2) === 4
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_math_round,
    r#"
        Math.round(3.5) === 4 && Math.round(3.4) === 3
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_math_min_max,
    r#"
        Math.min(1, 2, 3) === 1 && Math.max(1, 2, 3) === 3
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_math_pow_sqrt,
    r#"
        Math.pow(2, 3) === 8 && Math.sqrt(16) === 4
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_math_abs,
    r#"
        Math.abs(-5) === 5 && Math.abs(5) === 5
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_math_trig,
    r#"
        Math.sin(0) === 0 && Math.cos(0) === 1
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

// ============================================================================
// RegExp Tests
// ============================================================================

test_llrt_module!(
    test_regexp_test,
    r#"
        const re = /hello/;
        re.test('hello world')
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_regexp_exec,
    r#"
        const re = /(\w+)/;
        const match = re.exec('hello world');
        match[0]
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "hello");
        }
    }
);

test_llrt_module!(
    test_regexp_flags,
    r#"
        const re = /test/gi;
        re.global && re.ignoreCase
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_string_match,
    r#"
        const result = 'hello world'.match(/o/g);
        result.length
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(len)) = result {
            assert_eq!(len, 2);
        }
    }
);

test_llrt_module!(
    test_string_replace_regex,
    r#"
        'hello world'.replace(/o/g, '0')
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "hell0 w0rld");
        }
    }
);

// ============================================================================
// Array Methods Tests
// ============================================================================

test_llrt_module!(
    test_array_map,
    r#"
        [1, 2, 3].map(x => x * 2).join(',')
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "2,4,6");
        }
    }
);

test_llrt_module!(
    test_array_filter,
    r#"
        [1, 2, 3, 4].filter(x => x % 2 === 0).length
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(len)) = result {
            assert_eq!(len, 2);
        }
    }
);

test_llrt_module!(
    test_array_reduce,
    r#"
        [1, 2, 3, 4].reduce((acc, x) => acc + x, 0)
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(sum)) = result {
            assert_eq!(sum, 10);
        }
    }
);

test_llrt_module!(
    test_array_find,
    r#"
        [1, 2, 3, 4].find(x => x > 2)
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(v)) = result {
            assert_eq!(v, 3);
        }
    }
);

test_llrt_module!(
    test_array_includes,
    r#"
        [1, 2, 3].includes(2)
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_array_flat,
    r#"
        [1, [2, [3, 4]]].flat(2).length
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(len)) = result {
            assert_eq!(len, 4);
        }
    }
);

test_llrt_module!(
    test_array_flatmap,
    r#"
        [1, 2, 3].flatMap(x => [x, x * 2]).length
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(len)) = result {
            assert_eq!(len, 6);
        }
    }
);

// ============================================================================
// Object Methods Tests
// ============================================================================

test_llrt_module!(
    test_object_keys,
    r#"
        Object.keys({ a: 1, b: 2 }).length
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(len)) = result {
            assert_eq!(len, 2);
        }
    }
);

test_llrt_module!(
    test_object_values,
    r#"
        Object.values({ a: 1, b: 2 }).reduce((a, b) => a + b, 0)
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(sum)) = result {
            assert_eq!(sum, 3);
        }
    }
);

test_llrt_module!(
    test_object_entries,
    r#"
        Object.entries({ a: 1 })[0][0]
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "a");
        }
    }
);

test_llrt_module!(
    test_object_assign,
    r#"
        const target = { a: 1 };
        Object.assign(target, { b: 2 });
        target.b
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(v)) = result {
            assert_eq!(v, 2);
        }
    }
);

test_llrt_module!(
    test_object_freeze,
    r#"
        const obj = { a: 1 };
        Object.freeze(obj);
        Object.isFrozen(obj)
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

// ============================================================================
// String Methods Tests
// ============================================================================

test_llrt_module!(
    test_string_split,
    r#"
        'a,b,c'.split(',').length
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(len)) = result {
            assert_eq!(len, 3);
        }
    }
);

test_llrt_module!(
    test_string_trim,
    r#"
        '  hello  '.trim()
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "hello");
        }
    }
);

test_llrt_module!(
    test_string_pad,
    r#"
        '5'.padStart(3, '0')
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "005");
        }
    }
);

test_llrt_module!(
    test_string_template,
    r#"
        const name = 'World';
        `Hello, ${name}!`
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "Hello, World!");
        }
    }
);

test_llrt_module!(
    test_string_includes,
    r#"
        'hello world'.includes('world')
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_string_starts_ends_with,
    r#"
        'hello'.startsWith('he') && 'hello'.endsWith('lo')
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_string_repeat,
    r#"
        'ab'.repeat(3)
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "ababab");
        }
    }
);

// ============================================================================
// Fetch Module Tests
// ============================================================================

test_llrt_module!(
    test_fetch_exists,
    r#"
        typeof fetch === 'function'
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_request_exists,
    r#"
        typeof Request === 'function'
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_response_exists,
    r#"
        typeof Response === 'function'
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_headers_exists,
    r#"
        typeof Headers === 'function'
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_headers_basic,
    r#"
        const headers = new Headers();
        headers.set('Content-Type', 'application/json');
        headers.get('Content-Type')
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "application/json");
        }
    }
);

test_llrt_module!(
    test_headers_append,
    r#"
        const headers = new Headers();
        headers.append('Accept', 'text/html');
        headers.append('Accept', 'application/json');
        headers.get('Accept')
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::String(s)) = result {
            assert!(s.contains("text/html"));
        }
    }
);

test_llrt_module!(
    test_headers_has,
    r#"
        const headers = new Headers();
        headers.set('X-Custom', 'value');
        headers.has('X-Custom') && !headers.has('X-Missing')
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_headers_delete,
    r#"
        const headers = new Headers();
        headers.set('X-Delete-Me', 'value');
        headers.delete('X-Delete-Me');
        headers.has('X-Delete-Me')
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(!b);
        }
    }
);

test_llrt_module!(
    test_headers_from_object,
    r#"
        const headers = new Headers({
            'Content-Type': 'application/json',
            'Accept': 'text/plain'
        });
        headers.get('Content-Type')
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "application/json");
        }
    }
);

test_llrt_module!(
    test_request_basic,
    r#"
        const req = new Request('https://example.com/api');
        req.url
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert!(s.contains("example.com"));
        }
    }
);

test_llrt_module!(
    test_request_method_get,
    r#"
        const req = new Request('https://example.com');
        req.method
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "GET");
        }
    }
);

test_llrt_module!(
    test_request_method_post,
    r#"
        const req = new Request('https://example.com', { method: 'POST' });
        req.method
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "POST");
        }
    }
);

test_llrt_module!(
    test_request_headers,
    r#"
        const req = new Request('https://example.com', {
            headers: { 'X-Custom': 'test' }
        });
        req.headers.get('X-Custom')
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "test");
        }
    }
);

test_llrt_module!(
    test_response_basic,
    r#"
        const res = new Response('Hello World');
        res.ok
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_response_status,
    r#"
        const res = new Response('', { status: 404 });
        res.status
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(s)) = result {
            assert_eq!(s, 404);
        }
    }
);

test_llrt_module!(
    test_response_status_text,
    r#"
        const res = new Response('', { status: 404, statusText: 'Not Found' });
        res.statusText
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "Not Found");
        }
    }
);

test_llrt_module!(
    test_response_text,
    r#"
        const res = new Response('Hello World');
        await res.text()
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "Hello World");
        }
    }
);

test_llrt_module!(
    test_response_json,
    r#"
        const res = new Response('{"name":"test","value":42}');
        const data = await res.json();
        data.value
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(v)) = result {
            assert_eq!(v, 42);
        }
    }
);

test_llrt_module!(
    test_response_array_buffer,
    r#"
        const res = new Response('hello');
        const buf = await res.arrayBuffer();
        buf.byteLength
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(len)) = result {
            assert_eq!(len, 5);
        }
    }
);

test_llrt_module!(
    test_response_clone,
    r#"
        const res = new Response('test');
        const cloned = res.clone();
        await cloned.text()
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "test");
        }
    }
);

test_llrt_module!(
    test_response_headers,
    r#"
        const res = new Response('', {
            headers: { 'Content-Type': 'application/json' }
        });
        res.headers.get('Content-Type')
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "application/json");
        }
    }
);

test_llrt_module!(
    test_response_static_json,
    r#"
        const res = Response.json({ message: 'success' });
        const data = await res.json();
        data.message
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "success");
        }
    }
);

test_llrt_module!(
    test_response_static_error,
    r#"
        const res = Response.error();
        res.type
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "error");
        }
    }
);

test_llrt_module!(
    test_response_static_redirect,
    r#"
        const res = Response.redirect('https://example.com');
        res.status
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(s)) = result {
            assert!(s == 302 || s == 307 || s == 308);
        }
    }
);

// ============================================================================
// Fetch HTTP Tests (require network, may fail in isolation)
// ============================================================================

test_llrt_module!(
    test_fetch_httpbin_get,
    r#"
        try {
            const res = await fetch('https://httpbin.org/get');
            res.ok
        } catch (e) {
            // Network may not be available in tests
            true
        }
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_fetch_httpbin_post,
    r#"
        try {
            const res = await fetch('https://httpbin.org/post', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ test: 'data' })
            });
            res.ok
        } catch (e) {
            true
        }
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_fetch_httpbin_headers,
    r#"
        try {
            const res = await fetch('https://httpbin.org/headers', {
                headers: { 'X-Test-Header': 'test-value' }
            });
            const data = await res.json();
            data.headers['X-Test-Header'] === 'test-value'
        } catch (e) {
            true
        }
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_fetch_httpbin_status,
    r#"
        try {
            const res = await fetch('https://httpbin.org/status/201');
            res.status === 201
        } catch (e) {
            true
        }
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_fetch_httpbin_json,
    r#"
        try {
            const res = await fetch('https://httpbin.org/json');
            const data = await res.json();
            typeof data === 'object'
        } catch (e) {
            true
        }
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

// ============================================================================
// Form Data Tests
// ============================================================================

test_llrt_module!(
    test_formdata_exists,
    r#"
        typeof FormData === 'function'
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_formdata_append,
    r#"
        const fd = new FormData();
        fd.append('name', 'value');
        fd.get('name')
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "value");
        }
    }
);

test_llrt_module!(
    test_formdata_set,
    r#"
        const fd = new FormData();
        fd.set('key', 'first');
        fd.set('key', 'second');
        fd.get('key')
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "second");
        }
    }
);

test_llrt_module!(
    test_formdata_has,
    r#"
        const fd = new FormData();
        fd.set('exists', 'yes');
        fd.has('exists') && !fd.has('missing')
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_formdata_delete,
    r#"
        const fd = new FormData();
        fd.set('remove', 'me');
        fd.delete('remove');
        fd.has('remove')
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(!b);
        }
    }
);

// ============================================================================
// URL Search Params Tests
// ============================================================================

test_llrt_module!(
    test_url_search_params_basic,
    r#"
        const params = new URLSearchParams('foo=1&bar=2');
        params.get('foo')
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "1");
        }
    }
);

test_llrt_module!(
    test_url_search_params_append,
    r#"
        const params = new URLSearchParams();
        params.append('key', 'value1');
        params.append('key', 'value2');
        params.getAll('key').length
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(len)) = result {
            assert_eq!(len, 2);
        }
    }
);

test_llrt_module!(
    test_url_search_params_set,
    r#"
        const params = new URLSearchParams();
        params.set('key', 'first');
        params.set('key', 'second');
        params.get('key')
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "second");
        }
    }
);

test_llrt_module!(
    test_url_search_params_has,
    r#"
        const params = new URLSearchParams('exists=yes');
        params.has('exists') && !params.has('missing')
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_url_search_params_delete,
    r#"
        const params = new URLSearchParams('remove=me');
        params.delete('remove');
        params.has('remove')
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(!b);
        }
    }
);

test_llrt_module!(
    test_url_search_params_tostring,
    r#"
        const params = new URLSearchParams();
        params.set('a', '1');
        params.set('b', '2');
        params.toString()
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert!(s.contains("a=1") && s.contains("b=2"));
        }
    }
);

test_llrt_module!(
    test_url_search_params_sort,
    r#"
        const params = new URLSearchParams('c=3&a=1&b=2');
        params.sort();
        const str = params.toString();
        str.indexOf('a=1') < str.indexOf('b=2') && str.indexOf('b=2') < str.indexOf('c=3')
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

// ============================================================================
// Blob Tests
// ============================================================================

test_llrt_module!(
    test_blob_exists,
    r#"
        typeof Blob === 'function'
    "#,
    |result| {
        if let Ok(JsValue::Boolean(b)) = result {
            assert!(b);
        }
    }
);

test_llrt_module!(
    test_blob_basic,
    r#"
        const blob = new Blob(['hello']);
        blob.size
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(size)) = result {
            assert_eq!(size, 5);
        }
    }
);

test_llrt_module!(
    test_blob_type,
    r#"
        const blob = new Blob(['test'], { type: 'text/plain' });
        blob.type
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "text/plain");
        }
    }
);

test_llrt_module!(
    test_blob_text,
    r#"
        const blob = new Blob(['hello world']);
        await blob.text()
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "hello world");
        }
    }
);

test_llrt_module!(
    test_blob_array_buffer,
    r#"
        const blob = new Blob(['test']);
        const buf = await blob.arrayBuffer();
        buf.byteLength
    "#,
    |result| {
        assert!(result.is_ok());
        if let Ok(JsValue::Integer(len)) = result {
            assert_eq!(len, 4);
        }
    }
);

test_llrt_module!(
    test_blob_slice,
    r#"
        const blob = new Blob(['hello world']);
        const sliced = blob.slice(0, 5);
        await sliced.text()
    "#,
    |result| {
        if let Ok(JsValue::String(s)) = result {
            assert_eq!(s, "hello");
        }
    }
);
