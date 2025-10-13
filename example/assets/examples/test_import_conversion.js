// 测试各种 import 语句的自动转换
// 这个文件演示了如何在 example playground 中使用 import 语句

// ========================================
// 1. 默认导入 (Default Import)
// ========================================
import assert from "assert";
import crypto from "crypto";
import zlib from "zlib";

// ========================================
// 2. 命名导入 (Named Import)
// ========================================
import { EventEmitter } from "events";
import { join, dirname, basename } from "path";
import { inspect, format } from "util";
import { Buffer } from "buffer";
import { URL, URLSearchParams } from "url";

// ========================================
// 3. 使用导入的模块
// ========================================

// 测试 assert
assert.ok(true, "Assert works!");

// 测试 crypto
const hash = crypto.createHash("sha256");
hash.update("Hello FJS");
const hashResult = hash.digest("hex");

// 测试 events
const emitter = new EventEmitter();
emitter.on("test", (data) => console.log("Received:", data));
emitter.emit("test", "Hello Events!");

// 测试 path
const fullPath = join("/home", "user", "documents", "file.txt");
const dir = dirname(fullPath);
const base = basename(fullPath);

// 测试 util
const obj = { name: "FJS", version: "1.1", features: ["JS", "Async"] };
const inspected = inspect(obj, { colors: true, depth: 2 });
const formatted = format("Hello %s v%s", obj.name, obj.version);

// 测试 Buffer
const buf = Buffer.from("Hello FJS", "utf8");
const hex = buf.toString("hex");

// 测试 URL
const url = new URL("https://github.com/fluttercandies/fjs");
const hostname = url.hostname;

// ========================================
// 4. 返回测试结果
// ========================================
({
  success: true,
  tests: {
    assert: "✓ Passed",
    crypto: `✓ Hash: ${hashResult.substring(0, 16)}...`,
    events: "✓ Event emitted",
    path: `✓ Path: ${fullPath}`,
    util: `✓ Formatted: ${formatted}`,
    buffer: `✓ Hex: ${hex}`,
    url: `✓ Hostname: ${hostname}`,
  },
  message: "All imports were successfully converted and executed!"
})
