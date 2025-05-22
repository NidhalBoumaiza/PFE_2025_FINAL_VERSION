# Firebase Cloud Messaging (FCM) Setup

This document provides instructions for setting up Firebase Cloud Messaging for the MediLink app to enable push notifications.

## Prerequisites

1. A Firebase project connected to your Flutter app
2. Firebase Authentication and Firestore already set up

## Step 1: Enable FCM in Firebase Console

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to "Messaging" in the left sidebar (under "Engage")
4. Click "Get Started" if you haven't enabled FCM yet

## Step 2: Set Up Cloud Functions for FCM

Since sending FCM messages from the client is not secure, you should use Firebase Cloud Functions to send notifications. Here's a simple Cloud Function implementation:

1. Install Firebase CLI if you haven't already:
   ```bash
   npm install -g firebase-tools
   ```

2. Log in to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase Functions in your project:
   ```bash
   firebase init functions
   ```

4. Implement the Cloud Function to send FCM notifications:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Send FCM notification when a new document is added to the fcm_requests collection
exports.sendFCMNotification = functions.firestore
  .document('fcm_requests/{docId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    if (!data.token || !data.payload) {
      console.log('Missing required fields in FCM request');
      return null;
    }
    
    try {
      const response = await admin.messaging().send({
        token: data.token,
        notification: data.payload.notification,
        data: data.payload.data,
        android: {
          priority: 'high',
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
        },
      });
      
      console.log('Successfully sent message:', response);
      
      // Update the document to mark it as processed
      return snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        success: true,
      });
    } catch (error) {
      console.log('Error sending message:', error);
      
      // Update the document to mark it as failed
      return snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        success: false,
        error: error.message,
      });
    }
  });

// Add a Firestore trigger to handle specific actions
exports.handleAppointmentCreated = functions.firestore
  .document('appointments/{appointmentId}')
  .onCreate(async (snap, context) => {
    const appointment = snap.data();
    
    // Skip if necessary data is missing
    if (!appointment.doctorId || !appointment.patientId) {
      console.log('Missing required IDs in appointment');
      return null;
    }
    
    try {
      // Get the doctor's FCM token
      const doctorDoc = await admin.firestore().collection('users').doc(appointment.doctorId).get();
      
      if (!doctorDoc.exists || !doctorDoc.data().fcmToken) {
        console.log('Doctor FCM token not found');
        return null;
      }
      
      // Get patient name for the notification
      const patientDoc = await admin.firestore().collection('users').doc(appointment.patientId).get();
      const patientName = patientDoc.exists ? `${patientDoc.data().name} ${patientDoc.data().lastName}` : 'A patient';
      
      // Send notification to doctor
      await admin.messaging().send({
        token: doctorDoc.data().fcmToken,
        notification: {
          title: 'New Appointment Request',
          body: `${patientName} requested an appointment on ${new Date(appointment.date.toDate()).toLocaleDateString()} at ${appointment.time}`,
        },
        data: {
          type: 'newAppointment',
          appointmentId: context.params.appointmentId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
        },
      });
      
      // Create notification record in Firestore
      await admin.firestore().collection('notifications').add({
        title: 'New Appointment Request',
        body: `${patientName} requested an appointment on ${new Date(appointment.date.toDate()).toLocaleDateString()} at ${appointment.time}`,
        senderId: appointment.patientId,
        recipientId: appointment.doctorId,
        type: 'newAppointment',
        appointmentId: context.params.appointmentId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      });
      
      return null;
    } catch (error) {
      console.log('Error handling appointment creation:', error);
      return null;
    }
  });

// Handle appointment status updates
exports.handleAppointmentUpdated = functions.firestore
  .document('appointments/{appointmentId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Skip if status didn't change
    if (before.status === after.status) {
      return null;
    }
    
    try {
      // Get the patient's FCM token
      const patientDoc = await admin.firestore().collection('users').doc(after.patientId).get();
      
      if (!patientDoc.exists || !patientDoc.data().fcmToken) {
        console.log('Patient FCM token not found');
        return null;
      }
      
      // Get doctor name for the notification
      const doctorDoc = await admin.firestore().collection('users').doc(after.doctorId).get();
      const doctorName = doctorDoc.exists ? `Dr. ${doctorDoc.data().name} ${doctorDoc.data().lastName}` : 'The doctor';
      
      let title, body, type;
      
      if (after.status === 'accepted') {
        title = 'Appointment Accepted';
        body = `${doctorName} accepted your appointment on ${new Date(after.date.toDate()).toLocaleDateString()} at ${after.time}`;
        type = 'appointmentAccepted';
      } else if (after.status === 'rejected') {
        title = 'Appointment Rejected';
        body = `${doctorName} couldn't accept your appointment on ${new Date(after.date.toDate()).toLocaleDateString()} at ${after.time}`;
        type = 'appointmentRejected';
      } else {
        return null; // Not a status we're interested in
      }
      
      // Send notification to patient
      await admin.messaging().send({
        token: patientDoc.data().fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: type,
          appointmentId: context.params.appointmentId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
        },
      });
      
      // Create notification record in Firestore
      await admin.firestore().collection('notifications').add({
        title: title,
        body: body,
        senderId: after.doctorId,
        recipientId: after.patientId,
        type: type,
        appointmentId: context.params.appointmentId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      });
      
      return null;
    } catch (error) {
      console.log('Error handling appointment update:', error);
      return null;
    }
  });

