// Module Mode - Streams and Compression
// Stream and compression examples

import { ReadableStream } from "stream/web";
import { StringDecoder } from "string_decoder";

// Create ReadableStream
const stream = new ReadableStream({
  start(controller) {
    controller.enqueue("Hello ");
    controller.enqueue("from ");
    controller.enqueue("FJS!");
    controller.close();
  }
});

// Read stream
const reader = stream.getReader();
let result = "";
while (true) {
  const { done, value } = await reader.read();
  if (done) break;
  result += value;
}

const result = {
  streamContent: result
};

console.log(result);
