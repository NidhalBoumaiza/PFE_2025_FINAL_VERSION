import 'package:get/get.dart';
import 'package:flutter/material.dart';

const String ServerFailureMessage =
    'Une erreur s\'est produite, veuillez réessayer plus tard';
const String OfflineFailureMessage = 'Vous n\'êtes pas connecté à Internet';
const String UnauthorizedFailureMessage = 'Email ou mot de passe incorrect';
const String SignUpSuccessMessage = 'Inscription réussie 😊';
const String InvalidEmailMessage = 'L\'adresse email n\'est pas valide';
const String PasswordMismatchMessage = 'Les mots de passe ne correspondent pas';

class LanguageService extends Translations {
  static Locale? get locale => Get.deviceLocale;
  static const Locale fallbackLocale = Locale('fr', 'FR');

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

      // Language names
      'french': 'Français',
      'english': 'Anglais',
      'arabic': 'Arabe',

      // App information
      'app_name_version': 'Application Médicale v1.0.0',
      'copyright': '© 2025 Application Médicale. Tous droits réservés.',

      // Login and Sign-Up page strings
      'sign_in': 'Se connecter',
      'email': 'Email',
      'email_hint': 'Entrez votre email',
      'email_placeholder': 'Entrez votre email',
      'password': 'Mot de passe',
      'password_hint': 'Entrez votre mot de passe',
      'password_placeholder': 'Entrez votre mot de passe',
      'forgot_password': 'Mot de passe oublié ?',
      'connect_button_text': 'Se connecter',
      'no_account': 'Vous n\'avez pas de compte ?',
      'sign_up': 'S\'inscrire',
      'continue_with_google': 'Continuer avec Google',
      'signing_in_with_google': 'Connexion avec Google...',
      'email_required': 'L\'email est requis',
      'password_required': 'Le mot de passe est requis',
      'or_login_with': 'Ou se connecter avec',
      'signup_title': 'S\'inscrire',
      'next_button': 'Suivant',
      'name_label': 'Nom',
      'name_hint': 'Entrez votre nom',
      'first_name_label': 'Prénom',
      'first_name_hint': 'Entrez votre prénom',
      'date_of_birth_label': 'Date de naissance',
      'date_of_birth_hint': 'Sélectionnez votre date de naissance',
      'phone_number_label': 'Numéro de téléphone',
      'phone_number_hint': 'Entrez votre numéro de téléphone',
      'medical_history_label': 'Antécédents médicaux',
      'medical_history_hint': 'Décrivez vos antécédents médicaux',
      'specialty_label': 'Spécialité',
      'specialty_hint': 'Entrez votre spécialité',
      'license_number_label': 'Numéro de licence',
      'license_number_hint': 'Entrez votre numéro de licence',
      'confirm_password_label': 'Confirmer le mot de passe',
      'confirm_password_hint': 'Confirmez votre mot de passe',
      'confirm_password_placeholder': 'Confirmez votre mot de passe',
      'register_button': 'S\'inscrire',
      'name_required': 'Le nom est requis',
      'first_name_required': 'Le prénom est requis',
      'date_of_birth_required': 'La date de naissance est obligatoire',
      'phone_number_required': 'Le numéro de téléphone est requis',
      'specialty_required': 'La spécialité est requise',
      'license_number_required': 'Le numéro de licence est requis',
      'confirm_password_required':
          'La confirmation du mot de passe est requise',

      // Password and authentication related
      'create_password_title': 'Créer un mot de passe',
      'create_account_button': 'Créer le compte',
      'continue_button': 'Continuer',
      'back_button': 'Retour',
      'sending_verification_code': 'Envoi du code de vérification...',
      'account_verification_required': 'Vérification du compte requise',
      'account_not_activated_message':
          'Votre compte n\'a pas été activé. Veuillez vérifier votre email pour continuer.',
      'verify_now': 'Vérifier maintenant',
      'creating_test_account': 'Création du compte de test...',
      'test_account_created': 'Compte de test créé',
      'email_label': 'Email',
      'password_label': 'Mot de passe',
      'account_already_activated': 'Compte déjà activé pour les tests.',
      'error': 'Erreur',
      'failed_to_create_test_account': 'Échec de la création du compte de test',

