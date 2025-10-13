// Script Mode - Complex Example
// Combined usage example

(async () => {
  // Use dynamic import
  const { Buffer } = await import("buffer");
  
  // Create Buffer
  const buf = Buffer.from("Hello FJS", "utf8");
  
  // Convert to different formats
  return {
    original: "Hello FJS",
    hex: buf.toString("hex"),
    base64: buf.toString("base64"),
    length: buf.length
  };
})()
