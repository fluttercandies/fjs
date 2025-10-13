import crypto from "crypto";
const hmac = crypto.createHmac("sha256", "secret-key");
hmac.update("Hello FJS");
hmac.digest("hex")
