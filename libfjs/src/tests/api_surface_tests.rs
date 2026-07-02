//! Public API surface and multi-API integration tests.
//!
//! These tests intentionally exercise multiple APIs together. The smaller test
//! modules cover isolated behavior; this file protects the public API contracts
//! that app integrations commonly compose in production.

use crate::api::bytecode::JsBytecode;
use crate::api::engine::{JsEngine, JsEngineRuntimeOptions};
use crate::api::error::{JsError, JsResult};
use crate::api::runtime::{JsAsyncContext, JsAsyncRuntime, JsContext, JsRuntime, MemoryUsage};
use crate::api::source::{
    JsBuiltinOptions, JsBytecodeEndianness, JsCode, JsEvalOptions, JsModule, JsModuleBytecode,
    JsModuleBytecodeBundle, JsModuleBytecodeOptions, JsScriptBytecode, JsScriptBytecodeOptions,
    MAX_FILE_SIZE, get_raw_source_code, get_raw_source_code_sync,
};
use crate::api::value::JsValue;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

static TEMP_FILE_COUNTER: AtomicU64 = AtomicU64::new(0);

struct TempJsFile {
    path: PathBuf,
}

impl TempJsFile {
    fn new(name: &str, contents: impl AsRef<[u8]>) -> Self {
        let id = TEMP_FILE_COUNTER.fetch_add(1, Ordering::Relaxed);
        let path = std::env::temp_dir().join(format!(
            "fjs-api-surface-{}-{id}-{name}",
            std::process::id()
        ));
        fs::write(&path, contents).unwrap();
        Self { path }
    }

    fn path_string(&self) -> String {
        self.path.to_string_lossy().into_owned()
    }
}

impl Drop for TempJsFile {
    fn drop(&mut self) {
        let _ = fs::remove_file(&self.path);
    }
}

fn assert_memory_usage_is_readable(usage: &MemoryUsage) {
    assert!(usage.malloc_size() >= 0);
    assert!(usage.malloc_limit() >= 0);
    assert!(usage.memory_used_size() >= 0);
    assert!(usage.malloc_count() >= 0);
    assert!(usage.memory_used_count() >= 0);
    assert!(usage.atom_count() >= 0);
    assert!(usage.atom_size() >= 0);
    assert!(usage.str_count() >= 0);
    assert!(usage.str_size() >= 0);
    assert!(usage.obj_count() >= 0);
    assert!(usage.obj_size() >= 0);
    assert!(usage.prop_count() >= 0);
    assert!(usage.prop_size() >= 0);
    assert!(usage.shape_count() >= 0);
    assert!(usage.shape_size() >= 0);
    assert!(usage.js_func_count() >= 0);
    assert!(usage.js_func_size() >= 0);
    assert!(usage.js_func_code_size() >= 0);
    assert!(usage.js_func_pc2line_count() >= 0);
    assert!(usage.js_func_pc2line_size() >= 0);
    assert!(usage.c_func_count() >= 0);
    assert!(usage.array_count() >= 0);
    assert!(usage.fast_array_count() >= 0);
    assert!(usage.fast_array_elements() >= 0);
    assert!(usage.binary_object_count() >= 0);
    assert!(usage.binary_object_size() >= 0);
    assert_eq!(usage.total_memory(), usage.memory_used_size());
    assert_eq!(usage.total_allocations(), usage.malloc_count());
    assert!(usage.summary().contains("Memory:"));
}

fn builtin_flags(options: &JsBuiltinOptions) -> [Option<bool>; 30] {
    [
        options.abort,
        options.assert,
        options.async_hooks,
        options.buffer,
        options.child_process,
        options.console,
        options.crypto,
        options.dgram,
        options.dns,
        options.events,
        options.exceptions,
        options.fetch,
        options.fs,
        options.https,
        options.intl,
        options.navigator,
        options.net,
        options.os,
        options.path,
        options.perf_hooks,
        options.process,
        options.stream_web,
        options.string_decoder,
        options.temporal,
        options.timers,
        options.tty,
        options.url,
        options.util,
        options.zlib,
        options.json,
    ]
}

fn enabled_builtin_count(options: &JsBuiltinOptions) -> usize {
    builtin_flags(options)
        .into_iter()
        .filter(|flag| *flag == Some(true))
        .count()
}

fn expect_integer(value: JsValue, expected: i64) {
    assert!(
        matches!(value, JsValue::Integer(actual) if actual == expected),
        "expected integer {expected}, got {value:?}"
    );
}

fn expect_string(value: JsValue, expected: &str) {
    assert!(
        matches!(value, JsValue::String(ref actual) if actual == expected),
        "expected string {expected:?}, got {value:?}"
    );
}

fn unwrap_js_result(result: JsResult) -> JsValue {
    match result {
        JsResult::Ok(value) => value,
        JsResult::Err(error) => panic!("expected JsResult::Ok, got {error:?}"),
    }
}

