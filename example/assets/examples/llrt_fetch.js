try { 
  const response = await fetch("https://api.github.com/repos/fluttercandies/fjs");
  response.status; 
} catch(e) { 
  "Request failed" 
}
