import 'package:get/get_navigation/src/root/internacionalization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

// Language service to manage language preferences
class LanguageService {
  static const String LANGUAGE_KEY = 'app_language';

  // Save language preference
  static Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LANGUAGE_KEY, languageCode);
  }

  // Get saved language preference
  static Future<Locale?> getSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(LANGUAGE_KEY);

    if (languageCode == null) return null;

    switch (languageCode) {
      case 'fr':
        return const Locale('fr', 'FR');
      case 'en':
        return const Locale('en', 'US');
      case 'ar':
        return const Locale('ar', 'AR');
      default:
        return null;
    }
  }

  // Get language name from language code
  static String getLanguageName(String localeCode) {
    switch (localeCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return 'Français';
    }
  }

  // Get language code from language name
  static String? getLanguageCode(String languageName) {
    switch (languageName) {
      case 'Français':
        return 'fr';
      case 'English':
        return 'en';
      case 'العربية':
        return 'ar';
      default:
        return null;
    }
  }
}

// ignore_for_file: constant_identifier_names

class AppTranslations extends Translations {
  // Define constants (French as base language)
  static const String ServerFailureMessage =
      "Une erreur est survenue, veuillez réessayer plus tard";
  static const String OfflineFailureMessage =
      "Vous n'êtes pas connecté à internet";
  static const String UnauthorizedFailureMessage =
      "Email ou mot de passe incorrect";
  static const String SignUpSuccessMessage = "Inscription réussie 😊";
  static const String InvalidEmailMessage = "L'adresse email est invalide";
  static const String PasswordMismatchMessage =
      "Les mots de passe ne correspondent pas";

  @override
  Map<String, Map<String, String>> get keys => {
    'fr_FR': {
      'title': 'Application Médicale',
      'server_failure_message': ServerFailureMessage,
      'offline_failure_message': OfflineFailureMessage,
      'unauthorized_failure_message': UnauthorizedFailureMessage,
      'sign_up_success_message': SignUpSuccessMessage,
      'invalid_email_message': InvalidEmailMessage,
      'password_mismatch_message': PasswordMismatchMessage,
      'unexpected_error_message': "Une erreur inattendue s'est produite",
      'invalid_credentials': "Email ou mot de passe incorrect",
      'login_success': "Connexion réussie",

      // Location permission strings
      'location_permission_title': 'Activer la localisation',
      'location_permission_message':
          'Pour trouver les médecins près de chez vous, nous avons besoin de votre position. Voulez-vous activer la localisation ?',
      'allow': 'Autoriser',
      'deny': 'Refuser',
      'location_enabled_success': 'Localisation activée avec succès',
      'location_disabled': 'Localisation désactivée',
      'location_permission_denied': 'Permission de localisation refusée',
      'enable_location_settings': 'Activer les paramètres de localisation',
      'location_required_for_search':
          'La localisation est nécessaire pour rechercher des médecins à proximité',
      'location_enabled': 'Localisation activée',
      'location_disabled': 'Localisation désactivée',

      // New fields translations
      'blood_type': 'Groupe sanguin',
      'select_blood_type': 'Sélectionnez votre groupe sanguin',
      'height': 'Taille',
      'enter_height': 'Entrez votre taille',
      'weight': 'Poids',
      'enter_weight': 'Entrez votre poids',
      'allergies': 'Allergies',
      'enter_allergies': 'Entrez vos allergies (séparées par des virgules)',
      'chronic_diseases': 'Maladies chroniques',
      'enter_chronic_diseases': 'Entrez vos maladies chroniques',
      'emergency_contact': 'Contact d\'urgence',
      'emergency_contact_name': 'Nom du contact d\'urgence',
      'enter_emergency_name': 'Entrez le nom du contact d\'urgence',
      'emergency_relationship': 'Relation avec le contact d\'urgence',
      'enter_emergency_relationship':
          'Entrez votre relation (ex: parent, conjoint)',
      'emergency_phone': 'Téléphone du contact d\'urgence',
      'enter_emergency_phone': 'Entrez le numéro de téléphone',
      'education': 'Formation',
      'enter_education': 'Entrez vos formations',
      'experience': 'Expérience',
      'enter_experience': 'Entrez vos expériences professionnelles',
      'consultation_fee_label': 'Tarif de consultation',
      'consultation_fee_hint': 'Entrez votre tarif de consultation',
      'currency': 'DT',
      'medical_information': 'Informations médicales',
      'address': 'Adresse',
      'enter_address': 'Entrez votre adresse',
      'location': 'Localisation',
      'save': 'Enregistrer',

      // Login and Sign-Up page strings
      'sign_in': 'Connexion',
      'email': 'Email',
      // ... rest of the existing translations
    },
    'en_US': {
      'title': 'Medical App',
      'server_failure_message': 'An error occurred, please try again later',
      'offline_failure_message': 'You are not connected to the internet',
      'unauthorized_failure_message': 'Incorrect email or password',
      'sign_up_success_message': 'Registration successful 😊',
      'invalid_email_message': 'The email address is invalid',
      'password_mismatch_message': 'Passwords do not match',
      'unexpected_error_message': 'An unexpected error occurred',
      'invalid_credentials': 'Incorrect email or password',
      'login_success': 'Login successful',

      // Location permission strings
      'location_permission_title': 'Enable Location',
      'location_permission_message':
          'To find doctors near you, we need your location. Would you like to enable location services?',
      'allow': 'Allow',
      'deny': 'Deny',
      'location_enabled_success': 'Location enabled successfully',
      'location_disabled': 'Location disabled',
      'location_permission_denied': 'Location permission denied',
      'enable_location_settings': 'Enable Location Settings',
      'location_required_for_search':
          'Location is required to search for nearby doctors',
      'location_enabled': 'Location enabled',
      'location_disabled': 'Location disabled',

      // New fields translations
      'blood_type': 'Blood Type',
      'select_blood_type': 'Select your blood type',
      'height': 'Height',
      'enter_height': 'Enter your height',
      'weight': 'Weight',
      'enter_weight': 'Enter your weight',
      'allergies': 'Allergies',
      'enter_allergies': 'Enter your allergies (comma separated)',
      'chronic_diseases': 'Chronic Diseases',
      'enter_chronic_diseases': 'Enter your chronic diseases',
      'emergency_contact': 'Emergency Contact',
      'emergency_contact_name': 'Emergency Contact Name',
      'enter_emergency_name': 'Enter emergency contact name',
      'emergency_relationship': 'Relationship with Emergency Contact',
      'enter_emergency_relationship':
          'Enter your relationship (e.g. parent, spouse)',
      'emergency_phone': 'Emergency Contact Phone',
      'enter_emergency_phone': 'Enter phone number',
      'education': 'Education',
      'enter_education': 'Enter your education',
      'experience': 'Experience',
      'enter_experience': 'Enter your professional experience',
      'consultation_fee_label': 'Consultation Fee',
      'consultation_fee_hint': 'Enter your consultation fee',
      'currency': 'TND',
      'medical_information': 'Medical Information',
      'address': 'Address',
      'enter_address': 'Enter your address',
      'location': 'Location',
      'save': 'Save',

      // Login and Sign-Up page strings
      'sign_in': 'Sign In',
      'email': 'Email',
      // ... rest of the existing translations
    },
    // ... rest of the language keys
  };
}
