//! # Error Handling
//!
//! This module provides comprehensive error types for the FJS JavaScript runtime.
//! It uses `thiserror` for ergonomic error definitions and provides rich context
//! for debugging and user feedback.

use flutter_rust_bridge::frb;
use std::fmt;

/// Represents various types of JavaScript errors.
///
/// This enum provides detailed error information for different
/// categories of errors that can occur during JavaScript execution.
#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone)]
pub enum JsError {
    /// Promise-related errors (async operation failures)
    Promise(String),
    /// Module-related errors (import/export failures)
    Module {
        /// Optional module name where the error occurred
        module: Option<String>,
        /// Optional method name where the error occurred
        method: Option<String>,
        /// Error message
        message: String,
    },
    /// Context attachment errors (global object setup failures)
    Context(String),
    /// Storage initialization errors (dynamic module storage failures)
    Storage(String),
    /// File I/O errors (file reading failures)
    Io {
        /// Optional file path where the error occurred
        path: Option<String>,
        /// Error message
        message: String,
    },
    /// JavaScript runtime errors from QuickJS engine
    Runtime(String),
    /// Generic catch-all errors
    Generic(String),
    /// Engine lifecycle errors
    Engine(String),
    /// Bridge communication errors
    Bridge(String),
    /// Type conversion errors
    Conversion {
        /// The source type
        from: String,
        /// The target type
        to: String,
        /// Error message
        message: String,
    },
    /// Timeout errors
    Timeout {
        /// Operation that timed out
        operation: String,
        /// Timeout duration in milliseconds
        timeout_ms: u64,
    },
    /// Memory limit exceeded errors
    MemoryLimit(String),
    /// Stack overflow errors
    StackOverflow(String),
    /// Syntax errors in JavaScript code
    Syntax {
        /// Line number where the error occurred
        line: Option<u32>,
        /// Column number where the error occurred
        column: Option<u32>,
        /// Error message
        message: String,
    },
    /// Reference errors (undefined variables, etc.)
    Reference(String),
    /// Type errors in JavaScript
    Type(String),
    /// Cancelled operation errors
    Cancelled(String),
}

impl JsError {
    /// Creates a new promise error.
    ///
    /// ## Parameters
    ///
    /// - `msg`: Error message describing the promise failure
    ///
    /// ## Returns
    ///
    /// A `JsError::Promise` instance
    #[frb(ignore)]
    pub fn promise<S: Into<String>>(msg: S) -> Self {
        JsError::Promise(msg.into())
    }

    /// Creates a new module error.
    ///
    /// ## Parameters
    ///
    /// - `module`: Optional module name where the error occurred
    /// - `method`: Optional method name where the error occurred
    /// - `message`: Error message
    ///
    /// ## Returns
    ///
    /// A `JsError::Module` instance
    #[frb(ignore)]
    pub fn module<S: Into<String>>(
        module: Option<String>,
        method: Option<String>,
        message: S,
    ) -> Self {
        JsError::Module {
            module,
            method,
            message: message.into(),
        }
    }

    /// Creates a new context error.
    ///
    /// ## Parameters
    ///
    /// - `msg`: Error message describing the context failure
    ///
    /// ## Returns
    ///
    /// A `JsError::Context` instance
    #[frb(ignore)]
    pub fn context<S: Into<String>>(msg: S) -> Self {
        JsError::Context(msg.into())
    }

    /// Creates a new storage error.
    ///
    /// ## Parameters
    ///
    /// - `msg`: Error message describing the storage failure
    ///
    /// ## Returns
    ///
    /// A `JsError::Storage` instance
    #[frb(ignore)]
    pub fn storage<S: Into<String>>(msg: S) -> Self {
        JsError::Storage(msg.into())
    }

    /// Creates a new I/O error.
    ///
    /// ## Parameters
    ///
    /// - `path`: Optional file path where the error occurred
    /// - `message`: Error message
    ///
    /// ## Returns
    ///
    /// A `JsError::Io` instance
    #[frb(ignore)]
    pub fn io<S: Into<String>>(path: Option<String>, message: S) -> Self {
        JsError::Io {
            path,
            message: message.into(),
        }
    }

    /// Creates a new runtime error.
    ///
    /// ## Parameters
    ///
    /// - `msg`: Error message describing the runtime failure
    ///
    /// ## Returns
    ///
    /// A `JsError::Runtime` instance
    #[frb(ignore)]
    pub fn runtime<S: Into<String>>(msg: S) -> Self {
        JsError::Runtime(msg.into())
    }

