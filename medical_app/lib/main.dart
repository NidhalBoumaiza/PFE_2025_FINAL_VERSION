import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medical_app/constants.dart';
import 'package:medical_app/core/utils/app_themes.dart';
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
import 'package:medical_app/firebase_options.dart';
import 'package:medical_app/injection_container.dart' as di;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medical_app/cubit/theme_cubit/theme_cubit.dart';
import 'package:medical_app/cubit/toggle%20cubit/toggle_cubit.dart';
import 'package:medical_app/features/ratings/presentation/bloc/rating_bloc.dart';
import 'package:medical_app/features/rendez_vous/presentation/blocs/rendez-vous%20BLoC/rendez_vous_bloc.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/conversation%20BLoC/conversations_bloc.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/messageries%20BLoC/messagerie_bloc.dart';
import 'package:medical_app/features/dashboard/presentation/blocs/dashboard%20BLoC/dashboard_bloc.dart';
import 'package:medical_app/features/ordonnance/presentation/bloc/prescription_bloc.dart';
import 'package:medical_app/features/profile/presentation/pages/blocs/BLoC%20update%20profile/update_user_bloc.dart';
import 'package:medical_app/features/dossier_medical/presentation/bloc/dossier_medical_bloc.dart';
import 'package:medical_app/i18n/app_translation.dart';
import 'package:medical_app/core/utils/theme_manager.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import 'features/authentication/presentation/blocs/forget password bloc/forgot_password_bloc.dart';
import 'features/authentication/presentation/blocs/reset password bloc/reset_password_bloc.dart';
import 'features/authentication/presentation/blocs/verify code bloc/verify_code_bloc.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");

  // Save notification to Firestore
  try {
    final notificationData = {
      'title': message.notification?.title ?? 'New Notification',
      'body': message.notification?.body ?? '',
      'senderId': message.data['senderId'] ?? '',
      'recipientId': message.data['recipientId'] ?? '',
      'type': message.data['type'] ?? 'newAppointment',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      if (message.data['appointmentId'] != null)
        'appointmentId': message.data['appointmentId'],
      if (message.data['prescriptionId'] != null)
        'prescriptionId': message.data['prescriptionId'],
      if (message.data['ratingId'] != null)
        'ratingId': message.data['ratingId'],
      'data':
          message.data.isNotEmpty
              ? Map<String, dynamic>.from(message.data)
              : null,
    };

    await FirebaseFirestore.instance
        .collection('notifications')
        .add(notificationData);
    print('Notification saved to Firestore');
  } catch (e) {
    print('Error saving notification to Firestore: $e');
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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

  // Disable Firebase Auth reCAPTCHA for testing (remove in production)
  // await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);

  // Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Set Firestore persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // Set up FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize FCM and local notifications
  await _initializeFCM();

  // Check and request location permissions
  await _checkAndRequestLocationPermission();

  // Initialize French locale for date formatting
  await initializeDateFormatting('fr_FR', null);

  // Initialize dependency injection
  await di.init();

  // Save FCM token if available
  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString('FCM_TOKEN');
  if (savedToken != null) {
    await _saveFcmToken(savedToken);
  }

  // Get saved language
  final savedLanguageCode = prefs.getString('app_language') ?? 'fr';
  final savedLocale = Locale(
    savedLanguageCode,
    savedLanguageCode == 'fr'
        ? 'FR'
        : savedLanguageCode == 'en'
        ? 'US'
        : 'AR',
  );

  // Determine initial screen
  final authLocalDataSource = di.sl<AuthLocalDataSource>();
  Widget initialScreen;
  try {
    final token = await authLocalDataSource.getToken();
    final user = await authLocalDataSource.getUser();
    if (token != null && user.id != null && user.id!.isNotEmpty) {
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

Future<void> _checkAndRequestLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print('Location permission denied');
      return;
    }
  }
  if (permission == LocationPermission.deniedForever) {
    print('Location permission permanently denied');
    return;
  }
  print('Location permission granted');
}

