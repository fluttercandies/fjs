# Patched copy of dlopen2 0.9.0

Upstream 0.9.0 (https://github.com/OpenByteDev/dlopen2) removed the
`once_cell` dependency from `Cargo.toml` (commit 2665207d) but kept
`once_cell::sync::Lazy` in `src/raw/unix.rs` behind
`#[cfg(not(any(target_os = "linux", target_os = "macos")))]`, so every
other unix target — android included — fails to compile with E0433.

This vendored copy replaces that `Lazy` with `std::sync::LazyLock`
(stable since Rust 1.80; the crate declares `rust-version = "1.85"`).
That is the only source change; the crate was also trimmed to `Cargo.toml`,
`src/`, and `README.md`.

Drop this patch once upstream publishes a release that compiles for
android.
