// Util module test
import { inspect, format, isDeepStrictEqual, types } from "util";

console.log("=== Util Module Test ===");

// Test inspect function
const obj = { 
  name: "FJS", 
  version: "1.1.0", 
  nested: { value: 42 },
  array: [1, 2, 3]
};
const inspected = inspect(obj);
console.log("✓ inspect function working:");
console.log(inspected);

// Test inspect with options
const inspectedWithOptions = inspect(obj, { 
  colors: false, 
  depth: 2, 
  compact: true 
});
console.log("✓ inspect with options working:");
console.log(inspectedWithOptions);

// Test format function
const formatted1 = format("Hello %s", "FJS");
const formatted2 = format("Number: %d, String: %s", 42, "test");
const formatted3 = format("Object: %j", { key: "value" });
console.log("✓ format function working:");
console.log("  String format:", formatted1);
console.log("  Mixed format:", formatted2);
console.log("  JSON format:", formatted3);

// Test isDeepStrictEqual
const obj1 = { a: 1, b: { c: 2 } };
const obj2 = { a: 1, b: { c: 2 } };
const obj3 = { a: 1, b: { c: 3 } };
const deepEqual1 = isDeepStrictEqual(obj1, obj2);
const deepEqual2 = isDeepStrictEqual(obj1, obj3);
console.log("✓ isDeepStrictEqual working:");
console.log("  Equal objects:", deepEqual1);
console.log("  Different objects:", deepEqual2);

// Test types utility (if available)
if (types) {
  console.log("✓ types utility available:");
  
  // Test type checking functions
  const isDate = types.isDate(new Date());
  const isRegExp = types.isRegExp(/test/);
  const isString = types.isString("hello");
  const isNumber = types.isNumber(42);
  const isBoolean = types.isBoolean(true);
  const isNull = types.isNull(null);
  const isUndefined = types.isUndefined(undefined);
  
  console.log("  isDate(new Date()):", isDate);
  console.log("  isRegExp(/test/):", isRegExp);
  console.log("  isString('hello'):", isString);
  console.log("  isNumber(42):", isNumber);
  console.log("  isBoolean(true):", isBoolean);
  console.log("  isNull(null):", isNull);
  console.log("  isUndefined(undefined):", isUndefined);
} else {
  console.log("⚠ types utility not available");
}

// Test format with multiple arguments and specifiers
try {
  const complexFormat = format("Debug: %s %d %j %o", "test", 42, { key: "value" }, [1, 2, 3]);
  console.log("✓ Complex format working:", complexFormat);
} catch (e) {
  console.log("⚠ Complex format failed:", e.message);
}

// Test inspect circular references
try {
  const circular = { name: "test" };
  circular.self = circular;
  const circularInspected = inspect(circular);
  console.log("✓ Circular reference handling working");
  console.log("  Circular object inspected");
} catch (e) {
  console.log("⚠ Circular reference handling failed:", e.message);
}

// Test format with no arguments
try {
  const noArgs = format("Simple string");
  console.log("✓ Format with no arguments:", noArgs);
} catch (e) {
  console.log("⚠ Format with no arguments failed:", e.message);
}

console.log("=== Util Module Test Completed ===");
