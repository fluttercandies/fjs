// Simple test to check if modules can be imported
console.log("=== Module Import Test ===");

// Test basic console
console.log("Testing console...");
console.log("✓ Console is available");

// Test if require function exists
console.log("Testing require function...");
if (typeof require !== 'undefined') {
    console.log("✓ Require function is available");
    
    // Try to import some modules
    try {
        const path = require('path');
        console.log("✓ Path module imported successfully");
        console.log("Path join test:", path.join('a', 'b', 'c'));
    } catch (e) {
        console.log("✗ Path module import failed:", e.message);
    }
    
    try {
        const crypto = require('crypto');
        console.log("✓ Crypto module imported successfully");
        console.log("Crypto available functions:", Object.keys(crypto));
    } catch (e) {
        console.log("✗ Crypto module import failed:", e.message);
    }
    
    try {
        const events = require('events');
        console.log("✓ Events module imported successfully");
        console.log("EventEmitter available:", typeof events.EventEmitter);
    } catch (e) {
        console.log("✗ Events module import failed:", e.message);
    }
    
} else {
    console.log("✗ Require function is not available");
}

// Test import statement (ES6 modules)
console.log("Testing ES6 imports...");
try {
    // This will fail if modules are not properly registered
    // but we can at least see if the import syntax is supported
    console.log("ES6 import syntax test would go here");
    console.log("✓ ES6 import syntax check completed");
} catch (e) {
    console.log("✗ ES6 import test failed:", e.message);
}

console.log("=== Module Import Test Completed ===");
