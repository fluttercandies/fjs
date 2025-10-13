// Test script specifically designed for the homepage copy functionality
// This script generates various types of results that users would want to copy

console.log("=== Homepage Copy Functionality Test ===");

// Generate a comprehensive test result that would be useful to copy
const testResults = {
  basic: "Hello from FJS JavaScript Runtime!",
  timestamp: new Date().toISOString(),
  math: {
    calculation: "42 * 17 = 714",
    formula: "Math.sqrt(144) = 12",
    complex: "Math.PI.toFixed(4) = 3.1416"
  },
  data: {
    user: {
      name: "Flutter Developer",
      version: "1.1.0",
      platform: typeof process !== 'undefined' ? process.platform : "browser"
    },
    features: ["JavaScript Execution", "Copy Results", "Code Examples", "Node.js Modules"]
  },
  json: JSON.stringify({
    framework: "Flutter",
    engine: "QuickJS", 
    version: "1.1.0",
    features: {
      execution: true,
      copy: true,
      examples: true
    },
    modules: ["console", "assert", "crypto", "events", "path", "util"]
  }, null, 2)
};

// Display results in a format that's easy to copy
console.log("📋 Basic Results:");
console.log(testResults.basic);
console.log("⏰ Timestamp:", testResults.timestamp);

console.log("\n🔢 Mathematical Results:");
Object.entries(testResults.math).forEach(([key, value]) => {
  console.log(`  ${value}`);
});

console.log("\n👤 User Data:");
console.log(`Name: ${testResults.data.user.name}`);
console.log(`Version: ${testResults.data.user.version}`);
console.log(`Platform: ${testResults.data.user.platform}`);
console.log(`Features: ${testResults.data.features.join(', ')}`);

console.log("\n📄 Formatted JSON Output:");
console.log(testResults.json);

// Test some string operations that generate copy-worthy results
console.log("\n🔤 String Operations:");
const greeting = "FJS - Flutter JavaScript Runtime";
console.log("Original:", greeting);
console.log("Uppercase:", greeting.toUpperCase());
console.log("Reversed:", greeting.split('').reverse().join(''));
console.log("Words:", greeting.split(' '));

// Test array operations
console.log("\n📊 Array Operations:");
const numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
console.log("Numbers:", numbers);
console.log("Doubled:", numbers.map(n => n * 2));
console.log("Even numbers:", numbers.filter(n => n % 2 === 0));
console.log("Sum:", numbers.reduce((a, b) => a + b, 0));

// Generate a formatted table-like output
console.log("\n📋 Formatted Table:");
const tableData = [
  { name: "Console", status: "✅ Available", usage: "console.log()" },
  { name: "Math", status: "✅ Available", usage: "Math.sqrt(16)" },
  { name: "Date", status: "✅ Available", usage: "new Date()" },
  { name: "JSON", status: "✅ Available", usage: "JSON.stringify()" }
];

console.log("Module | Status | Usage");
console.log("-------|--------|------");
tableData.forEach(row => {
  console.log(`${row.name.padEnd(7)} | ${row.status.padEnd(8)} | ${row.usage}`);
});

// Create a multi-line result that's perfect for testing copy functionality
console.log("\n📄 Multi-line Report:");
console.log(`
===============================
 FJS Runtime Test Report
===============================
Execution Time: ${new Date().toISOString()}
Platform: ${typeof process !== 'undefined' ? process.platform : "Unknown"}
JavaScript Engine: QuickJS
Copy Status: ✅ Working
Features Tested:
- Basic output
- Mathematical calculations
- String operations
- Array manipulation
- JSON formatting
- Table generation
===============================
All tests completed successfully!
===============================
`);

// Test error handling (for copy error scenarios)
console.log("\n❌ Error Simulation:");
try {
  throw new Error("This is a simulated error for testing copy functionality with error messages.");
} catch (error) {
  console.log("Error:", error.message);
  console.log("Type:", error.constructor.name);
  if (error.stack) {
    console.log("Stack Trace Available: Yes");
  }
}

console.log("\n🎯 Test Complete!");
console.log("You can now test copying these results using the copy button!");
console.log("The copy button should appear next to both the code and result sections.");

// Generate a final comprehensive result
const finalResult = {
  summary: "FJS Homepage Copy Test",
  features: ["Code Copy", "Result Copy", "Visual Feedback", "Error Handling"],
  status: "✅ All Working",
  timestamp: new Date().toISOString(),
  recommendations: [
    "Try copying the JavaScript code above",
    "Copy various types of results",
    "Test with different content lengths",
    "Verify copy button state changes"
  ]
};

console.log("\n📝 Final Summary:");
console.log(JSON.stringify(finalResult, null, 2));
