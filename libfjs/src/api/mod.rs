//! # JavaScript API Module
//!
//! This module provides the core JavaScript execution API for Flutter integration.
//! It contains submodules for different aspects of JavaScript runtime management:
//!
//! - **js**: Runtime, context, and execution management
//! - **value**: Type-safe value conversion between Rust and JavaScript
//! - **module**: Module system and dynamic loading capabilities
//!
//! ## Initialization
//!
//! The `init_app()` function sets up the Flutter Rust bridge with default utilities.
//! This function should be called once during application initialization.

pub mod js;
pub mod value;
pub mod module;

/// Initializes the Flutter Rust bridge with default user utilities.
///
/// This function sets up the bridge configuration required for communication
/// between Flutter (Dart) and Rust code. It should be called once during
/// application startup before any other FJS functionality is used.
///
/// # Safety
///
/// This function is safe to call multiple times, but subsequent calls will
/// have no effect as the bridge is already initialized.
#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
