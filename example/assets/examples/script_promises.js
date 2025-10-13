// Script Mode - Promises and async/await
// Promise and async/await examples

// Promise chain
Promise.resolve(42)
  .then(x => x * 2)
  .then(x => x + 10)

// async/await (top-level await supported)
await Promise.all([
  Promise.resolve(1),
  Promise.resolve(2),
  Promise.resolve(3)
])