async fn wait_for_engine_error(engine: &JsEngine, needle: &str) -> Vec<String> {
    let deadline = Instant::now() + Duration::from_secs(2);
    loop {
        let errors = engine.drain_unhandled_job_errors();
        if errors.iter().any(|error| error.contains(needle)) {
            return errors;
        }
        assert!(
            Instant::now() < deadline,
            "timed out waiting for engine background error containing {needle:?}"
        );
        tokio::time::sleep(Duration::from_millis(20)).await;
    }
}

async fn wait_for_runtime_error(runtime: &JsAsyncRuntime, needle: &str) -> Vec<String> {
    let deadline = Instant::now() + Duration::from_secs(2);
    loop {
        let errors = runtime.drain_unhandled_job_errors().await;
        if errors.iter().any(|error| error.contains(needle)) {
            return errors;
        }
        assert!(
            Instant::now() < deadline,
            "timed out waiting for runtime background error containing {needle:?}"
        );
        tokio::time::sleep(Duration::from_millis(20)).await;
    }
}

#[tokio::test]
async fn source_value_error_and_result_public_helpers_cover_edge_cases() {
    let source_file = TempJsFile::new("source.js", b"const fileBacked = 42;");

    let inline = JsCode::code("const inline = 1;".to_string());
    assert!(inline.is_code());
    assert!(!inline.is_path());
    assert!(!inline.is_bytes());
    assert_eq!(inline.as_path(), None);
    assert_eq!(
        get_raw_source_code_sync(inline.clone()).unwrap(),
        b"const inline = 1;".to_vec()
    );
    assert_eq!(
        get_raw_source_code(inline).await.unwrap(),
        b"const inline = 1;".to_vec()
    );

    let file_source = JsCode::path(source_file.path_string());
    assert!(file_source.is_path());
    assert_eq!(
        file_source.as_path(),
        Some(source_file.path_string().as_str())
    );
    assert_eq!(
        get_raw_source_code_sync(file_source.clone()).unwrap(),
        b"const fileBacked = 42;".to_vec()
    );
    assert_eq!(
        get_raw_source_code(file_source).await.unwrap(),
        b"const fileBacked = 42;".to_vec()
    );

    let bytes = JsCode::bytes(vec![b'a', 0, b'b', b';']);
    assert!(bytes.is_bytes());
    assert_eq!(
        get_raw_source_code_sync(bytes.clone()).unwrap(),
        vec![b'a', 0, b'b', b';']
    );
    assert_eq!(
        get_raw_source_code(bytes).await.unwrap(),
        vec![b'a', 0, b'b', b';']
    );

    let missing = get_raw_source_code_sync(JsCode::path(
        Path::new(&source_file.path_string())
            .with_extension("missing")
            .to_string_lossy()
            .into_owned(),
    ))
    .unwrap_err();
    assert_eq!(missing.code(), "IO_ERROR");
    assert!(missing.is_recoverable());

    assert_eq!(MAX_FILE_SIZE, 10 * 1024 * 1024);

    let module_from_new = JsModule::new(
        "surface/new.js".to_string(),
        JsCode::code("export const value = 1;".to_string()),
    );
    assert_eq!(module_from_new.name, "surface/new.js");
    assert!(module_from_new.source.is_code());
    assert!(
        JsModule::code(
            "surface/code.js".to_string(),
            "export default 1;".to_string()
        )
        .source
        .is_code()
    );
    assert!(
        JsModule::path("surface/path.js".to_string(), source_file.path_string())
            .source
            .is_path()
    );
    assert!(
        JsModule::bytes(
            "surface/bytes.js".to_string(),
            b"export default 1;".to_vec()
        )
        .source
        .is_bytes()
    );

    assert_eq!(
        JsBytecodeEndianness::default(),
        JsBytecodeEndianness::Little
    );
    let module_options = JsModuleBytecodeOptions::defaults();
    assert_eq!(
        module_options.endianness,
        Some(JsBytecodeEndianness::Little)
    );
    assert_eq!(module_options.strip_source, Some(true));
    assert_eq!(module_options.strip_debug, Some(true));
    let custom_module_options = JsModuleBytecodeOptions {
        endianness: Some(JsBytecodeEndianness::Big),
        strip_source: Some(false),
        strip_debug: Some(false),
    };
    assert_eq!(
        custom_module_options.endianness,
        Some(JsBytecodeEndianness::Big)
    );
    let native_module_options = JsModuleBytecodeOptions {
        endianness: Some(JsBytecodeEndianness::Native),
        strip_source: None,
        strip_debug: None,
    };
    assert_eq!(
        native_module_options.endianness,
        Some(JsBytecodeEndianness::Native)
    );

    let script_options = JsScriptBytecodeOptions::defaults();
    assert_eq!(
        script_options.endianness,
        Some(JsBytecodeEndianness::Little)
    );
    assert_eq!(script_options.strip_source, Some(true));
    assert_eq!(script_options.strip_debug, Some(true));
    assert_eq!(script_options.strict, Some(true));
    assert_eq!(script_options.backtrace_barrier, Some(false));
    assert_eq!(script_options.promise, Some(false));

    let module_bytecode = JsModuleBytecode::new("bytecode/new.js".to_string(), vec![1, 2, 3]);
    assert_eq!(module_bytecode.name, "bytecode/new.js");
    assert_eq!(module_bytecode.bytes, vec![1, 2, 3]);
    let bundle = JsModuleBytecodeBundle::new(
        Some("bytecode/new.js".to_string()),
        vec![module_bytecode.clone()],
    );
    assert_eq!(bundle.entry, Some("bytecode/new.js".to_string()));
    assert_eq!(bundle.modules.len(), 1);
    let script_bytecode = JsScriptBytecode::new("script/new.js".to_string(), vec![4, 5, 6]);
    assert_eq!(script_bytecode.name, "script/new.js");
    assert_eq!(script_bytecode.bytes, vec![4, 5, 6]);

    let defaults = JsEvalOptions::defaults();
    assert_eq!(defaults.global, Some(true));
    assert_eq!(defaults.strict, Some(true));
    assert_eq!(defaults.backtrace_barrier, Some(false));
    assert_eq!(defaults.promise, Some(false));
    let promise = JsEvalOptions::with_promise();
    assert_eq!(promise.promise, Some(true));
    let module = JsEvalOptions::module();
    assert_eq!(module.global, Some(false));
    assert_eq!(module.promise, Some(true));
    let custom = JsEvalOptions::new(Some(false), Some(false), Some(true), Some(true));
    assert_eq!(custom.global, Some(false));
    assert_eq!(custom.strict, Some(false));
    assert_eq!(custom.backtrace_barrier, Some(true));
    assert_eq!(custom.promise, Some(true));

    assert!(
        builtin_flags(&JsBuiltinOptions::all())
            .into_iter()
            .all(|flag| flag == Some(true))
    );
    assert!(
        builtin_flags(&JsBuiltinOptions::none())
            .into_iter()
            .all(|flag| flag.is_none())
    );
    let essential = JsBuiltinOptions::essential();
    assert_eq!(enabled_builtin_count(&essential), 5);
    assert_eq!(essential.console, Some(true));
    assert_eq!(essential.timers, Some(true));
    assert_eq!(essential.buffer, Some(true));
    assert_eq!(essential.util, Some(true));
    assert_eq!(essential.json, Some(true));
    let web = JsBuiltinOptions::web();
    assert_eq!(enabled_builtin_count(&web), 10);
    assert_eq!(web.fetch, Some(true));
    assert_eq!(web.navigator, Some(true));
    assert_eq!(web.fs, None);
    let node = JsBuiltinOptions::node();
    assert_eq!(enabled_builtin_count(&node), 22);
    assert_eq!(node.process, Some(true));
    assert_eq!(node.fs, Some(true));
    assert_eq!(node.child_process, None);

    let mut nested_object = HashMap::new();
    nested_object.insert("flag".to_string(), JsValue::boolean(true));
    nested_object.insert(
        "items".to_string(),
        JsValue::array(vec![JsValue::integer(1), JsValue::string("two")]),
    );

    let value_cases = vec![
        (JsValue::none(), "null", true),
        (JsValue::boolean(false), "boolean", true),
        (JsValue::integer(i64::from(i32::MAX)), "number", true),
        (JsValue::float(std::f64::consts::PI), "number", true),
        (JsValue::bigint("9007199254740993"), "bigint", true),
        (JsValue::string("surface"), "string", true),
        (JsValue::bytes(vec![0, 1, 2]), "ArrayBuffer", false),
        (
            JsValue::array(vec![JsValue::integer(1), JsValue::boolean(true)]),
            "Array",
            false,
        ),
        (JsValue::object(nested_object), "Object", false),
        (JsValue::date(1_609_459_200_000), "Date", false),
        (JsValue::Symbol("token".to_string()), "symbol", false),
        (JsValue::Function("fnName".to_string()), "function", false),
    ];
    for (value, type_name, primitive) in value_cases {
        assert_eq!(value.type_name(), type_name);
        assert_eq!(value.is_primitive(), primitive);
    }
    assert!(JsValue::none().is_none());
    assert!(JsValue::boolean(true).is_boolean());
    assert!(JsValue::integer(1).is_number());
    assert!(JsValue::float(1.5).is_number());
    assert!(JsValue::bigint("2").is_number());
    assert!(JsValue::string("s").is_string());
    assert!(JsValue::bytes(vec![]).is_bytes());
    assert!(JsValue::array(vec![]).is_array());
    assert!(JsValue::object(HashMap::new()).is_object());
    assert!(JsValue::date(0).is_date());

    let errors = vec![
        (
            JsError::promise("promise failed"),
            "PROMISE_ERROR",
            true,
            "promise failed",
        ),
        (
            JsError::module(
                Some("mod.js".to_string()),
                Some("run".to_string()),
                "module failed",
            ),
            "MODULE_ERROR",
            true,
            "module failed",
        ),
        (
            JsError::context("context failed"),
            "CONTEXT_ERROR",
            false,
            "context failed",
        ),
        (
            JsError::storage("storage failed"),
            "STORAGE_ERROR",
            false,
            "storage failed",
        ),
        (
            JsError::io(Some("/tmp/file.js".to_string()), "missing"),
            "IO_ERROR",
            true,
            "missing",
        ),
        (
            JsError::runtime("runtime failed"),
            "RUNTIME_ERROR",
            true,
            "runtime failed",
        ),
        (
            JsError::generic("generic failed"),
            "GENERIC_ERROR",
            true,
            "generic failed",
        ),
        (
            JsError::engine("engine failed"),
            "ENGINE_ERROR",
            false,
            "engine failed",
        ),
        (
            JsError::bridge("bridge failed"),
            "BRIDGE_ERROR",
            true,
            "bridge failed",
        ),
        (
            JsError::conversion("JsValue", "String", "bad type"),
            "CONVERSION_ERROR",
            true,
            "bad type",
        ),
        (
            JsError::timeout("compile", 50),
            "TIMEOUT_ERROR",
            true,
            "50ms",
        ),
        (
            JsError::memory_limit("out of memory"),
            "MEMORY_LIMIT_ERROR",
            false,
            "out of memory",
        ),
        (
            JsError::StackOverflow("too deep".to_string()),
            "STACK_OVERFLOW_ERROR",
            false,
            "too deep",
        ),
        (
            JsError::syntax(Some(2), Some(10), "unexpected"),
            "SYNTAX_ERROR",
            true,
            "unexpected",
        ),
        (
            JsError::reference("missing name"),
            "REFERENCE_ERROR",
            true,
            "missing name",
        ),
        (
            JsError::type_error("bad call"),
            "TYPE_ERROR",
            true,
            "bad call",
        ),
        (
            JsError::cancelled("closed"),
            "CANCELLED_ERROR",
            false,
            "closed",
        ),
    ];
    for (error, code, recoverable, text) in errors {
        assert_eq!(error.code(), code);
        assert_eq!(error.is_recoverable(), recoverable, "{error:?}");
        assert!(error.to_string().contains(text), "{error:?}");
    }

    let ok = JsResult::ok(JsValue::integer(42));
    assert!(ok.is_ok());
    assert!(!ok.is_err());
    assert_eq!(ok.clone().map(|value| value.type_name()).unwrap(), "number");
    expect_integer(ok.into_result().unwrap(), 42);

    let err = JsResult::err(JsError::runtime("original"));
    assert!(err.is_err());
    assert!(!err.is_ok());
    assert!(err.clone().map(|value| value.type_name()).is_err());
    let remapped = err.map_err(|error| JsError::engine(format!("wrapped: {error}")));
    let remapped_error = remapped.into_result().unwrap_err();
    assert_eq!(remapped_error.code(), "ENGINE_ERROR");
    assert!(remapped_error.to_string().contains("wrapped"));

    let from_ok: JsResult = Ok::<_, JsError>(JsValue::string("converted")).into();
    expect_string(from_ok.into_result().unwrap(), "converted");
    let from_err: Result<JsValue, JsError> = JsResult::err(JsError::bridge("bridge down")).into();
    assert_eq!(from_err.unwrap_err().code(), "BRIDGE_ERROR");
}

