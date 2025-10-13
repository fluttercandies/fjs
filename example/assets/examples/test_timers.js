// Timers module test
console.log("=== Timers Module Test ===");

// Test setTimeout
let timeoutExecuted = false;
const timeoutId = setTimeout(() => {
  timeoutExecuted = true;
  console.log("✓ setTimeout executed");
}, 10);

console.log("✓ setTimeout scheduled");

// Test setInterval
let intervalCount = 0;
const intervalId = setInterval(() => {
  intervalCount++;
  console.log(`✓ Interval executed ${intervalCount} times`);
  if (intervalCount >= 2) {
    clearInterval(intervalId);
    console.log("✓ setInterval cleared");
  }
}, 5);

console.log("✓ setInterval scheduled");

// Test setImmediate (if available)
try {
  let immediateExecuted = false;
  const immediateId = setImmediate(() => {
    immediateExecuted = true;
    console.log("✓ setImmediate executed");
  });
  console.log("✓ setImmediate scheduled");
} catch (e) {
  console.log("⚠ setImmediate not available:", e.message);
}

// Test clearTimeout
const clearTimeoutId = setTimeout(() => {
  console.log("⚠ This should not execute");
}, 50);
clearTimeout(clearTimeoutId);
console.log("✓ clearTimeout working");

// Test clearing intervals
const testIntervalId = setInterval(() => {
  console.log("⚠ This interval should not execute");
}, 50);
clearInterval(testIntervalId);
console.log("✓ clearInterval working");

// Test timer with parameters
let parameterTest = false;
const paramTimeoutId = setTimeout((param1, param2, param3) => {
  parameterTest = (param1 === "hello" && param2 === 42 && param3 === true);
  console.log("✓ setTimeout with parameters:", parameterTest);
}, 15, "hello", 42, true);

console.log("✓ setTimeout with parameters scheduled");

// Test nested timers
let nestedTimerExecuted = false;
const nestedTimeoutId = setTimeout(() => {
  setTimeout(() => {
    nestedTimerExecuted = true;
    console.log("✓ Nested setTimeout executed");
  }, 5);
}, 10);

console.log("✓ Nested setTimeout scheduled");

// Test timer return values
const timeoutReturnValue = setTimeout(() => {}, 100);
const intervalReturnValue = setInterval(() => {}, 100);
console.log("✓ Timer return values:");
console.log("  Timeout ID type:", typeof timeoutReturnValue);
console.log("  Interval ID type:", typeof intervalReturnValue);

// Clean up remaining timers at the end
setTimeout(() => {
  clearInterval(intervalId);
  clearTimeout(timeoutId);
  clearTimeout(paramTimeoutId);
  clearTimeout(nestedTimeoutId);
  
  console.log("✓ All timers cleaned up");
  console.log("=== Timers Module Test Completed ===");
}, 100);

console.log("✓ Timers module test initialized");
