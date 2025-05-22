import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medical_app/constants.dart'; // Import constants instead of main.dart
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/notifications/data/models/notification_model.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/utils/notification_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class NotificationRemoteDataSource {
  /// Get all notifications for a specific user
  Future<List<NotificationModel>> getNotifications(String userId);

  /// Send a notification
  Future<Unit> sendNotification({
    required String title,
    required String body,
    required String senderId,
    required String recipientId,
    required NotificationType type,
    String? appointmentId,
    String? prescriptionId,
    String? ratingId,
    Map<String, dynamic>? data,
  });

  /// Mark a notification as read
  Future<Unit> markNotificationAsRead(String notificationId);

  /// Mark all notifications as read for a specific user
  Future<Unit> markAllNotificationsAsRead(String userId);

  /// Delete a notification
  Future<Unit> deleteNotification(String notificationId);

  /// Get unread notifications count
  Future<int> getUnreadNotificationsCount(String userId);

  /// Setup FCM to receive notifications
  Future<String?> setupFCM();

  /// Save FCM token to the server
  Future<Unit> saveFCMToken(String userId, String token);

  /// Stream of notifications for a specific user
  Stream<List<NotificationModel>> notificationsStream(String userId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseMessaging firebaseMessaging;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

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
  Future<Unit> sendNotification({
    required String title,
    required String body,
    required String senderId,
    required String recipientId,
    required NotificationType type,
    String? appointmentId,
    String? prescriptionId,
    String? ratingId,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('Sending notification to $recipientId from $senderId');

      // Get sender info to include name in notification
      String senderName = '';
      try {
        final senderDoc =
            await firestore.collection('users').doc(senderId).get();
        if (senderDoc.exists) {
          senderName =
              '${senderDoc.data()?['name'] ?? ''} ${senderDoc.data()?['lastName'] ?? ''}'
                  .trim();
        }

        if (senderName.isEmpty && data != null) {
          senderName = data['doctorName'] ?? data['patientName'] ?? '';
        }

        print('Sender name: $senderName');
      } catch (e) {
        print('Error getting sender info: $e');
      }

      // Create notification model
      final notification = NotificationModel(
        id: '', // Firestore will generate ID
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
        data:
            data != null
                ? {...data, 'senderName': senderName}
                : {'senderName': senderName},
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

      print('Notification saved to Firestore with ID: ${docRef.id}');

      // Try to get recipient FCM token from users collection first
      String? fcmToken;
      final userDoc =
          await firestore.collection('users').doc(recipientId).get();

      if (userDoc.exists && userDoc.data()?['fcmToken'] != null) {
        fcmToken = userDoc.data()?['fcmToken'];
        print('Found FCM token for recipient in users collection: $fcmToken');
      }

      // If token not found or is empty, try role-specific collections
      if (fcmToken == null || fcmToken.isEmpty) {
        // Try medecins collection
        final medecinDoc =
            await firestore.collection('medecins').doc(recipientId).get();
        if (medecinDoc.exists && medecinDoc.data()?['fcmToken'] != null) {
          fcmToken = medecinDoc.data()?['fcmToken'];
          print(
            'Found FCM token for recipient in medecins collection: $fcmToken',
          );
        }

        // If still not found, try patients collection
        if (fcmToken == null || fcmToken.isEmpty) {
          final patientDoc =
              await firestore.collection('patients').doc(recipientId).get();
          if (patientDoc.exists && patientDoc.data()?['fcmToken'] != null) {
            fcmToken = patientDoc.data()?['fcmToken'];
            print(
              'Found FCM token for recipient in patients collection: $fcmToken',
            );
          }
        }
      }

      if (fcmToken != null && fcmToken.isNotEmpty) {
        // Create payload with enhanced data
        final payload = {
          'notification': {'title': title, 'body': body},
          'data': {
            'notificationId': docRef.id,
            'type': NotificationUtils.notificationTypeToString(type),
            'senderId': senderId,
            'recipientId': recipientId,
            'senderName': senderName,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        };

        if (appointmentId != null) {
          payload['data'] = {
            ...payload['data'] as Map<String, dynamic>,
            'appointmentId': appointmentId,
          };
        }
        if (prescriptionId != null) {
          payload['data'] = {
            ...payload['data'] as Map<String, dynamic>,
            'prescriptionId': prescriptionId,
          };
        }
        if (ratingId != null) {
          payload['data'] = {
            ...payload['data'] as Map<String, dynamic>,
            'ratingId': ratingId,
          };
        }

        // Add any additional data
        if (data != null) {
          payload['data'] = {
            ...payload['data'] as Map<String, dynamic>,
            ...data,
          };
        }

        try {
          // ATTEMPT 1: First attempt direct FCM sending (new method that bypasses Express)
          bool directSuccess = await sendDirectFCMNotification(
            fcmToken,
            title,
            body,
            payload,
          );

          if (directSuccess) {
            print('Notification sent successfully via direct FCM');
          } else {
            // ATTEMPT 2: If direct method fails, try through Cloud Functions via Firestore trigger
            await firestore.collection('fcm_requests').add({
              'token': fcmToken,
              'payload': payload,
              'timestamp': FieldValue.serverTimestamp(),
            });
            print('FCM request added to queue via Firestore');

            // ATTEMPT 3: Try using Express server as final fallback
            try {
              // Convert all data values to strings
              Map<String, String> stringData = {};
              (payload['data'] as Map<String, dynamic>).forEach((key, value) {
                if (value == null) {
                  stringData[key] = '';
                } else if (value is Map || value is List) {
                  stringData[key] = jsonEncode(value);
                } else {
                  stringData[key] = value.toString();
                }
              });

              final http.Response response = await http.post(
                Uri.parse(AppConstants.sendNotification),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'token': fcmToken,
                  'title': title,
                  'body': body,
                  'data': stringData,
                }),
              );

              if (response.statusCode == 200) {
                print('Notification sent successfully via Express server');
              } else {
                print(
                  'Failed to send notification via Express: ${response.statusCode}, ${response.body}',
                );
              }
            } catch (serverError) {
              print(
                'Error sending notification via Express server: $serverError',
              );
            }
          }
        } catch (e) {
          print('Error during notification sending: $e');
        }
      } else {
        print(
          'No FCM token found for recipient: $recipientId in any collection',
        );
        // This is not a failure state - we still created the notification in Firestore
        // The user will see it when they open the app
      }

      // Return success since we saved the notification to Firestore
      return unit;
    } catch (e) {
      print('Error sending notification: $e');
      throw ServerException('Failed to send notification: $e');
    }
  }

  // Direct FCM notification method that uses the HTTP v1 API
  Future<bool> sendDirectFCMNotification(
    String token,
    String title,
    String body,
    Map<String, dynamic> payload,
  ) async {
    try {
      // Get an access token for FCM API
      final String? accessToken = await getAccessToken();

      if (accessToken == null) {
        print(
          'Failed to get access token for FCM, trying Express server v1 endpoint',
        );
        return await sendViaExpressServerV1(token, title, body, payload);
      }

      // Your Firebase project ID from constants
      const String projectId = AppConstants.firebaseProjectId;

      if (projectId == 'YOUR_FIREBASE_PROJECT_ID') {
        print(
          'Firebase Project ID not set - trying Express server v1 endpoint',
        );
        return await sendViaExpressServerV1(token, title, body, payload);
      }

      // Format the notification payload for the HTTP v1 API
      final Map<String, dynamic> fcmMessage = {
        'message': {
          'token': token,
          'notification': {'title': title, 'body': body},
          'data':
              payload['data'] != null
                  ? Map<String, String>.from(
                    payload['data'].map(
                      (key, value) => MapEntry(key, value?.toString() ?? ''),
                    ),
                  )
                  : {},
          'android': {
            'priority': 'HIGH',
            'notification': {
              'channel_id': 'high_importance_channel',
              'priority': 'HIGH',
              'default_sound': true,
              'default_vibrate_timings': true,
            },
          },
          'apns': {
            'payload': {
              'aps': {'badge': 1, 'sound': 'default', 'content-available': 1},
            },
          },
        },
      };

      // Send the message using the HTTP v1 API
      final http.Response response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(fcmMessage),
      );

      if (response.statusCode == 200) {
        print(
          'Successfully sent direct FCM notification using HTTP v1 API: ${response.body}',
        );
        return true;
      } else {
        print(
          'Error calling FCM API: ${response.statusCode}, ${response.body}, trying Express server',
        );
        return await sendViaExpressServerV1(token, title, body, payload);
      }
    } catch (e) {
      print(
        'Exception sending direct FCM notification: $e, trying Express server',
      );
      return await sendViaExpressServerV1(token, title, body, payload);
    }
  }

  // Send notification via Express server using v1 API
  Future<bool> sendViaExpressServerV1(
    String token,
    String title,
    String body,
    Map<String, dynamic> payload,
  ) async {
    try {
      final http.Response response = await http.post(
        Uri.parse(AppConstants.sendNotificationV1),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': title,
          'body': body,
          'data': payload['data'] ?? {},
        }),
      );

      if (response.statusCode == 200) {
        print('Successfully sent notification via Express server v1 endpoint');
        return true;
      } else {
        print(
          'Error sending notification via Express server: ${response.statusCode}, ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Exception sending notification via Express server: $e');
      return false;
    }
  }

  // Get an access token for FCM API using Firebase Authentication
  Future<String?> getAccessToken() async {
    try {
      // Get the access token from our Express server
      try {
        final response = await http.get(
          Uri.parse(AppConstants.getFcmToken),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'success' && data['token'] != null) {
            print('Successfully retrieved FCM token from Express server');
            return data['token'];
          } else {
            print(
              'Invalid response format from FCM token endpoint: ${response.body}',
            );
          }
        } else {
          print(
            'Failed to get FCM token: HTTP ${response.statusCode}, ${response.body}',
          );
        }
      } catch (e) {
        print('Error getting token from server: $e');
      }

      // Return null to fallback to other notification methods
      return null;
    } catch (e) {
      print('Error getting access token: $e');
      return null;
    }
  }

  @override
  Future<Unit> markNotificationAsRead(String notificationId) async {
    try {
      await firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
      return unit;
    } catch (e) {
      throw ServerException('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<Unit> markAllNotificationsAsRead(String userId) async {
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
      return unit;
    } catch (e) {
      throw ServerException('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<Unit> deleteNotification(String notificationId) async {
    try {
      await firestore.collection('notifications').doc(notificationId).delete();
      return unit;
    } catch (e) {
      throw ServerException('Failed to delete notification: $e');
    }
  }

  @override
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
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

        // Initialize local notifications
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.high,
        );

        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);

        return token;
      } else {
        throw ServerException('FCM permissions denied');
      }
    } catch (e) {
      throw ServerException('Failed to setup FCM: $e');
    }
  }

  @override
  Future<Unit> saveFCMToken(String userId, String token) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
      return unit;
    } catch (e) {
      throw ServerException('Failed to save FCM token: $e');
    }
  }

  @override
  Stream<List<NotificationModel>> notificationsStream(String userId) {
    try {
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
          );
    } catch (e) {
      throw ServerException('Failed to get notifications stream: $e');
    }
  }
}
