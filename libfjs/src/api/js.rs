use crate::api::value::JsValue;
use anyhow::anyhow;
use flutter_rust_bridge::{frb, DartFnFuture};
use rquickjs::function::Args;
use rquickjs::loader::{
    BuiltinLoader, BuiltinResolver, FileResolver, ModuleLoader, NativeLoader, ScriptLoader,
};
use rquickjs::{async_with, CatchResultExt, FromJs, Module, Object, Promise};
use std::sync::atomic::AtomicBool;
use std::sync::Arc;
use tokio::io::AsyncReadExt;
use tokio::sync::Mutex;

#[frb(opaque)]
#[derive(Clone)]
pub struct MemoryUsage(rquickjs::qjs::JSMemoryUsage);

macro_rules! proxy_memory_usage_getter {
    ($($name:ident),+) => {
        impl MemoryUsage {
            $(
                #[frb(sync, getter)]
                pub fn $name(&self) -> i64 { self.0.$name }
            )+
        }
    };
}

proxy_memory_usage_getter!(
    malloc_size,
    malloc_limit,
    memory_used_size,
    malloc_count,
    memory_used_count,
    atom_count,
    atom_size,
    str_count,
    str_size,
    obj_count,
    obj_size,
    prop_count,
    prop_size,
    shape_count,
    shape_size,
    js_func_count,
    js_func_size,
    js_func_code_size,
    js_func_pc2line_count,
    js_func_pc2line_size,
    c_func_count,
    array_count,
    fast_array_count,
    fast_array_elements,
    binary_object_count,
    binary_object_size
);

#[frb(opaque)]
#[derive(Clone)]
pub struct JsRuntime(rquickjs::Runtime);

impl JsRuntime {
    #[frb(sync)]
    pub fn new() -> anyhow::Result<Self> {
        let runtime = rquickjs::Runtime::new()?;
        Ok(Self(runtime))
    }

    #[frb(sync)]
    pub fn set_memory_limit(&self, limit: usize) {
        self.0.set_memory_limit(limit);
    }
    #[frb(sync)]
    pub fn set_max_stack_size(&self, limit: usize) {
        self.0.set_max_stack_size(limit);
    }
    #[frb(sync)]
    pub fn set_gc_threshold(&self, threshold: usize) {
        self.0.set_gc_threshold(threshold);
    }
    #[frb(sync)]
    pub fn run_gc(&self) {
        self.0.run_gc();
    }
    #[frb(sync)]
    pub fn memory_usage(&self) -> MemoryUsage {
        let usage = self.0.memory_usage();
        MemoryUsage(usage)
    }
    #[frb(sync)]
    pub fn is_job_pending(&self) -> bool {
        self.0.is_job_pending()
    }
    #[frb(sync)]
    pub fn execute_pending_job(&self) -> anyhow::Result<bool> {
        self.0.execute_pending_job().map_err(|e| anyhow!(e))
    }
    #[frb(sync)]
    pub fn set_dump_flags(&self, flags: u64) {
        self.0.set_dump_flags(flags);
    }
    #[frb(sync)]
    pub fn set_info(&self, info: String) -> anyhow::Result<()> {
        self.0.set_info(info)?;
        Ok(())
    }
}

#[frb(opaque)]
#[derive(Clone)]
pub struct JsAsyncRuntime(rquickjs::AsyncRuntime);

impl JsAsyncRuntime {
    #[frb(sync)]
    pub fn new() -> anyhow::Result<Self> {
        let runtime = rquickjs::AsyncRuntime::new()?;
        Ok(Self(runtime))
    }

