import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class AiChatbotEvent extends Equatable {
  const AiChatbotEvent();

  @override
  List<Object?> get props => [];
}

class SendTextMessageEvent extends AiChatbotEvent {
  final String message;

  const SendTextMessageEvent({required this.message});

  @override
  List<Object?> get props => [message];
}

class SendImageMessageEvent extends AiChatbotEvent {
  final File imageFile;
  final String taskPrompt;

  const SendImageMessageEvent({
    required this.imageFile,
    required this.taskPrompt,
  });

  @override
  List<Object?> get props => [imageFile, taskPrompt];
}

class SendPdfMessageEvent extends AiChatbotEvent {
  final File pdfFile;

  const SendPdfMessageEvent({required this.pdfFile});

  @override
  List<Object?> get props => [pdfFile];
}

class ClearChatEvent extends AiChatbotEvent {
  const ClearChatEvent();
} 