// TTY module test
import { isatty } from "tty";

console.log("=== TTY Module Test ===");

// Test isatty function
try {
  // Test stdin (file descriptor 0)
  const isStdinTty = isatty(0);
  console.log("✓ isatty(0) for stdin:", isStdinTty);
  
  // Test stdout (file descriptor 1)
  const isStdoutTty = isatty(1);
  console.log("✓ isatty(1) for stdout:", isStdoutTty);
  
  // Test stderr (file descriptor 2)
  const isStderrTty = isatty(2);
  console.log("✓ isatty(2) for stderr:", isStderrTty);
  
  console.log("✓ isatty function working correctly");
} catch (e) {
  console.log("⚠ isatty function failed:", e.message);
}

// Test with invalid file descriptors
try {
  const isInvalidTty = isatty(-1);
  console.log("✓ isatty with invalid FD:", isInvalidTty);
} catch (e) {
  console.log("⚠ isatty with invalid FD failed (expected):", e.message);
}

// Test with different file descriptor values
try {
  const testCases = [0, 1, 2, 3, 100, -1];
  console.log("✓ Testing various file descriptors:");
  testCases.forEach(fd => {
    try {
      const result = isatty(fd);
      console.log(`  FD ${fd}: ${result}`);
    } catch (e) {
      console.log(`  FD ${fd}: Error - ${e.message}`);
    }
  });
} catch (e) {
  console.log("⚠ File descriptor testing failed:", e.message);
}

// Check if we can detect if running in terminal
const isTerminal = isatty(1) || isatty(2);
console.log("✓ Running in terminal:", isTerminal);

// Note: TTY module in some environments may have limited functionality
// This test focuses on the core isatty function which is most commonly available

console.log("=== TTY Module Test Completed ===");
