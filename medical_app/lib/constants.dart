/// Global application constants for API, Firebase, and notification configurations.
class AppConstants {
  // API Configuration
  /// Base URL for API requests.
  /// Use 'http://10.0.2.2:3000/api/v1' for Android emulators to access the host machine's localhost.
  /// Use 'http://192.168.1.18:3000/api/v1' for physical devices on the same network.
  /// For production, replace with your server URL (e.g., 'https://api.medicalapp.com/api/v1').
  static const String baseUrl = 'http://192.168.1.24:3000/api/v1';

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

  static const String mailApiKey = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiI0IiwianRpIjoiYjZlZDUyMGFhMjBmMjRmYjQ2NDMyOWEyYmFhNTU1ZTZlNjQwMWFjZWNiODRkZGI1Yzk1MzdiYzc4Yzk0OTkwNGMzZjkwM2M0MGVhN2MzMDgiLCJpYXQiOjE3NDk0NzI1NTQuNzQxNzg5LCJuYmYiOjE3NDk0NzI1NTQuNzQxNzkyLCJleHAiOjQ5MDUxNDYxNTQuNzM2OTEzLCJzdWIiOiIxNTk1NTQ5Iiwic2NvcGVzIjpbXX0.b5zt1s4D00lfbO0cWbEgG3zOEV3OIOqp1j5elVtWyGcR3T2tn4nlLUUhqKxcYmb1CJcLS01aeavWO4H9Dp3BHRfZQuymEw94Naf8elrQ6QLDLW6OxNR3izTHxEGxBUXIQypf9MYs9xfvVWnp3ARw0yw4WGDnXC89xGwntZJcOTJn5Hvcsc6oRH89Rl3JotCdcEQT0DaUnrFS3zI3R3qm_m52RxUoy-YtVBvUGmaykian8huj_C-z3aRBbjZU7hUgSyxHnYQPICOCiy0vdOj22ZSfiw51SSbohohcUfeBSUam_Nk5ZBoRMo9t2_jOw0QaoYKHvK7XsVvQrHPq4PnmPh8sBz_nyOjS6WyE4lBGxKAEnxlNhtk2dcqNhPW2EgbCD-JwyZ7LIpty_zE0OwFVHZ-vUcUWAPGM7otZFTWa85TjRke9WPmvZrhC_31JQY76tvolCdI__SohMwDGDJrTYFhadOEbDTVwXiM5h-6GAcxbyA97E8BgDM4OpcrXDAq1k1tgDUEJ2DuIeHvA0BDi_WiKOmwWeANoC34Ee6PFMNj4PzOimVqGVgg4PSX9hZicETjEBZ-dW5m-B87-o-8TcpNIsQQn8Gt7x6bLJYXNC6F6SDbELh97CS6LuxDbxvvPPvSRJNWA_sWBYu67AZ1lIALyvCkwzh47GbPdKb26BNk" ;
}
