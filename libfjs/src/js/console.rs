use flutter_rust_bridge::frb;
use rquickjs::class::Trace;
use rquickjs::function::Rest;
use rquickjs::{Ctx, Error, Function, IntoJs, Object, Result, Type, Value};
use std::fmt::Write;
use std::sync::Arc;

#[derive(Default, Clone, Debug)]
#[non_exhaustive]
struct FormatArgs {
    key: Option<bool>,
}

impl FormatArgs {
    pub fn is_key(&self) -> bool {
        self.key.unwrap_or(false)
    }

    pub fn with_key(self) -> Self {
        Self {
            key: Some(true),
            ..self
        }
    }
}

/// A formatter for the [`Console`] object
///
/// This formatter is used to format values to be printed by the console object.
///
/// [`Console`]: crate::console::Console
#[derive(Clone, Debug, Trace)]
struct Formatter {
    max_depth: usize,
}

impl Default for Formatter {
    fn default() -> Self {
        Self::builder().build()
    }
}

impl Formatter {
    pub fn builder() -> FormatterBuilder {
        FormatterBuilder::default()
    }

    pub fn format(&self, out: &mut impl Write, value: Value<'_>) -> Result<()> {
        self._format(out, value, FormatArgs::default(), 0)
    }

    /// A poor attempt at mimicking the node format
    /// See https://github.com/nodejs/node/blob/363eca1033458b8c2808207e2e5fc88e0f4df655/lib/internal/util/inspect.js#L842
    fn _format(
        &self,
        out: &mut impl Write,
        value: Value<'_>,
        args: FormatArgs,
        depth: usize,
    ) -> Result<()> {
        match value.type_of() {
            Type::String => {
                write!(
                    out,
                    "{}",
                    value
                        .into_string()
                        .ok_or(Error::new_from_js("value", "string"))?
                        .to_string()?
                )
                    .map_err(|_| Error::Unknown)?;
            }
            Type::Int => {
                write!(
                    out,
                    "{}",
                    value.as_int().ok_or(Error::new_from_js("value", "int"))?
                )
                    .map_err(|_| Error::Unknown)?;
            }
            Type::Bool => {
                write!(
                    out,
                    "{}",
                    value.as_bool().ok_or(Error::new_from_js("value", "bool"))?
                )
                    .map_err(|_| Error::Unknown)?;
            }
            Type::Float => {
                write!(
                    out,
                    "{}",
                    value
                        .as_float()
                        .ok_or(Error::new_from_js("value", "float"))?
                )
                    .map_err(|_| Error::Unknown)?;
            }
            Type::BigInt => {
                write!(
                    out,
                    "{}n",
                    value
                        .into_big_int()
                        .ok_or(Error::new_from_js("value", "bigint"))?
                        .to_i64()?
                )
                    .map_err(|_| Error::Unknown)?;
            }
            Type::Array => {
                let array = value
                    .into_array()
                    .ok_or(Error::new_from_js("value", "array"))?;
                if depth > self.max_depth {
                    write!(out, "[Array]").map_err(|_| Error::Unknown)?;
                } else if args.is_key() {
                    for (i, element) in array.iter().enumerate() {
                        if i > 0 {
                            write!(out, ",").map_err(|_| Error::Unknown)?;
                        }
                        self._format(out, element?, FormatArgs::default().with_key(), depth + 1)?;
                    }
                } else {
                    write!(out, "[ ").map_err(|_| Error::Unknown)?;
                    for (i, element) in array.iter().enumerate() {
                        if i > 0 {
                            write!(out, ", ").map_err(|_| Error::Unknown)?;
                        }
                        self._format(out, element?, FormatArgs::default(), depth + 1)?;
                    }
                    write!(out, " ]").map_err(|_| Error::Unknown)?;
                }
            }
            Type::Object => {
                if depth > self.max_depth {
                    write!(out, "[Object]").map_err(|_| Error::Unknown)?;
                } else if args.is_key() {
                    write!(out, "[object Object]").map_err(|_| Error::Unknown)?;
                } else {
                    let object = value
                        .into_object()
                        .ok_or(Error::new_from_js("value", "object"))?;
                    write!(out, "{{ ").map_err(|_| Error::Unknown)?;
                    let mut first = true;
                    for prop in object.props() {
                        if !first {
                            write!(out, ", ").map_err(|_| Error::Unknown)?;
                        }
                        first = false;
                        let (key, val) = prop?;
                        self._format(out, key, FormatArgs::default().with_key(), depth + 1)?;
                        write!(out, ": ").map_err(|_| Error::Unknown)?;
                        self._format(out, val, FormatArgs::default(), depth + 1)?;
                    }
                    write!(out, " }}").map_err(|_| Error::Unknown)?;
                }
            }
            Type::Symbol => {
                let symbol = value
                    .as_symbol()
                    .ok_or(Error::new_from_js("value", "symbol"))?;
                let description = match symbol.description()?.as_string() {
                    Some(description) => description.to_string()?,
                    None => String::default(),
                };
                write!(out, "Symbol({})", description).map_err(|_| Error::Unknown)?;
            }
            Type::Function => {
                let function = value
                    .as_function()
                    .ok_or(Error::new_from_js("value", "function"))?
                    .as_object()
                    .ok_or(Error::new_from_js("function", "object"))?;
                let name: Option<String> = function.get("name").ok().and_then(|n| {
                    if n == "[object Object]" {
                        None
                    } else {
                        Some(n)
                    }
                });
                match name {
                    Some(name) => {
                        write!(out, "[Function: {}]", name).map_err(|_| Error::Unknown)?
                    }
                    None => write!(out, "[Function (anonymous)]").map_err(|_| Error::Unknown)?,
                }
            }
            Type::Null => {
                write!(out, "null", ).map_err(|_| Error::Unknown)?;
            }
            Type::Undefined => {
                write!(out, "undefined", ).map_err(|_| Error::Unknown)?;
            }
            _ => {}
        };

        Ok(())
    }
}

