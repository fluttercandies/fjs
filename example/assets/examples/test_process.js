// Process module test
console.log("=== Process Module Test ===");

// Test basic process information
const pid = process.pid;
const ppid = process.ppid;
const title = process.title;
console.log("✓ Basic process info:");
console.log("  PID:", pid);
console.log("  PPID:", ppid);
console.log("  Title:", title);

// Test platform and architecture
const platform = process.platform;
const arch = process.arch;
console.log("✓ Platform info:");
console.log("  Platform:", platform);
console.log("  Architecture:", arch);

// Test Node.js version compatibility
const nodeVersion = process.version;
const versions = process.versions;
console.log("✓ Version info:");
console.log("  Process version:", nodeVersion);
console.log("  Available versions:", Object.keys(versions).length > 0);

// Test environment variables
const env = process.env;
const pathEnv = env.PATH || env.Path;
const homeEnv = env.HOME || env.USERPROFILE;
console.log("✓ Environment variables:");
console.log("  PATH available:", !!pathEnv);
console.log("  Home directory available:", !!homeEnv);

// Test current working directory
const cwd = process.cwd();
console.log("✓ Current working directory:", cwd);

// Test process arguments
const argv = process.argv;
console.log("✓ Process arguments:");
console.log("  Argument count:", argv.length);
console.log("  Script name:", argv[0] || "N/A");

// Test execution time
const hrtime = process.hrtime();
const hrtimeBigint = process.hrtime.bigint();
console.log("✓ High resolution time:");
console.log("  hrtime array:", hrtime);
console.log("  hrtime bigint:", hrtimeBigint);

// Test memory usage (if available)
try {
  const memUsage = process.memoryUsage();
  console.log("✓ Memory usage:");
  console.log("  RSS:", memUsage.rss);
  console.log("  Heap total:", memUsage.heapTotal);
  console.log("  Heap used:", memUsage.heapUsed);
} catch (e) {
  console.log("⚠ Memory usage not available:", e.message);
}

// Test uptime
try {
  const uptime = process.uptime();
  console.log("✓ Process uptime:", uptime, "seconds");
} catch (e) {
  console.log("⚠ Uptime not available:", e.message);
}

// Test nextTick (if available)
try {
  let tickExecuted = false;
  process.nextTick(() => {
    tickExecuted = true;
  });
  // Note: This is async, so we can't test it synchronously
  console.log("✓ process.nextTick called (async)");
} catch (e) {
  console.log("⚠ process.nextTick not available:", e.message);
}

// Test exit code handling
const currentExitCode = process.exitCode;
console.log("✓ Exit code handling available");
console.log("  Current exit code:", currentExitCode);

console.log("=== Process Module Test Completed ===");
