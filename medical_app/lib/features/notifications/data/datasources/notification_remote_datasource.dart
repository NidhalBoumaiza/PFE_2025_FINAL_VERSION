import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:medical_app/constants.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:googleapis_auth/auth_io.dart';

import 'package:medical_app/features/notifications/data/models/notification_model.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/utils/notification_utils.dart';

abstract class NotificationRemoteDataSource {
  /// Fetches all notifications for a user.
  Future<List<NotificationModel>> getNotifications(String userId);

  /// Sends a notification to a recipient.
  /// [recipientRole] specifies whether the recipient is 'patient' or 'doctor'.
  Future<void> sendNotification({
    required String title,
    required String body,
    required String senderId,
    required String recipientId,
    required NotificationType type,
    required String recipientRole,
    String? appointmentId,
    String? prescriptionId,
    String? ratingId,
    Map<String, dynamic>? data,
  });

  /// Marks a single notification as read.
  Future<void> markNotificationAsRead(String notificationId);

  /// Marks all notifications for a user as read.
  Future<void> markAllNotificationsAsRead(String userId);

  /// Deletes a notification.
  Future<void> deleteNotification(String notificationId);

  /// Gets the count of unread notifications for a user.
  Future<int> getUnreadNotificationsCount(String userId);

  /// Sets up FCM and returns the FCM token.
  Future<String?> setupFCM();

  /// Saves the FCM token for a user.
  Future<void> saveFCMToken(String userId, String token);

