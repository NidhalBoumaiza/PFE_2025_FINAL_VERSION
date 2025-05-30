import 'package:equatable/equatable.dart';
import '../../data/models/chat_message_model.dart';

abstract class AiChatbotState extends Equatable {
  const AiChatbotState();

  @override
  List<Object?> get props => [];
}

class AiChatbotInitial extends AiChatbotState {
  const AiChatbotInitial();
}

class AiChatbotLoaded extends AiChatbotState {
  final List<ChatMessageModel> messages;
  final bool isLoading;

  const AiChatbotLoaded({
    required this.messages,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [messages, isLoading];

  AiChatbotLoaded copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
  }) {
    return AiChatbotLoaded(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AiChatbotError extends AiChatbotState {
  final String message;
  final List<ChatMessageModel> messages;

  const AiChatbotError({
    required this.message,
    required this.messages,
  });

  @override
  List<Object?> get props => [message, messages];
} 