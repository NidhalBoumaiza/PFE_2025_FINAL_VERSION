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

  /// Check if a notification exists in the database (for testing purposes)
  Future<bool> notificationExists(String notificationId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseMessaging firebaseMessaging;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final String _projectId = 'medicalapp-f1951';
  final String _clientEmail =
      'medicalapp@medicalapp-f1951.iam.gserviceaccount.com';
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
      print('DEBUG: getNotifications called with userId: $userId');

      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      print('DEBUG: Querying Firestore for notifications...');
      final querySnapshot = await firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              print('DEBUG: Firestore query timed out after 10 seconds');
              throw Exception('Query timeout: Failed to load notifications');
            },
          );

      print(
        'DEBUG: Firestore query completed. Found ${querySnapshot.docs.length} documents',
      );

      if (querySnapshot.docs.isEmpty) {
        print('DEBUG: No notifications found for user $userId');
        return [];
      }

      final notifications =
          querySnapshot.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  if (data.isEmpty) {
                    print(
                      'Warning: Empty notification document found: ${doc.id}',
                    );
                    return null;
                  }
                  final jsonData = {'id': doc.id, ...data};
                  return NotificationModel.fromJson(jsonData);
                } catch (e) {
                  print('Error parsing notification ${doc.id}: $e');
                  return null;
                }
              })
              .where((notification) => notification != null)
              .cast<NotificationModel>()
              .toList();

      print('DEBUG: Successfully parsed ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      print('DEBUG: Error in getNotifications: $e');
      throw Exception('Failed to load notifications: ${e.toString()}');
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

      // Get sender info with better error handling
      String senderName = 'Unknown User';
      String? senderPhoto;
      try {
        for (var collection in ['users', 'medecins', 'patients']) {
          final senderDoc =
              await firestore.collection(collection).doc(senderId).get();
          if (senderDoc.exists) {
            final senderData = senderDoc.data();
            senderName =
                '${senderData?['name'] ?? ''} ${senderData?['lastName'] ?? ''}'
                    .trim();
            senderPhoto = senderData?['photoUrl'] as String?;
            if (senderName.isNotEmpty) break;
          }
        }
        if (senderName == 'Unknown User' && data != null) {
          senderName =
              data['doctorName'] ?? data['patientName'] ?? 'Unknown User';
        }
      } catch (e) {
        print('Error fetching sender info for senderId $senderId: $e');
      }

      // Get notification priority and sound
      final priority = NotificationUtils.getNotificationPriority(type);
      final sound = NotificationUtils.getNotificationSound(type);
      final icon = NotificationUtils.getNotificationIcon(type);

      // Create enhanced notification model
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
        data: {
          'senderName': senderName,
          'priority': priority,
          'sound': sound,
          'icon': icon,
          if (senderPhoto != null) 'senderPhoto': senderPhoto,
          ...(data ?? {}),
        },
      );

      // Save notification to Firestore with retry logic
      DocumentReference? docRef;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          docRef = await firestore.collection('notifications').add({
            'title': notification.title,
            'body': notification.body,
            'senderId': notification.senderId,
            'recipientId': notification.recipientId,
            'type': NotificationUtils.notificationTypeToString(
              notification.type,
            ),
            'appointmentId': notification.appointmentId,
            'prescriptionId': notification.prescriptionId,
            'ratingId': notification.ratingId,
            'createdAt': notification.createdAt.toIso8601String(),
            'isRead': notification.isRead,
            'data': notification.data,
            'priority': priority,
          });
          break;
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            throw ServerException(
              'Failed to save notification after $maxRetries attempts: $e',
            );
          }
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }

      if (docRef == null) {
        throw ServerException('Failed to create notification document');
      }

      // Get recipient FCM token with better error handling
      String? fcmToken;
      String? recipientLanguage = 'fr'; // Default language
      try {
        final collection = recipientRole == 'doctor' ? 'medecins' : 'patients';
        final userDoc =
            await firestore.collection(collection).doc(recipientId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          fcmToken = userData?['fcmToken'] as String?;
          recipientLanguage = userData?['preferredLanguage'] as String? ?? 'fr';

          if (fcmToken == null || fcmToken.isEmpty) {
            print(
              'No FCM token found for recipient $recipientId in $collection',
            );
            // Try to get from users collection as fallback
            final fallbackDoc =
                await firestore.collection('users').doc(recipientId).get();
            if (fallbackDoc.exists) {
              fcmToken = fallbackDoc.data()?['fcmToken'] as String?;
            }
          }
        } else {
          print('Recipient $recipientId not found in $collection');
        }
      } catch (e) {
        print('Error fetching FCM token for recipient $recipientId: $e');
      }

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _sendFCMNotificationWithRetry(
          fcmToken: fcmToken,
          title: title,
          body: body,
          type: type,
          priority: priority,
          sound: sound,
          icon: icon,
          docRef: docRef,
          data: notification.data ?? {},
          recipientLanguage: recipientLanguage ?? 'fr',
        );
      } else {
        print(
          'No valid FCM token for recipient $recipientId, notification saved to Firestore only',
        );
      }
    } catch (e) {
      print('Error sending notification to recipient $recipientId: $e');
      throw ServerException('Failed to send notification: $e');
    }
  }

  /// Enhanced FCM sending with retry logic and better error handling
  Future<void> _sendFCMNotificationWithRetry({
    required String fcmToken,
    required String title,
    required String body,
    required NotificationType type,
    required String priority,
    required String sound,
    required String icon,
    required DocumentReference docRef,
    required Map<String, dynamic> data,
    required String recipientLanguage,
  }) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
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
          "auth_provider_x509_cert_url":
              "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url":
              "https://www.googleapis.com/robot/v1/metadata/x509/medicalapp%40medicalapp-f1951.iam.gserviceaccount.com",
        });

        final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
        final client = http.Client();
        final accessToken = await obtainAccessCredentialsViaServiceAccount(
          credentials,
          scopes,
          client,
        );

        // Enhanced FCM payload
        final fcmPayload = {
          'message': {
            'token': fcmToken,
            'notification': {'title': title, 'body': body},
            'data': {
              'notificationId': docRef.id,
              'type': NotificationUtils.notificationTypeToString(type),
              'priority': priority,
              'sound': sound,
              'icon': icon,
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'language': recipientLanguage,
              ...data.map(
                (key, value) => MapEntry(key, value?.toString() ?? ''),
              ),
            },
            'android': {
              'priority': priority == 'max' ? 'HIGH' : 'NORMAL',
              'notification': {
                'channel_id': _getChannelId(type),
                'sound': sound == 'default' ? 'default' : '$sound.mp3',
                'default_vibrate_timings': true,
                'visibility': priority == 'max' ? 'public' : 'private',
                'icon': icon,
                'color': _getNotificationColor(type),
              },
              'data': {'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
            },
            'apns': {
              'payload': {
                'aps': {
                  'badge': 1,
                  'sound': sound == 'default' ? 'default' : '$sound.caf',
                  'alert': {'title': title, 'body': body},
                  'category': NotificationUtils.notificationTypeToString(type),
                },
              },
              'headers': {
                'apns-priority': priority == 'max' ? '10' : '5',
                'apns-collapse-id': NotificationUtils.notificationTypeToString(
                  type,
                ),
              },
            },
            'webpush': {
              'headers': {'Urgency': priority == 'max' ? 'high' : 'normal'},
              'notification': {
                'title': title,
                'body': body,
                'icon': '/icons/$icon.png',
                'badge': '/icons/badge.png',
                'tag': NotificationUtils.notificationTypeToString(type),
                'requireInteraction': priority == 'max',
              },
            },
          },
        };

        // Send FCM message
        final response = await http.post(
          Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${accessToken.accessToken.data}',
          },
          body: jsonEncode(fcmPayload),
        );

        if (response.statusCode == 200) {
          print('Successfully sent FCM notification to token $fcmToken');
          break;
        } else if (response.statusCode == 404 || response.statusCode == 410) {
          // Token is invalid, remove it from user document
          await _removeInvalidFCMToken(fcmToken);
          throw ServerException('Invalid FCM token, removed from user');
        } else {
          throw ServerException(
            'FCM error: ${response.statusCode}, ${response.body}',
          );
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          throw ServerException(
            'Failed to send FCM notification after $maxRetries attempts: $e',
          );
        }
        await Future.delayed(Duration(milliseconds: 1000 * retryCount));
      }
    }
  }

  /// Get notification channel ID based on type
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.emergencyAlert:
        return 'emergency_channel';
      case NotificationType.appointmentReminder:
      case NotificationType.medicationReminder:
        return 'reminder_channel';
      case NotificationType.appointmentAccepted:
      case NotificationType.appointmentRejected:
      case NotificationType.appointmentCanceled:
        return 'appointment_channel';
      case NotificationType.newPrescription:
      case NotificationType.prescriptionUpdated:
        return 'prescription_channel';
      default:
        return 'default_channel';
    }
  }

  /// Get notification color based on type
  String _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.emergencyAlert:
        return '#FF0000'; // Red
      case NotificationType.appointmentAccepted:
        return '#4CAF50'; // Green
      case NotificationType.appointmentRejected:
      case NotificationType.appointmentCanceled:
        return '#F44336'; // Red
      case NotificationType.newPrescription:
        return '#2196F3'; // Blue
      case NotificationType.appointmentReminder:
      case NotificationType.medicationReminder:
        return '#FF9800'; // Orange
      default:
        return '#2FA7BB'; // App primary color
    }
  }

  /// Remove invalid FCM token from user documents
  Future<void> _removeInvalidFCMToken(String invalidToken) async {
    try {
      // Search in all user collections and remove the invalid token
      for (var collection in ['users', 'medecins', 'patients']) {
        final query =
            await firestore
                .collection(collection)
                .where('fcmToken', isEqualTo: invalidToken)
                .get();

        for (var doc in query.docs) {
          await doc.reference.update({'fcmToken': FieldValue.delete()});
          print('Removed invalid FCM token from ${doc.id} in $collection');
        }
      }
    } catch (e) {
      print('Error removing invalid FCM token: $e');
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
      print(
        'DEBUG: Attempting to delete notification with ID: $notificationId',
      );

      // First check if the notification exists
      final docSnapshot =
          await firestore.collection('notifications').doc(notificationId).get();

      if (!docSnapshot.exists) {
        print(
          'DEBUG: Notification $notificationId does not exist in Firestore',
        );
        throw ServerException('Notification not found');
      }

      print(
        'DEBUG: Notification $notificationId found, proceeding with deletion',
      );

      // Delete the notification
      await firestore.collection('notifications').doc(notificationId).delete();

      print(
        'DEBUG: Successfully deleted notification $notificationId from Firestore',
      );

      // Verify deletion
      final verifySnapshot =
          await firestore.collection('notifications').doc(notificationId).get();

      if (verifySnapshot.exists) {
        print(
          'DEBUG: WARNING - Notification $notificationId still exists after deletion attempt',
        );
        throw ServerException(
          'Failed to delete notification - still exists after deletion',
        );
      } else {
        print(
          'DEBUG: Confirmed - Notification $notificationId has been successfully deleted',
        );
      }
    } catch (e) {
      print('DEBUG: Error deleting notification $notificationId: $e');
      throw ServerException('Failed to delete notification: $e');
    }
  }

  /// Check if a notification exists in the database (for testing purposes)
  Future<bool> notificationExists(String notificationId) async {
    try {
      final docSnapshot =
          await firestore.collection('notifications').doc(notificationId).get();
      return docSnapshot.exists;
    } catch (e) {
      print('DEBUG: Error checking notification existence: $e');
      return false;
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
    try {
      if (userId.isEmpty) {
        return Stream.error('User ID cannot be empty');
      }

      return firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return <NotificationModel>[];
            }

            return snapshot.docs
                .map((doc) {
                  try {
                    final data = doc.data();
                    if (data.isEmpty) {
                      print(
                        'Warning: Empty notification document found: ${doc.id}',
                      );
                      return null;
                    }
                    final jsonData = {'id': doc.id, ...data};
                    return NotificationModel.fromJson(jsonData);
                  } catch (e) {
                    print('Error parsing notification ${doc.id}: $e');
                    return null;
                  }
                })
                .where((notification) => notification != null)
                .cast<NotificationModel>()
                .toList();
          })
          .handleError((error) {
            print('Error in notifications stream: $error');
            throw Exception(
              'Failed to stream notifications: ${error.toString()}',
            );
          });
    } catch (e) {
      print('Error setting up notifications stream: $e');
      return Stream.error(
        'Failed to setup notifications stream: ${e.toString()}',
      );
    }
  }
}