      // Forgot password
      'forgot_password_title': 'Mot de passe oublié',
      'verification_code_sent': 'Code de vérification envoyé',
      'send_code_button': 'Envoyer le code',
      'back_to_login': 'Retour à la connexion',

      // Reset password
      'reset_password_title': 'Réinitialiser le mot de passe',
      'new_password_title': 'Nouveau mot de passe',
      'create_new_password_for_account':
          'Créez un nouveau mot de passe pour votre compte',
      'new_password_label': 'Nouveau mot de passe',
      'new_password_placeholder': 'Entrez votre nouveau mot de passe',
      'password_reset_success': 'Mot de passe réinitialisé avec succès',
      'reset_password_button': 'Réinitialiser le mot de passe',

      // Settings page strings
      'settings': 'Paramètres',
      'appearance': 'Apparence',
      'language': 'Langue',
      'notifications': 'Notifications',
      'dark_mode': 'Mode sombre',
      'light_mode': 'Mode clair',
      'account': 'Compte',
      'about': 'À propos',
      'edit_profile': 'Modifier le profil',
      'change_password': 'Changer le mot de passe',
      'logout': 'Se déconnecter',
      'logout_success': 'Déconnexion réussie',
      'update_your_personal_information':
          'Mettre à jour vos informations personnelles',
      'edit_profile_and_office_location':
          'Modifier le profil et l\'emplacement du bureau',
      'profile_updated_successfully': 'Profil mis à jour avec succès',
      'error_updating_profile': 'Erreur lors de la mise à jour du profil',
      'sign_out_of_your_account': 'Se déconnecter de votre compte',
      'logout_confirmation': 'Êtes-vous sûr de vouloir vous déconnecter ?',

      // Change password translations
      'update_password': 'Mettre à jour le mot de passe',
      'enter_current_and_new_password':
          'Entrez votre mot de passe actuel et le nouveau',
      'current_password': 'Mot de passe actuel',
      'new_password': 'Nouveau mot de passe',
      'confirm_new_password': 'Confirmer le nouveau mot de passe',
      'current_password_required': 'Le mot de passe actuel est requis',
      'new_password_required': 'Le nouveau mot de passe est requis',
      'confirm_new_password_required':
          'La confirmation du nouveau mot de passe est requise',
      'password_min_length':
          'Le mot de passe doit contenir au moins 6 caractères',
      'passwords_dont_match': 'Les mots de passe ne correspondent pas',
      'current_password_placeholder': 'Entrez votre mot de passe actuel',
      'new_password_placeholder': 'Entrez votre nouveau mot de passe',
      'confirm_password_placeholder': 'Confirmez votre nouveau mot de passe',
      'password_update_success': 'Mot de passe mis à jour avec succès',
      'current_password_incorrect': 'Le mot de passe actuel est incorrect',
      'password_update_error': 'Erreur lors de la mise à jour du mot de passe',
      'user_not_found': 'Utilisateur non trouvé',
      'delete_account': 'Supprimer le compte',
      'delete_account_warning':
          'Cela supprimera définitivement votre compte et toutes vos données',
      'delete_account_description':
          'Cette action est irréversible. Toutes vos données seront définitivement supprimées.',
      'confirm_password_to_delete': 'Entrez votre mot de passe pour confirmer',
      'enter_password': 'Entrez votre mot de passe',
      'confirm_delete_account': 'Confirmer la suppression du compte',
      'delete': 'Supprimer',
      'account_deleted_successfully': 'Compte supprimé avec succès',
      'delete_account_error': 'Erreur lors de la suppression du compte',

      // Additional missing keys
      'enabled': 'activées',
      'disabled': 'désactivées',
      'failed_to_load_profile': 'Échec du chargement du profil',
      'update_your_password': 'Mettre à jour votre mot de passe',
      'cancel': 'Annuler',
      'notification_settings': 'Paramètres de notification',
      'manage_notification_preferences':
          'Gérer les préférences de notification',
      'notification_settings_coming_soon':
          'Paramètres de notification bientôt disponibles',
      'ok': 'OK',
      'appointments': 'Rendez-vous',
      'messages': 'Messages',
      'prescriptions': 'Ordonnances',
      'error_loading_user_data':
          'Erreur lors du chargement des données utilisateur',

