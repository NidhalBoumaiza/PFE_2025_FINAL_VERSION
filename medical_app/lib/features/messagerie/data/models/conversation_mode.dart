import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';

class ConversationModel extends ConversationEntity {
  ConversationModel({
    String? id,
    required String patientId,
    required String doctorId,
    required String patientName,
    required String doctorName,
    required String lastMessage,
    required String lastMessageType,
    required DateTime lastMessageTime,
    String? lastMessageUrl,
    bool lastMessageRead = true,
  }) : super(
    id: id,
    patientId: patientId,
    doctorId: doctorId,
    patientName: patientName,
    doctorName: doctorName,
    lastMessage: lastMessage,
    lastMessageType: lastMessageType,
    lastMessageTime: lastMessageTime,
    lastMessageUrl: lastMessageUrl,
    lastMessageRead: lastMessageRead,
  );

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String?,
      patientId: json['patientId'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      patientName: json['patientName'] as String? ?? 'Unknown Patient',
      doctorName: json['doctorName'] as String? ?? 'Unknown Doctor',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageType: json['lastMessageType'] as String? ?? 'text',
      lastMessageTime: parseDateTime(json['lastMessageTime'] as String?),
      lastMessageUrl: json['lastMessageUrl'] as String?,
      lastMessageRead: json['lastMessageRead'] as bool? ?? true,
    );
  }

  static DateTime parseDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final data = {
      'patientId': patientId,
      'doctorId': doctorId,
      'patientName': patientName,
      'doctorName': doctorName,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageTime': lastMessageTime.toIso8601String(),
    };
    if (id != null) {
      data['id'] = id!;
    }
    if (lastMessageUrl != null) {
      data['lastMessageUrl'] = lastMessageUrl!;
    }
    return data;
  }
}