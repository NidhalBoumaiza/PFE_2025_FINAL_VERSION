import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:medical_app/constants.dart';
import 'package:medical_app/core/utils/app_themes.dart';
import 'package:medical_app/core/utils/theme_manager.dart';
import 'package:medical_app/cubit/theme_cubit/theme_cubit.dart';
import 'package:medical_app/cubit/toggle%20cubit/toggle_cubit.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/authentication/presentation/blocs/Signup%20BLoC/signup_bloc.dart';
import 'package:medical_app/features/authentication/presentation/blocs/login%20BLoC/login_bloc.dart';
import 'package:medical_app/features/authentication/presentation/pages/login_screen.dart';
import 'package:medical_app/features/home/presentation/pages/home_medecin.dart';
import 'package:medical_app/features/home/presentation/pages/home_patient.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_event.dart';
import 'package:medical_app/features/notifications/presentation/pages/notifications_medecin.dart';
import 'package:medical_app/features/notifications/presentation/pages/notifications_patient.dart';
import 'package:medical_app/features/notifications/utils/notification_utils.dart';
import 'package:medical_app/features/ratings/presentation/bloc/rating_bloc.dart';
import 'package:medical_app/features/rendez_vous/presentation/blocs/rendez-vous%20BLoC/rendez_vous_bloc.dart';
import 'package:medical_app/firebase_options.dart';
import 'package:medical_app/injection_container.dart' as di;
import 'package:provider/provider.dart';
import 'features/authentication/presentation/blocs/forget password bloc/forgot_password_bloc.dart';
import 'features/authentication/presentation/blocs/reset password bloc/reset_password_bloc.dart';
import 'features/authentication/presentation/blocs/verify code bloc/verify_code_bloc.dart';
import 'features/messagerie/presentation/blocs/conversation%20BLoC/conversations_bloc.dart';
import 'features/messagerie/presentation/blocs/messageries%20BLoC/messagerie_bloc.dart';
import 'features/profile/presentation/pages/blocs/BLoC update profile/update_user_bloc.dart';
import 'i18n/app_translation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/dashboard/presentation/blocs/dashboard BLoC/dashboard_bloc.dart';
import 'features/ordonnance/presentation/bloc/prescription_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medical_app/features/dossier_medical/presentation/bloc/dossier_medical_bloc.dart';

// API endpoints for the Express backend
// This class is now moved to constants.dart

// Set up the background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Need to initialize Firebase before using it in the background
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");

  // Save notification to Firestore for display when app is opened
  saveNotificationToFirestore(message);
}

// Save notification data to Firestore for persistence
Future<void> saveNotificationToFirestore(RemoteMessage message) async {
  try {
    final notificationData = {
      'title': message.notification?.title ?? 'New Notification',
      'body': message.notification?.body ?? '',
      'senderId': message.data['senderId'] ?? '',
      'recipientId': message.data['recipientId'] ?? '',
      'type': message.data['type'] ?? 'newAppointment',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    // Add additional data if available
    if (message.data['appointmentId'] != null) {
      notificationData['appointmentId'] = message.data['appointmentId'];
    }

    if (message.data['prescriptionId'] != null) {
      notificationData['prescriptionId'] = message.data['prescriptionId'];
    }

    await FirebaseFirestore.instance
        .collection('notifications')
        .add(notificationData);
    print('Notification saved to Firestore');
  } catch (e) {
    print('Error saving notification to Firestore: $e');
  }
}

// Send notification using Express backend
Future<void> sendNotification({
  required String token,
  required String title,
  required String body,
  Map<String, dynamic>? data,
}) async {
  try {
    final response = await http.post(
      Uri.parse(AppConstants.sendNotification),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'title': title,
        'body': body,
        'data': data ?? {},
      }),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification: ${response.body}');
    }
  } catch (e) {
    print('Error sending notification: $e');
  }
}

