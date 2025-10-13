// Module Mode - Network Operations
// Network operations

import { lookup } from "dns";

// DNS lookup (requires network)
try {
  const address = await new Promise((resolve, reject) => {
    lookup("github.com", (err, address) => {
      if (err) reject(err);
      else resolve(address);
    });
  });
  
  const result = {
    domain: "github.com",
    ipAddress: address
  };
  console.log(result);
} catch (e) {
  const result = {
    error: "DNS lookup failed",
    message: e.message
  };
  console.log(result);
}
