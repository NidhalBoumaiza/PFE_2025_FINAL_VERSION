import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';

class NotificationUtils {
  /// Convert a string to NotificationType enum
  static NotificationType stringToNotificationType(String type) {
    switch (type) {
      case 'newAppointment':
        return NotificationType.newAppointment;
      case 'appointmentAccepted':
        return NotificationType.appointmentAccepted;
      case 'appointmentRejected':
        return NotificationType.appointmentRejected;
      case 'newRating':
        return NotificationType.newRating;
      case 'newPrescription':
        return NotificationType.newPrescription;
      default:
        return NotificationType.newAppointment;
    }
  }

  /// Convert NotificationType enum to string
  static String notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.newAppointment:
        return 'newAppointment';
      case NotificationType.appointmentAccepted:
        return 'appointmentAccepted';
      case NotificationType.appointmentRejected:
        return 'appointmentRejected';
      case NotificationType.newRating:
        return 'newRating';
      case NotificationType.newPrescription:
        return 'newPrescription';
    }
  }

  /// Get notification title based on type
  static String getNotificationTitle(NotificationType type) {
    switch (type) {
      case NotificationType.newAppointment:
        return 'New Appointment';
      case NotificationType.appointmentAccepted:
        return 'Appointment Accepted';
      case NotificationType.appointmentRejected:
        return 'Appointment Rejected';
      case NotificationType.newRating:
        return 'New Rating';
      case NotificationType.newPrescription:
        return 'New Prescription';
    }
  }
}
