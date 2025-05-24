enum NotificationType {
  newAppointment,
  appointmentAccepted,
  appointmentRejected,
  appointmentAssigned,
  newPrescription,
  prescriptionUpdated,
  newMessage,
  newRating,
}

class NotificationUtils {
  static String notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.newAppointment:
        return 'newAppointment';
      case NotificationType.appointmentAccepted:
        return 'appointmentAccepted';
      case NotificationType.appointmentRejected:
        return 'appointmentRejected';
      case NotificationType.appointmentAssigned:
        return 'appointmentAssigned';
      case NotificationType.newPrescription:
        return 'newPrescription';
      case NotificationType.prescriptionUpdated:
        return 'prescriptionUpdated';
      case NotificationType.newMessage:
        return 'newMessage';
      case NotificationType.newRating:
        return 'newRating';
    }
  }

  static NotificationType stringToNotificationType(String type) {
    switch (type) {
      case 'newAppointment':
        return NotificationType.newAppointment;
      case 'appointmentAccepted':
        return NotificationType.appointmentAccepted;
      case 'appointmentRejected':
        return NotificationType.appointmentRejected;
      case 'appointmentAssigned':
        return NotificationType.appointmentAssigned;
      case 'newPrescription':
        return NotificationType.newPrescription;
      case 'prescriptionUpdated':
        return NotificationType.prescriptionUpdated;
      case 'newMessage':
        return NotificationType.newMessage;
      case 'newRating':
        return NotificationType.newRating;
      default:
        return NotificationType.newAppointment;
    }
  }
}