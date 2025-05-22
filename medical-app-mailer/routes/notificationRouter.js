const express = require("express");
const notificationController = require("../controllers/notificationController");
const router = express.Router();

router.route("/send").post(notificationController.sendNotification);
router
  .route("/send-v1")
  .post(notificationController.sendNotificationV1);
router
  .route("/test-send")
  .post(notificationController.sendTestNotification);
router
  .route("/save")
  .post(notificationController.saveNotificationToFirestore);
router
  .route("/user-token/:userId")
  .get(notificationController.getUserFcmToken);
router
  .route("/get-fcm-token")
  .get(notificationController.getFcmAccessToken);

module.exports = router;
