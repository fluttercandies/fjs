await (async () => { 
  const result = await Promise.resolve("Hello"); 
  return result + " World"; 
})()