/// Builder for [`Formatter`]
#[derive(Default, Clone, Debug)]
#[non_exhaustive]
struct FormatterBuilder {
    max_depth: Option<usize>,
}

impl FormatterBuilder {
    /// Set the maximum depth to format, defaults to 10.
    ///
    /// If the depth is reached, the formatter will not try to print
    /// inner items and will print `[Array]` or `[Object]`.
    pub fn max_depth(self, max_depth: usize) -> Self {
        Self {
            max_depth: Some(max_depth),
            ..self
        }
    }

    /// Build the formatter
    pub fn build(self) -> Formatter {
        Formatter {
            max_depth: self.max_depth.unwrap_or(10),
        }
    }
}

#[derive(Clone, Trace, Debug)]
struct Console {
    target: String,
    formatter: Formatter,
}

impl Default for Console {
    fn default() -> Self {
        Self {
            target: "console".to_string(),
            formatter: Formatter::default(),
        }
    }
}

impl Console {
    pub fn new(target: String, formatter: Formatter) -> Self {
        Self { target, formatter }
    }
    fn print(&self, level: log::Level, values: Rest<Value<'_>>) -> Result<()> {
        let mut message = String::new();
        for (i, value) in values.0.into_iter().enumerate() {
            if i > 0 {
                write!(&mut message, ", ").map_err(|_| Error::Unknown)?
            }
            self.formatter.format(&mut message, value)?
        }
        log::log!(target: &self.target, level, "{}", message);
        Ok(())
    }
    fn log(&self, args: Rest<Value<'_>>) -> Result<()> {
        self.print(log::Level::Info, args)
    }
    fn warn(&self, args: Rest<Value<'_>>) -> Result<()> {
        self.print(log::Level::Warn, args)
    }
    fn error(&self, args: Rest<Value<'_>>) -> Result<()> {
        self.print(log::Level::Error, args)
    }
    fn debug(&self, args: Rest<Value<'_>>) -> Result<()> {
        self.print(log::Level::Debug, args)
    }
}


pub fn setup_console(ctx: &Ctx<'_>) -> Result<()> {
    let console = Arc::new(Console::default());
    let c = Object::new(ctx.clone())?;
    let c1 = console.clone();
    c.set("log", Function::new(ctx.clone(), move |ctx: Ctx, args: Rest<Value>| {
        c1.log(args).map_err(|e| ctx.throw(e.to_string().into_js(&ctx).unwrap()))
    }))?;
    let c2 = console.clone();
    c.set("warn", Function::new(ctx.clone(), move |ctx: Ctx, args: Rest<Value>| {
        c2.warn(args).map_err(|e| ctx.throw(e.to_string().into_js(&ctx).unwrap()))
    }))?;
    let c3 = console.clone();
    c.set("error", Function::new(ctx.clone(), move |ctx: Ctx, args: Rest<Value>| {
        c3.error(args).map_err(|e| ctx.throw(e.to_string().into_js(&ctx).unwrap()))
    }))?;
    let c4 = console.clone();
    c.set("debug", Function::new(ctx.clone(), move |ctx: Ctx, args: Rest<Value>| {
        c4.debug(args).map_err(|e| ctx.throw(e.to_string().into_js(&ctx).unwrap()))
    }))?;
    let object = ctx.globals();
    object.set("console", c)?;
    Ok(())
}