    pub async fn set_modules(&self, modules: Vec<JsModule>) -> anyhow::Result<()> {
        let mut builtin_resolver = BuiltinResolver::default();
        let mut builtin_loader = BuiltinLoader::default();
        for module in modules {
            let code = get_raw_source_code(module.source).await?;
            builtin_resolver = builtin_resolver.with_module(&module.name);
            builtin_loader = builtin_loader.with_module(&module.name, code);
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
        let usage = self.0.memory_usage().await;
        MemoryUsage(usage)
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

    pub async fn set_info(&self, info: String) -> anyhow::Result<()> {
        self.0.set_info(info).await?;
        Ok(())
    }
}

#[frb(opaque)]
#[derive(Clone)]
pub struct JsContext(rquickjs::Context);

impl JsContext {
    #[frb(sync)]
    pub fn new(rt: &JsRuntime) -> anyhow::Result<Self> {
        let context = rquickjs::Context::full(&rt.0)?;
        Ok(Self(context))
    }
    #[frb(sync)]
    pub fn eval(&self, code: String) -> JsResult {
        self.eval_with_options(code, JsEvalOptions::default())
    }
    #[frb(sync)]
    pub fn eval_with_options(&self, code: String, options: JsEvalOptions) -> JsResult {
        if options.promise.unwrap_or(false) {
            return JsResult::Err("Promise not supported in sync context".to_string());
        }
        self.0.with(|ctx| {
            if let Some(builtin_options) = &options.builtin_options {
                if let Err(e) = builtin_options.init(&ctx) {
                    return JsResult::Err(e.to_string());
                }
                if builtin_options.string_decoder.unwrap_or_default() {
                    return JsResult::Err(
                        "String decoder is not supported in sync context".to_string(),
                    );
                }
            }
            let res = ctx.eval_with_options(code, options.into());
            JsResult::from_result(&ctx, res)
        })
    }
    #[frb(sync)]
    pub fn eval_file(&self, path: String) -> JsResult {
        self.eval_file_with_options(path, JsEvalOptions::default())
    }

    #[frb(sync)]
    pub fn eval_file_with_options(&self, path: String, options: JsEvalOptions) -> JsResult {
        if options.promise.unwrap_or(false) {
            return JsResult::Err("Promise not supported in sync context".to_string());
        }
        self.0.with(|ctx| {
            if let Some(builtin_options) = &options.builtin_options {
                if let Err(e) = builtin_options.init(&ctx) {
                    return JsResult::Err(e.to_string());
                }
                if builtin_options.string_decoder.unwrap_or_default() {
                    return JsResult::Err(
                        "String decoder is not supported in sync context".to_string(),
                    );
                }
            }
            let res = ctx.eval_file_with_options(path, options.into());
            JsResult::from_result(&ctx, res)
        })
    }
}

#[frb(opaque)]
#[derive(Clone)]
pub struct JsAsyncContext(rquickjs::AsyncContext);

impl JsAsyncContext {
    pub async fn from(rt: &JsAsyncRuntime) -> anyhow::Result<Self> {
        let context = rquickjs::AsyncContext::full(&rt.0).await?;
        Ok(Self(context))
    }

    pub async fn eval(&self, code: String) -> JsResult {
        self.eval_with_options(code, JsEvalOptions::default()).await
    }

    pub async fn eval_with_options(&self, code: String, options: JsEvalOptions) -> JsResult {
        async_with!(self.0 => |ctx| {
            let mut options = options;
            options.promise = Some(true);
            let res = ctx.eval_with_options(code, options.into());
            JsResult::from_promise_result(&ctx, res).await
        })
        .await
    }

    pub async fn eval_file(&self, path: String) -> JsResult {
        self.eval_file_with_options(path, JsEvalOptions::default())
            .await
    }

    pub async fn eval_file_with_options(&self, path: String, options: JsEvalOptions) -> JsResult {
        async_with!(self.0 => |ctx| {
            let mut options = options;
            options.promise = Some(true);
            if let Some(builtin_options) = &options.builtin_options {
                if let Err(e) = builtin_options.init(&ctx) {
                    return JsResult::Err(e.to_string());
                }
                if let Err(e) = builtin_options.init_async(ctx.clone()).await {
                    return JsResult::Err(e.to_string());
                }
            }
            let res = ctx.eval_file_with_options(path, options.into());
            JsResult::from_promise_result(&ctx, res).await
        })
        .await
    }

    pub async fn eval_function(
        &self,
        module: String,
        method: String,
        params: Option<Vec<JsValue>>,
    ) -> JsResult {
        let params = params.unwrap_or_default();
        async_with!(self.0 => |ctx| {
            match Module::import(&ctx, module.clone()).catch(&ctx) {
                Ok(promise) => {
                    match promise.into_future::<rquickjs::Value>().await.catch(&ctx) {
                        Ok(v) => {
                            if !v.is_object() {
                                return JsResult::Err(format!("Is the module({}) registered correctly?", &module));
                            }
                            let obj = v.as_object().unwrap();
                            let m: rquickjs::Result<rquickjs::Value> = obj.get(&method);
                            match m.catch(&ctx) {
                                Ok(m) => {
                                    return if m.is_function() {
                                        let func = m.as_function().unwrap();
                                        let res = func.call((rquickjs::function::Rest(params),));
                                        JsResult::from_promise_result(&ctx, res).await
                                    } else {
                                        JsResult::Err(format!("Method `{}` not found in the module({}).", &method, &module))
                                    }
                                }
                                Err(e) => {
                                    JsResult::Err(e.to_string())
                                }
                            }
                        }
                        Err(e) => {
                            JsResult::Err(e.to_string())
                        }
                    }
                }
                Err(e) =>  JsResult::Err(e.to_string())
            }
        })
            .await
    }
}

#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub enum JsAction {
    Eval {
        id: u32,
        source: JsCode,
        options: Option<JsEvalOptions>,
    },
    DeclareModule {
        id: u32,
        module: JsModule,
    },
    EvaluateModule {
        id: u32,
        module: JsModule,
    },
    ImportModule {
        id: u32,
        specifier: String,
    },
    EnableBuiltinModule {
        id: u32,
        builtin_options: JsBuiltinOptions,
    },
}

#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub struct JsActionResult {
    pub id: u32,
    pub result: JsResult,
}

