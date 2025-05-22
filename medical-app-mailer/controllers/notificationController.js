const catchAsync = require("../utils/catchAsync");
const AppError = require("../utils/appError");
const admin = require("firebase-admin");
const path = require("path");

// Initialize Firebase Admin SDK with proper error handling
let firebaseInitialized = false;

try {
  // Use absolute path to the service account key
  const serviceAccountPath = path.join(
    __dirname,
    "..",
    "serviceAccountKey.json"
  );

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(require(serviceAccountPath)),
    });
    console.log("Firebase Admin SDK initialized successfully");
    firebaseInitialized = true;
  }
} catch (error) {
  console.error(
    "Firebase Admin initialization error:",
    error.message
  );
  console.error(
    "You need a valid serviceAccountKey.json file from Firebase Console"
  );
  console.error(
    "Path: Project Settings > Service Accounts > Generate New Private Key"
  );
}

// Helper function to get an FCM access token for the v1 API
const getFcmAccessToken = async () => {
  if (!firebaseInitialized) {
    throw new Error("Firebase Admin SDK not initialized");
  }

  try {
    // Get the access token from the admin SDK
    const accessToken = await admin
      .app()
      .options.credential.getAccessToken();
    return accessToken.access_token; // Return just the token string
  } catch (error) {
    console.error("Error getting FCM access token:", error);
    throw error;
  }
};

// Get FCM access token for v1 API
exports.getFcmAccessToken = catchAsync(async (req, res, next) => {
  if (!firebaseInitialized) {
    return next(
      new AppError(
        "Firebase Admin SDK is not properly initialized. Check your serviceAccountKey.json file.",
        500
      )
    );
  }

  try {
    const token = await getFcmAccessToken();

    console.log("FCM access token generated for v1 API");

    res.status(200).json({
      status: "success",
      token: token,
      expiresIn: "1 hour", // FCM tokens typically expire in 1 hour
    });
  } catch (error) {
    console.error("Error generating FCM access token:", error);
    return next(
      new AppError(
        "Failed to generate FCM access token: " + error.message,
        500
      )
    );
  }
});

// Helper function to convert all values in an object to strings
const convertToStringValues = (obj) => {
  if (!obj) return {};

  const result = {};

  // Process each key in the object
  Object.keys(obj).forEach((key) => {
    // Handle null or undefined values
    if (obj[key] === null || obj[key] === undefined) {
      result[key] = ""; // Convert to empty string
    }
    // Handle objects (including arrays)
    else if (typeof obj[key] === "object") {
      try {
        result[key] = JSON.stringify(obj[key]); // Try to stringify the object
      } catch (e) {
        result[key] = String(obj[key]); // Fallback if stringify fails
      }
    }
    // Convert all other types to string
    else {
      result[key] = String(obj[key]);
    }
  });

  console.log(
    "Converted data object to string values for FCM",
    result
  );
  return result;
};

// Save notification to Firestore and optionally send FCM notification
const saveNotificationToFirestore = async (
  title,
  body,
  senderId,
  recipientId,
  type,
  appointmentId = null,
  prescriptionId = null,
  data = {},
  token = null
) => {
  if (!firebaseInitialized) {
    throw new Error("Firebase Admin SDK not initialized");
  }

  // Save to Firestore
  const notificationData = {
    title,
    body,
    senderId,
    recipientId,
    type: type || "general",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    isRead: false,
  };

  if (appointmentId) notificationData.appointmentId = appointmentId;
  if (prescriptionId)
    notificationData.prescriptionId = prescriptionId;
  if (data) notificationData.data = data;

  const result = await admin
    .firestore()
    .collection("notifications")
    .add(notificationData);

  console.log("Notification saved to Firestore:", result.id);

  // Return the new notification ID
  return result.id;
};

// Preferred method: Send notification using the modern FCM HTTP v1 API
exports.sendNotificationV1 = catchAsync(async (req, res, next) => {
  const { token, title, body, data } = req.body;

  if (!token) {
    return next(new AppError("FCM token is required", 400));
  }

  if (!title || !body) {
    return next(
      new AppError("Notification title and body are required", 400)
    );
  }

  if (!firebaseInitialized) {
    return next(
      new AppError(
        "Firebase Admin SDK is not properly initialized. Check your serviceAccountKey.json file.",
        500
      )
    );
  }

  try {
    // Log the notification details for debugging
    console.log("=============================================");
    console.log("V1 NOTIFICATION REQUEST:");
    console.log("Token:", token);
    console.log("Title:", title);
    console.log("Body:", body);
    console.log("Data:", JSON.stringify(data || {}, null, 2));
    console.log("=============================================");

    // Get project ID from service account
    const projectId = admin.app().options.projectId;

    // Convert data to strings if it exists
    const stringData = data ? convertToStringValues(data) : {};

    // Using the Admin SDK's built-in method which now uses the v1 API
    const response = await admin.messaging().send({
      token: token,
      notification: {
        title: title,
        body: body,
      },
      data: stringData,
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          priority: "high",
        },
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: "default",
            contentAvailable: true,
          },
        },
      },
    });

    console.log(
      "Notification sent successfully via v1 API:",
      response
    );

    // Save to Firestore if needed
    let firestoreId = null;
    if (data && data.recipientId && data.senderId) {
      try {
        firestoreId = await saveNotificationToFirestore(
          title,
          body,
          data.senderId,
          data.recipientId,
          data.type || "general",
          data.appointmentId || null,
          data.prescriptionId || null,
          data
        );
      } catch (firestoreError) {
        console.error(
          "Firestore save failed:",
          firestoreError.message
        );
        // Continue with success response even if Firestore fails
      }
    }

    res.status(200).json({
      status: "success",
      message:
        "Notification sent successfully via v1 API" +
        (firestoreId ? " and saved to database" : ""),
      projectId: projectId,
      response: {
        fcm: response,
        firestoreId,
      },
    });
  } catch (error) {
    console.error("Error sending notification via v1 API:", error);

    // Special handling for common FCM errors
    if (error.code === "messaging/invalid-payload") {
      return next(
        new AppError(
          "Invalid notification payload: " + error.message,
          400
        )
      );
    } else if (
      error.code === "messaging/invalid-recipient" ||
      error.code === "messaging/registration-token-not-registered"
    ) {
      return next(
        new AppError("Invalid FCM token: " + error.message, 400)
      );
    }

    return next(
      new AppError(
        "Failed to send notification via v1 API: " + error.message,
        500
      )
    );
  }
});

