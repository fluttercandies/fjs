use crate::api::source::{
    JsModuleBytecode, JsModuleBytecodeBundle, JsModuleBytecodeOptions, JsScriptBytecode,
    JsScriptBytecodeOptions,
};
use anyhow::anyhow;
use rquickjs::loader::{ImportAttributes, Loader, Resolver};
use rquickjs::promise::MaybePromise;
use rquickjs::{CatchResultExt, Ctx, Module, Value, WriteOptions, qjs};
use std::collections::HashMap;
use std::ffi::CString;
use std::sync::Arc;

#[derive(Default)]
struct CompileOnlyResolver;

fn normalize_compile_specifier(base: &str, name: &str) -> String {
    if !name.starts_with('.') {
        return name.to_string();
    }

    let mut segments: Vec<&str> = base
        .split('/')
        .filter(|segment| !segment.is_empty())
        .collect();
    if !segments.is_empty() {
        segments.pop();
    }

    for segment in name.split('/') {
        match segment {
            "" | "." => {}
            ".." => {
                segments.pop();
            }
            value => segments.push(value),
        }
    }

    segments.join("/")
}

impl Resolver for CompileOnlyResolver {
    fn resolve<'js>(
        &mut self,
        _ctx: &Ctx<'js>,
        base: &str,
        name: &str,
        _attributes: Option<ImportAttributes<'js>>,
    ) -> rquickjs::Result<String> {
        Ok(normalize_compile_specifier(base, name))
    }
}

#[derive(Default)]
struct CompileOnlyLoader;

impl Loader for CompileOnlyLoader {
    fn load<'js>(
        &mut self,
        ctx: &Ctx<'js>,
        name: &str,
        _attributes: Option<ImportAttributes<'js>>,
    ) -> rquickjs::Result<Module<'js, rquickjs::module::Declared>> {
        Module::declare(ctx.clone(), name, "export {};")
    }
}

pub(crate) fn validate_module_bytecode_impl(
    module_name: &str,
    bytecode: &[u8],
) -> anyhow::Result<()> {
    let runtime = compile_runtime()?;
    runtime.set_loader(CompileOnlyResolver, CompileOnlyLoader);
    let context = rquickjs::Context::full(&runtime)?;

    context.with(|ctx| {
        let raw_value = read_bytecode_value(&ctx, bytecode)
            .catch(&ctx)
            .map_err(|e| anyhow!("Failed to read bytecode module '{}': {}", module_name, e))?;
        if !raw_value.is_module() {
            return Err(anyhow!(
                "Failed to read bytecode module '{}': bytecode does not contain an ES module",
                module_name
            ));
        }
        drop(raw_value);
        let module = unsafe { Module::load(ctx.clone(), bytecode) }
            .catch(&ctx)
            .map_err(|e| anyhow!("Failed to read bytecode module '{}': {}", module_name, e))?;
        let embedded_name: String = module
            .name()
            .map_err(|e| anyhow!("Failed to inspect bytecode module '{}': {}", module_name, e))?;
        if embedded_name != module_name {
            return Err(anyhow!(
                "Bytecode module name mismatch: expected '{}', found '{}'",
                module_name,
                embedded_name
            ));
        }
        Ok(())
    })
}

pub(crate) fn compile_module_bytecode_impl(
    module_name: &str,
    source_code: Vec<u8>,
    options: JsModuleBytecodeOptions,
) -> anyhow::Result<JsModuleBytecode> {
    let runtime = compile_runtime()?;
    runtime.set_loader(CompileOnlyResolver, CompileOnlyLoader);
    let context = rquickjs::Context::full(&runtime)?;

    context.with(|ctx| {
        let module = Module::declare(ctx.clone(), module_name, source_code)
            .map_err(|e| anyhow!("Failed to compile module '{}': {}", module_name, e))?;
        let bytes = module
            .write(options.into())
            .map_err(|e| anyhow!("Failed to serialize module '{}': {}", module_name, e))?;
        Ok(JsModuleBytecode::new(module_name.to_string(), bytes))
    })
}

