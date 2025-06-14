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
  Future<List<ConversationEntity>> getConversations(
    String userId,
    bool isDoctor,
  );
  Stream<List<ConversationEntity>> conversationsStream(
    String userId,
    bool isDoctor,
  );
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
  Future<List<ConversationEntity>> getConversations(
    String userId,
    bool isDoctor,
  ) async {
    try {
      print(
        'Récupération des conversations pour utilisateur: $userId, estMédecin: $isDoctor',
      );
      final snapshot =
          await firestore
              .collection('conversations')
              .where(isDoctor ? 'doctorId' : 'patientId', isEqualTo: userId)
              .orderBy('lastMessageTime', descending: true)
              .get();
      print('${snapshot.docs.length} conversations récupérées');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        print('Données de conversation: $data');
        // Validate required fields
        final patientId = data['patientId'] as String? ?? '';
        final doctorId = data['doctorId'] as String? ?? '';
        if (patientId.isEmpty || doctorId.isEmpty) {
          print(
            'Attention: Conversation ${doc.id} a un patientId ou doctorId vide',
          );
        }
        return ConversationModel(
          id: doc.id,
          patientId: patientId,
          doctorId: doctorId,
          patientName: data['patientName'] as String? ?? 'Patient Inconnu',
          doctorName: data['doctorName'] as String? ?? 'Médecin Inconnu',
          lastMessage: data['lastMessage'] as String? ?? '',
          lastMessageType: data['lastMessageType'] as String? ?? 'text',
          lastMessageTime:
              ConversationModel.parseDateTime(
                data['lastMessageTime'] as String?,
              ) ??
              DateTime.now(),
          lastMessageUrl: data['lastMessageUrl'] as String?,
          lastMessageRead: _isMessageReadByUser(data, userId, isDoctor),
        );
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des conversations: $e');
      if (e is FirebaseException) {
        print('Code d\'erreur Firebase: ${e.code}, message: ${e.message}');
      }
      throw ServerException('Échec de récupération des conversations: $e');
    }
  }

  @override
  Stream<List<ConversationEntity>> conversationsStream(
    String userId,
    bool isDoctor,
  ) {
    try {
      print(
        'Démarrage du flux de conversations pour utilisateur: $userId, estMédecin: $isDoctor',
      );
      return firestore
          .collection('conversations')
          .where(isDoctor ? 'doctorId' : 'patientId', isEqualTo: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) {
            print('Flux a reçu ${snapshot.docs.length} conversations');
            return snapshot.docs.map((doc) {
              final data = doc.data();
              // Validate required fields
              final patientId = data['patientId'] as String? ?? '';
              final doctorId = data['doctorId'] as String? ?? '';
              if (patientId.isEmpty || doctorId.isEmpty) {
                print(
                  'Attention: Conversation ${doc.id} a un patientId ou doctorId vide',
                );
              }
              return ConversationModel(
                id: doc.id,
                patientId: patientId,
                doctorId: doctorId,
                patientName:
                    data['patientName'] as String? ?? 'Patient Inconnu',
                doctorName: data['doctorName'] as String? ?? 'Médecin Inconnu',
                lastMessage: data['lastMessage'] as String? ?? '',
                lastMessageType: data['lastMessageType'] as String? ?? 'text',
                lastMessageTime:
                    ConversationModel.parseDateTime(
                      data['lastMessageTime'] as String?,
                    ) ??
                    DateTime.now(),
                lastMessageUrl: data['lastMessageUrl'] as String?,
                lastMessageRead: _isMessageReadByUser(data, userId, isDoctor),
              );
            }).toList();
          })
          .handleError((error) {
            print('Erreur de flux de conversation: $error');
            throw ServerException('Erreur de flux Firestore: $error');
          });
    } catch (e) {
      print('Erreur d\'initialisation du flux de conversation: $e');
      throw ServerException('Échec d\'initialisation du flux: $e');
    }
  }

  // Helper method to determine if the last message is read by the current user
  bool _isMessageReadByUser(
    Map<String, dynamic> data,
    String userId,
    bool isDoctor,
  ) {
    // If the current user is the sender of the last message, it's considered read
    final String lastMessageSenderId =
        data['lastMessageSenderId'] as String? ?? '';
    if (lastMessageSenderId == userId) {
      return true;
    }

    // Otherwise, check if the user is in the 'readBy' list of the last message
    final List<String> readBy = List<String>.from(
      data['lastMessageReadBy'] ?? [],
    );
    return readBy.contains(userId);
  }

  @override
  Future<void> sendMessage(MessageModel message, File? file) async {
    try {
      String? fileUrl;
      String? fileName;

      // Upload file if provided
      if (file != null) {
        print('Téléchargement du fichier pour le message ${message.id}');
        if (file.path.isEmpty) {
          throw ServerException(
            'Chemin de fichier invalide pour le message ${message.id}',
          );
        }
        final ref = storage
            .ref()
            .child('conversations')
            .child(message.conversationId)
            .child(message.id);
        final uploadTask = await ref.putFile(file);
        fileUrl = await uploadTask.ref.getDownloadURL();
        fileName = message.fileName ?? file.path.split('/').last;
        print('Fichier téléchargé, URL: $fileUrl, nom du fichier: $fileName');
      }

      // Prepare message data with 'sent' status
      final messageData =
          message.toJson()
            ..['url'] = fileUrl
            ..['fileName'] = fileName
            ..['status'] = 'sent';

      // Save message to Firestore
      print(
        'Enregistrement du message ${message.id} dans Firestore avec statut: envoyé',
      );
      await firestore
          .collection('conversations')
          .doc(message.conversationId)
          .collection('messages')
          .doc(message.id)
          .set(messageData);
      print('Message ${message.id} enregistré avec statut: envoyé');

      // Update conversation metadata
      print(
        'Mise à jour du dernier message de la conversation ${message.conversationId}',
      );
      await firestore
          .collection('conversations')
          .doc(message.conversationId)
          .update({
            'lastMessage': message.type == 'text' ? message.content : '',
            'lastMessageType': message.type,
            'lastMessageTime': message.timestamp.toIso8601String(),
            'lastMessageUrl': fileUrl ?? '',
            'lastMessageSenderId': message.senderId,
            'lastMessageReadBy': [message.senderId],
          });
      print(
        'Dernier message de la conversation ${message.conversationId} mis à jour',
      );

      // Send notification to the recipient
      final conversationDoc =
          await firestore
              .collection('conversations')
              .doc(message.conversationId)
              .get();
      if (conversationDoc.exists) {
        final conversationData = conversationDoc.data()!;
        final recipientId =
            message.senderId == conversationData['patientId']
                ? conversationData['doctorId'] as String
                : conversationData['patientId'] as String;
        final recipientRole =
            message.senderId == conversationData['patientId']
                ? 'doctor'
                : 'patient';
        final senderName =
            message.senderId == conversationData['patientId']
                ? conversationData['patientName'] as String
                : conversationData['doctorName'] as String;

        final notificationTitle = 'Nouveau message de $senderName';

        // Improved message body based on message type
        String notificationBody;
        switch (message.type) {
          case 'image':
            notificationBody = '📷 Photo';
            break;
          case 'video':
            notificationBody = '🎬 Vidéo';
            break;
          case 'document':
            notificationBody = '📄 Document';
            break;
          case 'audio':
            notificationBody = '🎵 Audio';
            break;
          default: // text
            notificationBody =
                message.content.length > 100
                    ? '${message.content.substring(0, _findWordBoundary(message.content, 97))}...'
                    : message.content;
        }

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
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              // Include file URL if available
              if (fileUrl != null) 'fileUrl': fileUrl,
              if (fileName != null) 'fileName': fileName,
            },
          );
          print(
            'Notification envoyée pour le message ${message.id} au destinataire $recipientId',
          );
        } catch (notificationError) {
          print(
            'Échec d\'envoi de notification pour le message ${message.id}: $notificationError',
          );
          // Consider retry mechanism or logging to analytics
        }
      } else {
        print(
          'Conversation ${message.conversationId} non trouvée, notification ignorée',
        );
      }
    } catch (e) {
      print('Erreur lors de l\'envoi du message ${message.id}: $e');
      if (e is FirebaseException) {
        print('Code d\'erreur Firebase: ${e.code}, message: ${e.message}');
      }
      throw ServerException('Échec d\'envoi du message: $e');
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
      print('Récupération des messages pour la conversation: $conversationId');
      final snapshot =
          await firestore
              .collection('conversations')
              .doc(conversationId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .get();
      print('${snapshot.docs.length} messages récupérés');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        print('Données du message: $data');
        return MessageModel.fromJson({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des messages: $e');
      if (e is FirebaseException) {
        print('Code d\'erreur Firebase: ${e.code}, message: ${e.message}');
      }
      throw ServerException('Échec de récupération des messages: $e');
    }
  }

  @override
  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    try {
      print(
        'Démarrage du flux de messages pour la conversation: $conversationId',
      );
      return firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
            print('Flux a reçu ${snapshot.docs.length} messages');
            return snapshot.docs.map((doc) {
              final data = doc.data();
              print('Données du message du flux: $data');
              return MessageModel.fromJson({'id': doc.id, ...data});
            }).toList();
          })
          .handleError((error) {
            print('Erreur de flux de messages: $error');
            throw ServerException('Erreur de flux Firestore: $error');
          });
    } catch (e) {
      print('Erreur d\'initialisation du flux de messages: $e');
      throw ServerException('Échec d\'initialisation du flux: $e');
    }
  }
}
