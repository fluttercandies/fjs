// Assert module test
import assert from "assert";

console.log("=== Assert Module Test ===");

// Test basic assertions
assert.ok(true, "Basic assertion should pass");
assert.ok(1, "Truthy value should pass");
assert.ok("hello", "Non-empty string should pass");
console.log("✓ assert.ok() working");

// Test strict equality
assert.strictEqual(42, 42, "Numbers should be strictly equal");
assert.strictEqual("hello", "hello", "Strings should be strictly equal");
console.log("✓ assert.strictEqual() working");

// Test deep equality
assert.deepEqual({ a: 1 }, { a: 1 }, "Objects should be deeply equal");
assert.deepEqual([1, 2, 3], [1, 2, 3], "Arrays should be deeply equal");
console.log("✓ assert.deepEqual() working");

// Test inequality
assert.notStrictEqual(42, "42", "Number and string should not be strictly equal");
assert.notDeepEqual({ a: 1 }, { a: 2 }, "Different objects should not be deeply equal");
console.log("✓ assert.notStrictEqual() and assert.notDeepEqual() working");

// Test throws
try {
  assert.throws(() => {
    throw new Error("Test error");
  }, /Test error/, "Should throw an error with matching message");
  console.log("✓ assert.throws() working");
} catch (e) {
  console.error("✗ assert.throws() failed:", e.message);
}

// Test doesNotThrow
try {
  assert.doesNotThrow(() => {
    return "no error";
  }, "Should not throw an error");
  console.log("✓ assert.doesNotThrow() working");
} catch (e) {
  console.error("✗ assert.doesNotThrow() failed:", e.message);
}

console.log("=== Assert Module Test Completed ===");
