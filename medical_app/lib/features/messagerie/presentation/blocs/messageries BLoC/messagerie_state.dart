import 'package:equatable/equatable.dart';
import 'package:medical_app/features/messagerie/data/models/message_model.dart';

// Base state for MessagerieBloc
abstract class MessagerieState extends Equatable {
  final List<MessageModel> messages; // List of messages
  final int stateId; // Unique ID to force UI rebuilds

  const MessagerieState({
    required this.messages,
    this.stateId = 0,
  });

  @override
  List<Object?> get props => [messages, stateId];
}

class MessagerieInitial extends MessagerieState {
  const MessagerieInitial() : super(messages: const [], stateId: 0);
}

class MessagerieLoading extends MessagerieState {
  const MessagerieLoading({required super.messages, super.stateId});
}

class MessagerieStreamActive extends MessagerieState {
  const MessagerieStreamActive({required super.messages, super.stateId});
}

class MessagerieMessageSent extends MessagerieState {
  const MessagerieMessageSent({required super.messages, super.stateId});
}

class MessagerieSuccess extends MessagerieState {
  const MessagerieSuccess({required super.messages, super.stateId});
}

class MessagerieError extends MessagerieState {
  final String message; // Error message

  const MessagerieError({
    required super.messages,
    required this.message,
    super.stateId,
  });

  @override
  List<Object?> get props => [...super.props, message];
}