#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub enum JsCallback {
    Initialized,
    Handler(JsActionResult),
    Bridge(JsValue),
}

#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub enum JsCallbackResult {
    Initialized,
    Handler,
    Bridge(JsResult),
}

#[frb(opaque)]
pub struct JsEngineCore {
    context: JsAsyncContext,
    sender: Arc<Mutex<tokio::sync::mpsc::UnboundedSender<JsAction>>>,
    receiver: Arc<Mutex<tokio::sync::mpsc::UnboundedReceiver<JsAction>>>,
    disposed: AtomicBool,
    running: AtomicBool,
}

impl JsEngineCore {
    #[frb(sync)]
    pub fn new(context: &JsAsyncContext) -> anyhow::Result<Self> {
        let (sender, receiver) = tokio::sync::mpsc::unbounded_channel();
        Ok(Self {
            context: context.clone(),
            sender: Arc::new(Mutex::new(sender)),
            receiver: Arc::new(Mutex::new(receiver)),
            disposed: AtomicBool::new(false),
            running: AtomicBool::new(false),
        })
    }

    #[frb(sync, getter)]
    pub fn context(&self) -> JsAsyncContext {
        self.context.clone()
    }

    #[frb(sync, getter)]
    pub fn disposed(&self) -> bool {
        self.disposed.load(std::sync::atomic::Ordering::SeqCst)
    }

    #[frb(sync, getter)]
    pub fn running(&self) -> bool {
        self.running.load(std::sync::atomic::Ordering::SeqCst)
    }

    pub async fn dispose(&self) -> anyhow::Result<()> {
        if self.disposed.load(std::sync::atomic::Ordering::SeqCst) {
            return Err(anyhow!("Engine is disposed"));
        }
        if !self.sender.lock().await.is_closed() {
            drop(self.sender.lock().await);
            self.sender.lock().await.closed().await;
        }
        self.disposed
            .store(true, std::sync::atomic::Ordering::SeqCst);
        Ok(())
    }

    pub async fn exec(&self, action: JsAction) -> anyhow::Result<()> {
        if self.disposed.load(std::sync::atomic::Ordering::SeqCst) {
            return Err(anyhow!("Engine is disposed"));
        }
        let sender = self.sender.lock().await;
        sender.send(action).map_err(|e| anyhow!(e))?;
        Ok(())
    }

