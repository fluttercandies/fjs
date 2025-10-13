import { readFile } from "fs";
try { 
  await readFile("package.json", "utf8"); 
} catch(e) { 
  "File not found" 
}