  /// Streams notifications for a user.
  Stream<List<NotificationModel>> notificationsStream(String userId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseMessaging firebaseMessaging;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final String _projectId = 'medicalapp-f1951';
  final String _clientEmail = 'medicalapp@medicalapp-f1951.iam.gserviceaccount.com';
  final String _privateKey = '''
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDbKI4UVJsNwdMJ
IeaMObKSxD2ygSBBzCGcdx05eL0gBoZa1NNudcBWHgFO/yCc1pSvnwdgeNtNnWT/
xlNp/LJdrgGNjJj7dbfDnTH/gsYX4OwIcXfHM/wr/qXbqQU2lWN4od6cL3E242ul
bHAp1tDZLD9jAGIUI/zhFJjnRXoQ4nuDroqFXbuQVRQQS5LszsOiei6JTba7pE3P
PskhwGUDqqGzsv/gRNqWG28lsNEryk4ItmBx+sptGCfoMWlflMmVDqizBArd/nR5
hpNoB/yrYyZ2vMINB4Rw0iaDx2vCrEapJ1JBMm69HCa5nQRR3rRV+2bvBjpX7yDk
OzNn57u9AgMBAAECggEAJuVuPgZ8FHd7jInjQKz22ByTNKy9PGBN8NalLa+TpWzz
CIjwU5D7h21A3zPhpmRhNEA9z23zwjU2mTyqTkvGnmDFLsmu1yZf7IxoNMiRfuhx
C9iToRvFXEuQRUmcvsDJzD2yZDb5WXwIfW4fBBX3sCutvlTxk1CFz67XqmhGz1sG
2v9JrvjIIM7tQ3QRqKQuazy5JTZyX8gybaMsmXFJPNc71+Ft6o6wOiomfNa7zXwd
e7cHkuG3lm5LwbDFRiLodvyexx8Yo8p1icnnHhabNpveDa2nRjs9pfG0UYWpCvxL
zPNB6MS6aMhPlJdTjL9/R/qAwcBdHO+Rg8WhsPxn8wKBgQD2auFpXwUR59RmcT5Y
1HuUXWtXfHvqOFvs3EvFZ7NbrPm/pVhvltW7velaponpMkAnPWEvGWgVN9GTQ9iG
Jw6hazxCB5xDWDFT3kYWwoAYok3QX/rJezDMwG6QyuAoAflq1OB3y7Ar4ITf73WP
I0nG1/P8e49ykWtBqE+t4+zdhwKBgQDjrk5+3sjA3Wws0KoBynW83iPLniIbyPC2
INYRN0C1yfb6cJMnW7iuEpa2ugsxhlLEHqjJ0REpkUbXMraPPFmCTepDove2u2yt
AjkmHh1CtAyNER5pIJQ9zEn12n1o9MED7K8GpyXGTOYmRfJpl6y1P5JVLG04aXTL
+sIwZ0RNmwKBgQCkxBCW8Wclctst6Hik0ucS7Ggy5lTA5xBoT2EGzPE70mxofbml
W7jsQO8AoyzB1czZsAwEfzt+PIWQr6PfB8ybmGWBTS9qRFUvXAeHfmRClHvtYdAB
2rJlpiIIBO9fMPrCOTciQvs4S3bteWMk45aYM5u77i6bj6qlC1LD1gxyjwKBgQDA
i0Uot8EwkVCNKb3MG+qr2XSOGuIfezRN4cEG+CIKWo06R/+6NjAdTe0VBIq4zC6s
Wn1Fhz+rVoeBMAsBYPkVYEzv/B7e8uu59/paiPcX1OoUVljQcNPM2znk52xNWUbt
ybhOuQYSCDBOR7L0p2dQND3NN+/51/0FD8AvbPVvZwKBgGPLpWZMg4PSwhFp2fWY
u3jdkF7eVHwmTNsCTxnf8P+RvrpKXeadmLSsoaDGNpZ4vui/qA6H7tKBvt0g9YNG
yVVbfYQy+11zs8wtBcr7yjRL4wEg4Mi+QrwJ2bzoKEJAm+7kO3odHJr1C46TFIZg
wwxt8k2z9k2sCyBaXijtjTDC
-----END PRIVATE KEY-----
''';

  NotificationRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseMessaging,
    required this.flutterLocalNotificationsPlugin,
  });

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final notificationsQuery =
      await firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return notificationsQuery.docs
          .map(
            (doc) => NotificationModel.fromJson({'id': doc.id, ...doc.data()}),
      )
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch notifications: $e');
    }
  }

  @override
  Future<void> sendNotification({
    required String title,
    required String body,
    required String senderId,
    required String recipientId,
    required NotificationType type,
    required String recipientRole,
    String? appointmentId,
    String? prescriptionId,
    String? ratingId,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Validate recipient role
      if (!['patient', 'doctor'].contains(recipientRole)) {
        throw ServerException('Invalid recipient role: $recipientRole');
      }

      // Get sender info
      String senderName = 'Unknown User';
      try {
        for (var collection in ['users', 'medecins', 'patients']) {
          final senderDoc = await firestore.collection(collection).doc(senderId).get();
          if (senderDoc.exists) {
            senderName = '${senderDoc.data()?['name'] ?? ''} ${senderDoc.data()?['lastName'] ?? ''}'.trim();
            if (senderName.isNotEmpty) break;
          }
        }
        if (senderName == 'Unknown User' && data != null) {
          senderName = data['doctorName'] ?? data['patientName'] ?? 'Unknown User';
        }
      } catch (e) {
        print('Error fetching sender info for senderId $senderId: $e');
      }

      // Create notification model
      final notification = NotificationModel(
        id: '',
        title: title,
        body: body,
        senderId: senderId,
        recipientId: recipientId,
        type: type,
        appointmentId: appointmentId,
        prescriptionId: prescriptionId,
        ratingId: ratingId,
        createdAt: DateTime.now(),
        isRead: false,
        data: data != null ? {...data, 'senderName': senderName} : {'senderName': senderName},
      );

      // Save notification to Firestore
      final docRef = await firestore.collection('notifications').add({
        'title': notification.title,
        'body': notification.body,
        'senderId': notification.senderId,
        'recipientId': notification.recipientId,
        'type': NotificationUtils.notificationTypeToString(notification.type),
        'appointmentId': notification.appointmentId,
        'prescriptionId': notification.prescriptionId,
        'ratingId': notification.ratingId,
        'createdAt': notification.createdAt.toIso8601String(),
        'isRead': notification.isRead,
        'data': notification.data,
      });

      // Get recipient FCM token
      String? fcmToken;
      try {
        final collection = recipientRole == 'doctor' ? 'medecins' : 'patients';
        final userDoc = await firestore.collection(collection).doc(recipientId).get();
        if (userDoc.exists) {
          fcmToken = userDoc.data()?['fcmToken'] as String?;
          if (fcmToken == null || fcmToken.isEmpty) {
            print('No FCM token found for recipient $recipientId in $collection');
          }
        } else {
          print('Recipient $recipientId not found in $collection');
        }
      } catch (e) {
        print('Error fetching FCM token for recipient $recipientId: $e');
      }

      if (fcmToken != null && fcmToken.isNotEmpty) {
        // Create payload
        final payload = {
          'notification': {'title': title, 'body': body},
          'data': {
            'notificationId': docRef.id,
            'type': NotificationUtils.notificationTypeToString(type),
            'senderId': senderId,
            'recipientId': recipientId,
            'senderName': senderName,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            if (appointmentId != null) 'appointmentId': appointmentId,
            if (prescriptionId != null) 'prescriptionId': prescriptionId,
            if (ratingId != null) 'ratingId': ratingId,
            ...(data ?? {}),
          },
        };

        // Get access token using service account
        final credentials = ServiceAccountCredentials.fromJson({
          "type": "service_account",
          "project_id": _projectId,
          "private_key_id": "e2c6dbcd5e03f62c952f4ee688aee7aa7f97b35d",
          "private_key": _privateKey,
          "client_email": _clientEmail,
          "client_id": "115771578850872674063",
          "auth_uri": "https://accounts.google.com/o/oauth2/auth",
          "token_uri": "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/medicalapp%40medicalapp-f1951.iam.gserviceaccount.com"
        });

        final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
        final client = http.Client();
        final accessToken = await obtainAccessCredentialsViaServiceAccount(
          credentials,
          scopes,
          client,
        );

        // Send FCM message
        final response = await http.post(
          Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${accessToken.accessToken.data}',
          },
          body: jsonEncode({
            'message': {
              'token': fcmToken,
              'notification': {
                'title': title,
                'body': body,
              },
              'data': payload['data'],
              'android': {
                'priority': 'HIGH', // Changed from 'high' to 'HIGH'
                'notification': {
                  'channel_id': 'high_importance_channel',
                  // Remove priority from here as it's not valid in this level
                  'sound': 'default',
                  'default_vibrate_timings': true,
                },
              },
              'apns': {
                'payload': {
                  'aps': {
                    'badge': 1,
                    'sound': 'default',
                  },
                },
              },
            },
          }),
        );

        if (response.statusCode != 200) {
          throw ServerException('Failed to send FCM notification: ${response.statusCode}, ${response.body}');
        }
        print('Successfully sent FCM notification to token $fcmToken');
      } else {
        print('No valid FCM token for recipient $recipientId, notification saved to Firestore');
      }
    } catch (e) {
      print('Error sending notification to recipient $recipientId: $e');
      throw ServerException('Failed to send notification: $e');
    }
  }

  /// Sends an FCM notification to the specified token.
  /// Note: Client-side FCM sending is insecure for production; use a backend (e.g., Cloud Functions) instead.
  Future<void> sendDirectFCMNotification(
      String token,
      String title,
      String body,
      Map<String, dynamic> payload,
      ) async {
    try {
      // Validate Firebase project ID
      if (AppConstants.firebaseProjectId.isEmpty) {
        throw ServerException('Firebase project ID is not configured');
      }

      // Get Firebase Authentication ID token
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw ServerException('No authenticated user found');
      }
      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw ServerException('Failed to get ID token');
      }

      // Convert data payload to strings
      final dataPayload = Map<String, String>.from(
        payload['data'].map(
              (key, value) => MapEntry(key, value?.toString() ?? ''),
        ),
      );

      // Format FCM payload for HTTP v1 API
      final fcmMessage = {
        'message': {
          'token': token,
          'notification': {'title': title, 'body': body},
          'data': dataPayload,
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': AppConstants.notificationChannelId,
              'priority': 'high',
              'default_sound': true,
              'default_vibrate_timings': true,
            },
          },
          'apns': {
            'payload': {
              'aps': {'badge': 1, 'sound': 'default'},
            },
          },
        },
      };

      // Send the message
      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/${AppConstants.firebaseProjectId}/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(fcmMessage),
      );

      if (response.statusCode != 200) {
        throw ServerException(
          'Failed to send FCM notification: ${response.statusCode}, ${response.body}',
        );
      }
      print('Successfully sent FCM notification to token $token');
    } catch (e) {
      print('Exception sending FCM notification to token $token: $e');
      throw ServerException('Failed to send FCM notification: $e');
    }
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw ServerException('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = firestore.batch();
      final notificationsQuery =
      await firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notificationsQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw ServerException('Failed to delete notification: $e');
    }
  }

  @override
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      // Requires Firestore SDK with aggregate query support
      final notificationsQuery =
      await firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return notificationsQuery.count ?? 0;
    } catch (e) {
      throw ServerException('Failed to get unread notifications count: $e');
    }
  }

  @override
  Future<String?> setupFCM() async {
    try {
      // Request permission
      final settings = await firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        final token = await firebaseMessaging.getToken();
        if (token == null) {
          throw ServerException('Failed to get FCM token');
        }

        // Initialize local notifications for Android
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          AppConstants.notificationChannelId,
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.high,
        );
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
        >()
            ?.createNotificationChannel(channel);

        // Initialize local notifications for iOS
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
        >()
            ?.requestPermissions(alert: true, badge: true, sound: true);

        return token;
      } else {
        throw ServerException('FCM permissions denied');
      }
    } catch (e) {
      throw ServerException('Failed to setup FCM: $e');
    }
  }

  @override
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await firestore.collection('users').doc(userId).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (e) {
      throw ServerException('Failed to save FCM token: $e');
    }
  }

  @override
  Stream<List<NotificationModel>> notificationsStream(String userId) {
    return firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs
              .map(
                (doc) => NotificationModel.fromJson({
              'id': doc.id,
              ...doc.data(),
            }),
          )
              .toList(),
    )
        .handleError((error) {
      print('Error in notifications stream for user $userId: $error');
      throw ServerException('Failed to stream notifications: $error');
    });
  }
}