// Module Mode - Comprehensive Example
// Complete example using multiple modules

import crypto from "crypto";
import { Buffer } from "buffer";
import { join } from "path";
import { inspect } from "util";
import async_hooks from "async_hooks";

// Create data
const data = {
  timestamp: Date.now(),
  asyncId: async_hooks.executionAsyncId(),
  path: join("/tmp", "test.txt")
};

// Encrypt data
const cipher = crypto.createHash("sha256");
cipher.update(JSON.stringify(data));
const encrypted = cipher.digest("hex");

// Create buffer examples
const textBuffer = Buffer.from("Hello FJS", "utf8");
const hexBuffer = Buffer.from("4a61766153736372697074", "hex");

// Return complete result
const result = {
  originalData: data,
  encrypted: encrypted.substring(0, 32) + "...",
  textBufferHex: textBuffer.toString("hex"),
  hexBufferText: hexBuffer.toString("utf8"),
  bufferSizes: {
    text: textBuffer.length,
    hex: hexBuffer.length
  },
  inspection: inspect(data, { colors: false, depth: 2 })
};

console.log(result);
