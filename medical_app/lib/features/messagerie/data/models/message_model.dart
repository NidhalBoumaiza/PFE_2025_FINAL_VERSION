import 'package:medical_app/features/messagerie/domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.content,
    required super.type,
    super.url,
    super.fileName,
    required super.timestamp,
    required super.status,
    required super.readBy,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      url: json['url'] as String?,
      fileName: json['fileName'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.firstWhere(
            (status) => status.toString().split('.').last == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      readBy: List<String>.from(json['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'url': url,
      'fileName': fileName,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'readBy': readBy,
    };
  }

  @override
  MessageModel copyWith({
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
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      readBy: readBy ?? this.readBy,
    );
  }
}