pub(crate) fn compile_script_bytecode_impl(
    script_name: &str,
    source_code: Vec<u8>,
    options: JsScriptBytecodeOptions,
) -> anyhow::Result<JsScriptBytecode> {
    let runtime = compile_runtime()?;
    let context = rquickjs::Context::full(&runtime)?;

    context.with(|ctx| {
        let compiled = compile_script_value(&ctx, script_name, source_code, &options)
            .catch(&ctx)
            .map_err(|e| anyhow!("Failed to compile script '{}': {}", script_name, e))?;
        let bytes = write_bytecode_value(&ctx, &compiled, options.into())
            .catch(&ctx)
            .map_err(|e| anyhow!("Failed to serialize script '{}': {}", script_name, e))?;
        Ok(JsScriptBytecode::new(script_name.to_string(), bytes))
    })
}

pub(crate) fn validate_script_bytecode_impl(
    script_name: &str,
    bytecode: &[u8],
) -> anyhow::Result<()> {
    let runtime = compile_runtime()?;
    let context = rquickjs::Context::full(&runtime)?;

    context.with(|ctx| {
        let value = read_bytecode_value(&ctx, bytecode)
            .catch(&ctx)
            .map_err(|e| anyhow!("Failed to read script bytecode '{}': {}", script_name, e))?;
        if value.is_module() {
            return Err(anyhow!(
                "Failed to read script bytecode '{}': bytecode contains an ES module",
                script_name
            ));
        }
        if !is_executable_script_value(&value) {
            return Err(anyhow!(
                "Failed to read script bytecode '{}': bytecode does not contain an executable script",
                script_name
            ));
        }
        Ok(())
    })
}

pub(crate) fn compile_module_bundle_impl(
    entry: Option<String>,
    modules: Vec<(String, Vec<u8>)>,
    options: JsModuleBytecodeOptions,
) -> anyhow::Result<JsModuleBytecodeBundle> {
    if let Some(entry_name) = &entry
        && !modules.iter().any(|(name, _)| name == entry_name)
    {
        return Err(anyhow!(
            "Bundle entry '{}' is not present in the provided modules",
            entry_name
        ));
    }

    let mut unique = HashMap::with_capacity(modules.len());
    for (name, source) in &modules {
        if unique.insert(name.clone(), source.clone()).is_some() {
            return Err(anyhow!("Duplicate bundle module name '{}'", name));
        }
    }

    let runtime = compile_runtime()?;
    let shared_modules = Arc::new(unique);
    runtime.set_loader(
        BundleCompileResolver::new(shared_modules.clone()),
        BundleCompileLoader::new(shared_modules),
    );
    let context = rquickjs::Context::full(&runtime)?;

    context.with(|ctx| {
        let mut compiled = Vec::with_capacity(modules.len());
        for (name, source) in modules {
            let module = Module::declare(ctx.clone(), name.clone(), source)
                .catch(&ctx)
                .map_err(|e| anyhow!("Failed to compile bundle module '{}': {}", name, e))?;
            let bytes = module
                .write(options.clone().into())
                .catch(&ctx)
                .map_err(|e| anyhow!("Failed to serialize bundle module '{}': {}", name, e))?;
            compiled.push(JsModuleBytecode::new(name, bytes));
        }

        compiled.sort_by(|left, right| left.name.cmp(&right.name));
        Ok(JsModuleBytecodeBundle::new(entry, compiled))
    })
}

fn compile_runtime() -> anyhow::Result<rquickjs::Runtime> {
    let runtime = rquickjs::Runtime::new()?;
    runtime.set_max_stack_size(crate::runtime::stack::SYNC_MAX_STACK_SIZE);
    Ok(runtime)
}

