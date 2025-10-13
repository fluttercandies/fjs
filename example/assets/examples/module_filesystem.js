// Module Mode - File System Operations
// File system operations

import { readFile, writeFile, readdir } from "fs/promises";

// Note: These operations may need permissions in real environment
try {
  // Try to read file
  const content = await readFile("package.json", "utf8");
  const result = {
    success: true,
    content: JSON.parse(content)
  };
  console.log(result);
} catch (e) {
  const result = {
    success: false,
    error: "File not found or permission denied",
    message: e.message
  };
  console.log(result);
}
