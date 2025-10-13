function counter() { 
  let count = 0; 
  return () => ++count; 
} 
const c = counter(); 
c(); 
c(); 
c()