    /// Creates a new generic error.
    ///
    /// ## Parameters
    ///
    /// - `msg`: Error message
    ///
    /// ## Returns
    ///
    /// A `JsError::Generic` instance
    #[frb(ignore)]
    pub fn generic<S: Into<String>>(msg: S) -> Self {
        JsError::Generic(msg.into())
    }

    /// Creates a new engine error.
    ///
    /// ## Parameters
    ///
    /// - `msg`: Error message describing the engine failure
    ///
    /// ## Returns
    ///
    /// A `JsError::Engine` instance
    #[frb(ignore)]
    pub fn engine<S: Into<String>>(msg: S) -> Self {
        JsError::Engine(msg.into())
    }

    /// Creates a new bridge error.
    ///
    /// ## Parameters
    ///
    /// - `msg`: Error message describing the bridge failure
    ///
    /// ## Returns
    ///
    /// A `JsError::Bridge` instance
    #[frb(ignore)]
    pub fn bridge<S: Into<String>>(msg: S) -> Self {
        JsError::Bridge(msg.into())
    }

    /// Creates a new conversion error.
    ///
    /// ## Parameters
    ///
    /// - `from`: The source type
    /// - `to`: The target type
    /// - `message`: Error message
    ///
    /// ## Returns
    ///
    /// A `JsError::Conversion` instance
    #[frb(ignore)]
    pub fn conversion<S: Into<String>>(from: S, to: S, message: S) -> Self {
        JsError::Conversion {
            from: from.into(),
            to: to.into(),
            message: message.into(),
        }
    }

    /// Creates a new timeout error.
    ///
    /// ## Parameters
    ///
    /// - `operation`: The operation that timed out
    /// - `timeout_ms`: The timeout duration in milliseconds
    ///
    /// ## Returns
    ///
    /// A `JsError::Timeout` instance
    #[frb(ignore)]
    pub fn timeout<S: Into<String>>(operation: S, timeout_ms: u64) -> Self {
        JsError::Timeout {
            operation: operation.into(),
            timeout_ms,
        }
    }

    /// Creates a new memory limit error.
    ///
    /// ## Parameters
    ///
    /// - `msg`: Error message describing the memory limit failure
    ///
    /// ## Returns
    ///
    /// A `JsError::MemoryLimit` instance
    #[frb(ignore)]
    pub fn memory_limit<S: Into<String>>(msg: S) -> Self {
        JsError::MemoryLimit(msg.into())
    }

    /// Creates a new syntax error.
    ///
    /// ## Parameters
    ///
    /// - `line`: Optional line number where the error occurred
    /// - `column`: Optional column number where the error occurred
    /// - `message`: Error message
    ///
    /// ## Returns
    ///
    /// A `JsError::Syntax` instance
    #[frb(ignore)]
    pub fn syntax<S: Into<String>>(line: Option<u32>, column: Option<u32>, message: S) -> Self {
        JsError::Syntax {
            line,
            column,
            message: message.into(),
        }
    }

    /// Creates a new reference error.
    ///
    /// ## Parameters
    ///
    /// - `msg`: Error message
    ///
    /// ## Returns
    ///
    /// A `JsError::Reference` instance
    #[frb(ignore)]
    pub fn reference<S: Into<String>>(msg: S) -> Self {
        JsError::Reference(msg.into())
    }

    /// Creates a new type error.
    ///
    /// ## Parameters
    ///
    /// - `msg`: Error message
    ///
    /// ## Returns
    ///
    /// A `JsError::Type` instance
    #[frb(ignore)]
    pub fn type_error<S: Into<String>>(msg: S) -> Self {
        JsError::Type(msg.into())
    }

    /// Creates a new cancelled error.
    ///
    /// ## Parameters
    ///
    /// - `msg`: Error message
    ///
    /// ## Returns
    ///
    /// A `JsError::Cancelled` instance
    #[frb(ignore)]
    pub fn cancelled<S: Into<String>>(msg: S) -> Self {
        JsError::Cancelled(msg.into())
    }

    /// Converts the error to a string representation.
    ///
    /// ## Returns
    ///
    /// A formatted string describing the error
    #[frb(sync)]
    pub fn to_string(&self) -> String {
        format!("{}", self)
    }