Future<void> _initializeFCM() async {
  // Request notification permissions
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');

  // Initialize local notifications
  const androidInitSettings = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );
  const iosInitSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidInitSettings,
    iOS: iosInitSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (details) async {
      if (details.payload != null) {
        print('Notification payload: ${details.payload}');
        _handleNotificationPayload(details.payload!);
      }
    },
  );

  // Create Android notification channel
  final androidPlugin =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
  await androidPlugin?.createNotificationChannel(channel);

  // Set iOS foreground notification options
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get and save FCM token
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('FCM_TOKEN', fcmToken);
    await _saveFcmToken(fcmToken);
    print('FCM Token: $fcmToken');
  }

  // Listen for token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('FCM_TOKEN', newToken);
    await _saveFcmToken(newToken);
    print('FCM Token refreshed: $newToken');
  });
}

Future<void> _saveFcmToken(String token) async {
  if (token.isEmpty) {
    print('Error: Empty FCM token');
    return;
  }

  try {
    final authLocalDataSource = di.sl<AuthLocalDataSource>();
    final user = await authLocalDataSource.getUser();
    if (user.id != null && user.id!.isNotEmpty) {
      String collection = user.role == 'patient' ? 'patients' : 'medecins';
      await FirebaseFirestore.instance.collection(collection).doc(user.id).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance.collection('users').doc(user.id).set({
        'id': user.id,
        'name': user.name ?? '',
        'lastName': user.lastName ?? '',
        'email': user.email ?? '',
        'role': user.role ?? '',
        'fcmToken': token,
      }, SetOptions(merge: true));
      print('FCM Token saved for user ${user.id}');
    } else {
      print('No user ID available, saved FCM token to SharedPreferences');
    }
  } catch (e) {
    print('Error saving FCM token: $e');
  }
}

void _handleNotificationPayload(String payload) {
  try {
    final data = jsonDecode(payload);
    final notificationType = data['type'];
    final navigatorKey = GlobalKey<NavigatorState>();
    final context = navigatorKey.currentContext;
    if (context == null) return;

    di.sl<AuthLocalDataSource>().getUser().then((user) {
      final route =
          user.role == 'medecin'
              ? const NotificationsMedecin()
              : const NotificationsPatient();
      Navigator.push(context, MaterialPageRoute(builder: (_) => route));
    });
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
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _setupForegroundNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a foreground message: ${message.messageId}');
      final notification = message.notification;
      final data = message.data;

      if (notification != null && navigatorKey.currentContext != null) {
        final notificationBloc =
            navigatorKey.currentContext!.read<NotificationBloc>();
        String senderName =
            data['senderName'] ??
            data['doctorName'] ??
            data['patientName'] ??
            'Unknown';
        String title =
            notification.title ?? data['title'] ?? 'New Notification';
        String body = notification.body ?? data['body'] ?? '';

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
              recipientId: data['recipientId'] ?? '',
              senderId: data['senderId'] ?? '',
              type:
                  data['type'] != null
                      ? NotificationUtils.stringToNotificationType(data['type'])
                      : NotificationType.newAppointment,
              createdAt: DateTime.now(),
              isRead: false,
              appointmentId: data['appointmentId'],
              prescriptionId: data['prescriptionId'],
              ratingId: data['ratingId'],
              data: data.isNotEmpty ? Map<String, dynamic>.from(data) : null,
            ),
          ),
        );

        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
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
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(data),
        );
      }
    });
  }

  void _handleMessage(RemoteMessage message) {
    di
        .sl<AuthLocalDataSource>()
        .getUser()
        .then((user) {
          final route =
              user.role == 'medecin'
                  ? const NotificationsMedecin()
                  : const NotificationsPatient();
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => route),
          );
        })
        .catchError((_) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const NotificationsPatient()),
          );
        });
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
        BlocProvider(create: (_) => di.sl<DossierMedicalBloc>()),
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
