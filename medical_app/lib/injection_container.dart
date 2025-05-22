import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/cubit/theme_cubit/theme_cubit.dart';
import 'package:medical_app/cubit/toggle%20cubit/toggle_cubit.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_remote_data_source.dart';
import 'package:medical_app/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:medical_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:medical_app/features/authentication/domain/usecases/create_account_use_case.dart';
import 'package:medical_app/features/authentication/domain/usecases/send_verification_code_use_case.dart';
import 'package:medical_app/features/authentication/domain/usecases/change_password_use_case.dart';
import 'package:medical_app/features/authentication/domain/usecases/login_usecase.dart';
import 'package:medical_app/features/authentication/domain/usecases/update_user_use_case.dart';
import 'package:medical_app/features/authentication/domain/usecases/verify_code_use_case.dart';
import 'package:medical_app/features/authentication/presentation/blocs/Signup%20BLoC/signup_bloc.dart';
import 'package:medical_app/features/authentication/presentation/blocs/login%20BLoC/login_bloc.dart';

import 'package:medical_app/features/messagerie/data/data_sources/message_local_datasource.dart';
import 'package:medical_app/features/messagerie/data/data_sources/message_remote_datasource.dart';
import 'package:medical_app/features/messagerie/data/repositories/message_repository_impl.dart';
import 'package:medical_app/features/messagerie/domain/repositories/message_repository.dart';
import 'package:medical_app/features/messagerie/domain/use_cases/get_conversations.dart';
import 'package:medical_app/features/messagerie/domain/use_cases/get_message.dart';
import 'package:medical_app/features/messagerie/domain/use_cases/get_messages_stream_usecase.dart';
import 'package:medical_app/features/messagerie/domain/use_cases/send_message.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/conversation%20BLoC/conversations_bloc.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/messageries%20BLoC/messagerie_bloc.dart';
import 'package:medical_app/features/rendez_vous/data/data%20sources/rdv_local_data_source.dart';
import 'package:medical_app/features/rendez_vous/data/data%20sources/rdv_remote_data_source.dart';
import 'package:medical_app/features/rendez_vous/data/repositories/rendez_vous_repository_impl.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/assign_doctor_to_rendez_vous_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/create_rendez_vous_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/fetch_doctors_by_specialty_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/fetch_rendez_vous_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/update_rendez_vous_status_use_case.dart';
import 'package:medical_app/features/rendez_vous/presentation/blocs/rendez-vous%20BLoC/rendez_vous_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/authentication/presentation/blocs/forget password bloc/forgot_password_bloc.dart';
import 'features/authentication/presentation/blocs/reset password bloc/reset_password_bloc.dart';
import 'features/authentication/presentation/blocs/verify code bloc/verify_code_bloc.dart';
import 'features/profile/presentation/pages/blocs/BLoC update profile/update_user_bloc.dart';

// Rating feature imports
import 'package:medical_app/features/ratings/data/datasources/rating_remote_datasource.dart';
import 'package:medical_app/features/ratings/data/repositories/rating_repository_impl.dart';
import 'package:medical_app/features/ratings/domain/repositories/rating_repository.dart';
import 'package:medical_app/features/ratings/domain/usecases/submit_doctor_rating_use_case.dart';
import 'package:medical_app/features/ratings/domain/usecases/has_patient_rated_appointment_use_case.dart';
import 'package:medical_app/features/ratings/presentation/bloc/rating_bloc.dart';
import 'package:medical_app/features/ratings/domain/usecases/get_doctor_ratings_use_case.dart';
import 'package:medical_app/features/ratings/domain/usecases/get_doctor_average_rating_use_case.dart';

// Dashboard feature imports
import 'package:medical_app/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:medical_app/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:medical_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:medical_app/features/dashboard/domain/usecases/get_doctor_dashboard_stats_use_case.dart';
import 'package:medical_app/features/dashboard/domain/usecases/get_upcoming_appointments_use_case.dart';
import 'package:medical_app/features/dashboard/presentation/blocs/dashboard%20BLoC/dashboard_bloc.dart';

// Add prescription feature imports
import 'package:medical_app/features/ordonnance/data/datasources/prescription_remote_datasource.dart';
import 'package:medical_app/features/ordonnance/data/repositories/prescription_repository_impl.dart';
import 'package:medical_app/features/ordonnance/domain/repositories/prescription_repository.dart';
import 'package:medical_app/features/ordonnance/domain/usecases/create_prescription_use_case.dart';
import 'package:medical_app/features/ordonnance/domain/usecases/edit_prescription_use_case.dart';
import 'package:medical_app/features/ordonnance/domain/usecases/get_doctor_prescriptions_use_case.dart';
import 'package:medical_app/features/ordonnance/domain/usecases/get_patient_prescriptions_use_case.dart';
import 'package:medical_app/features/ordonnance/domain/usecases/get_prescription_by_appointment_id_use_case.dart';
import 'package:medical_app/features/ordonnance/domain/usecases/get_prescription_by_id_use_case.dart';
import 'package:medical_app/features/ordonnance/domain/usecases/update_prescription_use_case.dart';
import 'package:medical_app/features/ordonnance/presentation/bloc/prescription_bloc.dart';

