// Module Mode - Named Import
// Named imports

import { join, dirname, basename } from "path";
import { inspect, format } from "util";

// Use path
const fullPath = join("/home", "user", "documents", "file.txt");
const fileName = basename(fullPath);
const directory = dirname(fullPath);

// Use util
const inspected = inspect({ name: "FJS", version: "1.1" });
const formattedString = format("Hello %s v%s", "FJS", "1.1");

// Create additional path examples
const resolvedPath = join(directory, "config", "settings.json");

const result = {
  pathOperations: {
    fullPath: fullPath,
    fileName: fileName,
    directory: directory,
    resolved: resolvedPath
  },
  utilOperations: {
    inspected: inspected,
    formatted: formattedString
  }
};

console.log(result);