    pub async fn start(
        &self,
        bridge: impl Fn(JsCallback) -> DartFnFuture<JsCallbackResult> + Sync + Send + 'static,
    ) -> anyhow::Result<()> {
        if self.disposed.load(std::sync::atomic::Ordering::SeqCst) {
            return Err(anyhow!("Engine is disposed"));
        }
        if self.running.load(std::sync::atomic::Ordering::SeqCst) {
            return Err(anyhow!("Engine is already running"));
        }
        self.running
            .store(true, std::sync::atomic::Ordering::SeqCst);

        let cb = Arc::new(bridge);

        async_with!(self.context.0 => |ctx| {
            if let Err(e) = register_fjs(ctx.clone(),cb.clone()) {
                return Err(anyhow!(e.to_string()));
            }
            cb(JsCallback::Initialized).await;
            loop {
                let mut receiver = self.receiver.lock().await;
                match receiver.recv().await {
                    None => {
                        return Ok(());
                    },
                    Some(ev) => {
                        let ctx_s = ctx.clone();
                        let cb = cb.clone();
                        ctx.spawn(async move {
                            match ev {
                              JsAction::Eval {
                                id,
                                source,
                                options,
                              } => {
                                let mut options = options.unwrap_or_default();
                                options.promise = Some(true);
                                if let Some(builtin_options) = &options.builtin_options {
                                    if let Err(e) = builtin_options.init(&ctx_s){
                                        let res = JsActionResult {id, result: JsResult::Err(e.to_string())};
                                        cb(JsCallback::Handler(res)).await;
                                        return;
                                    }
                                    if let Err(e) = builtin_options.init_async(ctx_s.clone()).await {
                                        let res = JsActionResult {id, result: JsResult::Err(e.to_string())};
                                        cb(JsCallback::Handler(res)).await;
                                        return;
                                    }
                                }
                                let res =  match get_raw_source_code(source).await {
                                  Err(e) => {
                                    JsResult::Err(e.to_string())
                                  }
                                  Ok(source) => {
                                    let res = ctx_s.eval_with_options(source, options.into());
                                    JsResult::from_promise_result(&ctx_s, res).await
                                  }
                                };
                                let res = JsActionResult {id, result: res};
                                cb(JsCallback::Handler(res)).await;
                              }
                              JsAction::EnableBuiltinModule {
                                id,
                                builtin_options,
                              } => {
                                    if let Err(e) = builtin_options.init(&ctx_s){
                                        let res = JsActionResult {id, result: JsResult::Err(e.to_string())};
                                        cb(JsCallback::Handler(res)).await;
                                        return;
                                    }
                                    if let Err(e) = builtin_options.init_async(ctx_s.clone()).await {
                                        let res = JsActionResult {id, result: JsResult::Err(e.to_string())};
                                        cb(JsCallback::Handler(res)).await;
                                        return;
                                    }
                                    let res = JsActionResult {id, result: JsResult::Ok(JsValue::None)};
                                    cb(JsCallback::Handler(res)).await;
                              }
                              JsAction::DeclareModule {
                                id,
                                module: JsModule { name, source },
                              } => {
                                let res = match get_raw_source_code(source).await {
                                  Err(e) => {
                                    JsResult::Err(e.to_string())
                                  }
                                  Ok(source) => {
                                    let res = Module::declare(ctx_s.clone(), name, source).catch(&ctx_s);
                                    match res {
                                      Ok(_) => JsResult::Ok(JsValue::None),
                                      Err(e) => JsResult::Err(e.to_string()),
                                    }
                                  }
                                };
                                let res = JsActionResult {id, result: res};
                                cb(JsCallback::Handler(res)).await;
                              }
                              JsAction::EvaluateModule {
                                id,
                                module: JsModule { name, source },
                              } => {
                                let res = match get_raw_source_code(source).await {
                                  Err(e) => {
                                    JsResult::Err(e.to_string())
                                  }
                                  Ok(source) => {
                                    let res = Module::evaluate(ctx_s.clone(), name, source);
                                    JsResult::from_promise_result(&ctx_s, res).await
                                  }
                                };
                                let res = JsActionResult {id, result: res};
                                cb(JsCallback::Handler(res)).await;
                              }
                              JsAction::ImportModule {
                                id,
                                specifier,
                              } => {
                                let res = Module::import(&ctx_s.clone(), specifier);
                                let res = JsResult::from_promise_result(&ctx_s, res).await;
                                let res = JsActionResult {id, result: res};
                                cb(JsCallback::Handler(res)).await;
                              }
                            }
                        });
                    }
                }
            }
        })
            .await?;
        self.running
            .store(false, std::sync::atomic::Ordering::SeqCst);
        self.disposed
            .store(true, std::sync::atomic::Ordering::SeqCst);
        Ok(())
    }
}