    /// Returns the error code for this error type.
    ///
    /// The error code is a constant string identifier for the error category,
    /// useful for programmatic error handling.
    ///
    /// ## Returns
    ///
    /// The error code as a string (e.g., "PROMISE_ERROR", "RUNTIME_ERROR")
    ///
    /// ## Example
    ///
    /// ```dart
    /// const error = JsError.syntax(
    ///   message: 'Unexpected token',
    ///   line: 1,
    ///   column: 10,
    /// );
    ///
    /// switch (error.code()) {
    ///   case 'SYNTAX_ERROR':
    ///     print('Syntax error in code');
    ///     break;
    ///   case 'RUNTIME_ERROR':
    ///     print('Runtime error occurred');
    ///     break;
    ///   default:
    ///     print('Other error: ${error.code()}');
    /// }
    /// ```
    #[frb(sync)]
    pub fn code(&self) -> String {
        match self {
            JsError::Promise(_) => "PROMISE_ERROR".to_string(),
            JsError::Module { .. } => "MODULE_ERROR".to_string(),
            JsError::Context(_) => "CONTEXT_ERROR".to_string(),
            JsError::Storage(_) => "STORAGE_ERROR".to_string(),
            JsError::Io { .. } => "IO_ERROR".to_string(),
            JsError::Runtime(_) => "RUNTIME_ERROR".to_string(),
            JsError::Generic(_) => "GENERIC_ERROR".to_string(),
            JsError::Engine(_) => "ENGINE_ERROR".to_string(),
            JsError::Bridge(_) => "BRIDGE_ERROR".to_string(),
            JsError::Conversion { .. } => "CONVERSION_ERROR".to_string(),
            JsError::Timeout { .. } => "TIMEOUT_ERROR".to_string(),
            JsError::MemoryLimit { .. } => "MEMORY_LIMIT_ERROR".to_string(),
            JsError::StackOverflow(_) => "STACK_OVERFLOW_ERROR".to_string(),
            JsError::Syntax { .. } => "SYNTAX_ERROR".to_string(),
            JsError::Reference(_) => "REFERENCE_ERROR".to_string(),
            JsError::Type(_) => "TYPE_ERROR".to_string(),
            JsError::Cancelled(_) => "CANCELLED_ERROR".to_string(),
        }
    }

    /// Returns whether this error is recoverable.
    ///
    /// Recoverable errors are typically transient issues (like network errors,
    /// parse errors, or timeout errors) that might succeed if retried.
    /// Non-recoverable errors indicate serious issues (like context failures,
    /// memory limits, or stack overflows) that generally cannot be fixed
    /// without changing the execution environment.
    ///
    /// ## Returns
    ///
    /// `true` if the error is recoverable, `false` otherwise
    ///
    /// ## Example
    ///
    /// ```dart
    /// final error = JsError.runtime('Temporary runtime failure');
    ///
    /// if (error.isRecoverable()) {
    ///   await Future.delayed(const Duration(seconds: 1));
    ///   print('Retrying operation...');
    /// } else {
    ///   print('Fatal error, cannot recover');
    /// }
    /// ```
    #[frb(sync)]
    pub fn is_recoverable(&self) -> bool {
        match self {
            JsError::Promise(_)
            | JsError::Module { .. }
            | JsError::Io { .. }
            | JsError::Runtime(_)
            | JsError::Generic(_)
            | JsError::Bridge(_)
            | JsError::Conversion { .. }
            | JsError::Timeout { .. }
            | JsError::Syntax { .. }
            | JsError::Reference(_)
            | JsError::Type(_) => true,
            JsError::Context(_)
            | JsError::Storage(_)
            | JsError::Engine(_)
            | JsError::MemoryLimit { .. }
            | JsError::StackOverflow(_)
            | JsError::Cancelled(_) => false,
        }
    }