pub(crate) fn validate_module_bundle_impl(bundle: &JsModuleBytecodeBundle) -> anyhow::Result<()> {
    if let Some(entry) = &bundle.entry
        && !bundle.modules.iter().any(|module| &module.name == entry)
    {
        return Err(anyhow!(
            "Bundle entry '{}' is not present in the provided bytecode modules",
            entry
        ));
    }

    let mut seen = HashMap::with_capacity(bundle.modules.len());
    for module in &bundle.modules {
        if seen.insert(module.name.clone(), ()).is_some() {
            return Err(anyhow!("Duplicate bundle module name '{}'", module.name));
        }
        validate_module_bytecode_impl(&module.name, &module.bytes)?;
    }

    Ok(())
}

pub(crate) fn load_module_bytecode_checked<'js>(
    ctx: Ctx<'js>,
    module_name: &str,
    bytecode: &[u8],
) -> rquickjs::Result<Module<'js, rquickjs::module::Declared>> {
    let value = read_bytecode_value(&ctx, bytecode)?;
    if !value.is_module() {
        return Err(rquickjs::Error::new_loading_message(
            module_name,
            "bytecode does not contain an ES module",
        ));
    }
    drop(value);
    unsafe { Module::load(ctx, bytecode) }
}

pub(crate) fn eval_script_bytecode<'js>(
    ctx: &Ctx<'js>,
    script_name: &str,
    bytecode: &[u8],
) -> rquickjs::Result<MaybePromise<'js>> {
    let value = read_bytecode_value(ctx, bytecode)?;
    if value.is_module() {
        return Err(rquickjs::Error::new_loading_message(
            script_name,
            "bytecode contains an ES module; use module bytecode APIs instead",
        ));
    }
    if !is_executable_script_value(&value) {
        return Err(rquickjs::Error::new_loading_message(
            script_name,
            "bytecode does not contain an executable script",
        ));
    }

    unsafe {
        qjs::JS_UpdateStackTop(qjs::JS_GetRuntime(ctx.as_raw().as_ptr()));
    }

    let evaluated = unsafe {
        let duplicated = qjs::JS_DupValue(ctx.as_raw().as_ptr(), value.as_raw());
        qjs::JS_EvalFunction(ctx.as_raw().as_ptr(), duplicated)
    };
    drop(value);

    if unsafe { qjs::JS_VALUE_GET_NORM_TAG(evaluated) } == qjs::JS_TAG_EXCEPTION {
        return Err(rquickjs::Error::Exception);
    }

    let evaluated = unsafe { Value::from_raw(ctx.clone(), evaluated) };
    Ok(MaybePromise::from_value(evaluated))
}

fn compile_script_value<'js>(
    ctx: &Ctx<'js>,
    script_name: &str,
    source_code: Vec<u8>,
    options: &JsScriptBytecodeOptions,
) -> rquickjs::Result<Value<'js>> {
    let file_name = CString::new(script_name)?;
    let mut flag = qjs::JS_EVAL_TYPE_GLOBAL;

    if options.strict.unwrap_or(true) {
        flag |= qjs::JS_EVAL_FLAG_STRICT;
    }
    if options.backtrace_barrier.unwrap_or(false) {
        flag |= qjs::JS_EVAL_FLAG_BACKTRACE_BARRIER;
    }
    if options.promise.unwrap_or(false) {
        flag |= qjs::JS_EVAL_FLAG_ASYNC;
    }
    flag |= qjs::JS_EVAL_FLAG_COMPILE_ONLY;

    unsafe {
        qjs::JS_UpdateStackTop(qjs::JS_GetRuntime(ctx.as_raw().as_ptr()));
    }

    let raw = unsafe {
        qjs::JS_Eval(
            ctx.as_raw().as_ptr(),
            source_code.as_ptr().cast(),
            source_code.len() as _,
            file_name.as_ptr(),
            flag as i32,
        )
    };

    if unsafe { qjs::JS_VALUE_GET_NORM_TAG(raw) } == qjs::JS_TAG_EXCEPTION {
        return Err(rquickjs::Error::Exception);
    }

    Ok(unsafe { Value::from_raw(ctx.clone(), raw) })
}

