const app = require("./app");
const dotenv = require("dotenv");

// Load environment variables
dotenv.config({ path: "./.env" });

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
  console.log("\n===========================================");
  console.log("🚀 Notification Server running on port " + port);
  console.log("===========================================");
  console.log("\n📌 Available endpoints:");
  console.log("- GET  /api/v1/test - Test server connection");
  console.log(
    "- POST /api/v1/notifications/send - Send notification using Firebase FCM"
  );
  console.log(
    "- POST /api/v1/notifications/save - Save notification to Firestore"
  );
  console.log(
    "- GET  /api/v1/notifications/user-token/:userId - Get user's FCM token"
  );
  console.log(
    "- POST /api/v1/notifications/test-send - Send test notification (no Firebase)"
  );
  console.log("\n📝 Example notification request:");
  console.log(
    JSON.stringify(
      {
        token: "fcm-token-here",
        title: "New Appointment",
        body: "You have a new appointment request",
        data: {
          type: "newAppointment",
          senderId: "patient-id",
          recipientId: "doctor-id",
          appointmentId: "appointment-id",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      null,
      2
    )
  );

  console.log(
    "\n📱 Remember: all data values must be strings in FCM payloads"
  );
  console.log("===========================================\n");
});