async fn get_raw_source_code(source: JsCode) -> anyhow::Result<String> {
    let code = match source {
        JsCode::Code(code) => code,
        JsCode::Path(path) => {
            let mut f = tokio::fs::File::open(path).await?;
            let mut codes = String::new();
            f.read_to_string(&mut codes).await?;
            codes
        }
    };
    Ok(code)
}

#[frb(dart_metadata = ("freezed"), dart_code = "
  bool get isOk => this is JsResult_Ok;
  bool get isErr => this is JsResult_Err;
  JsValue get ok => (this as JsResult_Ok).field0;
  String get err => (this as JsResult_Err).field0;
")]
#[derive(Debug, Clone)]
pub enum JsResult {
    Ok(JsValue),
    Err(String),
}

impl JsResult {
    async fn from_promise_result<'js>(
        ctx: &rquickjs::Ctx<'js>,
        res: rquickjs::Result<Promise<'js>>,
    ) -> Self {
        match res.catch(ctx) {
            Ok(promise) => match promise.into_future::<rquickjs::Value>().await.catch(ctx) {
                Ok(v) => match JsValue::from_js(ctx, v).catch(ctx) {
                    Ok(v) => JsResult::Ok(v),
                    Err(e) => JsResult::Err(e.to_string()),
                },
                Err(e) => JsResult::Err(e.to_string()),
            },
            Err(e) => JsResult::Err(e.to_string()),
        }
    }

    fn from_result<'js>(
        ctx: &rquickjs::Ctx<'js>,
        res: rquickjs::Result<rquickjs::Value<'js>>,
    ) -> Self {
        res.catch(ctx)
            .map(|v| JsValue::from_js(ctx, v))
            .map_or_else(
                |e| JsResult::Err(e.to_string()),
                |v| match v {
                    Ok(v) => JsResult::Ok(v),
                    Err(e) => JsResult::Err(e.to_string()),
                },
            )
    }
}

#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub struct JsEvalOptions {
    /// Global code.
    pub global: Option<bool>,
    /// Force 'strict' mode.
    pub strict: Option<bool>,
    /// Don't include the stack frames before this eval in the Error() backtraces.
    pub backtrace_barrier: Option<bool>,
    /// Support top-level-await.
    pub promise: Option<bool>,
    /// Builtin modules to include in the context.
    pub builtin_options: Option<JsBuiltinOptions>,
}

impl JsEvalOptions {
    #[frb(sync)]
    pub fn new(
        global: Option<bool>,
        strict: Option<bool>,
        backtrace_barrier: Option<bool>,
        promise: Option<bool>,
        builtin_options: Option<JsBuiltinOptions>,
    ) -> Self {
        JsEvalOptions {
            global,
            strict,
            backtrace_barrier,
            promise,
            builtin_options,
        }
    }
}

impl From<JsEvalOptions> for rquickjs::context::EvalOptions {
    fn from(v: JsEvalOptions) -> Self {
        let mut opts = rquickjs::context::EvalOptions::default();
        opts.global = v.global.unwrap_or(true);
        opts.strict = v.strict.unwrap_or(true);
        opts.backtrace_barrier = v.backtrace_barrier.unwrap_or(false);
        opts.promise = v.promise.unwrap_or(false);
        opts
    }
}

impl Default for JsEvalOptions {
    #[frb(ignore)]
    fn default() -> Self {
        JsEvalOptions {
            global: Some(true),
            strict: Some(true),
            backtrace_barrier: Some(false),
            promise: Some(false),
            builtin_options: None,
        }
    }
}