// Legacy API endpoint (for backward compatibility only)
exports.sendNotification = catchAsync(async (req, res, next) => {
  // Just call the v1 API method
  return exports.sendNotificationV1(req, res, next);
});

// Save notification to Firestore
exports.saveNotificationToFirestore = catchAsync(
  async (req, res, next) => {
    const {
      title,
      body,
      senderId,
      recipientId,
      type,
      appointmentId,
      prescriptionId,
      data,
      token,
    } = req.body;

    if (!title || !body || !senderId || !recipientId) {
      return next(
        new AppError("Missing required notification fields", 400)
      );
    }

    if (!firebaseInitialized) {
      return next(
        new AppError(
          "Firebase Admin SDK is not properly initialized. Check your serviceAccountKey.json file.",
          500
        )
      );
    }

    try {
      // Save to Firestore
      const firestoreId = await saveNotificationToFirestore(
        title,
        body,
        senderId,
        recipientId,
        type,
        appointmentId,
        prescriptionId,
        data
      );

      // Send FCM notification if token is provided
      let fcmSent = false;
      let fcmResponse = null;

      if (token) {
        try {
          fcmResponse = await admin.messaging().send({
            token,
            notification: { title, body },
            data: convertToStringValues({
              notificationId: firestoreId,
              senderId,
              recipientId,
              type: type || "general",
              ...data,
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            }),
            android: {
              priority: "high",
              notification: {
                channelId: "high_importance_channel",
              },
            },
          });

          fcmSent = true;
          console.log("FCM notification sent:", fcmResponse);
        } catch (fcmError) {
          console.error(
            "Error sending FCM notification:",
            fcmError.message
          );
          // Continue since we already saved to Firestore
        }
      }

      res.status(201).json({
        status: "success",
        message: fcmSent
          ? "Notification saved and sent"
          : "Notification saved to Firestore",
        notificationId: firestoreId,
        fcm: fcmSent ? fcmResponse : null,
      });
    } catch (error) {
      console.error("Error saving notification:", error);
      return next(
        new AppError(
          "Failed to save notification: " + error.message,
          500
        )
      );
    }
  }
);

// Get user FCM token
exports.getUserFcmToken = catchAsync(async (req, res, next) => {
  const { userId } = req.params;

  if (!userId) {
    return next(new AppError("User ID is required", 400));
  }

  if (!firebaseInitialized) {
    return next(
      new AppError(
        "Firebase Admin SDK is not properly initialized. Check your serviceAccountKey.json file.",
        500
      )
    );
  }

  try {
    // Check multiple collections for the user's FCM token
    const collections = ["users", "patients", "medecins"];
    let fcmToken = null;

    for (const collection of collections) {
      try {
        const doc = await admin
          .firestore()
          .collection(collection)
          .doc(userId)
          .get();
        if (doc.exists && doc.data()?.fcmToken) {
          fcmToken = doc.data().fcmToken;
          break;
        }
      } catch (err) {
        console.error(
          `Error checking ${collection} collection:`,
          err.message
        );
        // Continue checking other collections
      }
    }

    if (fcmToken) {
      return res.status(200).json({
        status: "success",
        data: { fcmToken },
      });
    } else {
      return res.status(404).json({
        status: "fail",
        message: "FCM token not found for this user",
      });
    }
  } catch (error) {
    console.error("Error retrieving FCM token:", error);
    return next(
      new AppError(
        "Failed to retrieve FCM token: " + error.message,
        500
      )
    );
  }
});

// Test notification endpoint (for testing without FCM)
exports.sendTestNotification = catchAsync(async (req, res, next) => {
  const { title, body, data } = req.body;

  if (!title || !body) {
    return next(new AppError("Title and body are required", 400));
  }

  console.log("=============================================");
  console.log("TEST NOTIFICATION (No Firebase):");
  console.log("Title:", title);
  console.log("Body:", body);
  console.log("Data:", JSON.stringify(data || {}, null, 2));
  console.log("=============================================");

  res.status(200).json({
    status: "success",
    message: "Test notification processed (Firebase not used)",
    notification: {
      title,
      body,
      data: data || {},
      processed_at: new Date().toISOString(),
    },
  });
});
