const admin = require("firebase-admin");
const path = require("path");

// Initialize Firebase Admin SDK with proper error handling
let firebaseInitialized = false;

const initializeFirebase = () => {
  if (firebaseInitialized) {
    return admin;
  }

  try {
    if (!admin.apps.length) {
      // Try environment variables first, then fall back to JSON file
      let credential;

      if (
        process.env.FIREBASE_PROJECT_ID &&
        process.env.FIREBASE_PRIVATE_KEY &&
        process.env.FIREBASE_CLIENT_EMAIL
      ) {
        console.log(
          "Using Firebase credentials from environment variables"
        );
        credential = admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(
            /\\n/g,
            "\n"
          ),
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        });
      } else {
        console.log(
          "Using Firebase credentials from serviceAccountKey.json"
        );
        const serviceAccountPath = path.join(
          __dirname,
          "..",
          "serviceAccountKey.json"
        );

        // Check if file exists
        const fs = require("fs");
        if (!fs.existsSync(serviceAccountPath)) {
          throw new Error(
            `Service account key file not found at: ${serviceAccountPath}`
          );
        }

        credential = admin.credential.cert(
          require(serviceAccountPath)
        );
      }

      admin.initializeApp({
        credential: credential,
      });

      console.log("Firebase Admin SDK initialized successfully");
      firebaseInitialized = true;
    }
  } catch (error) {
    console.error(
      "Firebase Admin initialization error:",
      error.message
    );

    // Provide specific guidance based on error type
    if (
      error.message.includes("Invalid JWT Signature") ||
      error.message.includes("revoked")
    ) {
      console.error(
        "🔑 SOLUTION: Your service account key has been revoked or expired."
      );
      console.error("   → Generate a new key from Firebase Console:");
      console.error(
        "   → https://console.firebase.google.com/project/medicalapp-f1951/settings/serviceaccounts/adminsdk"
      );
    } else if (
      error.message.includes("ENOENT") ||
      error.message.includes("not found")
    ) {
      console.error(
        "📁 SOLUTION: Service account key file is missing."
      );
      console.error(
        "   → Download serviceAccountKey.json from Firebase Console"
      );
      console.error("   → Place it in the project root directory");
    } else if (error.message.includes("invalid_grant")) {
      console.error(
        "⏰ SOLUTION: Check system time synchronization or regenerate key."
      );
    } else {
      console.error(
        "❓ SOLUTION: Check the Firebase setup guide: FIREBASE_SETUP_GUIDE.md"
      );
    }

    console.error(
      "📖 Full setup guide available in: FIREBASE_SETUP_GUIDE.md"
    );
    throw error;
  }

  return admin;
};

// Test Firebase connection
const testConnection = async () => {
  if (!firebaseInitialized) {
    throw new Error("Firebase not initialized");
  }

  try {
    // Test Auth
    await admin.auth().listUsers(1);
    console.log("✅ Firebase Auth connection verified");

    // Test Firestore
    await admin
      .firestore()
      .collection("test")
      .doc("connection")
      .get();
    console.log("✅ Firestore connection verified");

    return true;
  } catch (error) {
    console.error(
      "❌ Firebase connection test failed:",
      error.message
    );
    throw error;
  }
};

// Get Firebase project info
const getProjectInfo = () => {
  if (!firebaseInitialized) {
    return null;
  }

  try {
    const app = admin.app();
    return {
      projectId: app.options.projectId,
      serviceAccount:
        app.options.credential?.clientEmail || "Unknown",
    };
  } catch (error) {
    console.error("Error getting project info:", error.message);
    return null;
  }
};

// Initialize Firebase immediately when this module is loaded
initializeFirebase();

module.exports = {
  admin,
  initializeFirebase,
  isFirebaseInitialized: () => firebaseInitialized,
  testConnection,
  getProjectInfo,
};