      // First Aid / Emergency translations
      'first_aid_title': 'Premiers Secours',
      'search_condition': 'Rechercher une condition...',
      'all': 'Tout',
      'emergency': 'Urgence',
      'common': 'Commun',
      'children': 'Enfants',
      'elderly': 'Personnes âgées',
      'no_results_found': 'Aucun résultat trouvé',
      'try_another_search': 'Essayez une autre recherche',
      'description': 'Description',
      'recommended_first_aid': 'Premiers secours recommandés',
      'assess_situation': 'Évaluer la situation',
      'assess_situation_desc':
          'Vérifier la sécurité de la zone et l\'état de la victime',
      'call_for_help': 'Appeler à l\'aide',
      'call_for_help_desc': 'Contacter les services d\'urgence si nécessaire',
      'administer_first_aid': 'Administrer les premiers secours',
      'administer_first_aid_desc':
          'Appliquer les techniques appropriées selon la situation',
      'monitor_condition': 'Surveiller l\'état',
      'monitor_condition_desc':
          'Continuer à surveiller la victime jusqu\'à l\'arrivée des secours',
      'emergency_call': 'Appel d\'urgence',

      // First aid conditions
      'cpr_title': 'Réanimation cardiopulmonaire (RCP)',
      'cpr_desc': 'Techniques de réanimation en cas d\'arrêt cardiaque',
      'bleeding_title': 'Hémorragie',
      'bleeding_desc': 'Comment arrêter le saignement et traiter les plaies',
      'burns_title': 'Brûlures',
      'burns_desc': 'Traitement des brûlures légères à sévères',
      'choking_title': 'Étouffement',
      'choking_desc':
          'Manœuvre de Heimlich et techniques de dégagement des voies respiratoires',
      'fractures_title': 'Fractures',
      'fractures_desc': 'Immobilisation et soins des fractures osseuses',

      // Location activation translations
      'location_enabled_success': 'Localisation activée avec succès',
      'could_not_get_location': 'Impossible d\'obtenir la localisation',
      'location_permission_denied': 'Permission de localisation refusée',
      'error_enabling_location':
          'Erreur lors de l\'activation de la localisation',
      'enable_location_settings': 'Activer la localisation',
      'location_required_for_map':
          'La localisation est requise pour utiliser la carte',
      'allow': 'Autoriser',
      'deny': 'Refuser',

      // Quiz screen translations
      'quiz': 'Quiz',
      'question': 'Question',
      'finish': 'Terminer',
      'next': 'Suivant',

      // Quiz questions and answers
      'cpr_frequency_question':
          'Quelle est la fréquence recommandée pour les compressions thoraciques lors de la RCP ?',
      'cpr_frequency_answer1': '60-80 compressions par minute',
      'cpr_frequency_answer2': '100-120 compressions par minute',

      'bleeding_question':
          'Quelle est la première étape pour arrêter une hémorragie sévère ?',
      'bleeding_answer1': 'Appliquer immédiatement un garrot',
      'bleeding_answer2': 'Appliquer une pression directe sur la plaie',

      'choking_question':
          'Que devez-vous faire si une personne s\'étouffe et ne peut pas parler ?',
      'choking_answer1': 'Effectuer la manœuvre de Heimlich',
      'choking_answer2': 'Donner de l\'eau à boire',

      // Appointment booking translations
      'medilink': 'MediLink',
      'select_date': 'Sélectionner la date',
      'find_your_doctor': 'Trouvez votre médecin',
      'select_specialty_date':
          'Sélectionnez une spécialité et une date pour votre rendez-vous',
      'medical_specialty': 'Spécialité médicale',
      'choose_specialty': 'Choisissez une spécialité',
      'please_select_specialty': 'Veuillez sélectionner une spécialité',
      'desired_date_time': 'Date et heure souhaitées',
      'select_date_time': 'Sélectionnez la date et l\'heure',
      'please_select_date_time': 'Veuillez sélectionner une date et une heure',
      'search_doctor': 'Rechercher un médecin',
      'please_select_valid_date_time':
          'Veuillez sélectionner une date et une heure valides',