// Save notification to Firestore using Express backend
Future<void> saveNotificationToServer({
  required String title,
  required String body,
  required String senderId,
  required String recipientId,
  required String type,
  String? appointmentId,
  String? prescriptionId,
}) async {
  try {
    final Map<String, dynamic> data = {
      'title': title,
      'body': body,
      'senderId': senderId,
      'recipientId': recipientId,
      'type': type,
    };

    if (appointmentId != null) {
      data['appointmentId'] = appointmentId;
    }

    if (prescriptionId != null) {
      data['prescriptionId'] = prescriptionId;
    }

    final response = await http.post(
      Uri.parse(AppConstants.saveNotification),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      print('Notification saved to server');
    } else {
      print('Failed to save notification: ${response.body}');
    }
  } catch (e) {
    print('Error saving notification: $e');
  }
}

// Initialize the local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Create a channel for Android notifications
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  showBadge: true,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configure Firebase reCAPTCHA verification (disable for testing)
  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );

  // For testing purposes, disable App Check
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(false);

  // Firebase persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // Initialize Firebase App Check (with debug provider only)
  await FirebaseAppCheck.instance.activate(
    // Use debug provider for development
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Set up FCM background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize FCM and local notifications
  await _initializeFCM();

  // Initialize French locale for date formatting (used in appointment details)
  await initializeDateFormatting('fr_FR', null);

  // Initialize service locator
  await di.init();

  // Now that service locator is initialized, properly save the FCM token
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('FCM_TOKEN');

    if (savedToken != null) {
      print(
        'Found saved FCM token, saving it properly now that DI is initialized',
      );
      await _saveFcmToken(savedToken);
    }
  } catch (e) {
    print('Error processing saved FCM token: $e');
  }

  final authLocalDataSource = di.sl<AuthLocalDataSource>();
  Widget initialScreen;

  // Get saved language
  final savedLocale = await LanguageService.getSavedLanguage();

  try {
    final token = await authLocalDataSource.getToken();
    print('Token: $token');
    final user = await authLocalDataSource.getUser();
    if (token != null && user.id!.isNotEmpty) {
      initialScreen =
          user.role == 'medecin' ? const HomeMedecin() : const HomePatient();
    } else {
      initialScreen = const LoginScreen();
    }
  } catch (e) {
    initialScreen = const LoginScreen();
  }

  runApp(MyApp(initialScreen: initialScreen, savedLocale: savedLocale));
}

Future<void> _initializeFCM() async {
  // Request permission for iOS and Android
  final NotificationSettings settings = await FirebaseMessaging.instance
      .requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

  print('User granted permission: ${settings.authorizationStatus}');

  // Initialize Flutter Local Notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse details) async {
      // Handle notification tap
      if (details.payload != null) {
        print('Notification payload: ${details.payload}');
        _handleNotificationPayload(details.payload!);
      }
    },
  );

  // Create high importance notification channel for Android
  final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(channel);
    print('Notification channel created successfully');
  }

  // Update the iOS foreground notification presentation options
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get FCM token and save it temporarily to SharedPreferences
  // It will be properly saved to Firestore after DI initialization
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    try {
      // Save to SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('FCM_TOKEN', fcmToken);

      // Try to save to Firestore if possible
      await _saveFcmToken(fcmToken);
      print('FCM Token: $fcmToken'); // Print token for testing purposes
    } catch (e) {
      print('Initial save of FCM token encountered an error: $e');
      // Error is expected here if DI isn't initialized yet - token is in SharedPreferences
    }
  } else {
    print('Failed to get FCM token');
  }

  // Listen for token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    // Save new token to SharedPreferences first
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('FCM_TOKEN', newToken);
      print('FCM Token refreshed and saved to SharedPreferences: $newToken');

      // Try to save to Firestore if possible
      _saveFcmToken(newToken);
    });
  });
}

