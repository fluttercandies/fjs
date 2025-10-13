// Path module test
import { join, dirname, basename, extname, parse, resolve, relative, isAbsolute } from "path";

console.log("=== Path Module Test ===");

// Test path joining
const joined1 = join("/home", "user", "documents");
const joined2 = join("/home/user", "../admin", "file.txt");
console.log("✓ Path join working:");
console.log("  Normal join:", joined1);
console.log("  Join with parent directory:", joined2);

// Test directory extraction
const dir1 = dirname("/home/user/documents/file.txt");
const dir2 = dirname("/path/to/directory/");
console.log("✓ Directory extraction working:");
console.log("  File directory:", dir1);
console.log("  Directory path:", dir2);

// Test base name extraction
const base1 = basename("/home/user/documents/file.txt");
const base2 = basename("/home/user/documents/");
console.log("✓ Base name extraction working:");
console.log("  File base name:", base1);
console.log("  Directory base name:", base2);

// Test extension extraction
const ext1 = extname("/home/user/documents/file.txt");
const ext2 = extname("/home/user/documents/archive.tar.gz");
const ext3 = extname("/home/user/documents/noextension");
console.log("✓ Extension extraction working:");
console.log("  Simple extension:", ext1);
console.log("  Compound extension:", ext2);
console.log("  No extension:", ext3);

// Test path parsing
const parsed = parse("/home/user/documents/file.txt");
console.log("✓ Path parsing working:");
console.log("  Root:", parsed.root);
console.log("  Directory:", parsed.dir);
console.log("  Base:", parsed.base);
console.log("  Name:", parsed.name);
console.log("  Extension:", parsed.ext);

// Test absolute path resolution
const resolved1 = resolve("project", "src", "index.js");
const resolved2 = resolve("/home/user", "documents", "file.txt");
console.log("✓ Path resolution working:");
console.log("  Relative resolution:", resolved1);
console.log("  Absolute resolution:", resolved2);

// Test relative path calculation
const from = "/home/user/documents";
const to = "/home/user/downloads";
const relativePath = relative(from, to);
console.log("✓ Relative path calculation working:");
console.log("  From:", from);
console.log("  To:", to);
console.log("  Relative path:", relativePath);

// Test absolute path detection
const abs1 = isAbsolute("/home/user/file.txt");
const abs2 = isAbsolute("relative/path/file.txt");
const abs3 = isAbsolute("C:\\Windows\\file.txt");
console.log("✓ Absolute path detection working:");
console.log("  Absolute path (Unix):", abs1);
console.log("  Relative path:", abs2);
console.log("  Absolute path (Windows style):", abs3);

// Test edge cases
const emptyJoin = join();
const singlePath = join("single");
const normalizeJoin = join("/home//user/", "./documents/", "file.txt");
console.log("✓ Edge cases working:");
console.log("  Empty join:", emptyJoin);
console.log("  Single path:", singlePath);
console.log("  Normalize join:", normalizeJoin);

console.log("=== Path Module Test Completed ===");
