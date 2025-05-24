import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/messagerie/data/models/message_model.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';
import 'package:medical_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:medical_app/features/notifications/utils/notification_utils.dart';
import '../models/conversation_mode.dart';

// Interface for messaging data source
abstract class MessagingRemoteDataSource {
  Future<List<ConversationEntity>> getConversations(String userId, bool isDoctor);
  Stream<List<ConversationEntity>> conversationsStream(String userId, bool isDoctor);
  Future<void> sendMessage(MessageModel message, File? file);
  Future<List<MessageModel>> getMessages(String conversationId);
  Stream<List<MessageModel>> getMessagesStream(String conversationId);
}

// Implementation using Firestore and Firebase Storage
class MessagingRemoteDataSourceImpl implements MessagingRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final NotificationRemoteDataSource notificationRemoteDataSource;

  MessagingRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
    required this.notificationRemoteDataSource,
  });

  @override
  Future<List<ConversationEntity>> getConversations(String userId, bool isDoctor) async {
    try {
      print('Fetching conversations for userId: $userId, isDoctor: $isDoctor');
      final snapshot = await firestore
          .collection('conversations')
          .where(isDoctor ? 'doctorId' : 'patientId', isEqualTo: userId)
          .orderBy('lastMessageTime', descending: true)
          .get();
      print('Fetched ${snapshot.docs.length} conversations');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        print('Conversation data: $data');
        // Validate required fields
        final patientId = data['patientId'] as String? ?? '';
        final doctorId = data['doctorId'] as String? ?? '';
        if (patientId.isEmpty || doctorId.isEmpty) {
          print('Warning: Conversation ${doc.id} has empty patientId or doctorId');
        }
        return ConversationModel(
          id: doc.id,
          patientId: patientId,
          doctorId: doctorId,
          patientName: data['patientName'] as String? ?? 'Unknown Patient',
          doctorName: data['doctorName'] as String? ?? 'Unknown Doctor',
          lastMessage: data['lastMessage'] as String? ?? '',
          lastMessageType: data['lastMessageType'] as String? ?? 'text',
          lastMessageTime: ConversationModel.parseDateTime(data['lastMessageTime'] as String?) ?? DateTime.now(),
          lastMessageUrl: data['lastMessageUrl'] as String?,
          lastMessageRead: _isMessageReadByUser(data, userId, isDoctor),
        );
      }).toList();
    } catch (e) {
      print('Error fetching conversations: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}, message: ${e.message}');
      }
      throw ServerException('Failed to fetch conversations: $e');
    }
  }

  @override
  Stream<List<ConversationEntity>> conversationsStream(String userId, bool isDoctor) {
    try {
      print('Starting conversation stream for userId: $userId, isDoctor: $isDoctor');
      return firestore
          .collection('conversations')
          .where(isDoctor ? 'doctorId' : 'patientId', isEqualTo: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) {
        print('Stream received ${snapshot.docs.length} conversations');
        return snapshot.docs.map((doc) {
          final data = doc.data();
          // Validate required fields
          final patientId = data['patientId'] as String? ?? '';
          final doctorId = data['doctorId'] as String? ?? '';
          if (patientId.isEmpty || doctorId.isEmpty) {
            print('Warning: Conversation ${doc.id} has empty patientId or doctorId');
          }
          return ConversationModel(
            id: doc.id,
            patientId: patientId,
            doctorId: doctorId,
            patientName: data['patientName'] as String? ?? 'Unknown Patient',
            doctorName: data['doctorName'] as String? ?? 'Unknown Doctor',
            lastMessage: data['lastMessage'] as String? ?? '',
            lastMessageType: data['lastMessageType'] as String? ?? 'text',
            lastMessageTime: ConversationModel.parseDateTime(data['lastMessageTime'] as String?) ?? DateTime.now(),
            lastMessageUrl: data['lastMessageUrl'] as String?,
            lastMessageRead: _isMessageReadByUser(data, userId, isDoctor),
          );
        }).toList();
      }).handleError((error) {
        print('Conversation stream error: $error');
        throw ServerException('Firestore stream error: $error');
      });
    } catch (e) {
      print('Error initializing conversation stream: $e');
      throw ServerException('Failed to initialize stream: $e');
    }
  }

  // Helper method to determine if the last message is read by the current user
  bool _isMessageReadByUser(Map<String, dynamic> data, String userId, bool isDoctor) {
    // If the current user is the sender of the last message, it's considered read
    final String lastMessageSenderId = data['lastMessageSenderId'] as String? ?? '';
    if (lastMessageSenderId == userId) {
      return true;
    }

    // Otherwise, check if the user is in the 'readBy' list of the last message
    final List<String> readBy = List<String>.from(data['lastMessageReadBy'] ?? []);
    return readBy.contains(userId);
  }

  @override
  Future<void> sendMessage(MessageModel message, File? file) async {
    try {
      String? fileUrl;
      String? fileName;

      // Upload file if provided
      if (file != null) {
        print('Uploading file for message ${message.id}');
        if (file.path.isEmpty) {
          throw ServerException('Invalid file path for message ${message.id}');
        }
        final ref = storage.ref().child('conversations').child(message.conversationId).child(message.id);
        final uploadTask = await ref.putFile(file);
        fileUrl = await uploadTask.ref.getDownloadURL();
        fileName = message.fileName ?? file.path.split('/').last;
        print('File uploaded, URL: $fileUrl, fileName: $fileName');
      }

      // Prepare message data with 'sent' status
      final messageData = message.toJson()
        ..['url'] = fileUrl
        ..['fileName'] = fileName
        ..['status'] = 'sent';

      // Save message to Firestore
      print('Saving message ${message.id} to Firestore with status: sent');
      await firestore
          .collection('conversations')
          .doc(message.conversationId)
          .collection('messages')
          .doc(message.id)
          .set(messageData);
      print('Saved message ${message.id} with status: sent');

      // Update conversation metadata
      print('Updating conversation ${message.conversationId} lastMessage');
      await firestore.collection('conversations').doc(message.conversationId).update({
        'lastMessage': message.type == 'text' ? message.content : '',
        'lastMessageType': message.type,
        'lastMessageTime': message.timestamp.toIso8601String(),
        'lastMessageUrl': fileUrl ?? '',
        'lastMessageSenderId': message.senderId,
        'lastMessageReadBy': [message.senderId],
      });
      print('Updated conversation ${message.conversationId} lastMessage');

      // Send notification to the recipient
      final conversationDoc = await firestore.collection('conversations').doc(message.conversationId).get();
      if (conversationDoc.exists) {
        final conversationData = conversationDoc.data()!;
        final recipientId = message.senderId == conversationData['patientId']
            ? conversationData['doctorId'] as String
            : conversationData['patientId'] as String;
        final recipientRole = message.senderId == conversationData['patientId'] ? 'doctor' : 'patient';
        final senderName = message.senderId == conversationData['patientId']
            ? conversationData['patientName'] as String
            : conversationData['doctorName'] as String;

        final notificationTitle = 'New Message from $senderName';
        final notificationBody = message.type == 'text'
            ? message.content.length > 100
            ? '${message.content.substring(0, _findWordBoundary(message.content, 97))}...'
            : message.content
            : 'Sent a ${message.type} message';

        try {
          await notificationRemoteDataSource.sendNotification(
            title: notificationTitle,
            body: notificationBody,
            senderId: message.senderId,
            recipientId: recipientId,
            type: NotificationType.newMessage,
            recipientRole: recipientRole,
            appointmentId: null,
            prescriptionId: null,
            ratingId: null,
            data: {
              'conversationId': message.conversationId,
              'senderName': senderName,
              'messageId': message.id,
              'messageType': message.type,
            },
          );
          print('Sent notification for message ${message.id} to recipient $recipientId');
        } catch (notificationError) {
          print('Failed to send notification for message ${message.id}: $notificationError');
          // Log the error but don't throw to ensure message sending isn't blocked
        }
      } else {
        print('Conversation ${message.conversationId} not found, skipping notification');
      }
    } catch (e) {
      print('Error sending message ${message.id}: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}, message: ${e.message}');
      }
      throw ServerException('Failed to send message: $e');
    }
  }

  // Helper method to find word boundary for truncation
  int _findWordBoundary(String text, int maxLength) {
    if (text.length <= maxLength) return maxLength;
    int boundary = text.lastIndexOf(' ', maxLength);
    return boundary == -1 ? maxLength : boundary;
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      print('Fetching messages for conversationId: $conversationId');
      final snapshot = await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();
      print('Fetched ${snapshot.docs.length} messages');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        print('Message data: $data');
        return MessageModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error fetching messages: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}, message: ${e.message}');
      }
      throw ServerException('Failed to fetch messages: $e');
    }
  }

  @override
  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    try {
      print('Starting message stream for conversationId: $conversationId');
      return firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        print('Stream received ${snapshot.docs.length} messages');
        return snapshot.docs.map((doc) {
          final data = doc.data();
          print('Stream message data: $data');
          return MessageModel.fromJson({
            'id': doc.id,
            ...data,
          });
        }).toList();
      }).handleError((error) {
        print('Message stream error: $error');
        throw ServerException('Firestore stream error: $error');
      });
    } catch (e) {
      print('Error initializing message stream: $e');
      throw ServerException('Failed to initialize stream: $e');
    }
  }
}