// Handle new prescription created
exports.handlePrescriptionCreated = functions.firestore
  .document('prescriptions/{prescriptionId}')
  .onCreate(async (snap, context) => {
    const prescription = snap.data();
    
    // Skip if necessary data is missing
    if (!prescription.doctorId || !prescription.patientId) {
      console.log('Missing required IDs in prescription');
      return null;
    }
    
    try {
      // Get the patient's FCM token
      const patientDoc = await admin.firestore().collection('users').doc(prescription.patientId).get();
      
      if (!patientDoc.exists || !patientDoc.data().fcmToken) {
        console.log('Patient FCM token not found');
        return null;
      }
      
      // Get doctor name for the notification
      const doctorDoc = await admin.firestore().collection('users').doc(prescription.doctorId).get();
      const doctorName = doctorDoc.exists ? `Dr. ${doctorDoc.data().name} ${doctorDoc.data().lastName}` : 'Your doctor';
      
      // Send notification to patient
      await admin.messaging().send({
        token: patientDoc.data().fcmToken,
        notification: {
          title: 'New Prescription',
          body: `${doctorName} has created a new prescription for you`,
        },
        data: {
          type: 'newPrescription',
          prescriptionId: context.params.prescriptionId,
          appointmentId: prescription.appointmentId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
        },
      });
      
      // Create notification record in Firestore
      await admin.firestore().collection('notifications').add({
        title: 'New Prescription',
        body: `${doctorName} has created a new prescription for you`,
        senderId: prescription.doctorId,
        recipientId: prescription.patientId,
        type: 'newPrescription',
        prescriptionId: context.params.prescriptionId,
        appointmentId: prescription.appointmentId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      });
      
      return null;
    } catch (error) {
      console.log('Error handling prescription creation:', error);
      return null;
    }
  });
```

5. Deploy your Cloud Functions:
   ```bash
   firebase deploy --only functions
   ```

## Step 3: Update Firestore Security Rules

Make sure your Firestore security rules allow reading and writing to the necessary collections:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read notifications addressed to them
    match /notifications/{notificationId} {
      allow read: if request.auth != null && resource.data.recipientId == request.auth.uid;
      allow create: if request.auth != null;
      allow update: if request.auth != null && resource.data.recipientId == request.auth.uid;
      allow delete: if request.auth != null && resource.data.recipientId == request.auth.uid;
    }
    
    // Allow authenticated users to create FCM requests
    match /fcm_requests/{requestId} {
      allow create: if request.auth != null;
      allow read, update, delete: if false; // Only cloud functions can read/update/delete
    }
    
    // Other rules for your app...
  }
}
```

## Step 4: App Configuration

1. Make sure you have the correct Firebase configuration files:
   - For Android: `android/app/google-services.json`
   - For iOS: `ios/Runner/GoogleService-Info.plist`

2. Update your `AndroidManifest.xml` (for Android):
   ```xml
   <manifest ...>
     <uses-permission android:name="android.permission.INTERNET"/>
     <uses-permission android:name="android.permission.VIBRATE" />
     <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
     
     <application ...>
       <!-- Add these permissions -->
       <meta-data
           android:name="com.google.firebase.messaging.default_notification_channel_id"
           android:value="high_importance_channel" />
           
       <meta-data
           android:name="com.google.firebase.messaging.default_notification_icon"
           android:resource="@mipmap/ic_launcher" />
           
       <meta-data
           android:name="firebase_messaging_auto_init_enabled"
           android:value="true" />
           
       <activity ...>
         <!-- Add this for notification click handling -->
         <intent-filter>
           <action android:name="FLUTTER_NOTIFICATION_CLICK" />
           <category android:name="android.intent.category.DEFAULT" />
         </intent-filter>
       </activity>
       
       <!-- Required for background message handling -->
       <service
           android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingBackgroundService"
           android:exported="false"
           android:permission="android.permission.BIND_JOB_SERVICE" />
           
       <service
           android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
           android:exported="false">
         <intent-filter>
           <action android:name="com.google.firebase.MESSAGING_EVENT" />
         </intent-filter>
       </service>
       
       <receiver
           android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingReceiver"
           android:exported="true"
           android:permission="com.google.android.c2dm.permission.SEND">
         <intent-filter>
           <action android:name="com.google.android.c2dm.intent.RECEIVE" />
         </intent-filter>
       </receiver>
     </application>
   </manifest>
   ```

3. For iOS, update your `Info.plist`:
   ```xml
   <key>UIBackgroundModes</key>
   <array>
     <string>fetch</string>
     <string>remote-notification</string>
   </array>
   <key>FirebaseAppDelegateProxyEnabled</key>
   <string>NO</string>
   ```

## Testing FCM

To test your FCM implementation:

1. Run your app on a physical device (not an emulator)
2. Verify that the app requests notification permissions
3. Check that the token is saved to Firestore in the user document
4. Test sending a notification using the Firebase Console:
   - Go to Firebase Console > Messaging > Send your first message
   - Create a new notification
   - Use the "Token" delivery option with the FCM token from your device
   - Send the message and verify it's received on your device

## Troubleshooting

- If notifications aren't being received, check the following:
  - Verify the FCM token is correctly saved in Firestore
  - Check Firebase Functions logs for any errors
  - Ensure the app has notification permissions enabled
  - For Android, make sure the device is not in battery optimization mode
  - For iOS, check that background modes are properly configured

- If notification tap doesn't navigate to the correct screen:
  - Check the payload data to ensure it contains the correct identifiers
  - Verify the navigation logic in the app is correctly handling the notification payload
</rewritten_file> 