// Script Mode - Error Handling
// Error handling examples

// try-catch
try {
  JSON.parse("{invalid json}");
} catch (e) {
  ({
    error: e.message,
    handled: true
  })
}
