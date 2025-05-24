/// Global application constants for API, Firebase, and notification configurations.
class AppConstants {
  // API Configuration
  /// Base URL for API requests.
  /// Use 'http://10.0.2.2:3000/api/v1' for Android emulators to access the host machine's localhost.
  /// Use 'http://192.168.1.18:3000/api/v1' for physical devices on the same network.
  /// For production, replace with your server URL (e.g., 'https://api.medicalapp.com/api/v1').
  static const String baseUrl = 'http://192.168.1.18:3000/api/v1';

  /// Endpoint for user authentication and management.
  static String get usersEndpoint => '$baseUrl/users';

  /// Endpoint for email-related services.
  static const String emailServiceUrl = '$baseUrl/email';

  /// Endpoint for medical dossier management.
  static const String dossierMedicalEndpoint = '$baseUrl/dossier-medical';

  // Firebase Configuration
  /// Firebase project ID, obtained from the Firebase Console.
  /// Ensure this matches your project's ID in the Firebase Console under Project Settings.
  static const String firebaseProjectId = 'medicalapp-f1951';

  // Notification Configuration
  /// Android notification channel ID for high-priority notifications.
  /// Used for FCM notifications to ensure proper display and sound/vibration settings.
  static const String notificationChannelId = 'high_importance_channel';
}
