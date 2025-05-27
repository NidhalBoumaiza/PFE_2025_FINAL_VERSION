enum NotificationType {
  newAppointment,
  appointmentAccepted,
  appointmentRejected,
  appointmentAssigned,
  newPrescription,
  prescriptionUpdated,
  newMessage,
  newRating,
  appointmentCanceled,
  prescriptionCanceled,
  prescriptionRefilled,
  dossierUpdate,
  appointmentReminder,
  medicationReminder,
  emergencyAlert,
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
      case NotificationType.appointmentCanceled:
        return 'appointmentCanceled';
      case NotificationType.prescriptionCanceled:
        return 'prescriptionCanceled';
      case NotificationType.prescriptionRefilled:
        return 'prescriptionRefilled';
      case NotificationType.dossierUpdate:
        return 'dossierUpdate';
      case NotificationType.appointmentReminder:
        return 'appointmentReminder';
      case NotificationType.medicationReminder:
        return 'medicationReminder';
      case NotificationType.emergencyAlert:
        return 'emergencyAlert';
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
      case 'appointmentCanceled':
        return NotificationType.appointmentCanceled;
      case 'prescriptionCanceled':
        return NotificationType.prescriptionCanceled;
      case 'prescriptionRefilled':
        return NotificationType.prescriptionRefilled;
      case 'dossierUpdate':
        return NotificationType.dossierUpdate;
      case 'appointmentReminder':
        return NotificationType.appointmentReminder;
      case 'medicationReminder':
        return NotificationType.medicationReminder;
      case 'emergencyAlert':
        return NotificationType.emergencyAlert;
      default:
        return NotificationType.newAppointment;
    }
  }

  /// Get notification priority based on type
  static String getNotificationPriority(NotificationType type) {
    switch (type) {
      case NotificationType.emergencyAlert:
        return 'max';
      case NotificationType.appointmentReminder:
      case NotificationType.medicationReminder:
        return 'high';
      case NotificationType.appointmentAccepted:
      case NotificationType.appointmentRejected:
      case NotificationType.appointmentCanceled:
      case NotificationType.newPrescription:
        return 'high';
      case NotificationType.newAppointment:
      case NotificationType.appointmentAssigned:
      case NotificationType.prescriptionUpdated:
      case NotificationType.newMessage:
      case NotificationType.newRating:
        return 'default';
      default:
        return 'default';
    }
  }

  /// Get notification sound based on type
  static String getNotificationSound(NotificationType type) {
    switch (type) {
      case NotificationType.emergencyAlert:
        return 'emergency_sound';
      case NotificationType.appointmentReminder:
      case NotificationType.medicationReminder:
        return 'reminder_sound';
      default:
        return 'default';
    }
  }

  /// Get notification icon based on type
  static String getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newAppointment:
      case NotificationType.appointmentAccepted:
      case NotificationType.appointmentRejected:
      case NotificationType.appointmentAssigned:
      case NotificationType.appointmentCanceled:
      case NotificationType.appointmentReminder:
        return 'ic_appointment';
      case NotificationType.newPrescription:
      case NotificationType.prescriptionUpdated:
      case NotificationType.prescriptionCanceled:
      case NotificationType.prescriptionRefilled:
      case NotificationType.medicationReminder:
        return 'ic_prescription';
      case NotificationType.newMessage:
        return 'ic_message';
      case NotificationType.newRating:
        return 'ic_rating';
      case NotificationType.dossierUpdate:
        return 'ic_medical_record';
      case NotificationType.emergencyAlert:
        return 'ic_emergency';
      default:
        return 'ic_notification';
    }
  }
}
