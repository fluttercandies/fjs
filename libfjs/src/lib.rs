//! # FJS - Flutter JavaScript Engine
//!
//! This library provides a Flutter-compatible JavaScript runtime environment
//! built on top of the QuickJS engine. It enables execution of JavaScript code
//! within Flutter applications with support for both synchronous and asynchronous
//! operations, module systems, and bidirectional communication between Dart and JavaScript.
//!
//! ## Features
//!
//! - Synchronous and asynchronous JavaScript execution
//! - Module system support (ES6 modules and CommonJS)
//! - Built-in Node.js compatibility modules
//! - Memory management and garbage collection control
//! - Bidirectional Dart-JavaScript communication
//! - Error handling and debugging capabilities
//!
//! ## Architecture
//!
//! The library is organized into several key components:
//!
//! - **Runtime Management**: Core runtime and context handling
//! - **Value Conversion**: Type-safe conversion between Dart and JavaScript values
//! - **Module System**: Dynamic module loading and resolution
//! - **Error Handling**: Comprehensive error types and propagation
//!
//! ## Usage
//!
//! ```rust
//! use libfjs::api::js::{JsRuntime, JsContext};
//!
//! // Create a runtime and context
//! let runtime = JsRuntime::new()?;
//! let context = JsContext::new(&runtime)?;
//!
//! // Execute JavaScript code
//! let result = context.eval("console.log('Hello, World!'); 42;")?;
//! ```

pub mod api;
mod frb_generated;

#[cfg(test)]
mod tests;
