// Script Mode - Dynamic Import
// Using dynamic import (also available in Script mode)

// Dynamic import crypto module
(async () => {
  const crypto = (await import("crypto")).default;
  const hash = crypto.createHash("sha256");
  hash.update("Hello FJS");
  return hash.digest("hex");
})()

// Dynamic import with destructuring
(async () => {
  const { join, dirname } = await import("path");
  return {
    joined: join("/home", "user", "file.txt"),
    dir: dirname("/home/user/file.txt")
  };
})()
