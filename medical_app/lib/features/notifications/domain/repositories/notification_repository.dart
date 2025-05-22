import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  /// Get all notifications for a specific user
  Future<Either<Failure, List<NotificationEntity>>> getNotifications(String userId);
  
  /// Send a notification
  Future<Either<Failure, Unit>> sendNotification({
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
  Future<Either<Failure, Unit>> markNotificationAsRead(String notificationId);
  
  /// Mark all notifications as read for a specific user
  Future<Either<Failure, Unit>> markAllNotificationsAsRead(String userId);
  
  /// Delete a notification
  Future<Either<Failure, Unit>> deleteNotification(String notificationId);
  
  /// Get unread notifications count
  Future<Either<Failure, int>> getUnreadNotificationsCount(String userId);
  
  /// Setup FCM to receive notifications
  Future<Either<Failure, String?>> setupFCM();
  
  /// Save FCM token to the server
  Future<Either<Failure, Unit>> saveFCMToken(String userId, String token);
  
  /// Stream of notifications for a specific user
  Stream<List<NotificationEntity>> notificationsStream(String userId);
} 