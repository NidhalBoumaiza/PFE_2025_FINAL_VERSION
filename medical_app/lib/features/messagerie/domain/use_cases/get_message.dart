import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/messagerie/data/models/message_model.dart';
import 'package:medical_app/features/messagerie/domain/repositories/message_repository.dart';

class GetMessagesUseCase {
  final MessagingRepository repository;

  GetMessagesUseCase(this.repository);

  Future<Either<Failure, List<MessageModel>>> call(String conversationId) async {
    return await repository.getMessages(conversationId);
  }
}