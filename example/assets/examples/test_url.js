// URL module test
import { URL, URLSearchParams } from "url";

console.log("=== URL Module Test ===");

// Test URL constructor and parsing
const url1 = new URL("https://github.com/fluttercandies/fjs");
console.log("✓ URL constructor working:");
console.log("  Protocol:", url1.protocol);
console.log("  Host:", url1.host);
console.log("  Hostname:", url1.hostname);
console.log("  Port:", url1.port);
console.log("  Pathname:", url1.pathname);
console.log("  Search:", url1.search);
console.log("  Hash:", url1.hash);

// Test URL with query parameters
const url2 = new URL("https://example.com/api/users?page=2&limit=10&sort=name");
console.log("✓ URL with query parameters:");
console.log("  Search:", url2.search);
console.log("  Search params:", url2.searchParams);
console.log("  Page param:", url2.searchParams.get("page"));
console.log("  Limit param:", url2.searchParams.get("limit"));

// Test URLSearchParams
const params = new URLSearchParams();
params.append("name", "FJS");
params.append("version", "1.1.0");
params.append("platform", "flutter");
console.log("✓ URLSearchParams working:");
console.log("  Created params:", params.toString());
console.log("  Get name:", params.get("name"));
console.log("  Has version:", params.has("version"));
console.log("  All keys:", Array.from(params.keys()));

// Test URL with port
const url3 = new URL("http://localhost:8080/api/test");
console.log("✓ URL with port:");
console.log("  Host:", url3.host);
console.log("  Port:", url3.port);

// Test URL with hash
const url4 = new URL("https://example.com/page#section1");
console.log("✓ URL with hash:");
console.log("  Hash:", url4.hash);
console.log("  Pathname:", url4.pathname);

// Test URL modification
const url5 = new URL("https://api.example.com/v1/users");
url5.pathname = "/v2/posts";
url5.searchParams.append("sort", "desc");
console.log("✓ URL modification:");
console.log("  Original:", "https://api.example.com/v1/users");
console.log("  Modified:", url5.toString());

// Test URL with authentication
try {
  const url6 = new URL("https://user:pass@example.com/secure");
  console.log("✓ URL with authentication:");
  console.log("  Username:", url6.username);
  console.log("  Password:", url6.password);
} catch (e) {
  console.log("⚠ URL authentication failed:", e.message);
}

// Test URL with file protocol
try {
  const url7 = new URL("file:///path/to/file.txt");
  console.log("✓ File URL:");
  console.log("  Protocol:", url7.protocol);
  console.log("  Pathname:", url7.pathname);
} catch (e) {
  console.log("⚠ File URL failed:", e.message);
}

// Test URLSearchParams iteration
const params2 = new URLSearchParams("a=1&b=2&c=3");
console.log("✓ URLSearchParams iteration:");
for (const [key, value] of params2) {
  console.log(`  ${key}: ${value}`);
}

// Test URL toString and toJSON
const url8 = new URL("https://example.com/test");
const urlString = url8.toString();
const urlJSON = url8.toJSON();
console.log("✓ URL serialization:");
console.log("  toString():", urlString);
console.log("  toJSON():", urlJSON);

// Test invalid URL handling
try {
  const invalidUrl = new URL("not-a-valid-url");
  console.log("⚠ Invalid URL should have thrown");
} catch (e) {
  console.log("✓ Invalid URL properly rejected:", e.message);
}

console.log("=== URL Module Test Completed ===");