    /// Classifies a caught QuickJS error into a structured `JsError`.
    ///
    /// Exception objects are classified by their JavaScript `name` property
    /// (`SyntaxError`, `TypeError`, ...), with line/column information parsed
    /// from the stack trace when available. The full message and stack text
    /// are preserved in the error message.
    #[frb(ignore)]
    pub(crate) fn from_caught<'js>(
        ctx: &rquickjs::Ctx<'js>,
        error: rquickjs::CaughtError<'js>,
    ) -> Self {
        match error {
            rquickjs::CaughtError::Exception(exception) => Self::from_exception(ctx, &exception),
            rquickjs::CaughtError::Value(value) => Self::from_thrown_value(ctx, value),
            rquickjs::CaughtError::Error(error) => error.into(),
        }
    }

    /// Classifies the currently pending exception on the context.
    #[frb(ignore)]
    pub(crate) fn from_pending_exception(ctx: &rquickjs::Ctx<'_>) -> Self {
        Self::from_thrown_value(ctx, ctx.catch())
    }

    /// Classifies an arbitrary thrown JavaScript value.
    #[frb(ignore)]
    pub(crate) fn from_thrown_value<'js>(
        ctx: &rquickjs::Ctx<'js>,
        value: rquickjs::Value<'js>,
    ) -> Self {
        use rquickjs::FromJs;

        if let Some(exception) = value
            .clone()
            .into_object()
            .and_then(rquickjs::Exception::from_object)
        {
            return Self::from_exception(ctx, &exception);
        }

        let message = rquickjs::convert::Coerced::<String>::from_js(ctx, value.clone())
            .map(|coerced| coerced.0)
            .unwrap_or_else(|_| {
                // Coercion may have left its own exception pending (e.g. a
                // throwing `toString`); clear it so later context operations
                // do not misattribute it.
                let _ = ctx.catch();
                format!("{value:?}")
            });
        JsError::Runtime(message)
    }

    #[frb(ignore)]
    fn from_exception<'js>(ctx: &rquickjs::Ctx<'js>, exception: &rquickjs::Exception<'js>) -> Self {
        let name = exception
            .as_object()
            .get::<_, Option<rquickjs::convert::Coerced<String>>>("name")
            .ok()
            .flatten()
            .map(|coerced| coerced.0)
            .filter(|name| !name.is_empty())
            .unwrap_or_else(|| "Error".to_string());
        let message = exception.message().unwrap_or_default();
        let stack = exception
            .stack()
            .map(|stack| stack.trim_end().to_string())
            .filter(|stack| !stack.is_empty());
        // Throwing `name`/`message`/`stack` accessors leave their own
        // exception pending on the context; clear it so later operations do
        // not misattribute it.
        if ctx.has_exception() {
            let _ = ctx.catch();
        }

        let mut detail = if message.is_empty() {
            name.clone()
        } else {
            format!("{name}: {message}")
        };
        if let Some(stack) = &stack {
            detail.push('\n');
            detail.push_str(stack);
        }

        // QuickJS reports stack exhaustion as `RangeError: Maximum call stack
        // size exceeded` or `InternalError: stack overflow (...)`; require the
        // matching name so user-thrown errors cannot spoof the classification.
        let is_stack_overflow = matches!(name.as_str(), "RangeError" | "InternalError")
            && (message.contains("Maximum call stack size exceeded")
                || message.contains("stack overflow"));
        if is_stack_overflow {
            return JsError::StackOverflow(detail);
        }

        match name.as_str() {
            "SyntaxError" => {
                let position = stack.as_deref().and_then(parse_stack_position);
                JsError::Syntax {
                    line: position.map(|(line, _)| line),
                    column: position.and_then(|(_, column)| column),
                    message: detail,
                }
            }
            "TypeError" => JsError::Type(detail),
            "ReferenceError" => JsError::Reference(detail),
            "InternalError" if message.contains("out of memory") => JsError::MemoryLimit(detail),
            _ => JsError::Runtime(detail),
        }
    }
}

/// Parses `line` and `column` from the first frame of a QuickJS stack trace
/// (`    at func (file:line:column)` or `    at file:line`).
fn parse_stack_position(stack: &str) -> Option<(u32, Option<u32>)> {
    let frame = stack.lines().find(|line| !line.trim().is_empty())?;
    let frame = frame.trim().trim_end_matches(')');
    let mut parts = frame.rsplitn(3, ':');
    let last = parts.next()?;
    let middle = parts.next();

    let last_number = last.parse::<u32>().ok()?;
    match middle.and_then(|segment| segment.parse::<u32>().ok()) {
        Some(line) => Some((line, Some(last_number))),
        None => Some((last_number, None)),
    }
}

