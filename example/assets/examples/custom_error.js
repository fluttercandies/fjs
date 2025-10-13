class CustomError extends Error { 
  constructor(msg) { 
    super(msg); 
    this.name = "CustomError"; 
  } 
} 
throw new CustomError("Something went wrong")