Future<void> _saveFcmToken(String token) async {
  // Validate the FCM token
  if (token.isEmpty) {
    print('Error: Attempted to save empty FCM token');
    return;
  }

  try {
    // Check if dependency injection is initialized properly
    if (!di.sl.isRegistered<AuthLocalDataSource>()) {
      print(
        'AuthLocalDataSource not registered yet, saving token to SharedPreferences',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('FCM_TOKEN', token);
      return;
    }

    final authLocalDataSource = di.sl<AuthLocalDataSource>();
    final user = await authLocalDataSource.getUser();

    if (user.id != null && user.id!.isNotEmpty) {
      // Determine the collection based on user's role
      String collection = 'users';
      if (user.role == 'patient') {
        collection = 'patients';
      } else if (user.role == 'medecin') {
        collection = 'medecins';
      }

      try {
        // Save the FCM token to the appropriate collection
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(user.id)
            .update({'fcmToken': token});
        print('FCM Token saved to $collection collection: $token');
      } catch (collectionError) {
        print('Error updating FCM token in $collection: $collectionError');

        // If the update failed, try to set the document instead
        try {
          await FirebaseFirestore.instance
              .collection(collection)
              .doc(user.id)
              .set({'fcmToken': token}, SetOptions(merge: true));
          print('FCM Token saved to $collection by merging: $token');
        } catch (setError) {
          print('Error setting FCM token in $collection: $setError');
        }
      }

      // Also update the token in the 'users' collection as a backup for notifications
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .update({'fcmToken': token});
        print('FCM Token saved to users collection: $token');
      } catch (userCollectionError) {
        if (userCollectionError is FirebaseException &&
            userCollectionError.code == 'not-found') {
          // If user doesn't exist in 'users' collection, create it
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.id)
                .set({
                  'id': user.id,
                  'name': user.name ?? '',
                  'lastName': user.lastName ?? '',
                  'email': user.email ?? '',
                  'role': user.role ?? '',
                  'fcmToken': token,
                });
            print('Created new user in users collection with FCM token');
          } catch (createError) {
            print('Error creating user document: $createError');
          }
        } else {
          print('Error updating FCM token in users: $userCollectionError');
        }
      }
    } else {
      // Store the token in SharedPreferences for later use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('FCM_TOKEN', token);
      print('User ID not available, saved FCM token to SharedPreferences');
    }
  } catch (e) {
    print('Error saving FCM token: $e');

    // Store the token in SharedPreferences as a fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('FCM_TOKEN', token);
      print('Saved FCM token to SharedPreferences as fallback');
    } catch (storageError) {
      print('Error saving FCM token to SharedPreferences: $storageError');
    }
  }
}

void _handleNotificationPayload(String payload) {
  try {
    final data = jsonDecode(payload);

    final notificationType = data['type'];
    final navigatorKey = GlobalKey<NavigatorState>();

    // Get the current context safely
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) return;

    // Determine the right screen to navigate to based on notification type
    switch (notificationType) {
      case 'newAppointment':
      case 'appointmentAccepted':
      case 'appointmentRejected':
        // Get the user role to navigate to the appropriate screen
        di.sl<AuthLocalDataSource>().getUser().then((user) {
          if (user.role == 'medecin') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsMedecin()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPatient()),
            );
          }
        });
        break;
      default:
        // For other types, just go to the notifications screen
        di.sl<AuthLocalDataSource>().getUser().then((user) {
          if (user.role == 'medecin') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsMedecin()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPatient()),
            );
          }
        });
    }
  } catch (e) {
    print('Error handling notification payload: $e');
  }
}

class MyApp extends StatefulWidget {
  final Widget initialScreen;
  final Locale? savedLocale;

