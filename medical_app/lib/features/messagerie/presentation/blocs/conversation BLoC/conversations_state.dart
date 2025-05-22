import 'package:equatable/equatable.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';

abstract class ConversationsState extends Equatable {
  final List<ConversationEntity> conversations;

  const ConversationsState({required this.conversations});

  @override
  List<Object> get props => [conversations];
}

class ConversationsInitial extends ConversationsState {
  const ConversationsInitial() : super(conversations: const []);
}

class ConversationsLoading extends ConversationsState {
  const ConversationsLoading({required super.conversations});
}

class ConversationsLoaded extends ConversationsState {
  const ConversationsLoaded({required super.conversations});
}

class ConversationsError extends ConversationsState {
  final String message;

  const ConversationsError({
    required this.message,
    required super.conversations,
  });

  @override
  List<Object> get props => [message, ...super.props];
}