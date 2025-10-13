try { 
  JSON.parse("invalid json"); 
} catch(e) { 
  "Error: " + e.message 
}
