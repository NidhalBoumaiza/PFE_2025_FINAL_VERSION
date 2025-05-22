import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/domain/usecases/delete_notification_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/get_notifications_stream_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/get_notifications_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/get_unread_notifications_count_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/mark_all_notifications_as_read_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/mark_notification_as_read_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/save_fcm_token_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/send_notification_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/setup_fcm_use_case.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_event.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final SendNotificationUseCase sendNotificationUseCase;
  final MarkNotificationAsReadUseCase markNotificationAsReadUseCase;
  final MarkAllNotificationsAsReadUseCase markAllNotificationsAsReadUseCase;
  final DeleteNotificationUseCase deleteNotificationUseCase;
  final GetUnreadNotificationsCountUseCase getUnreadNotificationsCountUseCase;
  final SetupFCMUseCase setupFCMUseCase;
  final SaveFCMTokenUseCase saveFCMTokenUseCase;
  final GetNotificationsStreamUseCase getNotificationsStreamUseCase;

  StreamSubscription<List<NotificationEntity>>? _notificationsSubscription;
  List<NotificationEntity> _notifications = [];
  int _unreadCount = 0;

  NotificationBloc({
    required this.getNotificationsUseCase,
    required this.sendNotificationUseCase,
    required this.markNotificationAsReadUseCase,
    required this.markAllNotificationsAsReadUseCase,
    required this.deleteNotificationUseCase,
    required this.getUnreadNotificationsCountUseCase,
    required this.setupFCMUseCase,
    required this.saveFCMTokenUseCase,
    required this.getNotificationsStreamUseCase,
  }) : super(NotificationInitial()) {
    on<GetNotificationsEvent>(_onGetNotifications);
    on<SendNotificationEvent>(_onSendNotification);
    on<MarkNotificationAsReadEvent>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllNotificationsAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<GetUnreadNotificationsCountEvent>(_onGetUnreadNotificationsCount);
    on<SetupFCMEvent>(_onSetupFCM);
    on<SaveFCMTokenEvent>(_onSaveFCMToken);
    on<GetNotificationsStreamEvent>(_onGetNotificationsStream);
    on<NotificationReceivedEvent>(_onNotificationReceived);
    on<NotificationErrorEvent>(_onNotificationError);
  }

  Future<void> _onGetNotifications(
    GetNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await getNotificationsUseCase(userId: event.userId);
    result.fold(
      (failure) => emit(
        const NotificationError(message: 'Failed to load notifications'),
      ),
      (notifications) {
        _notifications = notifications;
        emit(NotificationsLoaded(notifications: notifications));
      },
    );
  }

  Future<void> _onSendNotification(
    SendNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await sendNotificationUseCase(
      title: event.title,
      body: event.body,
      senderId: event.senderId,
      recipientId: event.recipientId,
      type: event.type,
      appointmentId: event.appointmentId,
      prescriptionId: event.prescriptionId,
      ratingId: event.ratingId,
      data: event.data,
    );
    result.fold(
      (failure) =>
          emit(const NotificationError(message: 'Failed to send notification')),
      (_) => emit(NotificationSent()),
    );
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await markNotificationAsReadUseCase(
      notificationId: event.notificationId,
    );
    result.fold(
      (failure) => emit(
        const NotificationError(message: 'Failed to mark notification as read'),
      ),
      (_) => emit(NotificationMarkedAsRead()),
    );
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await markAllNotificationsAsReadUseCase(
      userId: event.userId,
    );
    result.fold(
      (failure) => emit(
        const NotificationError(
          message: 'Failed to mark all notifications as read',
        ),
      ),
      (_) => emit(AllNotificationsMarkedAsRead()),
    );
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await deleteNotificationUseCase(
      notificationId: event.notificationId,
    );
    result.fold(
      (failure) => emit(
        const NotificationError(message: 'Failed to delete notification'),
      ),
      (_) => emit(NotificationDeleted()),
    );
  }

  Future<void> _onGetUnreadNotificationsCount(
    GetUnreadNotificationsCountEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await getUnreadNotificationsCountUseCase(
      userId: event.userId,
    );
    result.fold(
      (failure) =>
          emit(const NotificationError(message: 'Failed to get unread count')),
      (count) {
        _unreadCount = count;
        emit(UnreadNotificationsCountLoaded(count: count));
      },
    );
  }

  Future<void> _onSetupFCM(
    SetupFCMEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await setupFCMUseCase();
    result.fold(
      (failure) =>
          emit(const NotificationError(message: 'Failed to setup FCM')),
      (token) => emit(FCMSetupSuccess(token: token)),
    );
  }

  Future<void> _onSaveFCMToken(
    SaveFCMTokenEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await saveFCMTokenUseCase(
      userId: event.userId,
      token: event.token,
    );
    result.fold(
      (failure) =>
          emit(const NotificationError(message: 'Failed to save FCM token')),
      (_) => emit(FCMTokenSaved()),
    );
  }

  void _onGetNotificationsStream(
    GetNotificationsStreamEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());

    // Cancel existing subscription if there is one
    _notificationsSubscription?.cancel();

    // Subscribe to notifications stream
    _notificationsSubscription = getNotificationsStreamUseCase(
      userId: event.userId,
    ).listen(
      (notifications) {
        // Update notifications and unread count
        _notifications = notifications;
        _unreadCount = notifications.where((n) => !n.isRead).length;

        // Use add() to dispatch events instead of emitting directly from the listener
        if (notifications.isNotEmpty) {
          add(NotificationReceivedEvent(notification: notifications.first));
        }
      },
      onError: (error) {
        // Use add() to dispatch error event instead of emitting directly
        add(NotificationErrorEvent(message: 'Stream error: $error'));
      },
    );

    emit(NotificationStreamActive());
  }

  void _onNotificationReceived(
    NotificationReceivedEvent event,
    Emitter<NotificationState> emit,
  ) {
    emit(NotificationsLoaded(notifications: _notifications));
    emit(UnreadNotificationsCountLoaded(count: _unreadCount));
  }

  void _onNotificationError(
    NotificationErrorEvent event,
    Emitter<NotificationState> emit,
  ) {
    emit(NotificationError(message: event.message));
  }

  @override
  Future<void> close() {
    _notificationsSubscription?.cancel();
    return super.close();
  }
}
