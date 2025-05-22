import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';
import 'package:medical_app/features/messagerie/domain/repositories/message_repository.dart';

class GetConversationsUseCase {
  final MessagingRepository repository;

  GetConversationsUseCase(this.repository);

  Future<Either<Failure, List<ConversationEntity>>> call({
    required String userId,
    required bool isDoctor,
  }) async {
    return await repository.getConversations(userId: userId, isDoctor: isDoctor);
  }

  Stream<List<ConversationEntity>> getConversationsStream({
    required String userId,
    required bool isDoctor,
  }) {
    return repository.getConversationsStream(userId: userId, isDoctor: isDoctor);
  }
}