impl fmt::Display for JsError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            JsError::Promise(msg) => write!(f, "Promise error: {}", msg),
            JsError::Module {
                module,
                method,
                message,
            } => {
                let mut parts = Vec::new();
                if let Some(m) = module {
                    parts.push(format!("module: {}", m));
                }
                if let Some(m) = method {
                    parts.push(format!("method: {}", m));
                }
                parts.push(format!("error: {}", message));
                write!(f, "Module error - {}", parts.join(", "))
            }
            JsError::Context(msg) => write!(f, "Context error: {}", msg),
            JsError::Storage(msg) => write!(f, "Storage error: {}", msg),
            JsError::Io { path, message } => {
                if let Some(p) = path {
                    write!(f, "IO error at {}: {}", p, message)
                } else {
                    write!(f, "IO error: {}", message)
                }
            }
            JsError::Runtime(msg) => write!(f, "Runtime error: {}", msg),
            JsError::Generic(msg) => write!(f, "{}", msg),
            JsError::Engine(msg) => write!(f, "Engine error: {}", msg),
            JsError::Bridge(msg) => write!(f, "Bridge error: {}", msg),
            JsError::Conversion { from, to, message } => {
                write!(f, "Conversion error ({} -> {}): {}", from, to, message)
            }
            JsError::Timeout {
                operation,
                timeout_ms,
            } => {
                write!(
                    f,
                    "Timeout error: {} timed out after {}ms",
                    operation, timeout_ms
                )
            }
            JsError::MemoryLimit(msg) => {
                write!(f, "Memory limit exceeded: {}", msg)
            }
            JsError::StackOverflow(msg) => write!(f, "Stack overflow: {}", msg),
            JsError::Syntax {
                line,
                column,
                message,
            } => {
                let mut loc = String::new();
                if let Some(l) = line {
                    loc.push_str(&format!("line {}", l));
                    if let Some(c) = column {
                        loc.push_str(&format!(", column {}", c));
                    }
                }
                if loc.is_empty() {
                    write!(f, "Syntax error: {}", message)
                } else {
                    write!(f, "Syntax error at {}: {}", loc, message)
                }
            }
            JsError::Reference(msg) => write!(f, "Reference error: {}", msg),
            JsError::Type(msg) => write!(f, "Type error: {}", msg),
            JsError::Cancelled(msg) => write!(f, "Cancelled: {}", msg),
        }
    }
}

impl std::error::Error for JsError {}

impl From<anyhow::Error> for JsError {
    fn from(err: anyhow::Error) -> Self {
        JsError::Generic(format!("{err:#}"))
    }
}

impl From<std::io::Error> for JsError {
    fn from(err: std::io::Error) -> Self {
        JsError::Io {
            path: None,
            message: err.to_string(),
        }
    }
}

impl From<rquickjs::Error> for JsError {
    fn from(err: rquickjs::Error) -> Self {
        use rquickjs::Error;

        match err {
            Error::FromJs { from, to, message } | Error::IntoJs { from, to, message } => {
                JsError::Conversion {
                    from: from.to_string(),
                    to: to.to_string(),
                    message: message.unwrap_or_default(),
                }
            }
            Error::Resolving {
                base,
                name,
                message,
            } => JsError::Module {
                module: Some(name.clone()),
                method: None,
                message: match message {
                    Some(message) => format!("Failed to resolve '{name}' from '{base}': {message}"),
                    None => format!("Failed to resolve '{name}' from '{base}'"),
                },
            },
            Error::Loading { name, message } => JsError::Module {
                module: Some(name.clone()),
                method: None,
                message: match message {
                    Some(message) => format!("Failed to load '{name}': {message}"),
                    None => format!("Failed to load '{name}'"),
                },
            },
            Error::Allocation => JsError::MemoryLimit("Allocation failed".to_string()),
            Error::Io(error) => JsError::Io {
                path: None,
                message: error.to_string(),
            },
            other => JsError::Runtime(other.to_string()),
        }
    }
}

/// Represents the result of a JavaScript operation.
///
/// This enum provides a type-safe way to handle operations that can
/// either succeed with a value or fail with an error. It follows the
/// Result pattern common in Rust and functional programming.
///
/// ## Example
///
/// ```dart
/// final result = await context.eval(code: '1 + 1');
///
/// // Check result type
/// if (result.isOk) {
///   print('Success: ${result.ok.value}');
/// } else if (result.isErr) {
///   print('Error: ${result.err.toString()}');
/// }
///
/// // Or use when in Dart
/// result.when(
///   ok: (value) => print('Success: ${value.value}'),
///   err: (error) => print('Error: ${error.toString()}'),
/// );
/// ```
#[frb(dart_metadata = ("freezed"), dart_code = "
  bool get isOk => this is JsResult_Ok;
  bool get isErr => this is JsResult_Err;
  JsValue get ok => (this as JsResult_Ok).field0;
  JsError get err => (this as JsResult_Err).field0;
