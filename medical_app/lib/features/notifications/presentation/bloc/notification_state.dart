import 'package:equatable/equatable.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationsLoaded extends NotificationState {
  final List<NotificationEntity> notifications;

  const NotificationsLoaded({required this.notifications});

  @override
  List<Object> get props => [notifications];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError({required this.message});

  @override
  List<Object> get props => [message];
}

class NotificationSent extends NotificationState {}

class NotificationMarkedAsRead extends NotificationState {}

class AllNotificationsMarkedAsRead extends NotificationState {}

class NotificationDeleted extends NotificationState {}

class UnreadNotificationsCountLoaded extends NotificationState {
  final int count;

  const UnreadNotificationsCountLoaded({required this.count});

  @override
  List<Object> get props => [count];
}

class FCMSetupSuccess extends NotificationState {
  final String? token;

  const FCMSetupSuccess({this.token});

  @override
  List<Object> get props => token != null ? [token!] : [];
}

class FCMTokenSaved extends NotificationState {}

class NotificationStreamActive extends NotificationState {} 