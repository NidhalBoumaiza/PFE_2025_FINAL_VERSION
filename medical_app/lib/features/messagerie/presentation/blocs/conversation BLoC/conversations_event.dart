import 'package:equatable/equatable.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';

abstract class ConversationsEvent extends Equatable {
  const ConversationsEvent();

  @override
  List<Object> get props => [];
}

class FetchConversationsEvent extends ConversationsEvent {
  final String userId;
  final bool isDoctor;

  const FetchConversationsEvent({required this.userId, required this.isDoctor});

  @override
  List<Object> get props => [userId, isDoctor];
}

class SubscribeToConversationsEvent extends ConversationsEvent {
  final String userId;
  final bool isDoctor;

  const SubscribeToConversationsEvent({
    required this.userId,
    required this.isDoctor,
  });

  @override
  List<Object> get props => [userId, isDoctor];
}

class ConversationsUpdatedEvent extends ConversationsEvent {
  final List<ConversationEntity> conversations;

  const ConversationsUpdatedEvent({required this.conversations});

  @override
  List<Object> get props => [conversations];
}

class ConversationsStreamErrorEvent extends ConversationsEvent {
  final String error;

  const ConversationsStreamErrorEvent({required this.error});

  @override
  List<Object> get props => [error];
}

class MarkAllConversationsReadEvent extends ConversationsEvent {
  final String userId;

  const MarkAllConversationsReadEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}