fn is_executable_script_value(value: &Value<'_>) -> bool {
    value.is_function()
        || unsafe { qjs::JS_VALUE_GET_NORM_TAG(value.as_raw()) } == qjs::JS_TAG_FUNCTION_BYTECODE
}

fn read_bytecode_value<'js>(ctx: &Ctx<'js>, bytecode: &[u8]) -> rquickjs::Result<Value<'js>> {
    let raw = unsafe {
        qjs::JS_ReadObject(
            ctx.as_raw().as_ptr(),
            bytecode.as_ptr(),
            bytecode.len() as _,
            (qjs::JS_READ_OBJ_BYTECODE | qjs::JS_READ_OBJ_ROM_DATA) as i32,
        )
    };

    if unsafe { qjs::JS_VALUE_GET_NORM_TAG(raw) } == qjs::JS_TAG_EXCEPTION {
        return Err(rquickjs::Error::Exception);
    }

    Ok(unsafe { Value::from_raw(ctx.clone(), raw) })
}

fn write_bytecode_value<'js>(
    ctx: &Ctx<'js>,
    value: &Value<'js>,
    options: WriteOptions,
) -> rquickjs::Result<Vec<u8>> {
    let mut len = std::mem::MaybeUninit::uninit();
    let buf = unsafe {
        qjs::JS_WriteObject(
            ctx.as_raw().as_ptr(),
            len.as_mut_ptr(),
            value.as_raw(),
            options.to_flag(),
        )
    };

    if buf.is_null() {
        return Err(rquickjs::Error::Exception);
    }

    let len = unsafe { len.assume_init() };
    let bytes = unsafe { std::slice::from_raw_parts(buf, len as _) }.to_vec();
    unsafe { qjs::js_free(ctx.as_raw().as_ptr(), buf as _) };
    Ok(bytes)
}

#[derive(Debug, Clone)]
struct BundleCompileResolver {
    modules: Arc<HashMap<String, Vec<u8>>>,
}

impl BundleCompileResolver {
    fn new(modules: Arc<HashMap<String, Vec<u8>>>) -> Self {
        Self { modules }
    }
}

impl Resolver for BundleCompileResolver {
    fn resolve<'js>(
        &mut self,
        _ctx: &Ctx<'js>,
        base: &str,
        name: &str,
        _attributes: Option<ImportAttributes<'js>>,
    ) -> rquickjs::Result<String> {
        if self.modules.contains_key(name) {
            return Ok(name.to_string());
        }

        if name.starts_with('.') {
            let normalized = normalize_compile_specifier(base, name);
            if self.modules.contains_key(&normalized) {
                return Ok(normalized);
            }
            return Err(rquickjs::Error::new_resolving_message(
                base,
                name,
                "relative bundle dependency not found",
            ));
        }

        Ok(name.to_string())
    }
}

#[derive(Debug, Clone)]
struct BundleCompileLoader {
    modules: Arc<HashMap<String, Vec<u8>>>,
}

impl BundleCompileLoader {
    fn new(modules: Arc<HashMap<String, Vec<u8>>>) -> Self {
        Self { modules }
    }
}

impl Loader for BundleCompileLoader {
    fn load<'js>(
        &mut self,
        ctx: &Ctx<'js>,
        name: &str,
        _attributes: Option<ImportAttributes<'js>>,
    ) -> rquickjs::Result<Module<'js, rquickjs::module::Declared>> {
        if let Some(source) = self.modules.get(name) {
            return Module::declare(ctx.clone(), name, source.clone());
        }

        Module::declare(ctx.clone(), name, "export {};")
    }
}