#[frb(dart_metadata = ("freezed"), dart_code = "
  const JsBuiltinOptions._();
  factory JsBuiltinOptions.from(Set<String> enableModules) {
    return JsBuiltinOptions(
      fetch: enableModules.contains('fetch'),
      console: enableModules.contains('console'),
      buffer: enableModules.contains('buffer'),
      stringDecoder: enableModules.contains('string_decoder'),
      timers: enableModules.contains('timers'),
      stream: enableModules.contains('stream'),
      crypto: enableModules.contains('crypto'),
      abort: enableModules.contains('abort_controller'),
      url: enableModules.contains('url'),
      events: enableModules.contains('events'),
    );
  }
  Set<String> get enabledModules {
    final modules = <String>{};
    if (fetch == true) modules.add('fetch');
    if (console == true) modules.add('console');
    if (buffer == true) modules.add('buffer');
    if (stringDecoder == true) modules.add('string_decoder');
    if (timers == true) modules.add('timers');
    if (stream == true) modules.add('stream');
    if (crypto == true) modules.add('crypto');
    if (abort == true) modules.add('abort_controller');
    if (url == true) modules.add('url');
    if (events == true) modules.add('events');
    return modules;
  }
")]
#[derive(Debug, Clone)]
pub struct JsBuiltinOptions {
    pub fetch: Option<bool>,
    pub console: Option<bool>,
    pub buffer: Option<bool>,
    pub string_decoder: Option<bool>,
    pub timers: Option<bool>,
    pub stream: Option<bool>,
    pub crypto: Option<bool>,
    pub abort: Option<bool>,
    pub url: Option<bool>,
    pub events: Option<bool>,
}

impl Default for JsBuiltinOptions {
    #[frb(ignore)]
    fn default() -> Self {
        JsBuiltinOptions {
            fetch: None,
            console: None,
            buffer: None,
            string_decoder: None,
            timers: None,
            stream: None,
            crypto: None,
            abort: None,
            url: None,
            events: None,
        }
    }
}

impl JsBuiltinOptions {
    fn init<'js>(&self, ctx: &rquickjs::Ctx<'js>) -> rquickjs::CaughtResult<'js, ()> {
        if self.fetch.unwrap_or_default() {
            llrt_fetch::init(ctx).catch(ctx)?;
        }
        if self.console.unwrap_or_default() {
            llrt_console::init(ctx).catch(ctx)?;
        }
        if self.buffer.unwrap_or_default() {
            llrt_buffer::init(ctx).catch(ctx)?;
        }
        if self.timers.unwrap_or_default() {
            llrt_timers::init(ctx).catch(ctx)?;
        }
        if self.stream.unwrap_or_default() {
            llrt_stream_web::init(ctx).catch(ctx)?;
        }
        if self.crypto.unwrap_or_default() {
            llrt_crypto::init(ctx).catch(ctx)?;
        }
        if self.abort.unwrap_or_default() {
            llrt_abort::init(ctx).catch(ctx)?;
        }
        if self.url.unwrap_or_default() {
            llrt_url::init(ctx).catch(ctx)?;
        }
        if self.events.unwrap_or_default() {
            llrt_events::init(ctx).catch(ctx)?;
        }
        Ok(())
    }

    async fn init_async<'js>(&self, ctx: rquickjs::Ctx<'js>) -> rquickjs::CaughtResult<'js, ()> {
        if self.string_decoder.unwrap_or_default() {
            let (_module, module_eval) = Module::evaluate_def::<
                llrt_string_decoder::StringDecoderModule,
                _,
            >(ctx.clone(), "string_decoder")
            .catch(&ctx)?;
            module_eval.into_future::<()>().await.catch(&ctx)?;
        }
        Ok(())
    }
}

#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Hash, Eq, PartialEq, Ord, PartialOrd)]
pub struct JsModule {
    pub name: String,
    pub source: JsCode,
}

#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Hash, Eq, PartialEq, Ord, PartialOrd)]
pub enum JsCode {
    Code(String),
    Path(String),
}

