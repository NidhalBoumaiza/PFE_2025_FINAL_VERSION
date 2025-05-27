import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:get/get.dart';
import '../../utils/notification_utils.dart';

enum NotificationPriority { urgent, high, normal, low }

class EnhancedNotificationService {
  static final EnhancedNotificationService _instance =
      EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      _handleNotificationAction(payload);
    }
  }

  void _handleNotificationAction(String payload) {
    try {
      final parts = payload.split('|');
      if (parts.length >= 2) {
        final type = parts[0];
        final id = parts[1];

        switch (type) {
          case 'appointment':
            Get.toNamed('/appointment-details', arguments: {'id': id});
            break;
          case 'prescription':
            Get.toNamed('/prescription-details', arguments: {'id': id});
            break;
          case 'message':
            Get.toNamed('/chat', arguments: {'conversationId': id});
            break;
          case 'rating':
            Get.toNamed('/rating', arguments: {'appointmentId': id});
            break;
          default:
            Get.toNamed('/notifications');
        }
      }
    } catch (e) {
      print('Error handling notification action: $e');
    }
  }

  Future<bool> _areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('push_notifications') ?? true;
  }

  Future<bool> _isNotificationTypeEnabled(NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();

    switch (type) {
      case NotificationType.appointmentReminder:
      case NotificationType.newAppointment:
      case NotificationType.appointmentAccepted:
      case NotificationType.appointmentRejected:
      case NotificationType.appointmentCanceled:
        return prefs.getBool('appointment_reminders') ?? true;

      case NotificationType.medicationReminder:
        return prefs.getBool('medication_reminders') ?? true;

      case NotificationType.emergencyAlert:
        return prefs.getBool('emergency_alerts') ?? true;

      default:
        return true;
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    if (!await _areNotificationsEnabled()) return;
    if (!await _isNotificationTypeEnabled(type)) return;

    await initialize();

    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool('sound') ?? true;
    final vibrationEnabled = prefs.getBool('vibration') ?? true;

    final androidDetails = AndroidNotificationDetails(
      'medical_app_channel',
      'Medical App Notifications',
      channelDescription: 'Notifications for medical app',
      importance: _getAndroidImportance(priority),
      priority: _getAndroidPriority(priority),
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
      icon: _getNotificationIcon(type),
      color: _getNotificationColor(type),
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationType type,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    if (!await _areNotificationsEnabled()) return;
    if (!await _isNotificationTypeEnabled(type)) return;

    await initialize();

    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool('sound') ?? true;
    final vibrationEnabled = prefs.getBool('vibration') ?? true;

    final androidDetails = AndroidNotificationDetails(
      'medical_app_scheduled',
      'Scheduled Medical Notifications',
      channelDescription: 'Scheduled notifications for medical app',
      importance: _getAndroidImportance(priority),
      priority: _getAndroidPriority(priority),
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
      icon: _getNotificationIcon(type),
      color: _getNotificationColor(type),
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required String doctorName,
    required DateTime appointmentTime,
    String? patientName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final reminderMinutes = prefs.getInt('reminder_minutes_before') ?? 30;

    final reminderTime = appointmentTime.subtract(
      Duration(minutes: reminderMinutes),
    );

    if (reminderTime.isAfter(DateTime.now())) {
      final title = 'appointment_reminder'.tr;
      final body = 'appointment_reminder_message'.tr
          .replaceAll('{doctorName}', doctorName)
          .replaceAll('{time}', '${reminderMinutes} ${'minutes'.tr}');

      await scheduleNotification(
        title: title,
        body: body,
        scheduledDate: reminderTime,
        type: NotificationType.appointmentReminder,
        payload: 'appointment|$appointmentId',
        priority: NotificationPriority.high,
      );
    }
  }

  Future<void> scheduleMedicationReminder({
    required String medicationName,
    required List<DateTime> reminderTimes,
    String? prescriptionId,
  }) async {
    for (final reminderTime in reminderTimes) {
      if (reminderTime.isAfter(DateTime.now())) {
        final title = 'medication_reminder'.tr;
        final body = 'medication_reminder_message'.tr.replaceAll(
          '{medicationName}',
          medicationName,
        );

        await scheduleNotification(
          title: title,
          body: body,
          scheduledDate: reminderTime,
          type: NotificationType.medicationReminder,
          payload: 'prescription|${prescriptionId ?? ''}',
          priority: NotificationPriority.high,
        );
      }
    }
  }

  Future<void> showEmergencyAlert({
    required String message,
    String? actionData,
  }) async {
    final title = 'emergency_alert'.tr;
    final body = 'emergency_alert_message'.tr.replaceAll('{message}', message);

    await showInstantNotification(
      title: title,
      body: body,
      type: NotificationType.emergencyAlert,
      payload: 'emergency|${actionData ?? ''}',
      priority: NotificationPriority.urgent,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Importance.max;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.low:
        return Importance.low;
    }
  }

  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Priority.max;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.low:
        return Priority.low;
    }
  }

  String? _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentReminder:
      case NotificationType.newAppointment:
        return '@drawable/ic_appointment';
      case NotificationType.medicationReminder:
        return '@drawable/ic_medication';
      case NotificationType.emergencyAlert:
        return '@drawable/ic_emergency';
      case NotificationType.newPrescription:
        return '@drawable/ic_prescription';
      case NotificationType.newMessage:
        return '@drawable/ic_message';
      default:
        return '@mipmap/ic_launcher';
    }
  }

  Color? _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.emergencyAlert:
        return const Color(0xFFFF0000); // Red
      case NotificationType.appointmentReminder:
      case NotificationType.newAppointment:
        return const Color(0xFF1E88E5); // Blue
      case NotificationType.medicationReminder:
        return const Color(0xFF4CAF50); // Green
      case NotificationType.newPrescription:
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFF1E88E5); // Default blue
    }
  }
}