")]
#[derive(Debug, Clone)]
pub enum JsResult {
    /// Successful execution result containing the value
    Ok(super::value::JsValue),
    /// Error during execution containing the error details
    Err(JsError),
}

impl JsResult {
    /// Creates a successful result.
    ///
    /// ## Parameters
    ///
    /// - `value`: The result value
    ///
    /// ## Returns
    ///
    /// A `JsResult::Ok` instance
    #[frb(ignore)]
    pub fn ok(value: super::value::JsValue) -> Self {
        JsResult::Ok(value)
    }

    /// Creates an error result.
    ///
    /// ## Parameters
    ///
    /// - `error`: The error
    ///
    /// ## Returns
    ///
    /// A `JsResult::Err` instance
    #[frb(ignore)]
    pub fn err(error: JsError) -> Self {
        JsResult::Err(error)
    }

    /// Returns true if the result is Ok.
    ///
    /// ## Returns
    ///
    /// `true` if the result is `JsResult::Ok`, `false` otherwise
    #[frb(ignore)]
    pub fn is_ok(&self) -> bool {
        matches!(self, JsResult::Ok(_))
    }

    /// Returns true if the result is Err.
    ///
    /// ## Returns
    ///
    /// `true` if the result is `JsResult::Err`, `false` otherwise
    #[frb(ignore)]
    pub fn is_err(&self) -> bool {
        matches!(self, JsResult::Err(_))
    }

    /// Maps the Ok value using the provided function.
    ///
    /// If the result is Ok, applies the function to the value.
    /// If the result is Err, returns the error unchanged.
    ///
    /// ## Type Parameters
    ///
    /// - `U`: The output type of the mapping function
    /// - `F`: The function type to apply
    ///
    /// ## Parameters
    ///
    /// - `self`: The result to map
    /// - `f`: The function to apply to the Ok value
    ///
    /// ## Returns
    ///
    /// `Ok(f(value))` if Ok, `Err(error)` if Err
    #[frb(ignore)]
    pub fn map<U, F: FnOnce(super::value::JsValue) -> U>(self, f: F) -> Result<U, JsError> {
        match self {
            JsResult::Ok(v) => Ok(f(v)),
            JsResult::Err(e) => Err(e),
        }
    }

    /// Maps the Err value using the provided function.
    ///
    /// If the result is Err, applies the function to the error.
    /// If the result is Ok, returns the value unchanged.
    ///
    /// ## Type Parameters
    ///
    /// - `F`: The function type to apply
    ///
    /// ## Parameters
    ///
    /// - `self`: The result to map
    /// - `f`: The function to apply to the error
    ///
    /// ## Returns
    ///
    /// `Ok(value)` if Ok, `Err(f(error))` if Err
    #[frb(ignore)]
    pub fn map_err<F: FnOnce(JsError) -> JsError>(self, f: F) -> JsResult {
        match self {
            JsResult::Ok(v) => JsResult::Ok(v),
            JsResult::Err(e) => JsResult::Err(f(e)),
        }
    }

    /// Converts the JsResult to a standard Result.
    ///
    /// ## Parameters
    ///
    /// - `self`: The result to convert
    ///
    /// ## Returns
    ///
    /// `Ok(value)` if Ok, `Err(JsError)` if Err
    #[frb(ignore)]
    pub fn into_result(self) -> Result<super::value::JsValue, JsError> {
        match self {
            JsResult::Ok(v) => Ok(v),
            JsResult::Err(e) => Err(e),
        }
    }
}

impl From<Result<super::value::JsValue, JsError>> for JsResult {
    fn from(result: Result<super::value::JsValue, JsError>) -> Self {
        match result {
            Ok(v) => JsResult::Ok(v),
            Err(e) => JsResult::Err(e),
        }
    }
}

impl From<JsResult> for Result<super::value::JsValue, JsError> {
    fn from(result: JsResult) -> Self {
        match result {
            JsResult::Ok(v) => Ok(v),
            JsResult::Err(e) => Err(e),
        }
    }
}
