// Zlib module test
import zlib from "zlib";

console.log("=== Zlib Module Test ===");

// Test gzip compression and decompression
const originalText = "Hello, FJS JavaScript Runtime! This is a test string for compression.";
console.log("✓ Testing gzip compression/decompression:");

try {
  // Compress with gzip
  const compressed = zlib.gzipSync(originalText);
  console.log("  Original size:", originalText.length, "bytes");
  console.log("  Compressed size:", compressed.length, "bytes");
  console.log("  Compression ratio:", ((compressed.length / originalText.length) * 100).toFixed(1) + "%");
  
  // Decompress with gunzip
  const decompressed = zlib.gunzipSync(compressed);
  const decompressedText = decompressed.toString();
  console.log("  Decompressed successfully:", decompressedText === originalText);
} catch (e) {
  console.log("  ⚠ Gzip test failed:", e.message);
}

// Test deflate compression
console.log("✓ Testing deflate compression/decompression:");
try {
  const deflated = zlib.deflateSync(originalText);
  console.log("  Deflated size:", deflated.length, "bytes");
  
  const inflated = zlib.inflateSync(deflated);
  const inflatedText = inflated.toString();
  console.log("  Inflated successfully:", inflatedText === originalText);
} catch (e) {
  console.log("  ⚠ Deflate test failed:", e.message);
}

// Test brotli compression (if available)
console.log("✓ Testing brotli compression/decompression:");
try {
  const brotliCompressed = zlib.brotliCompressSync(originalText);
  console.log("  Brotli compressed size:", brotliCompressed.length, "bytes");
  
  const brotliDecompressed = zlib.brotliDecompressSync(brotliCompressed);
  const brotliText = brotliDecompressed.toString();
  console.log("  Brotli decompressed successfully:", brotliText === originalText);
} catch (e) {
  console.log("  ⚠ Brotli test failed (may not be available):", e.message);
}

// Test async compression (if available)
console.log("✓ Testing async compression:");
try {
  zlib.gzip(originalText, (err, result) => {
    if (err) {
      console.log("  ⚠ Async gzip failed:", err.message);
    } else {
      console.log("  Async gzip successful, size:", result.length, "bytes");
    }
  });
} catch (e) {
  console.log("  ⚠ Async compression not available:", e.message);
}

// Test compression with different compression levels
console.log("✓ Testing different compression levels:");
try {
  const level1 = zlib.gzipSync(originalText, { level: 1 });
  const level6 = zlib.gzipSync(originalText, { level: 6 });
  const level9 = zlib.gzipSync(originalText, { level: 9 });
  
  console.log("  Level 1 size:", level1.length, "bytes");
  console.log("  Level 6 size:", level6.length, "bytes");
  console.log("  Level 9 size:", level9.length, "bytes");
} catch (e) {
  console.log("  ⚠ Compression levels test failed:", e.message);
}

// Test compression options
console.log("✓ Testing compression with options:");
try {
  const withOptions = zlib.gzipSync(originalText, {
    level: 6,
    windowBits: 15,
    memLevel: 8
  });
  console.log("  With options size:", withOptions.length, "bytes");
} catch (e) {
  console.log("  ⚠ Compression options test failed:", e.message);
}

// Test empty string compression
console.log("✓ Testing empty string compression:");
try {
  const emptyCompressed = zlib.gzipSync("");
  const emptyDecompressed = zlib.gunzipSync(emptyCompressed);
  console.log("  Empty string compressed successfully:", emptyDecompressed.length === 0);
} catch (e) {
  console.log("  ⚠ Empty string compression failed:", e.message);
}

// Test large data compression
console.log("✓ Testing large data compression:");
try {
  const largeData = "x".repeat(1000);
  const largeCompressed = zlib.gzipSync(largeData);
  const largeDecompressed = zlib.gunzipSync(largeCompressed);
  console.log("  Large data (1000 chars) compression:");
  console.log("    Original:", largeData.length, "bytes");
  console.log("    Compressed:", largeCompressed.length, "bytes");
  console.log("    Decompressed successfully:", largeDecompressed.length === largeData.length);
} catch (e) {
  console.log("  ⚠ Large data compression failed:", e.message);
}

console.log("=== Zlib Module Test Completed ===");
