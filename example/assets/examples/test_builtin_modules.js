// Test to verify builtin modules are now properly registered
console.log("=== Builtin Modules Test ===");

// Test 1: Console module (should always be available if builtin modules are working)
console.log("1. Testing console module:");
try {
  console.log("   ✓ console.log() working");
  console.info("   ✓ console.info() working");
  console.warn("   ✓ console.warn() working");
  console.error("   ✓ console.error() working");
} catch (e) {
  console.log("   ✗ Console module failed:", e.message);
}

// Test 2: Try to import and use assert module
console.log("2. Testing assert module:");
try {
  const assert = require('assert');
  assert.ok(true, "Basic assertion should pass");
  assert.strictEqual(1, 1, "Strict equality should pass");
  console.log("   ✓ Assert module working");
} catch (e) {
  console.log("   ✗ Assert module failed:", e.message);
}

// Test 3: Try to import and use path module
console.log("3. Testing path module:");
try {
  const path = require('path');
  const joined = path.join('home', 'user', 'file.txt');
  const dirname = path.dirname('/home/user/file.txt');
  console.log("   ✓ Path module working");
  console.log(`   - Joined path: ${joined}`);
  console.log(`   - Dirname: ${dirname}`);
} catch (e) {
  console.log("   ✗ Path module failed:", e.message);
}

// Test 4: Try to import and use events module
console.log("4. Testing events module:");
try {
  const events = require('events');
  const EventEmitter = events.EventEmitter;
  const emitter = new EventEmitter();
  let eventFired = false;
  emitter.on('test', () => { eventFired = true; });
  emitter.emit('test');
  console.log("   ✓ Events module working");
  console.log(`   - Event fired: ${eventFired}`);
} catch (e) {
  console.log("   ✗ Events module failed:", e.message);
}

// Test 5: Try to import and use crypto module
console.log("5. Testing crypto module:");
try {
  const crypto = require('crypto');
  const hash = crypto.createHash('sha256');
  hash.update('test');
  const digest = hash.digest('hex');
  console.log("   ✓ Crypto module working");
  console.log(`   - SHA256 hash (first 16 chars): ${digest.substring(0, 16)}...`);
} catch (e) {
  console.log("   ✗ Crypto module failed:", e.message);
}

// Test 6: Try to import and use buffer module
console.log("6. Testing buffer module:");
try {
  const buffer = require('buffer');
  const Buffer = buffer.Buffer;
  const buf = Buffer.from('Hello, World!');
  const encoded = buf.toString('hex');
  console.log("   ✓ Buffer module working");
  console.log(`   - Buffer hex: ${encoded.substring(0, 16)}...`);
} catch (e) {
  console.log("   ✗ Buffer module failed:", e.message);
}

// Test 7: Try to import and use process module
console.log("7. Testing process module:");
try {
  const process = require('process');
  console.log("   ✓ Process module working");
  console.log(`   - PID: ${process.pid || 'N/A'}`);
  console.log(`   - Platform: ${process.platform || 'N/A'}`);
} catch (e) {
  console.log("   ✗ Process module failed:", e.message);
}

// Test 8: Check if other modules are importable (even if we don't test functionality)
console.log("8. Testing module availability:");
const modulesToCheck = [
  'timers', 'async_hooks', 'tty', 'util', 'zlib', 'url', 
  'fs', 'net', 'dns', 'child_process', 'perf_hooks'
];

modulesToCheck.forEach(moduleName => {
  try {
    const module = require(moduleName);
    console.log(`   ✓ ${moduleName} module available`);
  } catch (e) {
    console.log(`   ✗ ${moduleName} module not available: ${e.message}`);
  }
});

console.log("\n=== Summary ===");
console.log("If you see many ✓ marks above, the builtin modules are working correctly!");
console.log("If you see many ✗ marks, there may still be an issue with module registration.");
console.log("=== Builtin Modules Test Completed ===");
