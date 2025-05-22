import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:medical_app/features/messagerie/data/models/message_model.dart';

// Base event class for MessagerieBloc
abstract class MessagerieEvent extends Equatable {
  const MessagerieEvent();

  @override
  List<Object?> get props => [];
}

// Event to send a message (text, image, or file)
class SendMessageEvent extends MessagerieEvent {
  final MessageModel message; // The message to send
  final File? file; // Optional file (for images or files)

  const SendMessageEvent({required this.message, this.file});

  @override
  List<Object?> get props => [message, file];
}

// Event to fetch initial messages for a conversation
class FetchMessagesEvent extends MessagerieEvent {
  final String conversationId; // ID of the conversation

  const FetchMessagesEvent(this.conversationId);

  @override
  List<Object> get props => [conversationId];
}

// Event to subscribe to real-time message updates
class SubscribeToMessagesEvent extends MessagerieEvent {
  final String conversationId; // ID of the conversation

  const SubscribeToMessagesEvent(this.conversationId);

  @override
  List<Object> get props => [conversationId];
}

// Event to add a message to the local cache (before Firestore save)
class AddLocalMessageEvent extends MessagerieEvent {
  final MessageModel message; // The message to add locally

  const AddLocalMessageEvent(this.message);

  @override
  List<Object> get props => [message];
}

// Event to update a message's status (e.g., sent, read)
class UpdateMessageStatusEvent extends MessagerieEvent {
  final MessageModel message; // The message with updated status

  const UpdateMessageStatusEvent(this.message);

  @override
  List<Object> get props => [message];
}

// Event triggered when the Firestore stream provides updated messages
class MessagesUpdatedEvent extends MessagerieEvent {
  final List<MessageModel> messages; // Updated list of messages

  const MessagesUpdatedEvent({required this.messages});

  @override
  List<Object> get props => [messages];
}

// Event triggered when the Firestore stream encounters an error
class MessagesStreamErrorEvent extends MessagerieEvent {
  final String error; // Error message

  const MessagesStreamErrorEvent({required this.error});

  @override
  List<Object> get props => [error];
}