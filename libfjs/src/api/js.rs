use crate::api::value::JsValue;
use crate::js::setup_basics;
use anyhow::anyhow;
use flutter_rust_bridge::frb;
use rquickjs::loader::{
    BuiltinLoader, BuiltinResolver, FileResolver, ModuleLoader, NativeLoader, ScriptLoader,
};
pub use rquickjs::runtime::MemoryUsage;
use rquickjs::{async_with, CatchResultExt, FromJs, Promise};
use tokio::io::AsyncReadExt;

#[frb(opaque)]
pub struct AsyncRuntime(rquickjs::AsyncRuntime);

impl AsyncRuntime {
    #[frb(sync)]
    pub fn new() -> anyhow::Result<Self> {
        let runtime = rquickjs::AsyncRuntime::new()?;
        Ok(Self(runtime))
    }

    pub async fn set_modules(&self, modules: Vec<JsModule>) -> anyhow::Result<()> {
        let mut builtin_resolver = BuiltinResolver::default();
        let mut builtin_loader = BuiltinLoader::default();
        for module in modules {
            match module {
                JsModule::Code(module, code) => {
                    builtin_resolver = builtin_resolver.with_module(&module);
                    builtin_loader = builtin_loader.with_module(&module, code);
                }
                JsModule::Path(module, path) => {
                    let mut f = tokio::fs::File::open(&path).await?;
                    let mut codes = String::new();
                    f.read_to_string(&mut codes).await?;
                    builtin_resolver = builtin_resolver.with_module(&module);
                    builtin_loader = builtin_loader.with_module(&module, codes);
                }
            }
        }
        let resolver = (builtin_resolver, FileResolver::default());
        let loader = (
            builtin_loader,
            ModuleLoader::default(),
            NativeLoader::default(),
            ScriptLoader::default(),
        );
        self.0.set_loader(resolver, loader).await;
        Ok(())
    }

    pub async fn set_memory_limit(&self, limit: usize) {
        self.0.set_memory_limit(limit).await;
    }

    pub async fn set_max_stack_size(&self, limit: usize) {
        self.0.set_max_stack_size(limit).await;
    }

    pub async fn set_gc_threshold(&self, threshold: usize) {
        self.0.set_gc_threshold(threshold).await;
    }

    pub async fn run_gc(&self) {
        self.0.run_gc().await;
    }

    pub async fn memory_usage(&self) -> MemoryUsage {
        self.0.memory_usage().await
    }

    pub async fn is_job_pending(&self) -> bool {
        self.0.is_job_pending().await
    }

    pub async fn execute_pending_job(&self) -> anyhow::Result<bool> {
        self.0.execute_pending_job().await.map_err(|e| anyhow!(e))
    }

    pub async fn idle(&self) {
        self.0.idle().await;
    }
}

#[frb(opaque)]
pub struct AsyncContext(rquickjs::AsyncContext);

impl AsyncContext {
    pub async fn full(rt: &AsyncRuntime) -> anyhow::Result<Self> {
        let context = rquickjs::AsyncContext::full(&rt.0).await?;
        Ok(Self(context))
    }

    pub async fn eval(&self, code: String) -> EvalResult {
        self.eval_with_options(code, EvalOptions::new()).await
    }

    pub async fn eval_with_options(&self, code: String, options: EvalOptions) -> EvalResult {
        async_with!(self.0 => |ctx| {
            if let Err(e) = setup_basics(&ctx){
                return EvalResult::Err(e.to_string());
            }
            let res = ctx.eval_with_options(code, options.into());
            EvalResult::from_promise_result(&ctx, res).await
        })
        .await
    }

    pub async fn eval_file(&self, path: String) -> EvalResult {
        self.eval_file_with_options(path, EvalOptions::new()).await
    }

    pub async fn eval_file_with_options(&self, path: String, options: EvalOptions) -> EvalResult {
        async_with!(self.0 => |ctx| {
            if let Err(e) = setup_basics(&ctx){
                return EvalResult::Err(e.to_string());
            }
            let res = ctx.eval_file_with_options(path, options.into());
            EvalResult::from_promise_result(&ctx, res).await
        })
        .await
    }

