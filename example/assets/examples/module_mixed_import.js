// Module Mode - Mixed Import
// Mix of default and named imports

import async_hooks from "async_hooks";
import { Buffer } from "buffer";
import { URL, URLSearchParams } from "url";

// Use async_hooks
const asyncId = async_hooks.executionAsyncId();
const triggerId = async_hooks.triggerAsyncId();

// Use Buffer
const buf = Buffer.from("Hello FJS", "utf8");

// Use URL
const url = new URL("https://github.com/fluttercandies/fjs");

const result = {
  asyncId,
  triggerId,
  bufferHex: buf.toString("hex"),
  urlInfo: {
    hostname: url.hostname,
    pathname: url.pathname
  }
};

console.log(result);
