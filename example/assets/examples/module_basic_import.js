// Module Mode - Basic Import
// Basic import (default import)

import assert from "assert";
import crypto from "crypto";
import zlib from "zlib";

// Use assert
assert.ok(true, "Assertion passed!");

// Use crypto
const hash = crypto.createHash("sha256");
hash.update("Hello FJS");
const hashResult = hash.digest("hex");

// Output result
const result = {
  message: "Basic imports example",
  hashResult: hashResult.substring(0, 16) + "..."
};

console.log(result);
