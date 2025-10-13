// Very simple module availability check
console.log("=== Simple Module Check ===");

// Check if console is available
console.log("Console test:", console ? "✓ Available" : "✗ Not available");

// Check if require function exists
console.log("Require function:", typeof require !== 'undefined' ? "✓ Available" : "✗ Not available");

// Try very basic operations
try {
  // Test basic arithmetic
  const result = 1 + 1;
  console.log("Basic arithmetic:", result === 2 ? "✓ Working" : "✗ Failed");
} catch (e) {
  console.log("Basic arithmetic failed:", e.message);
}

// Test object creation
try {
  const obj = { test: true };
  console.log("Object creation:", obj.test === true ? "✓ Working" : "✗ Failed");
} catch (e) {
  console.log("Object creation failed:", e.message);
}

// Test function execution
try {
  function testFunc() { return true; }
  const result = testFunc();
  console.log("Function execution:", result === true ? "✓ Working" : "✗ Failed");
} catch (e) {
  console.log("Function execution failed:", e.message);
}

console.log("=== Simple Module Check Completed ===");
