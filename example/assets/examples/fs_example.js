// File System module example for FJS
// This script demonstrates the usage of the fs module

import fs from "fs";
import path from "path";

console.log("=== FJS File System Module Example ===");

try {
  // Check current working directory
  const cwd = process.cwd();
  console.log(`Current working directory: ${cwd}`);

  // Create a test directory
  const testDir = path.join(cwd, "test_output");
  try {
    fs.mkdirSync(testDir, { recursive: true });
    console.log(`Created directory: ${testDir}`);
  } catch (err) {
    console.log(`Directory already exists or creation failed: ${err.message}`);
  }

  // Write a file
  const testFile = path.join(testDir, "hello.txt");
  const content = "Hello from FJS JavaScript Runtime!";
  fs.writeFileSync(testFile, content, "utf8");
  console.log(`Wrote file: ${testFile}`);

  // Read the file
  const readContent = fs.readFileSync(testFile, "utf8");
  console.log(`File content: ${readContent}`);

  // Check if file exists
  const fileExists = fs.existsSync(testFile);
  console.log(`File exists: ${fileExists}`);

  // Get file stats
  const stats = fs.statSync(testFile);
  console.log(`File size: ${stats.size} bytes`);
  console.log(`Last modified: ${new Date(stats.mtimeMs).toISOString()}`);

  // List directory contents
  const files = fs.readdirSync(cwd);
  console.log(`Files in current directory: ${files.length}`);
  files.slice(0, 5).forEach(file => {
    console.log(`  - ${file}`);
  });

  console.log("=== FS module example completed ===");
} catch (error) {
  console.error(`Error in FS example: ${error.message}`);
}
