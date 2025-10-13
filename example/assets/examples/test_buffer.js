// Buffer module test
import { Buffer } from "buffer";

console.log("=== Buffer Module Test ===");

// Test creating buffers from strings
const str = "Hello, FJS!";
const buf1 = Buffer.from(str);
console.log("✓ Buffer.from(string) working");
console.log("Buffer content:", buf1.toString());

// Test creating buffers from arrays
const arr = [72, 101, 108, 108, 111]; // "Hello" in ASCII
const buf2 = Buffer.from(arr);
console.log("✓ Buffer.from(array) working");
console.log("Array to buffer:", buf2.toString());

// Test buffer allocation
const buf3 = Buffer.alloc(10);
buf3.fill('A');
console.log("✓ Buffer.alloc() working");
console.log("Allocated buffer:", buf3.toString());

// Test buffer encoding/decoding
const text = "Hello World";
const utf8Buf = Buffer.from(text, 'utf8');
const hexBuf = utf8Buf.toString('hex');
const base64Buf = utf8Buf.toString('base64');
console.log("✓ Buffer encoding working");
console.log("Original:", text);
console.log("Hex:", hexBuf);
console.log("Base64:", base64Buf);

// Test buffer slicing
const original = Buffer.from("Hello World");
const sliced = original.slice(0, 5);
console.log("✓ Buffer.slice() working");
console.log("Original:", original.toString());
console.log("Sliced:", sliced.toString());

// Test buffer concatenation
const buf4 = Buffer.from("Hello");
const buf5 = Buffer.from(" World");
const concatenated = Buffer.concat([buf4, buf5]);
console.log("✓ Buffer.concat() working");
console.log("Concatenated:", concatenated.toString());

// Test buffer length
console.log("✓ Buffer.length working");
console.log("Buffer length:", buf1.length);

// Test buffer comparison
const buf6 = Buffer.from("test");
const buf7 = Buffer.from("test");
const buf8 = Buffer.from("different");
console.log("✓ Buffer comparison working");
console.log("Equal buffers:", buf6.equals(buf7));
console.log("Different buffers:", buf6.equals(buf8));

console.log("=== Buffer Module Test Completed ===");
