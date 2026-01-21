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
    MemoryLimit {
        /// Current memory usage in bytes
        current: u64,
        /// Memory limit in bytes
        limit: u64,
    },
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
    /// - `current`: Current memory usage in bytes
    /// - `limit`: Memory limit in bytes
    ///
    /// ## Returns
    ///
    /// A `JsError::MemoryLimit` instance
    #[frb(ignore)]
    pub fn memory_limit(current: u64, limit: u64) -> Self {
        JsError::MemoryLimit { current, limit }
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
    /// try {
    ///   final result = await context.eval(code: 'invalid');
    /// } catch (e) {
    ///   if (e is JsError) {
    ///     switch (e.code()) {
    ///       case 'SYNTAX_ERROR':
    ///         print('Syntax error in code');
    ///         break;
    ///       case 'RUNTIME_ERROR':
    ///         print('Runtime error occurred');
    ///         break;
    ///       default:
    ///         print('Other error: ${e.code()}');
    ///     }
    ///   }
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
    /// try {
    ///   final result = await context.eval(code: code);
    /// } catch (e) {
    ///   if (e is JsError && e.isRecoverable()) {
    ///     // Can retry the operation
    ///     await Future.delayed(Duration(seconds: 1));
    ///     await context.eval(code: code);
    ///   } else {
    ///     // Fatal error, cannot recover
    ///     rethrow;
    ///   }
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
            JsError::MemoryLimit { current, limit } => {
                write!(
                    f,
                    "Memory limit exceeded: {} bytes used, {} bytes limit",
                    current, limit
                )
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
        JsError::Generic(err.to_string())
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
        match &err {
            rquickjs::Error::Exception => JsError::Runtime(err.to_string()),
            _ => JsError::Runtime(err.to_string()),
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
    /// `Ok(value)` if Ok, `Err(anyhow::Error)` if Err
    #[frb(ignore)]
    pub fn into_result(self) -> anyhow::Result<super::value::JsValue> {
        match self {
            JsResult::Ok(v) => Ok(v),
            JsResult::Err(e) => Err(anyhow::anyhow!("{}", e)),
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
