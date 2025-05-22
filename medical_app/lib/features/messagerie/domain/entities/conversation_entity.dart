import 'package:equatable/equatable.dart';

class ConversationEntity extends Equatable {
  final String? id;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String doctorName;
  final String lastMessage;
  final String lastMessageType;
  final DateTime lastMessageTime;
  final String? lastMessageUrl;
  final bool lastMessageRead;

  const ConversationEntity({
    this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageTime,
    this.lastMessageUrl,
    this.lastMessageRead = true,
  });

  factory ConversationEntity.create({
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
  }) {
    return ConversationEntity(
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
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    doctorId,
    patientName,
    doctorName,
    lastMessage,
    lastMessageType,
    lastMessageTime,
    lastMessageUrl,
    lastMessageRead,
  ];
}