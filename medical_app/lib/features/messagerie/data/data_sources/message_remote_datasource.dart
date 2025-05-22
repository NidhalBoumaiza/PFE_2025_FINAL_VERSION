import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/messagerie/data/models/message_model.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';
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

  MessagingRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
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
        return ConversationModel(
          id: doc.id,
          patientId: data['patientId'] as String? ?? '',
          doctorId: data['doctorId'] as String? ?? '',
          patientName: data['patientName'] as String? ?? 'Unknown Patient',
          doctorName: data['doctorName'] as String? ?? 'Unknown Doctor',
          lastMessage: data['lastMessage'] as String? ?? '',
          lastMessageType: data['lastMessageType'] as String? ?? 'text',
          lastMessageTime: ConversationModel.parseDateTime(data['lastMessageTime'] as String?),
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
          return ConversationModel(
            id: doc.id,
            patientId: data['patientId'] as String? ?? '',
            doctorId: data['doctorId'] as String? ?? '',
            patientName: data['patientName'] as String? ?? 'Unknown Patient',
            doctorName: data['doctorName'] as String? ?? 'Unknown Doctor',
            lastMessage: data['lastMessage'] as String? ?? '',
            lastMessageType: data['lastMessageType'] as String? ?? 'text',
            lastMessageTime: ConversationModel.parseDateTime(data['lastMessageTime'] as String?),
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
      });
      print('Updated conversation ${message.conversationId} lastMessage');
    } catch (e) {
      print('Error sending message ${message.id}: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}, message: ${e.message}');
      }
      throw ServerException('Failed to send message: $e');
    }
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