import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required String id,
    required String title,
    required String body,
    required String senderId,
    required String recipientId,
    required NotificationType type,
    String? appointmentId,
    String? prescriptionId,
    String? ratingId,
    required DateTime createdAt,
    bool isRead = false,
    Map<String, dynamic>? data,
  }) : super(
          id: id,
          title: title,
          body: body,
          senderId: senderId,
          recipientId: recipientId,
          type: type,
          appointmentId: appointmentId,
          prescriptionId: prescriptionId,
          ratingId: ratingId,
          createdAt: createdAt,
          isRead: isRead,
          data: data,
        );

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      senderId: json['senderId'] as String,
      recipientId: json['recipientId'] as String,
      type: NotificationType.values.firstWhere(
          (e) => e.toString() == 'NotificationType.${json['type']}'),
      appointmentId: json['appointmentId'] as String?,
      prescriptionId: json['prescriptionId'] as String?,
      ratingId: json['ratingId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'body': body,
      'senderId': senderId,
      'recipientId': recipientId,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };

    if (appointmentId != null) {
      data['appointmentId'] = appointmentId;
    }
    if (prescriptionId != null) {
      data['prescriptionId'] = prescriptionId;
    }
    if (ratingId != null) {
      data['ratingId'] = ratingId;
    }
    if (this.data != null) {
      data['data'] = this.data;
    }

    return data;
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? senderId,
    String? recipientId,
    NotificationType? type,
    String? appointmentId,
    String? prescriptionId,
    String? ratingId,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      type: type ?? this.type,
      appointmentId: appointmentId ?? this.appointmentId,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      ratingId: ratingId ?? this.ratingId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
} 