    pub async fn eval_function(
        &self,
        module: String,
        method: String,
        params: Option<Vec<JsValue>>,
    ) -> EvalResult {
        let params = params.unwrap_or_default();
        async_with!(self.0 => |ctx| {
            if let Err(e) = setup_basics(&ctx){
                return EvalResult::Err(e.to_string());
            }
            let v = rquickjs::Module::import(&ctx, module.clone());
            if v.is_err() {
                return EvalResult::Err(v.unwrap_err().to_string());
            }
            match v.catch(&ctx) {
                Ok(promise) => {
                    match promise.into_future::<rquickjs::Value>().await {
                        Ok(v) => {
                            if !v.is_object() {
                                return EvalResult::Err(format!("Is the module({}) registered correctly?", &module));
                            }
                            let obj = v.as_object().unwrap();
                            let m: rquickjs::Result<rquickjs::Value> = obj.get(&method);
                            match m {
                                Ok(m) => {
                                    return if m.is_function() {
                                        let func = m.as_function().unwrap();
                                        let res = func.call((rquickjs::function::Rest(params),));
                                        EvalResult::from_promise_result(&ctx, res).await
                                    } else {
                                        EvalResult::Err(format!("Method `{}` not found in the module({}).", &method, &module))
                                    }
                                }
                                Err(e) => {
                                    EvalResult::Err(e.to_string())
                                }
                            }
                        }
                        Err(e) => {
                            EvalResult::Err(e.to_string())
                        }
                    }
                }
                Err(e) =>  EvalResult::Err(e.to_string())
            }
        })
            .await
    }
}

#[derive(Debug)]
#[frb(dart_metadata = ("freezed", "immutable"), dart_code = "
  bool get isOk => this is EvalResult_Ok;
  bool get isErr => this is EvalResult_Err;
  JsValue get ok => (this as EvalResult_Ok).field0;
  String get err => (this as EvalResult_Err).field0;
")]
pub enum EvalResult {
    Ok(JsValue),
    Err(String),
}

impl EvalResult {
    async fn from_promise_result<'js>(
        ctx: &rquickjs::Ctx<'js>,
        res: rquickjs::Result<Promise<'js>>,
    ) -> Self {
        if res.is_err() {
            return EvalResult::Err(res.unwrap_err().to_string());
        }
        match res.catch(ctx) {
            Ok(promise) => match promise.into_future::<rquickjs::Value>().await {
                Ok(v) => match JsValue::from_js(ctx, v) {
                    Ok(v) => EvalResult::Ok(v),
                    Err(e) => EvalResult::Err(e.to_string()),
                },
                Err(e) => EvalResult::Err(e.to_string()),
            },
            Err(e) => EvalResult::Err(e.to_string()),
        }
    }
}

#[frb(dart_metadata = ("freezed", "immutable"))]
pub struct EvalOptions {
    /// Global code.
    pub global: bool,
    /// Force 'strict' mode.
    pub strict: bool,
    /// Don't include the stack frames before this eval in the Error() backtraces.
    pub backtrace_barrier: bool,
}

impl EvalOptions {
    #[frb(sync)]
    pub fn new() -> Self {
        EvalOptions {
            global: true,
            strict: true,
            backtrace_barrier: false,
        }
    }
    fn into(self) -> rquickjs::context::EvalOptions {
        let mut opts = rquickjs::context::EvalOptions::default();
        opts.global = self.global;
        opts.strict = self.strict;
        opts.backtrace_barrier = self.backtrace_barrier;
        opts.promise = true;
        opts
    }
}

#[frb(dart_metadata = ("freezed", "immutable"))]
#[derive(Debug, Clone, Hash, Eq, PartialEq, Ord, PartialOrd)]
pub enum JsModule {
    Code(String, String),
    Path(String, String),
}

impl JsModule {
    #[frb(sync)]
    pub fn new(module: String, code: Option<String>, path: Option<String>) -> anyhow::Result<Self> {
        match (code, path) {
            (Some(code), None) => Ok(Self::Code(module, code)),
            (None, Some(path)) => Ok(Self::Path(module, path)),
            _ => Err(anyhow!(
                "Module({}) must have either a path or code",
                module
            )),
        }
    }
    #[frb(sync)]
    pub fn from_code(module: String, code: String) -> Self {
        Self::Code(module, code)
    }
    #[frb(sync)]
    pub fn from_path(module: String, path: String) -> Self {
        Self::Path(module, path)
    }
}


#[cfg(test)]
mod test {
    use crate::api::js::{AsyncContext, AsyncRuntime, JsModule};
    use crate::api::value::{JsValue, KeyValue};