      // Patient profile translations
      'patient_profile': 'Profil du patient',
      'medical_information': 'Informations médicales',
      'no_medical_history': 'Aucun antécédent médical',
      'blood_type': 'Groupe sanguin',
      'height': 'Taille',
      'weight': 'Poids',
      'allergies': 'Allergies',
      'chronic_diseases': 'Maladies chroniques',
      'emergency_contact': 'Contact d\'urgence',
      'emergency_contact_name': 'Nom du contact d\'urgence',
      'emergency_contact_relationship': 'Relation',
      'emergency_contact_phone': 'Téléphone d\'urgence',
      'personal_information': 'Informations personnelles',
      'gender': 'Sexe',
      'male': 'Homme',
      'female': 'Femme',
      'address': 'Adresse',
      'cm': 'cm',
      'kg': 'kg',
      'info': 'Informations',
      'save': 'Enregistrer',
      'success': 'Succès',
      'profile_saved_successfully': 'Profil enregistré avec succès',

      // Doctor profile translations
      'doctor_profile': 'Profil du médecin',
      'professional_information': 'Informations professionnelles',
      'consultation_duration_label': 'Durée de consultation',
      'consultation_fee_label': 'Frais de consultation',
      'education': 'Formation',
      'experience': 'Expérience',
      'office_location': 'Emplacement du cabinet',
      'consultation_duration': 'Durée de consultation',
      'consultation_fee': 'Frais de consultation',

      // Specialty translations
      'cardiologist': 'Cardiologue',
      'dermatologist': 'Dermatologue',
      'neurologist': 'Neurologue',
      'pediatrician': 'Pédiatre',
      'orthopedic': 'Orthopédiste',
      'general_practitioner': 'Médecin généraliste',
      'psychologist': 'Psychologue',
      'gynecologist': 'Gynécologue',
      'ophthalmologist': 'Ophtalmologue',
      'dentist': 'Dentiste',
      'pulmonologist': 'Pneumologue',
      'nutritionist': 'Nutritionniste',
      'aesthetic_doctor': 'Médecin esthétique',

      // Dashboard translations
      'dashboard': 'Tableau de bord',
      'welcome': 'Bienvenue',
      'statistics': 'Statistiques',
      'patients': 'Patients',
      'my_patients': 'Mes Patients',
      'search_patient': 'Rechercher un patient',
      'loading_patients': 'Chargement des patients...',
      'no_patients_found_for_search':
          'Aucun patient trouvé pour cette recherche',
      'no_patients_yet': 'Aucun patient pour le moment',
      'try_different_search': 'Essayez une recherche différente',
      'patients_will_appear_here':
          'Les patients apparaîtront ici après vos consultations',
      'clear_search': 'Effacer la recherche',
      'unknown_patient': 'Patient inconnu',
      'last_consultation': 'Dernière consultation',
      'status_pending': 'En attente',
      'status_confirmed': 'Confirmé',
      'status_cancelled': 'Annulé',
      'status_completed': 'Terminé',
      'status_unknown': 'Statut inconnu',
      'what_are_you_looking_for': 'Que cherchez-vous ?',
      'see_all': 'Voir tout',
      'hello_doctor': 'Bonjour Dr. {0}',
      'day_overview': 'Aperçu de votre journée',
      'total_appointments': 'Total rendez-vous',
      'pending_appointments': 'Rendez-vous en attente',
      'completed_appointments': 'Rendez-vous terminés',
      'quick_actions': 'Actions rapides',
      'view_all_appointments': 'Voir tous les rendez-vous',
      'emergencies': 'Urgences',
      'emergency_feature_development':
          'Fonctionnalité d\'urgence en développement',
      'upcoming_appointments': 'Prochains rendez-vous',
      'no_upcoming_appointments': 'Aucun rendez-vous à venir',
      'pending_appointments_will_appear_here':
          'Les rendez-vous en attente apparaîtront ici',
      'loading_dashboard': 'Chargement du tableau de bord...',
      'error_loading_appointments': 'Erreur lors du chargement des rendez-vous',
      'error_loading_stats': 'Erreur lors du chargement des statistiques',