impl JsModule {
    #[frb(sync)]
    pub fn new(name: String, source: JsCode) -> Self {
        JsModule { name, source }
    }
    #[frb(sync)]
    pub fn code(module: String, code: String) -> Self {
        JsModule {
            name: module,
            source: JsCode::Code(code),
        }
    }
    #[frb(sync)]
    pub fn path(module: String, path: String) -> Self {
        JsModule {
            name: module,
            source: JsCode::Path(path),
        }
    }
}

fn register_fjs<'js>(
    ctx: rquickjs::Ctx<'js>,
    bridge: Arc<dyn Fn(JsCallback) -> DartFnFuture<JsCallbackResult> + Sync + Send + 'static>,
) -> rquickjs::CaughtResult<'js, ()> {
    let fjs = Object::new(ctx.clone()).catch(&ctx)?;
    fjs.set("bridge_call", new_bridge_call(ctx.clone(), bridge)?)
        .catch(&ctx)?;
    ctx.globals().set("fjs", fjs).catch(&ctx)?;
    Ok(())
}

fn new_bridge_call<'js>(
    ctx: rquickjs::Ctx<'js>,
    bridge: Arc<dyn Fn(JsCallback) -> DartFnFuture<JsCallbackResult> + Sync + Send + 'static>,
) -> rquickjs::CaughtResult<'js, rquickjs::Function<'js>> {
    let ctx_clone = ctx.clone();
    rquickjs::Function::new(
        ctx.clone(),
        move |args: rquickjs::function::Rest<rquickjs::Value<'js>>| -> rquickjs::Result<Promise> {
            if args.0.len() > 1 {
                return Err(rquickjs::Error::TooManyArgs {
                    expected: 1,
                    given: args.len(),
                });
            }
            if args.0.is_empty() {
                return Err(rquickjs::Error::MissingArgs {
                    expected: 1,
                    given: 0,
                });
            }
            let arg = args.0.first().unwrap();
            let js_value = JsValue::from_js(&ctx, arg.clone()).unwrap();
            let bridge_call = bridge.clone();
            let (promise, resolve, reject) = ctx.promise()?;
            let ctx_s = ctx.clone();
            ctx.spawn(async move {
                let res = bridge_call(JsCallback::Bridge(js_value)).await;
                match res {
                    JsCallbackResult::Bridge(res) => match res {
                        JsResult::Ok(value) => {
                            let mut args = Args::new(ctx_s, 1);
                            args.push_arg(value).unwrap();
                            resolve.call_arg::<()>(args).unwrap();
                        }
                        JsResult::Err(err) => {
                            let mut args = Args::new(ctx_s, 1);
                            args.push_arg(err).unwrap();
                            reject.call_arg::<()>(args).unwrap();
                        }
                    },
                    JsCallbackResult::Initialized => {
                        unreachable!("Bridge callback should not return Init variant");
                    }
                    JsCallbackResult::Handler => {
                        unreachable!("Bridge callback should not return Handler variant");
                    }
                }
            });
            Ok(promise)
        },
    )
    .catch(&ctx_clone)
}

#[cfg(test)]
mod test {
    use crate::api::js::{JsAsyncContext, JsAsyncRuntime, JsCode, JsModule};
    use crate::api::value::JsValue;

    #[tokio::test]
    async fn test() {
        env_logger::builder()
            .filter_level(log::LevelFilter::Trace)
            .init();
        let rt = JsAsyncRuntime::new().unwrap();
        let ctx = JsAsyncContext::from(&rt).await.unwrap();
        let modules = vec![JsModule::new("test".to_string(), JsCode::Code(
            // language=javascript
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
            "#.to_string()))];
        rt.set_modules(modules).await.unwrap();
        let r = ctx
            .eval_function(
                "test".to_string(),
                "test".to_string(),
                Some(vec![JsValue::Array(vec![
                    JsValue::String("hello".to_string()),
                    JsValue::String("world".to_string()),
                ])]),
            )
            .await;
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
    #[tokio::test]
    async fn test4() {
        let rt = JsAsyncRuntime::new().unwrap();
        let context = JsAsyncContext::from(&rt).await.unwrap();
    }
}
