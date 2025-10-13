// Test script to verify copy functionality works with actual content
console.log("=== Copy Functionality Test ===");

// Generate some test output that would be good for copying
const testResults = {
  basic: "Hello, World! This is a test result.",
  object: {
    name: "FJS Test",
    version: "1.1.0",
    features: ["console", "copy", "clipboard"],
    timestamp: new Date().toISOString()
  },
  array: [1, 2, 3, 4, 5, "test", { nested: true }],
  multiline: `This is a multiline string
that spans multiple lines
and contains various content:
- Numbers: 123, 456
- Strings: "hello", "world"
- Objects: { key: "value" }
- Arrays: [1, 2, 3]

Perfect for testing copy functionality!`,
  json_output: JSON.stringify({
    status: "success",
    data: {
      message: "Copy functionality test completed",
      results: ["All systems working", "Buttons visible", "Clipboard active"],
      metadata: {
        timestamp: new Date().toISOString(),
        platform: typeof process !== 'undefined' ? process.platform : "browser"
      }
    }
  }, null, 2)
};

// Display different types of content that users might want to copy
console.log("1. Basic result:");
console.log(testResults.basic);

console.log("\n2. Object result:");
console.log(JSON.stringify(testResults.object, null, 2));

console.log("\n3. Array result:");
console.log(JSON.stringify(testResults.array, null, 2));

console.log("\n4. Multiline result:");
console.log(testResults.multiline);

console.log("\n5. JSON output (formatted):");
console.log(testResults.json_output);

// Test some mathematical operations that produce copy-worthy results
const mathResults = {
  fibonacci: [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144],
  prime: [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47],
  calculations: {
    sum: Array.from({length: 100}, (_, i) => i + 1).reduce((a, b) => a + b, 0),
    factorial5: 120,
    pi_approx: Math.PI,
    sqrt2: Math.sqrt(2)
  }
};

console.log("\n6. Mathematical results:");
console.log("Fibonacci sequence:", mathResults.fibonacci.join(", "));
console.log("Prime numbers:", mathResults.prime.join(", "));
console.log("Calculations:");
Object.entries(mathResults.calculations).forEach(([key, value]) => {
  console.log(`  ${key}: ${value}`);
});

// Test error handling (for testing copy error messages)
console.log("\n7. Error simulation (for testing copy on errors):");
try {
  throw new Error("This is a simulated error for testing copy functionality with error messages.");
} catch (error) {
  console.log("Error caught:", error.message);
  console.log("Stack trace:", error.stack || "No stack trace available");
}

console.log("\n=== Copy Functionality Test Completed ===");
console.log("You can now test copying any of the above results using the copy button!");
console.log("The copy button should appear next to the result when there is content to copy.");
