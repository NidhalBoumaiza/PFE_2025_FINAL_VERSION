/// Global application constants
class AppConstants {
  // API Base URL (use 10.0.2.2 for emulator, or your server IP for physical devices)
  static const String baseUrl = 'http://192.168.1.18:3000/api/v1';

  // API Endpoints
  static String get sendNotification => '$baseUrl/notifications/send';
  static String get sendNotificationV1 => '$baseUrl/notifications/send-v1';
  static String get saveNotification => '$baseUrl/notifications/save';
  static String get getUserToken => '$baseUrl/notifications/user-token';
  static String get getFcmToken => '$baseUrl/notifications/get-fcm-token';
  static String get usersEndpoint =>
      '$baseUrl/users'; // Authentication endpoints

  // Firebase Configuration
  static const String firebaseProjectId =
      'medicalapp-f1951'; // Replace with your project ID


  static const String emailServiceUrl = '$baseUrl/email';
  static const String dossierMedicalEndpoint =
      '$baseUrl/dossier-medical';
}
