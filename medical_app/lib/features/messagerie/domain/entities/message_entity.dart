import 'package:equatable/equatable.dart';
import '../../data/models/message_model.dart';

enum MessageStatus { sending, sent, delivered, read, failed }

abstract class MessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String type;
  final String? url;
  final String? fileName;
  final DateTime timestamp;
  final MessageStatus status;
  final List<String> readBy;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    this.url,
    this.fileName,
    required this.timestamp,
    required this.status,
    required this.readBy,
  });

  MessageEntity copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? type,
    String? url,
    String? fileName,
    DateTime? timestamp,
    MessageStatus? status,
    List<String>? readBy,
  });

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    content,
    type,
    url,
    fileName,
    timestamp,
    status,
    readBy,
  ];

  static MessageEntity create({
    required String conversationId,
    required String senderId,
    required String content,
    required String type,
    String? fileName,
    required DateTime timestamp,
    String? url,
  }) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: type,
      fileName: fileName,
      url: url,
      timestamp: timestamp,
      status: MessageStatus.sending,
      readBy: [],
    );
  }
}