//! # FJS Unit Tests
//!
//! This module contains comprehensive unit tests for the FJS library,
//! covering value conversion, runtime management, engine operations,
//! module loading, error handling, and boundary conditions.

#[cfg(test)]
mod value_tests;

#[cfg(test)]
mod runtime_tests;

#[cfg(test)]
mod engine_tests;

#[cfg(test)]
mod module_tests;

#[cfg(test)]
mod error_tests;

#[cfg(test)]
mod boundary_tests;

#[cfg(test)]
mod async_tests;

#[cfg(test)]
mod memory_tests;

#[cfg(test)]
mod llrt_module_tests;

/// Test helper utilities
#[cfg(test)]
pub mod test_utils {
    use rquickjs::{Context, Ctx, Runtime};

    /// Runs a test with a JavaScript context.
    ///
    /// Creates a new runtime and context, then executes the provided function
    /// within the context. This is the standard pattern for most JS tests.
    #[allow(dead_code)]
    pub fn test_with<F>(f: F)
    where
        F: FnOnce(Ctx),
    {
        let rt = Runtime::new().unwrap();
        let ctx = Context::full(&rt).unwrap();
        ctx.with(|ctx| f(ctx));
    }

    /// Creates a test runtime with default settings.
    #[allow(dead_code)]
    pub fn create_test_runtime() -> Runtime {
        Runtime::new().unwrap()
    }

    /// Creates a test context from a runtime.
    #[allow(dead_code)]
    pub fn create_test_context(rt: &Runtime) -> Context {
        Context::full(rt).unwrap()
    }
}