  const MyApp({Key? key, required this.initialScreen, this.savedLocale})
    : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupInteractedMessage();
    _setupForegroundNotification();
  }

  Future<void> _setupInteractedMessage() async {
    // Get any messages which caused the application to open
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _setupForegroundNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      // Extract notification data
      final notification = message.notification;
      final data = message.data;

      // Add the notification to the bloc
      if (navigatorKey.currentContext != null) {
        try {
          final notificationBloc =
              navigatorKey.currentContext!.read<NotificationBloc>();

          // Create a notification entity with all available data
          String senderName =
              data['senderName'] ??
              data['doctorName'] ??
              data['patientName'] ??
              'Unknown';
          String title =
              notification?.title ?? data['title'] ?? 'New Notification';
          String body = notification?.body ?? data['body'] ?? '';

          // If we have sender information but it's not in the body, add it
          if (!body.contains(senderName) && senderName != 'Unknown') {
            if (data['type'] == 'appointmentAccepted') {
              body = 'Dr. $senderName has accepted your appointment';
            } else if (data['type'] == 'appointmentRejected') {
              body = 'Dr. $senderName has rejected your appointment';
            } else if (data['type'] == 'newMessage') {
              body = 'New message from $senderName: $body';
            }
          }

          notificationBloc.add(
            NotificationReceivedEvent(
              notification: NotificationEntity(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: title,
                body: body,
                recipientId: message.data['recipientId'] ?? '',
                senderId: message.data['senderId'] ?? '',
                type:
                    message.data['type'] != null
                        ? NotificationUtils.stringToNotificationType(
                          message.data['type'],
                        )
                        : NotificationType.newAppointment,
                createdAt: DateTime.now(),
                isRead: false,
                appointmentId: message.data['appointmentId'],
                prescriptionId: message.data['prescriptionId'],
                data:
                    message.data.isNotEmpty
                        ? Map<String, dynamic>.from(message.data)
                        : null,
              ),
            ),
          );
        } catch (e) {
          print('Error adding notification to bloc: $e');
        }

        // Show a local notification
        String title =
            notification?.title ?? data['title'] ?? 'New Notification';
        String body = notification?.body ?? data['body'] ?? '';

        // Add sender name to notification if available
        String senderName =
            data['senderName'] ??
            data['doctorName'] ??
            data['patientName'] ??
            '';
        if (senderName.isNotEmpty && !body.contains(senderName)) {
          if (data['type'] == 'appointmentAccepted') {
            body = 'Dr. $senderName has accepted your appointment';
          } else if (data['type'] == 'appointmentRejected') {
            body = 'Dr. $senderName has rejected your appointment';
          } else if (data['type'] == 'newMessage') {
            body = 'New message from $senderName: $body';
          }
        }

        print('Showing local notification: $title - $body');
        flutterLocalNotificationsPlugin.show(
          notification.hashCode ??
              DateTime.now().millisecondsSinceEpoch.hashCode,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              priority: Priority.max,
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              color: Colors.blue,
              largeIcon: const DrawableResourceAndroidBitmap(
                '@mipmap/ic_launcher',
              ),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });
  }

  void _handleMessage(RemoteMessage message) {
    // Handle notification clicks
    if (message.data['type'] != null) {
      // Get the current user role to navigate to the appropriate notification screen
      getAuthLocalDataSource().then((authLocalDataSource) {
        authLocalDataSource
            .getUser()
            .then((user) {
              if (user.role == 'medecin') {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsMedecin(),
                  ),
                );
              } else {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsPatient(),
                  ),
                );
              }
            })
            .catchError((_) {
              // If no user found, default to patient
              navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => const NotificationsPatient()),
              );
            });
      });
    }
  }

  // Helper method to get AuthLocalDataSource
  Future<AuthLocalDataSource> getAuthLocalDataSource() async {
    return di.sl<AuthLocalDataSource>();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<ThemeCubit>()),
        BlocProvider(create: (_) => di.sl<ToggleCubit>()),
        BlocProvider(create: (_) => di.sl<LoginBloc>()),
        BlocProvider(create: (_) => di.sl<SignupBloc>()),
        BlocProvider(create: (_) => di.sl<UpdateUserBloc>()),
        BlocProvider(create: (_) => di.sl<ForgotPasswordBloc>()),
        BlocProvider(create: (_) => di.sl<VerifyCodeBloc>()),
        BlocProvider(create: (_) => di.sl<ResetPasswordBloc>()),
        BlocProvider(create: (_) => di.sl<RendezVousBloc>()),
        BlocProvider(create: (_) => di.sl<ConversationsBloc>()),
        BlocProvider(create: (_) => di.sl<MessagerieBloc>()),
        BlocProvider(create: (_) => di.sl<RatingBloc>()),
        BlocProvider(create: (_) => di.sl<DashboardBloc>()),
        BlocProvider(create: (_) => di.sl<PrescriptionBloc>()),
        BlocProvider(create: (_) => di.sl<NotificationBloc>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          final themeMode =
              themeState is ThemeLoaded
                  ? themeState.themeMode
                  : ThemeMode.light;

          return ScreenUtilInit(
            designSize: const Size(360, 800),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return GetMaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'medilink'.tr,
                theme: AppThemes.lightTheme,
                darkTheme: AppThemes.darkTheme,
                themeMode: themeMode,
                navigatorKey: navigatorKey,
                home: widget.initialScreen,
                translations: AppTranslations(),
                locale: widget.savedLocale ?? Get.deviceLocale,
                fallbackLocale: const Locale('fr', 'FR'),
              );
            },
          );
        },
      ),
    );
  }
}
