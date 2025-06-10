const app = require("./app");
const dotenv = require("dotenv");

// Load environment variables
dotenv.config({ path: "./.env" });

// Initialize Firebase Admin SDK early
require("./utils/firebase");

// Set NODE_ENV to development if not already set
if (!process.env.NODE_ENV) {
  process.env.NODE_ENV = "development";
  console.log(
    "Environment not specified, defaulting to development mode"
  );
}

console.log(`Running in ${process.env.NODE_ENV} mode`);

// Add a test route to app.js exports
app.get("/api/v1/test", (req, res) => {
  res.status(200).json({
    status: "success",
    message: "Server is running correctly",
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
  });
});

const port = process.env.PORT || 3000;
const server = app.listen(port, () => {
  console.log(
    "\n📱 Remember: all data values must be strings in FCM payloads"
  );
  console.log("===========================================\n");
});
