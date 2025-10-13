// Crypto module example for FJS
// This script demonstrates the usage of the crypto module

import crypto from "crypto";

console.log("=== FJS Crypto Module Example ===");

// Create a hash using SHA-256
const data = "Hello, FJS Flutter JavaScript Runtime!";
const hash = crypto.createHash("sha256");
hash.update(data);
const hashResult = hash.digest("hex");
console.log(`SHA-256 hash: ${hashResult}`);

// Create an HMAC
const hmac = crypto.createHmac("sha256", "secret-key");
hmac.update("message to sign");
const hmacResult = hmac.digest("hex");
console.log(`HMAC-SHA256: ${hmacResult}`);

// Generate random bytes
const randomBytes = crypto.randomBytes(16);
console.log(`Random bytes (hex): ${randomBytes.toString("hex")}`);

// Timing-safe comparison
const string1 = "secure_string";
const string2 = "secure_string";
const timingSafe = crypto.timingSafeEqual(
  Buffer.from(string1),
  Buffer.from(string2)
);
console.log(`Timing-safe comparison: ${timingSafe}`);

console.log("=== Crypto module example completed ===");