      // Verification screen translations
      'verify_account': 'Vérifier le compte',
      'verify_identity': 'Vérifier l\'identité',
      'verification_code_sent_account':
          'Un code de vérification a été envoyé à {0} pour activer votre compte.',
      'verification_code_sent_reset':
          'Un code de vérification a été envoyé à {0} pour réinitialiser votre mot de passe.',
      'enter_verification_code': 'Entrez le code de vérification',
      'code_verified_successfully': 'Code vérifié avec succès',
      'verify_code': 'Vérifier le code',
      'please_enter_complete_code': 'Veuillez entrer le code complet',
      'didnt_receive_code': 'Vous n\'avez pas reçu le code ?',
      'new_code_will_be_sent': 'Un nouveau code sera envoyé',
      'verification': 'Vérification',

      // Medical record translations
      'medical_record': 'Dossier médical',
      'medical_records': 'Dossiers médicaux',
      'manage_medical_records': 'Gérer les dossiers médicaux',
      'medical_file': 'Fichier médical',
      'medical_files': 'Fichiers médicaux',
      'no_medical_files': 'Aucun fichier médical',
      'no_medical_files_message':
          'Ce patient n\'a pas encore de fichiers dans son dossier médical.',
      'access_denied': 'Accès refusé',
      'access_denied_message':
          'Vous devez avoir un rendez-vous confirmé avec ce patient pour accéder à son dossier médical.',
      'medical_record_access_error': 'Erreur d\'accès au dossier médical',
      'view_all': 'Voir tout',
      'modify_time_feature_coming_soon':
          'La fonctionnalité de modification d\'heure sera disponible prochainement',

      // Prescription translations
      'prescription': 'Ordonnance',
      'prescriptions': 'Ordonnances',
      'my_prescriptions': 'Mes ordonnances',
      'create_prescription': 'Créer une ordonnance',
      'prescription_details': 'Détails de l\'ordonnance',
      'medication': 'Médicament',
      'dosage': 'Posologie',
      'instructions': 'Instructions',
      'notes': 'Notes',
      'no_notes': 'Aucune note',
      'additional_notes_hint': 'Notes ou instructions supplémentaires...',
      'add_medication': 'Ajouter un médicament',
      'medication_name': 'Nom du médicament',
      'dosage_label': 'Posologie',
      'instructions_label': 'Instructions',
      'add': 'Ajouter',
      'prescription_date': 'Date de l\'ordonnance',
      'prescription_from': 'Ordonnance de',
      'doctor': 'Médecin',
      'editable': 'Modifiable',
      'loading_prescriptions': 'Chargement des ordonnances...',
      'no_prescriptions': 'Aucune ordonnance',
      'no_prescriptions_created_yet': 'Aucune ordonnance créée pour le moment',
      'no_prescriptions_received_yet': 'Aucune ordonnance reçue pour le moment',
      'prescription_created_successfully': 'Ordonnance créée avec succès!',
      'prescription_modified_successfully': 'Ordonnance modifiée avec succès!',
      'prescription_edited_success': 'Ordonnance modifiée avec succès',
      'prescription_error': 'Erreur: {0}',
      'select_appointment_for_prescription':
          'Sélectionner un rendez-vous pour l\'ordonnance',
      'no_eligible_appointments': 'Aucun rendez-vous éligible',
      'no_completed_or_past_appointments':
          'Aucun rendez-vous terminé ou passé trouvé',
      'filter_by': 'Filtrer par',
      'past_appointments': 'Rendez-vous passés',
      'completed': 'Terminé',
      'retry': 'Réessayer',
      'general_consultation': 'Consultation générale',

      // Appointment details translations
      'appointment_details': 'Détails du rendez-vous',
      'date': 'Date',
      'time': 'Heure',
      'appointment_cancelled_successfully': 'Rendez-vous annulé avec succès!',
      'rating_submitted_successfully': 'Évaluation soumise avec succès!',
      'no_prescription_created_for_appointment':
          'Aucune ordonnance créée pour ce rendez-vous',
      'no_prescription_available_for_appointment':
          'Aucune ordonnance disponible pour ce rendez-vous',
      'add_comment_optional': 'Ajouter un commentaire (optionnel)',
      'loading_rating': 'Chargement de l\'évaluation...',
      'prescription_from_date': 'Ordonnance du {date}',
      'view_details': 'Voir les détails',
      'no_prescription_created': 'Aucune ordonnance créée pour ce rendez-vous',
      'create_prescription_button': 'Créer l\'ordonnance',
      'edit_prescription_button': 'Modifier l\'ordonnance',
      'wait_until_appointment_end': 'Attendre la fin du rendez-vous',
      'rated_on_date': 'Évalué le {date}',
      'specialty_not_specified': 'Spécialité non spécifiée',
      'confirm_cancel_appointment':
          'Êtes-vous sûr de vouloir annuler ce rendez-vous ?',
      'unable_to_submit_rating_missing_info':
          'Impossible de soumettre l\'évaluation, informations manquantes',

