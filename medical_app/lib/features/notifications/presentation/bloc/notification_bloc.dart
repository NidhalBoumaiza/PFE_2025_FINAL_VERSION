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
import 'package:medical_app/features/notifications/utils/notification_utils.dart';

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
  bool _isLoading = false;
  String? _currentUserId;

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
    try {
      // Prevent multiple simultaneous loading operations
      if (_isLoading && _currentUserId == event.userId) {
        return;
      }

      _isLoading = true;
      _currentUserId = event.userId;

      emit(NotificationLoading());

      final result = await getNotificationsUseCase(userId: event.userId);

      if (!isClosed) {
        result.fold(
          (failure) {
            _isLoading = false;
            emit(
              const NotificationError(message: 'Failed to load notifications'),
            );
          },
          (notifications) {
            _notifications = notifications;
            _unreadCount = notifications.where((n) => !n.isRead).length;
            _isLoading = false;
            emit(NotificationsLoaded(notifications: notifications));
          },
        );
      }
    } catch (e) {
      _isLoading = false;
      if (!isClosed) {
        emit(
          NotificationError(
            message: 'Error loading notifications: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onSendNotification(
    SendNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final result = await sendNotificationUseCase(
        title: event.title,
        body: event.body,
        senderId: event.senderId,
        recipientId: event.recipientId,
        type: event.type,
        recipientRole: event.recipientRole,
        appointmentId: event.appointmentId,
        prescriptionId: event.prescriptionId,
        ratingId: event.ratingId,
        data: event.data,
      );

      if (!isClosed) {
        result.fold(
          (failure) => emit(
            const NotificationError(message: 'Failed to send notification'),
          ),
          (_) => emit(NotificationSent()),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          NotificationError(
            message: 'Error sending notification: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final result = await markNotificationAsReadUseCase(
        notificationId: event.notificationId,
      );

      if (!isClosed) {
        result.fold(
          (failure) => emit(
            const NotificationError(
              message: 'Failed to mark notification as read',
            ),
          ),
          (_) {
            // Update local state by creating new list with updated notification
            _notifications =
                _notifications.map((n) {
                  if (n.id == event.notificationId) {
                    // Create a new NotificationEntity with updated isRead status
                    return NotificationEntity(
                      id: n.id,
                      title: n.title,
                      body: n.body,
                      senderId: n.senderId,
                      recipientId: n.recipientId,
                      type: n.type,
                      appointmentId: n.appointmentId,
                      prescriptionId: n.prescriptionId,
                      ratingId: n.ratingId,
                      createdAt: n.createdAt,
                      isRead: true,
                      data: n.data,
                    );
                  }
                  return n;
                }).toList();
            _unreadCount = _notifications.where((n) => !n.isRead).length;

            emit(NotificationMarkedAsRead());
            emit(NotificationsLoaded(notifications: _notifications));
            emit(UnreadNotificationsCountLoaded(count: _unreadCount));
          },
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          NotificationError(
            message: 'Error marking notification as read: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final result = await markAllNotificationsAsReadUseCase(
        userId: event.userId,
      );

      if (!isClosed) {
        result.fold(
          (failure) => emit(
            const NotificationError(
              message: 'Failed to mark all notifications as read',
            ),
          ),
          (_) {
            // Update local state by creating new list with all notifications marked as read
            _notifications =
                _notifications
                    .map(
                      (n) => NotificationEntity(
                        id: n.id,
                        title: n.title,
                        body: n.body,
                        senderId: n.senderId,
                        recipientId: n.recipientId,
                        type: n.type,
                        appointmentId: n.appointmentId,
                        prescriptionId: n.prescriptionId,
                        ratingId: n.ratingId,
                        createdAt: n.createdAt,
                        isRead: true,
                        data: n.data,
                      ),
                    )
                    .toList();
            _unreadCount = 0;

            emit(AllNotificationsMarkedAsRead());
            emit(NotificationsLoaded(notifications: _notifications));
            emit(UnreadNotificationsCountLoaded(count: 0));
          },
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          NotificationError(
            message: 'Error marking all notifications as read: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final result = await deleteNotificationUseCase(
        notificationId: event.notificationId,
      );

      if (!isClosed) {
        result.fold(
          (failure) => emit(
            const NotificationError(message: 'Failed to delete notification'),
          ),
          (_) {
            // Update local state
            _notifications =
                _notifications
                    .where((n) => n.id != event.notificationId)
                    .toList();
            _unreadCount = _notifications.where((n) => !n.isRead).length;

            emit(NotificationDeleted());
            emit(NotificationsLoaded(notifications: _notifications));
            emit(UnreadNotificationsCountLoaded(count: _unreadCount));
          },
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          NotificationError(
            message: 'Error deleting notification: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onGetUnreadNotificationsCount(
    GetUnreadNotificationsCountEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final result = await getUnreadNotificationsCountUseCase(
        userId: event.userId,
      );

      if (!isClosed) {
        result.fold(
          (failure) => emit(
            const NotificationError(message: 'Failed to get unread count'),
          ),
          (count) {
            _unreadCount = count;
            emit(UnreadNotificationsCountLoaded(count: count));
          },
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          NotificationError(
            message: 'Error getting unread count: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onSetupFCM(
    SetupFCMEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final result = await setupFCMUseCase();

      if (!isClosed) {
        result.fold(
          (failure) =>
              emit(const NotificationError(message: 'Failed to setup FCM')),
          (token) => emit(FCMSetupSuccess(token: token)),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          NotificationError(message: 'Error setting up FCM: ${e.toString()}'),
        );
      }
    }
  }

  Future<void> _onSaveFCMToken(
    SaveFCMTokenEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final result = await saveFCMTokenUseCase(
        userId: event.userId,
        token: event.token,
      );

      if (!isClosed) {
        result.fold(
          (failure) => emit(
            const NotificationError(message: 'Failed to save FCM token'),
          ),
          (_) => emit(FCMTokenSaved()),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          NotificationError(message: 'Error saving FCM token: ${e.toString()}'),
        );
      }
    }
  }

  void _onGetNotificationsStream(
    GetNotificationsStreamEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Cancel existing subscription if there is one
      await _notificationsSubscription?.cancel();
      _notificationsSubscription = null;

      // Only set up stream if we don't already have one for this user
      if (_currentUserId != event.userId) {
        _currentUserId = event.userId;

        // Subscribe to notifications stream
        _notificationsSubscription = getNotificationsStreamUseCase(
          userId: event.userId,
        ).listen(
          (notifications) {
            if (!isClosed) {
              // Update notifications and unread count
              _notifications = notifications;
              _unreadCount = notifications.where((n) => !n.isRead).length;

              // Emit loaded state with current notifications
              emit(NotificationsLoaded(notifications: _notifications));
              emit(UnreadNotificationsCountLoaded(count: _unreadCount));

              // If we have new notifications, trigger a received event for the latest one
              if (notifications.isNotEmpty) {
                add(
                  NotificationReceivedEvent(notification: notifications.first),
                );
              }
            }
          },
          onError: (error) {
            if (!isClosed) {
              // Use add() to dispatch error event instead of emitting directly
              add(NotificationErrorEvent(message: 'Stream error: $error'));
            }
          },
        );

        if (!isClosed) {
          emit(NotificationStreamActive());
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          NotificationError(
            message: 'Error setting up notifications stream: ${e.toString()}',
          ),
        );
      }
    }
  }

  void _onNotificationReceived(
    NotificationReceivedEvent event,
    Emitter<NotificationState> emit,
  ) {
    if (!isClosed) {
      emit(NotificationsLoaded(notifications: _notifications));
      emit(UnreadNotificationsCountLoaded(count: _unreadCount));
    }
  }

  void _onNotificationError(
    NotificationErrorEvent event,
    Emitter<NotificationState> emit,
  ) {
    if (!isClosed) {
      emit(NotificationError(message: event.message));
    }
  }

  @override
  Future<void> close() {
    _notificationsSubscription?.cancel();
    _isLoading = false;
    return super.close();
  }
}
