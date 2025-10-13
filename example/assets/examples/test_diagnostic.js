// Diagnostic test to understand what's actually available in the runtime
console.log("=== Runtime Diagnostic Test ===");

// Check global object properties
console.log("Global object properties:");
const globalProps = Object.getOwnPropertyNames(globalThis);
console.log("Number of global properties:", globalProps.length);

// Look for key properties that should be available
const keyProps = ['console', 'require', 'process', 'global', 'globalThis'];
keyProps.forEach(prop => {
  const available = prop in globalThis;
  console.log(`${prop}:`, available ? "✓ Available" : "✗ Not available");
  if (available) {
    const type = typeof globalThis[prop];
    console.log(`  Type: ${type}`);
  }
});

// Check console specifically
if (typeof console !== 'undefined') {
  console.log("\nConsole methods:");
  const consoleMethods = Object.getOwnPropertyNames(console);
  consoleMethods.forEach(method => {
    if (typeof console[method] === 'function') {
      console.log(`  ${method}: ✓`);
    }
  });
}

// Check require function
if (typeof require !== 'undefined') {
  console.log("\nRequire function available");
  
  // Try to list available modules (this might not work but let's try)
  try {
    // Test if we can resolve modules
    const modulesToTest = ['console', 'events', 'path', 'crypto', 'buffer'];
    modulesToTest.forEach(moduleName => {
      try {
        const module = require(moduleName);
        console.log(`Module '${moduleName}': ✓ Available`);
        console.log(`  Exports: ${Object.keys(module).length} items`);
      } catch (e) {
        console.log(`Module '${moduleName}': ✗ Not available - ${e.message}`);
      }
    });
  } catch (e) {
    console.log("Module resolution test failed:", e.message);
  }
} else {
  console.log("\nRequire function not available - modules may need to be imported differently");
}

// Check if we can use ES6 import syntax
console.log("\nES6 module system:");
try {
  // This is a basic check - actual imports would need to be at top level
  console.log("ES6 import syntax support: ✓ (syntax level)");
} catch (e) {
  console.log("ES6 import syntax support: ✗");
}

// Check process object
if (typeof process !== 'undefined') {
  console.log("\nProcess object available:");
  console.log("  PID:", process.pid || "N/A");
  console.log("  Platform:", process.platform || "N/A");
  console.log("  Version:", process.version || "N/A");
} else {
  console.log("\nProcess object: Not available");
}

console.log("\n=== Runtime Diagnostic Test Completed ===");