      // AI Chatbot translations
      'ai_assistant': 'Assistant IA',
      'ai_clear_chat': 'Effacer la conversation',
      'ai_welcome_title': 'Bienvenue dans l\'Assistant Médical IA',
      'ai_welcome_description':
          'Je peux vous aider à analyser des images médicales, des documents PDF et répondre à vos questions de santé.',
      'ai_image_analysis': 'Analyse d\'images',
      'ai_image_analysis_desc':
          'Analyser vos radiographies, IRM et autres images médicales',
      'ai_pdf_analysis': 'Analyse PDF',
      'ai_pdf_analysis_desc': 'Analyser vos rapports médicaux et documents PDF',
      'ai_thinking': 'Réflexion en cours...',
      'ai_type_message': 'Tapez votre message...',
      'ai_image_prompt_title': 'Analyser l\'image médicale',
      'ai_image_prompt_description':
          'Décrivez ce que vous voulez analyser dans cette image médicale.',
      'ai_image_prompt_hint':
          'Ex: Analysez cette radiographie pour les fractures...',
      'ai_analyze': 'Analyser',
      'ai_select_attachment': 'Sélectionner une pièce jointe',
      'ai_select_image': 'Sélectionner une image',
      'ai_analyze_medical_images':
          'Analyser des images médicales (radiographies, IRM, etc.)',
      'ai_select_pdf': 'Sélectionner un PDF',
      'ai_analyze_medical_docs': 'Analyser des documents PDF médicaux',
      'ai_text_response': 'Réponse IA',
      'ai_image_analysis_error': 'Erreur lors de l\'analyse de l\'image',
      'ai_pdf_uploaded': 'PDF téléchargé avec succès',
      'ai_pdf_analysis_error': 'Erreur lors de l\'analyse du PDF',
      'ai_error_connecting': 'Erreur de connexion au service IA',
      'ai_service_unavailable': 'Service IA actuellement indisponible',

      // Notification translations
      'new_appointment': 'Nouveau rendez-vous',
      'appointment_accepted': 'Rendez-vous accepté',
      'appointment_rejected': 'Rendez-vous refusé',
      'patient_name_unknown': 'Patient',
      'doctor_name_unknown': 'Médecin inconnu',
      'default_doctor_name': 'Dr. Inconnu',
      'requested_appointment_for': 'a demandé un rendez-vous pour',
      'has_accepted_your_appointment_for': 'a accepté votre rendez-vous pour',
      'has_rejected_your_appointment_for': 'a refusé votre rendez-vous pour',
      'at': 'à',
      'appointment_accepted_message':
          'Dr. {0} a accepté votre rendez-vous du {1}',
      'appointment_rejected_message':
          'Dr. {0} a refusé votre rendez-vous du {1}',
      'appointment_cancelled_message':
          'Dr. {0} a annulé votre rendez-vous du {1}',
      'prescription_created_message':
          'Dr. {0} a créé une nouvelle ordonnance pour vous',
      'prescription_updated_message':
          'Dr. {0} a mis à jour votre ordonnance: {1}',
      'new_message_from': 'Nouveau message de {sender}: {message}',
      'doctor_with_name': 'Dr. {0}',

