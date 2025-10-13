// Crypto module test
import crypto from "crypto";

console.log("=== Crypto Module Test ===");

// Test hash creation
const data = "Hello, FJS!";
const hash = crypto.createHash("sha256");
hash.update(data);
const hashResult = hash.digest("hex");
console.log("✓ SHA-256 hash working:", hashResult.substring(0, 16) + "...");

// Test different hash algorithms
const md5Hash = crypto.createHash("md5").update(data).digest("hex");
const sha1Hash = crypto.createHash("sha1").update(data).digest("hex");
console.log("✓ MD5 hash working:", md5Hash);
console.log("✓ SHA-1 hash working:", sha1Hash);

// Test HMAC
const hmac = crypto.createHmac("sha256", "secret-key");
hmac.update("message to sign");
const hmacResult = hmac.digest("hex");
console.log("✓ HMAC-SHA256 working:", hmacResult.substring(0, 16) + "...");

// Test random bytes generation
const randomBytes1 = crypto.randomBytes(8);
const randomBytes2 = crypto.randomBytes(16);
console.log("✓ Random bytes generation working");
console.log("8 bytes:", randomBytes1.toString("hex"));
console.log("16 bytes:", randomBytes2.toString("hex"));

// Test randomInt (if available)
try {
  const randomInt = crypto.randomInt(1, 10);
  console.log("✓ Random int working:", randomInt);
} catch (e) {
  console.log("⚠ Random int not available or failed:", e.message);
}

// Test timing-safe comparison
const string1 = "secure_string";
const string2 = "secure_string";
const string3 = "different_string";
const timingSafe1 = crypto.timingSafeEqual(
  Buffer.from(string1),
  Buffer.from(string2)
);
const timingSafe2 = crypto.timingSafeEqual(
  Buffer.from(string1),
  Buffer.from(string3)
);
console.log("✓ Timing-safe comparison working");
console.log("Equal strings:", timingSafe1);
console.log("Different strings:", timingSafe2);

// Test multiple updates on hash
const multiHash = crypto.createHash("sha256");
multiHash.update("Part 1 ");
multiHash.update("Part 2 ");
multiHash.update("Part 3");
const multiHashResult = multiHash.digest("hex");
console.log("✓ Multiple hash updates working:", multiHashResult.substring(0, 16) + "...");

console.log("=== Crypto Module Test Completed ===");
