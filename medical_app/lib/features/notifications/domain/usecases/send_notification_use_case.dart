import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:medical_app/features/notifications/utils/notification_utils.dart';

class SendNotificationUseCase {
  final NotificationRepository repository;

  SendNotificationUseCase(this.repository);

  Future<Either<Failure, void>> call({
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
    return await repository.sendNotification(
      title: title,
      body: body,
      senderId: senderId,
      recipientId: recipientId,
      type: type,
      recipientRole: recipientRole,
      appointmentId: appointmentId,
      prescriptionId: prescriptionId,
      ratingId: ratingId,
      data: data,
    );
  }
}