    #[tokio::test]
    async fn test() {
        env_logger::builder()
            .filter_level(log::LevelFilter::Trace)
            .init();
        let rt = AsyncRuntime::new().unwrap();
        let ctx = AsyncContext::full(&rt).await.unwrap();
        rt.set_modules(vec![JsModule::Code("test".to_string(),  // language=javascript
                r#"
            export async function test(){
                console.log(arguments);
                console.debug(arguments);
                console.warn(arguments);
                console.error(arguments);
                console.log(JSON.stringify(arguments));
                console.log(await fetch('https://www.google.com/').then((res) => res.text()));
                // console.log(await fetch('https://www.baidu.com/').then((res) => res.text()));
                console.log(await fetch('https://httpbin.org/get').then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/get').then((res) => res.text()));
                console.log(await fetch('https://httpbin.org/get').then((res) => res.arrayBuffer()).then((a) => a.byteLength));
                console.log(await fetch('https://httpbin.org/post', { method: 'POST'}).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/put', { method: 'PUT'}).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/patch', { method: 'PATCH'}).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/delete', { method: 'DELETE'}).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/post', { method: 'POST', headers: { "content-TYPE": "application/x-www-form-urlencoded" }, body: { hello: "world" } }).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/post', { method: 'POST', headers: { "content-TYPE": "application/x-www-form-urlencoded" }, body: "hello=world" }).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/post', { method: 'POST', body: { hello: "world" } }).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/post', { method: 'POST', body: ["hello", "world"] }).then((res) => res.json()));
                console.log(await fetch('https://httpbin.org/post', { method: 'POST', body: JSON.stringify({ hello: "world" }) }).then((res) => res.json()));
                return arguments;
            }
            "#.to_string(),)]).await.unwrap();
        let r = ctx.eval_function("test".to_string(), "test".to_string(), Some(vec![
            JsValue::Array(vec![
                JsValue::String("hello".to_string()),
                JsValue::String("world".to_string()),
            ])
        ])).await;
        println!("{:?}", r);
    }
    // #[tokio::test]
    // async fn test2() {
    //     let engine = JsEngine::new(Some(vec![JsModule {
    //         name: "test".to_string(),
    //         code: Some("export async function test(){ return arguments; }".to_string()),
    //         path: None,
    //     }]))
    //         .await
    //         .unwrap();
    //     // engine.register_runtime_module(JsModule {
    //     //     name: "test".to_string(),
    //     //     code: Some("export async function test(){ return [2]; }".to_string()),
    //     //     path: None,
    //     // });
    //     let v = engine
    //         .call_method("test".to_string(), "test".to_string(), None)
    //         .await;
    //     println!("{:?}", v);
    // }
    // #[tokio::test]
    // async fn test3() {
    //     setup().await.unwrap();
    //     let engine = JsEngine::new(Some(vec![JsModule {
    //         name: "test".to_string(),
    //         code: Some("export async function test(){ return arguments; }".to_string()),
    //         path: None,
    //     }]))
    //         .await
    //         .unwrap();
    //     // engine.register_runtime_module(JsModule {
    //     //     name: "test".to_string(),
    //     //     code: Some("export async function test(){ return [2]; }".to_string()),
    //     //     path: None,
    //     // });
    //     let v = engine
    //         .call_method("test".to_string(), "test".to_string(), None)
    //         .await;
    //     println!("{:?}", v);
    //     // engine.remove_runtime_module("test".to_string());
    //     let v = engine
    //         .call_method("test".to_string(), "test".to_string(), None)
    //         .await;
    //     println!("{:?}", v);
    // }
    // #[tokio::test]
    // async fn test4() {
    //     let engine = JsEngine::new(Some(vec![JsModule {
    //         name: "test".to_string(),
    //         code: Some("export async function test(){ return 1; }".to_string()),
    //         path: None,
    //     }]))
    //         .await
    //         .unwrap();
    //     let r = engine
    //         .call_method("test".to_string(), "test".to_string(), None)
    //         .await;
    //     println!("{:?}", r);
    //     let r = engine.eval("(()=>{console.log(1);return Promise.resolve(1);})()".to_string()).await;
    //     println!("{:?}", r);
    //     let r = engine.eval("1+1".to_string()).await;
    //     println!("{:?}", r);
    // }
}