// Add notification feature imports
import 'package:medical_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:medical_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:medical_app/features/notifications/domain/usecases/delete_notification_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/get_notifications_stream_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/get_notifications_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/get_unread_notifications_count_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/mark_all_notifications_as_read_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/mark_notification_as_read_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/save_fcm_token_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/send_notification_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/setup_fcm_use_case.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:medical_app/features/authentication/presentation/blocs/update_password_bloc/update_password_bloc.dart';
import 'package:medical_app/features/authentication/domain/usecases/update_password_direct_use_case.dart';

// Dossier Medical Feature
import 'package:http/http.dart' as http;
import 'package:medical_app/features/dossier_medical/data/datasources/dossier_medical_remote_datasource.dart';
import 'package:medical_app/features/dossier_medical/data/repositories/dossier_medical_repository_impl.dart';
import 'package:medical_app/features/dossier_medical/domain/repositories/dossier_medical_repository.dart';
import 'package:medical_app/features/dossier_medical/domain/usecases/get_dossier_medical.dart';
import 'package:medical_app/features/dossier_medical/domain/usecases/has_dossier_medical.dart';
import 'package:medical_app/features/dossier_medical/presentation/bloc/dossier_medical_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Blocs and Cubits
  sl.registerFactory(() => ThemeCubit());
  sl.registerFactory(() => LoginBloc(loginUseCase: sl()));
  sl.registerFactory(() => SignupBloc(createAccountUseCase: sl()));
  sl.registerFactory(() => UpdateUserBloc(updateUserUseCase: sl()));
  sl.registerFactory(() => ToggleCubit());
  sl.registerFactory(
    () => ForgotPasswordBloc(sendVerificationCodeUseCase: sl()),
  );
  sl.registerFactory(() => VerifyCodeBloc(verifyCodeUseCase: sl()));
  sl.registerFactory(() => ResetPasswordBloc(changePasswordUseCase: sl()));
  sl.registerFactory(
    () => UpdatePasswordBloc(updatePasswordDirectUseCase: sl()),
  );
  sl.registerFactory(
    () => RendezVousBloc(
      fetchRendezVousUseCase: sl(),
      updateRendezVousStatusUseCase: sl(),
      createRendezVousUseCase: sl(),
      fetchDoctorsBySpecialtyUseCase: sl(),
      assignDoctorToRendezVousUseCase: sl(),
      notificationBloc: sl<NotificationBloc>(),
    ),
  );
  sl.registerFactory(() => ConversationsBloc(getConversationsUseCase: sl()));
  sl.registerFactory(
    () => MessagerieBloc(
      sendMessageUseCase: sl(),
      getMessagesUseCase: sl(),
      getMessagesStreamUseCase: sl(),
    ),
  );

  // Dashboard BLoC
  sl.registerFactory(
    () => DashboardBloc(
      getDoctorDashboardStatsUseCase: sl(),
      getUpcomingAppointmentsUseCase: sl(),
    ),
  );

  // Prescription BLoC
  sl.registerFactory(
    () => PrescriptionBloc(
      createPrescriptionUseCase: sl(),
      editPrescriptionUseCase: sl(),
      getPatientPrescriptionsUseCase: sl(),
      getDoctorPrescriptionsUseCase: sl(),
      getPrescriptionByIdUseCase: sl(),
      getPrescriptionByAppointmentIdUseCase: sl(),
      updatePrescriptionUseCase: sl(),
      notificationBloc: sl<NotificationBloc>(),
    ),
  );

  // Notification BLoC
  sl.registerFactory(
    () => NotificationBloc(
      getNotificationsUseCase: sl(),
      sendNotificationUseCase: sl(),
      markNotificationAsReadUseCase: sl(),
      markAllNotificationsAsReadUseCase: sl(),
      deleteNotificationUseCase: sl(),
      getUnreadNotificationsCountUseCase: sl(),
      setupFCMUseCase: sl(),
      saveFCMTokenUseCase: sl(),
      getNotificationsStreamUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => CreateAccountUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserUseCase(sl()));
  sl.registerLazySingleton(() => VerifyCodeUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => FetchRendezVousUseCase(sl()));
  sl.registerLazySingleton(() => UpdateRendezVousStatusUseCase(sl()));
  sl.registerLazySingleton(() => CreateRendezVousUseCase(sl()));
  sl.registerLazySingleton(() => FetchDoctorsBySpecialtyUseCase(sl()));
  sl.registerLazySingleton(() => AssignDoctorToRendezVousUseCase(sl()));
  sl.registerLazySingleton(() => GetConversationsUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => GetMessagesUseCase(sl()));
  sl.registerLazySingleton(() => GetMessagesStreamUseCase(sl()));
  sl.registerLazySingleton(() => SendVerificationCodeUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePasswordDirectUseCase(sl()));

  // Dashboard Use Cases
  sl.registerLazySingleton(() => GetDoctorDashboardStatsUseCase(sl()));
  sl.registerLazySingleton(() => GetUpcomingAppointmentsUseCase(sl()));

  // Prescription Use Cases
  sl.registerLazySingleton(() => CreatePrescriptionUseCase(sl()));
  sl.registerLazySingleton(() => EditPrescriptionUseCase(sl()));
  sl.registerLazySingleton(() => GetPatientPrescriptionsUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorPrescriptionsUseCase(sl()));
  sl.registerLazySingleton(() => GetPrescriptionByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetPrescriptionByAppointmentIdUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePrescriptionUseCase(sl()));

  // Notification Use Cases
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => SendNotificationUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationAsReadUseCase(sl()));
  sl.registerLazySingleton(() => MarkAllNotificationsAsReadUseCase(sl()));
  sl.registerLazySingleton(() => DeleteNotificationUseCase(sl()));
  sl.registerLazySingleton(() => GetUnreadNotificationsCountUseCase(sl()));
  sl.registerLazySingleton(() => SetupFCMUseCase(sl()));
  sl.registerLazySingleton(() => SaveFCMTokenUseCase(sl()));
  sl.registerLazySingleton(() => GetNotificationsStreamUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<RendezVousRepository>(
    () => RendezVousRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<MessagingRepository>(
    () => MessagingRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Dashboard Repository
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Prescription Repository
  sl.registerLazySingleton<PrescriptionRepository>(
    () => PrescriptionRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Notification Repository
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
      googleSignIn: sl(),
      localDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<RendezVousRemoteDataSource>(
    () =>
        RendezVousRemoteDataSourceImpl(firestore: sl(), localDataSource: sl()),
  );
  sl.registerLazySingleton<RendezVousLocalDataSource>(
    () => RendezVousLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<MessagingRemoteDataSource>(
    () => MessagingRemoteDataSourceImpl(firestore: sl(), storage: sl()),
  );
  sl.registerLazySingleton<MessagingLocalDataSource>(
    () => MessagingLocalDataSourceImpl(),
  );

  // Dashboard DataSource
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(firestore: sl()),
  );

  // Prescription DataSource
  sl.registerLazySingleton<PrescriptionRemoteDataSource>(
    () => PrescriptionRemoteDataSourceImpl(firestore: sl()),
  );

  // Notification Data Sources
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(
      firestore: sl(),
      firebaseMessaging: sl(),
      flutterLocalNotificationsPlugin: sl(),
    ),
  );

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
  sl.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker.instance,
  );

  // External - FCM and Local Notifications
  sl.registerLazySingleton(() => FirebaseMessaging.instance);
  sl.registerLazySingleton(() => FlutterLocalNotificationsPlugin());

  // Rating feature
  sl.registerFactory(
    () => RatingBloc(
      submitDoctorRatingUseCase: sl(),
      hasPatientRatedAppointmentUseCase: sl(),
      getDoctorRatingsUseCase: sl(),
      getDoctorAverageRatingUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => SubmitDoctorRatingUseCase(sl()));
  sl.registerLazySingleton(() => HasPatientRatedAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorRatingsUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorAverageRatingUseCase(sl()));
  sl.registerLazySingleton<RatingRepository>(
    () => RatingRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<RatingRemoteDataSource>(
    () => RatingRemoteDataSourceImpl(firestore: sl()),
  );

  // Dossier Medical
  // BLoC
  sl.registerFactory(() => DossierMedicalBloc(repository: sl()));

  // Use Cases
  sl.registerLazySingleton(() => GetDossierMedical(sl()));
  sl.registerLazySingleton(() => HasDossierMedical(sl()));

  // Repository
  sl.registerLazySingleton<DossierMedicalRepository>(
    () =>
        DossierMedicalRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<DossierMedicalRemoteDataSource>(
    () => DossierMedicalRemoteDataSourceImpl(client: http.Client()),
  );

  // Standalone registration
  sl.registerLazySingleton(() => http.Client());
}
