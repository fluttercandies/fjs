// Path module example for FJS
// This script demonstrates the usage of the path module

import { join, dirname, basename, extname, parse, resolve, relative } from "path";

console.log("=== FJS Path Module Example ===");

// Basic path joining
const path1 = "/home";
const path2 = "user";
const path3 = "documents";
const joined = join(path1, path2, path3);
console.log(`Joined path: ${joined}`);

// Extract directory name
const dir = dirname("/home/user/documents/file.txt");
console.log(`Directory: ${dir}`);

// Extract base name
const base = basename("/home/user/documents/file.txt");
console.log(`Base name: ${base}`);

// Extract extension
const ext = extname("/home/user/documents/file.txt");
console.log(`Extension: ${ext}`);

// Parse path components
const parsed = parse("/home/user/documents/file.txt");
console.log("Parsed path:");
console.log(`  Root: ${parsed.root}`);
console.log(`  Dir: ${parsed.dir}`);
console.log(`  Base: ${parsed.base}`);
console.log(`  Name: ${parsed.name}`);
console.log(`  Ext: ${parsed.ext}`);

// Resolve absolute path
const resolved = resolve("project", "src", "index.js");
console.log(`Resolved path: ${resolved}`);

// Calculate relative path
const from = "/home/user/documents";
const to = "/home/user/downloads";
const relativePath = relative(from, to);
console.log(`Relative path from '${from}' to '${to}': ${relativePath}`);

// Working with different path separators
const windowsPath = "C:\\Users\\name\\file.txt";
const normalized = join("users", "name", "file.txt");
console.log(`Normalized path: ${normalized}`);

console.log("=== Path module example completed ===");