      // Profile editing translations
      'edit_patient_profile': 'Modifier le profil patient',
      'edit_doctor_profile': 'Modifier le profil médecin',
      'enter_allergies_hint': 'Entrez les allergies séparées par des virgules',
      'enter_chronic_diseases_hint':
          'Entrez les maladies chroniques séparées par des virgules',
      'enter_emergency_name_hint': 'Entrez le nom du contact d\'urgence',
      'enter_emergency_relationship_hint':
          'Entrez la relation (ex: époux, parent, ami)',
      'enter_emergency_phone_hint': 'Entrez le numéro de téléphone d\'urgence',
      'consultation_fee_required': 'Les frais de consultation sont requis',
      'consultation_duration_required': 'La durée de consultation est requise',
      'invalid_consultation_duration': 'Durée de consultation invalide',
      'invalid_consultation_fee': 'Frais de consultation invalides',
      'education_label': 'Formation',
      'education_hint': 'Diplôme:MD,Année:2010;Diplôme:PhD,Année:2015',
      'experience_label': 'Expérience',
      'experience_hint': 'Poste:Chirurgien,Années:5;Poste:Consultant,Années:3',
      'office_location_label': 'Localisation du cabinet médical',
      'consultation_fee_hint': 'Entrez vos frais de consultation',
      'consultation_duration_hint': 'Durée en minutes',
      'choose_consultation_duration': 'Choisir la durée de consultation',
      'duration_label': 'Durée',
      'consultation_duration_updated': 'Durée de consultation mise à jour',
      'update_error': 'Erreur de mise à jour',
      'modify_consultation_duration': 'Modifier la durée de consultation',
      'doctor_prefix': 'Dr.',
      'consultation_duration_value': '{duration} minutes',
      'consultation_fee_value': '{fee} DT',
      'duration_minutes': '{minutes} minutes',
      'tap_to_set_office_location':
          'Appuyez pour définir l\'emplacement du cabinet',
      'change_location': 'Changer l\'emplacement',
      'set_office_location': 'Définir l\'emplacement du cabinet',
      'selected_location': 'Emplacement sélectionné',
      'tap_to_select_location':
          'Appuyez pour sélectionner l\'emplacement du cabinet',
      'confirm_location': 'Confirmer l\'emplacement',
      'location_access_failed': 'Échec d\'accès à l\'emplacement',
      'address_not_available': 'Adresse non disponible',
      'office_location_not_set': 'Emplacement du cabinet non défini',
      'set_location': 'Définir l\'emplacement',
      'doctor_office': 'Cabinet médical',
      'location_permission_title':
          'Permission d\'accès à l\'emplacement requise',
      'location_permission_message':
          'Cette application a besoin d\'accéder à votre emplacement pour fournir de meilleurs services.',
      'find_doctor_specialty': 'Rechercher par spécialité',
      'profile': 'Profil',
      'change_profile_picture_message':
          'Fonctionnalité de changement de photo de profil bientôt disponible',
      'confirm_logout': 'Êtes-vous sûr de vouloir vous déconnecter ?',
      'logout_error': 'Erreur lors de la déconnexion: {0}',
      'app_settings': 'Paramètres de l\'application',
      'date_of_birth_not_specified': 'Date de naissance non spécifiée',
      'medical_history': 'Antécédents médicaux',
      'previous_consultations': 'Consultations précédentes',
      'antecedent': 'Antécédent',

      // Specialties
      'specialties': 'Spécialités',
      'resuscitation': 'Réanimation',
      'choking': 'Étouffement',
      'bleeding': 'Saignement',
      'burns': 'Brûlures',

      // Profile completion screen translations
      'complete_profile': 'Compléter votre profil',
      'welcome_google_user': 'Bienvenue, @nom!',
      'complete_profile_message':
          'Veuillez compléter votre profil médical pour recevoir des soins personnalisés',
      'phone_min_length': 'Numéro de téléphone invalide',
      'height_cm': 'Taille (cm)',
      'weight_kg': 'Poids (kg)',
      'blood_type_placeholder': 'Sélectionnez votre groupe sanguin',
      'antecedent_placeholder': 'Conditions médicales, chirurgies, etc.',
      'profile_completed_success': 'Profil complété avec succès!',
      'complete_profile_button': 'Compléter le profil',
      'skip_for_now': 'Ignorer pour l\'instant',

      // Home screen and navigation
      'default_patient_name': 'Patient',
      'default_email': 'patient@example.com',
      'home': 'Accueil',
      'filter_by_date': 'Filtrer par date',
      'reset_filter': 'Réinitialiser le filtre',
      'patient': 'Patient',
      'hospitals': 'Hôpitaux',
      'first_aid': 'Premiers secours',
    },
  };
}
