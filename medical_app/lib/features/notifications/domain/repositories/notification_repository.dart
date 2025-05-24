import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/utils/notification_utils.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationEntity>>> getNotifications(String userId);

  Future<Either<Failure, void>> sendNotification({
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

  Future<Either<Failure, void>> markNotificationAsRead(String notificationId);

  Future<Either<Failure, void>> markAllNotificationsAsRead(String userId);

  Future<Either<Failure, void>> deleteNotification(String notificationId);

  Future<Either<Failure, int>> getUnreadNotificationsCount(String userId);

  Future<Either<Failure, String?>> setupFCM();

  Future<Either<Failure, void>> saveFCMToken(String userId, String token);

  Stream<List<NotificationEntity>> notificationsStream(String userId);
}