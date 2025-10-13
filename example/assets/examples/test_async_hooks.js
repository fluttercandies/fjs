// Async Hooks module test
import async_hooks from "async_hooks";

console.log("=== Async Hooks Module Test ===");

// Test basic async hooks functionality
const asyncId = async_hooks.executionAsyncId();
const triggerId = async_hooks.triggerAsyncId();
console.log("✓ Basic async IDs:");
console.log("  Execution async ID:", asyncId);
console.log("  Trigger async ID:", triggerId);

// Test async hooks create hook
let hookCreated = false;
let hookInitCount = 0;
let hookBeforeCount = 0;
let hookAfterCount = 0;
let hookDestroyCount = 0;

const hook = async_hooks.createHook({
  init(asyncId, type, triggerAsyncId, resource) {
    hookInitCount++;
    if (hookInitCount <= 3) { // Limit output to avoid spam
      console.log(`✓ Hook init: ${type} (ID: ${asyncId})`);
    }
  },
  before(asyncId) {
    hookBeforeCount++;
    if (hookBeforeCount <= 3) {
      console.log(`✓ Hook before: ${asyncId}`);
    }
  },
  after(asyncId) {
    hookAfterCount++;
    if (hookAfterCount <= 3) {
      console.log(`✓ Hook after: ${asyncId}`);
    }
  },
  destroy(asyncId) {
    hookDestroyCount++;
    if (hookDestroyCount <= 3) {
      console.log(`✓ Hook destroy: ${asyncId}`);
    }
  }
});

try {
  hook.enable();
  hookCreated = true;
  console.log("✓ Async hooks hook created and enabled");
} catch (e) {
  console.log("⚠ Async hooks hook creation failed:", e.message);
}

// Test async operations to trigger hooks
setTimeout(() => {
  console.log("✓ setTimeout executed (should trigger hooks)");
}, 10);

// Test Promise to trigger hooks
Promise.resolve().then(() => {
  console.log("✓ Promise resolved (should trigger hooks)");
});

// Test async_hooks executionAsyncResource (if available)
try {
  const resource = async_hooks.executionAsyncResource();
  console.log("✓ Execution async resource available");
} catch (e) {
  console.log("⚠ executionAsyncResource not available:", e.message);
}

// Test async_hooks AsyncResource class (if available)
try {
  const { AsyncResource } = async_hooks;
  const asyncResource = new AsyncResource('TEST_TYPE');
  console.log("✓ AsyncResource class available");
  
  // Test using AsyncResource
  asyncResource.runInAsyncScope(() => {
    console.log("✓ AsyncResource.runInAsyncScope executed");
  });
} catch (e) {
  console.log("⚠ AsyncResource not available:", e.message);
}

// Check hook statistics after a delay
setTimeout(() => {
  if (hookCreated) {
    console.log("✓ Hook statistics:");
    console.log("  Init calls:", hookInitCount);
    console.log("  Before calls:", hookBeforeCount);
    console.log("  After calls:", hookAfterCount);
    console.log("  Destroy calls:", hookDestroyCount);
    
    hook.disable();
    console.log("✓ Async hooks disabled");
  }
  
  console.log("=== Async Hooks Module Test Completed ===");
}, 100);

console.log("✓ Async hooks module test initialized");
