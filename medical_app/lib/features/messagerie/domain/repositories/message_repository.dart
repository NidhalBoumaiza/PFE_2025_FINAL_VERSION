import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/messagerie/data/models/message_model.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';

abstract class MessagingRepository {
  Future<Either<Failure, Unit>> sendMessage(MessageModel message, File? file);
  Future<Either<Failure, List<ConversationEntity>>> getConversations({
    required String userId,
    required bool isDoctor,
  });
  Stream<List<ConversationEntity>> getConversationsStream({
    required String userId,
    required bool isDoctor,
  });
  Future<Either<Failure, List<MessageModel>>> getMessages(String conversationId);
  Stream<List<MessageModel>> getMessagesStream(String conversationId);
}