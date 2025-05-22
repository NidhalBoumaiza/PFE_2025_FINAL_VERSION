import 'package:equatable/equatable.dart';

enum NotificationType {
  newAppointment,
  appointmentAccepted,
  appointmentRejected,
  newRating,
  newPrescription
}

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final String senderId;
  final String recipientId;
  final NotificationType type;
  final String? appointmentId;
  final String? prescriptionId;
  final String? ratingId;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.senderId,
    required this.recipientId,
    required this.type,
    this.appointmentId,
    this.prescriptionId,
    this.ratingId,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        senderId,
        recipientId,
        type,
        appointmentId,
        prescriptionId,
        ratingId,
        createdAt,
        isRead,
        data,
      ];
} 