#[tokio::test]
async fn sync_runtime_context_and_bytecode_public_apis_work_together() {
    let eval_file = TempJsFile::new("sync-eval.js", b"globalThis.__syncFile = 6 * 7; __syncFile");
    let eval_file_with_options = TempJsFile::new(
        "sync-eval-options.js",
        b"globalThis.__syncFileOptions = 40 + 2; __syncFileOptions",
    );
    let path_module = TempJsFile::new(
        "sync-path-module.js",
        b"export const value = 11; export function plus(v) { return value + v; }",
    );
    let bytecode_source = TempJsFile::new(
        "sync-bytecode-module.js",
        b"export const value = 21; export function double() { return value * 2; }",
    );
    let script_source = TempJsFile::new(
        "sync-bytecode-script.js",
        b"globalThis.__syncScript = 20 + 22; __syncScript",
    );

    let runtime = JsRuntime::create(
        Some(JsBuiltinOptions {
            console: Some(true),
            path: Some(true),
            json: Some(true),
            ..Default::default()
        }),
        Some(vec![
            JsModule::path("sync/path-module.js".to_string(), path_module.path_string()),
            JsModule::bytes(
                "sync/bytes-module.js".to_string(),
                b"export const value = 5;".to_vec(),
            ),
        ]),
    )
    .await
    .unwrap();

    runtime.set_memory_limit(16 * 1024 * 1024);
    runtime.set_max_stack_size(512 * 1024);
    runtime.set_gc_threshold(256 * 1024);
    runtime.set_dump_flags(0);
    runtime
        .set_info("sync-runtime-surface".to_string())
        .unwrap();
    runtime.run_gc();
    assert_memory_usage_is_readable(&runtime.memory_usage());
    assert!(!runtime.is_job_pending());
    assert!(!runtime.execute_pending_job().unwrap());

    let context = JsContext::from(&runtime).unwrap();
    let available = context.get_available_modules().unwrap();
    assert!(available.contains(&"path".to_string()));
    assert!(available.contains(&"sync/path-module.js".to_string()));
    assert!(available.contains(&"sync/bytes-module.js".to_string()));

    expect_integer(
        unwrap_js_result(context.eval("globalThis.__syncBase = 10; __syncBase + 1".to_string())),
        11,
    );
    expect_integer(
        unwrap_js_result(context.eval_with_options(
            "globalThis.__syncOptions = 12; __syncOptions".to_string(),
            JsEvalOptions::new(Some(true), Some(true), Some(false), Some(false)),
        )),
        12,
    );
    expect_integer(
        unwrap_js_result(context.eval_file(eval_file.path_string())),
        42,
    );
    expect_integer(
        unwrap_js_result(context.eval_file_with_options(
            eval_file_with_options.path_string(),
            JsEvalOptions::defaults(),
        )),
        42,
    );
    assert!(
        context
            .eval_with_options("42".to_string(), JsEvalOptions::with_promise())
            .is_err()
    );

    let module_bytecode = JsBytecode::compile_sync(
        JsModule::path(
            "sync/compiled-module.js".to_string(),
            bytecode_source.path_string(),
        ),
        Some(JsModuleBytecodeOptions {
            endianness: Some(JsBytecodeEndianness::Native),
            strip_source: Some(false),
            strip_debug: Some(false),
        }),
    )
    .unwrap();
    JsBytecode::validate_sync(module_bytecode.clone()).unwrap();
    assert_eq!(module_bytecode.name, "sync/compiled-module.js");
    assert!(!module_bytecode.bytes.is_empty());

    let bundle = JsBytecode::compile_module_bundle_sync(
        vec![
            JsModule::code(
                "sync/bundle-dep.js".to_string(),
                "export const value = 14;".to_string(),
            ),
            JsModule::code(
                "sync/bundle-main.js".to_string(),
                "import { value } from './bundle-dep.js'; export default value * 3;".to_string(),
            ),
        ],
        Some("sync/bundle-main.js".to_string()),
        Some(JsModuleBytecodeOptions {
            endianness: Some(JsBytecodeEndianness::Little),
            strip_source: Some(true),
            strip_debug: Some(true),
        }),
    )
    .unwrap();
    JsBytecode::validate_bundle_sync(bundle).unwrap();

    let script = JsBytecode::compile_script_sync(
        "sync/script-bytecode.js".to_string(),
        JsCode::path(script_source.path_string()),
        Some(JsScriptBytecodeOptions {
            endianness: Some(JsBytecodeEndianness::Little),
            strip_source: Some(false),
            strip_debug: Some(false),
            strict: Some(true),
            backtrace_barrier: Some(true),
            promise: Some(false),
        }),
    )
    .unwrap();
    JsBytecode::validate_script_sync(script).unwrap();
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn async_runtime_context_and_bytecode_public_apis_work_together() {
    let async_eval_file = TempJsFile::new(
        "async-eval.js",
        b"await Promise.resolve(); globalThis.__asyncFile = 39 + 3; __asyncFile",
    );
    let async_options_file = TempJsFile::new(
        "async-options.js",
        b"await Promise.resolve(); globalThis.__asyncOptions = 'file-options'; __asyncOptions",
    );

    let runtime = JsAsyncRuntime::create(
        Some(JsBuiltinOptions::essential()),
        Some(vec![JsModule::code(
            "async/math.js".to_string(),
            r#"
            export async function combine(input) {
              const delayed = await Promise.resolve(4);
              return input.base + input.values.reduce((sum, value) => sum + value, 0) + delayed;
            }

            export function noArgs() {
              return 42;
            }
            "#
            .to_string(),
        )]),
    )
    .await
    .unwrap();

    assert!(runtime.driver_running().await);
    runtime.set_memory_limit(16 * 1024 * 1024).await;
    runtime.set_max_stack_size(512 * 1024).await;
    runtime.set_gc_threshold(256 * 1024).await;
    runtime
        .set_info("async-runtime-surface".to_string())
        .await
        .unwrap();
    runtime.run_gc().await;
    assert_memory_usage_is_readable(&runtime.memory_usage().await);

    let context = JsAsyncContext::from(&runtime).await.unwrap();
    let available = context.get_available_modules().await.unwrap();
    assert!(available.contains(&"timers".to_string()));
    assert!(available.contains(&"async/math.js".to_string()));

    expect_integer(
        unwrap_js_result(
            context
                .eval("await Promise.resolve(40 + 2)".to_string())
                .await,
        ),
        42,
    );
    expect_string(
        unwrap_js_result(
            context
                .eval_with_options(
                    "await Promise.resolve('async-options')".to_string(),
                    JsEvalOptions::new(Some(true), Some(true), Some(true), Some(false)),
                )
                .await,
        ),
        "async-options",
    );
    expect_integer(
        unwrap_js_result(context.eval_file(async_eval_file.path_string()).await),
        42,
    );
    expect_string(
        unwrap_js_result(
            context
                .eval_file_with_options(async_options_file.path_string(), JsEvalOptions::defaults())
                .await,
        ),
        "file-options",
    );

    let mut payload = HashMap::new();
    payload.insert("base".to_string(), JsValue::integer(3));
    payload.insert(
        "values".to_string(),
        JsValue::array(vec![JsValue::integer(10), JsValue::integer(20)]),
    );
    expect_integer(
        unwrap_js_result(
            context
                .eval_function(
                    "async/math.js".to_string(),
                    "combine".to_string(),
                    Some(vec![JsValue::object(payload)]),
                )
                .await,
        ),
        37,
    );
    expect_integer(
        unwrap_js_result(
            context
                .eval_function("async/math.js".to_string(), "noArgs".to_string(), None)
                .await,
        ),
        42,
    );

    runtime.stop_driver().await;
    assert!(!runtime.driver_running().await);
    expect_string(
        unwrap_js_result(
            context
                .eval(
                    "Promise.resolve().then(() => { globalThis.__manualAsyncJob = 42; }); 'queued'"
                        .to_string(),
                )
                .await,
        ),
        "queued",
    );
    let _ = runtime.execute_pending_job().await.unwrap();
    runtime.idle().await;
    expect_integer(
        unwrap_js_result(
            context
                .eval("globalThis.__manualAsyncJob".to_string())
                .await,
        ),
        42,
    );
    runtime.start_driver().await;
    assert!(runtime.driver_running().await);

    expect_string(
        unwrap_js_result(
            context
                .eval(
                    "Promise.resolve().then(() => { throw new Error('async detached failure'); }); 'scheduled'"
                        .to_string(),
                )
                .await,
        ),
        "scheduled",
    );
    let errors = wait_for_runtime_error(&runtime, "async detached failure").await;
    assert_eq!(errors.len(), 1);

    let module = JsBytecode::compile(
        JsModule::code(
            "async/bytecode.js".to_string(),
            "export const value = 42;".to_string(),
        ),
        Some(JsModuleBytecodeOptions {
            endianness: Some(JsBytecodeEndianness::Little),
            strip_source: Some(true),
            strip_debug: Some(true),
        }),
    )
    .await
    .unwrap();
    JsBytecode::validate(module).await.unwrap();

    let bundle = JsBytecode::compile_module_bundle(
        vec![
            JsModule::code(
                "async/bundle-dep.js".to_string(),
                "export const value = 21;".to_string(),
            ),
            JsModule::code(
                "async/bundle-main.js".to_string(),
                "import { value } from './bundle-dep.js'; export default value * 2;".to_string(),
            ),
        ],
        Some("async/bundle-main.js".to_string()),
        None,
    )
    .await
    .unwrap();
    JsBytecode::validate_bundle(bundle).await.unwrap();

    let script = JsBytecode::compile_script(
        "async/script-bytecode.js".to_string(),
        JsCode::code("await Promise.resolve(42)".to_string()),
        Some(JsScriptBytecodeOptions {
            promise: Some(true),
            ..Default::default()
        }),
    )
    .await
    .unwrap();
    JsBytecode::validate_script(script).await.unwrap();
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn engine_public_apis_interoperate_across_sources_bytecode_bridge_and_shutdown() {
    let path_eval = TempJsFile::new(
        "engine-eval-path.js",
        b"await Promise.resolve(); globalThis.__enginePathValue = 6 * 7; __enginePathValue",
    );
    let path_module = TempJsFile::new(
        "engine-path-module.js",
        b"export function fromPath(input) { return input.base + 8; }",
    );

    let engine = Arc::new(
        JsEngine::create(
            Some(JsBuiltinOptions::essential()),
            Some(vec![JsModule::code(
                "engine/static.js".to_string(),
                "export const seed = 11; export function amplify(value) { return value * seed; }"
                    .to_string(),
            )]),
            Some(JsEngineRuntimeOptions {
                memory_limit: Some(32 * 1024 * 1024),
                gc_threshold: Some(512 * 1024),
                max_stack_size: Some(512 * 1024),
                info: Some("engine-surface".to_string()),
            }),
        )
        .await
        .unwrap(),
    );

    assert!(!engine.closed());
    assert!(!engine.running());
    assert!(engine.driver_running().await.unwrap());
    assert_memory_usage_is_readable(&engine.memory_usage().await.unwrap());
    engine.set_memory_limit(32 * 1024 * 1024).await.unwrap();
    engine.set_gc_threshold(512 * 1024).await.unwrap();
    engine.set_max_stack_size(512 * 1024).await.unwrap();
    engine
        .set_info("engine-surface-updated".to_string())
        .await
        .unwrap();
    engine.run_gc().await.unwrap();

    let bridge_events = Arc::new(Mutex::new(Vec::<String>::new()));
    let callback_events = bridge_events.clone();
    engine
        .init(move |value| {
            let callback_events = callback_events.clone();
            Box::pin(async move {
                let event = match &value {
                    JsValue::Integer(value) => format!("integer:{value}"),
                    JsValue::String(value) => format!("string:{value}"),
                    JsValue::Object(map) => {
                        let kind = match map.get("kind") {
                            Some(JsValue::String(kind)) => kind.as_str(),
                            _ => "unknown",
                        };
                        format!("object:{kind}")
                    }
                    other => other.type_name(),
                };
                {
                    let mut events = callback_events.lock().unwrap();
                    events.push(event);
                }

                match value {
                    JsValue::Integer(value) => JsResult::ok(JsValue::integer(value * 2)),
                    JsValue::String(value) => {
                        JsResult::ok(JsValue::string(format!("echo:{value}")))
                    }
                    JsValue::Object(map) => match map.get("value") {
                        Some(JsValue::Integer(value)) => {
                            JsResult::ok(JsValue::integer(value + 100))
                        }
                        _ => JsResult::err(JsError::bridge("missing object.value")),
                    },
                    other => JsResult::ok(other),
                }
            })
        })
        .await
        .unwrap();
    assert!(engine.running());

    expect_integer(
        engine
            .eval(
                JsCode::code(
                    r#"
                    const { seed, amplify } = await import('engine/static.js');
                    const bridged = await fjs.bridge_call({ kind: 'calc', value: seed });
                    amplify(2) + bridged
                    "#
                    .to_string(),
                ),
                None,
            )
            .await
            .unwrap(),
        133,
    );
    expect_integer(
        engine
            .eval(
                JsCode::bytes(b"await Promise.resolve(3 + 4)".to_vec()),
                None,
            )
            .await
            .unwrap(),
        7,
    );
    expect_integer(
        engine
            .eval(
                JsCode::path(path_eval.path_string()),
                Some(JsEvalOptions::with_promise()),
            )
            .await
            .unwrap(),
        42,
    );

    engine
        .declare_new_module(JsModule::path(
            "engine/path-module.js".to_string(),
            path_module.path_string(),
        ))
        .await
        .unwrap();
    engine
        .declare_new_modules(vec![
            JsModule::code(
                "engine/live.js".to_string(),
                "export function run(value) { return value + 1; }".to_string(),
            ),
            JsModule::code(
                "engine/pending.js".to_string(),
                "export const pending = true;".to_string(),
            ),
        ])
        .await
        .unwrap();
    assert!(
        engine
            .is_module_declared("engine/pending.js".to_string())
            .await
            .unwrap()
    );
    assert!(
        engine
            .is_module_available("engine/path-module.js".to_string())
            .await
            .unwrap()
    );
    expect_integer(
        engine
            .call(
                "engine/path-module.js".to_string(),
                "fromPath".to_string(),
                Some(vec![JsValue::object(HashMap::from([(
                    "base".to_string(),
                    JsValue::integer(34),
                )]))]),
            )
            .await
            .unwrap(),
        42,
    );
    expect_integer(
        engine
            .call(
                "engine/live.js".to_string(),
                "run".to_string(),
                Some(vec![JsValue::integer(40)]),
            )
            .await
            .unwrap(),
        41,
    );
    engine.clear_pending_modules().await.unwrap();
    assert!(
        engine
            .is_module_declared("engine/live.js".to_string())
            .await
            .unwrap()
    );
    assert!(
        !engine
            .is_module_declared("engine/pending.js".to_string())
            .await
            .unwrap()
    );

    let declared = engine.get_declared_modules().await.unwrap();
    assert!(declared.contains(&"engine/live.js".to_string()));
    let available = engine.get_available_modules().await.unwrap();
    assert!(available.contains(&"engine/static.js".to_string()));
    assert!(available.contains(&"engine/live.js".to_string()));
    assert!(available.contains(&"timers".to_string()));

    let evaluated = engine
        .evaluate_module(JsModule::code(
            "engine/evaluated.js".to_string(),
            "globalThis.__evaluatedModule = 42; export const loaded = true;".to_string(),
        ))
        .await
        .unwrap();
    assert!(evaluated.is_none());
    expect_integer(
        engine
            .eval(
                JsCode::code("globalThis.__evaluatedModule".to_string()),
                None,
            )
            .await
            .unwrap(),
        42,
    );

    let bytecode_call = JsBytecode::compile(
        JsModule::code(
            "engine/bytecode-call.js".to_string(),
            r#"
            export async function combine(payload) {
              const bridge = await fjs.bridge_call(payload.bridge);
              return payload.left + payload.right + bridge;
            }
            "#
            .to_string(),
        ),
        None,
    )
    .await
    .unwrap();
    JsBytecode::validate(bytecode_call.clone()).await.unwrap();
    engine
        .declare_new_bytecode_module(bytecode_call)
        .await
        .unwrap();
    expect_integer(
        engine
            .call(
                "engine/bytecode-call.js".to_string(),
                "combine".to_string(),
                Some(vec![JsValue::object(HashMap::from([
                    ("left".to_string(), JsValue::integer(10)),
                    ("right".to_string(), JsValue::integer(12)),
                    ("bridge".to_string(), JsValue::integer(10)),
                ]))]),
            )
            .await
            .unwrap(),
        42,
    );

    let dep = JsBytecode::compile(
        JsModule::code(
            "engine/bytecode-many-dep.js".to_string(),
            "export const value = 20;".to_string(),
        ),
        None,
    )
    .await
    .unwrap();
    let main = JsBytecode::compile(
        JsModule::code(
            "engine/bytecode-many-main.js".to_string(),
            "import { value } from './bytecode-many-dep.js'; export function total(extra) { return value + extra; }"
                .to_string(),
        ),
        None,
    )
    .await
    .unwrap();
    engine
        .declare_new_bytecode_modules(vec![dep, main])
        .await
        .unwrap();
    expect_integer(
        engine
            .call(
                "engine/bytecode-many-main.js".to_string(),
                "total".to_string(),
                Some(vec![JsValue::integer(22)]),
            )
            .await
            .unwrap(),
        42,
    );

    let declare_bundle = JsBytecode::compile_module_bundle(
        vec![JsModule::code(
            "engine/bytecode-bundle-declared.js".to_string(),
            "export function value() { return 42; }".to_string(),
        )],
        None,
        None,
    )
    .await
    .unwrap();
    JsBytecode::validate_bundle(declare_bundle.clone())
        .await
        .unwrap();
    engine
        .declare_new_bytecode_bundle(declare_bundle)
        .await
        .unwrap();
    expect_integer(
        engine
            .call(
                "engine/bytecode-bundle-declared.js".to_string(),
                "value".to_string(),
                None,
            )
            .await
            .unwrap(),
        42,
    );

    let evaluated_bytecode = JsBytecode::compile(
        JsModule::code(
            "engine/bytecode-evaluated.js".to_string(),
            "globalThis.__bytecodeEvaluated = 42; export const value = 42;".to_string(),
        ),
        None,
    )
    .await
    .unwrap();
    let evaluated_value = engine
        .evaluate_bytecode_module(evaluated_bytecode)
        .await
        .unwrap();
    assert!(evaluated_value.is_none());
    expect_integer(
        engine
            .eval(
                JsCode::code("globalThis.__bytecodeEvaluated".to_string()),
                None,
            )
            .await
            .unwrap(),
        42,
    );

    let evaluated_bundle = JsBytecode::compile_module_bundle(
        vec![
            JsModule::code(
                "engine/bytecode-bundle-dep.js".to_string(),
                "export const value = 21;".to_string(),
            ),
            JsModule::code(
                "engine/bytecode-bundle-main.js".to_string(),
                "import { value } from './bytecode-bundle-dep.js'; export function total() { return value * 2; }"
                    .to_string(),
            ),
        ],
        Some("engine/bytecode-bundle-main.js".to_string()),
        None,
    )
    .await
    .unwrap();
    JsBytecode::validate_bundle(evaluated_bundle.clone())
        .await
        .unwrap();
    let bundle_value = engine
        .evaluate_bytecode_bundle(evaluated_bundle)
        .await
        .unwrap();
    assert!(bundle_value.is_none());
    expect_integer(
        engine
            .call(
                "engine/bytecode-bundle-main.js".to_string(),
                "total".to_string(),
                None,
            )
            .await
            .unwrap(),
        42,
    );

    let script = JsBytecode::compile_script(
        "engine/script-bytecode.js".to_string(),
        JsCode::code(
            "globalThis.__scriptBytecode = await Promise.resolve(42); __scriptBytecode".to_string(),
        ),
        Some(JsScriptBytecodeOptions {
            promise: Some(true),
            ..Default::default()
        }),
    )
    .await
    .unwrap();
    JsBytecode::validate_script(script.clone()).await.unwrap();
    expect_integer(engine.evaluate_script_bytecode(script).await.unwrap(), 42);
    expect_integer(
        engine
            .eval(
                JsCode::code("globalThis.__scriptBytecode".to_string()),
                None,
            )
            .await
            .unwrap(),
        42,
    );

    expect_string(
        engine
            .eval(
                JsCode::code(
                    "Promise.resolve().then(() => { throw new Error('engine detached failure'); }); 'scheduled'"
                        .to_string(),
                ),
                None,
            )
            .await
            .unwrap(),
        "scheduled",
    );
    let errors = wait_for_engine_error(&engine, "engine detached failure").await;
    assert_eq!(errors.len(), 1);
    assert!(engine.drain_unhandled_job_errors().is_empty());

    let graceful_engine = engine.clone();
    let pending = tokio::spawn(async move {
        graceful_engine
            .eval(
                JsCode::code(
                    r#"
                    await new Promise((resolve) => setTimeout(resolve, 50));
                    "gracefully-drained"
                    "#
                    .to_string(),
                ),
                None,
            )
            .await
    });
    tokio::time::sleep(Duration::from_millis(10)).await;
    engine.close_gracefully().await.unwrap();
    expect_string(pending.await.unwrap().unwrap(), "gracefully-drained");
    assert!(engine.closed());
    assert!(!engine.running());
    assert!(!engine.driver_running().await.unwrap());

    let immediate = JsEngine::create(None, None, None).await.unwrap();
    immediate.init_without_bridge().await.unwrap();
    immediate.close().await.unwrap();
    immediate.close().await.unwrap();
    assert!(immediate.closed());
    assert!(immediate.memory_usage().await.is_err());

    let events = bridge_events.lock().unwrap();
    assert!(events.contains(&"object:calc".to_string()), "{events:?}");
    assert!(events.contains(&"integer:10".to_string()), "{events:?}");
}
