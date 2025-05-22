import 'package:medical_app/features/messagerie/data/models/message_model.dart';
import 'package:medical_app/features/messagerie/domain/repositories/message_repository.dart';

class GetMessagesStreamUseCase {
  final MessagingRepository repository;

  GetMessagesStreamUseCase(this.repository);

  Stream<List<MessageModel>> call(String conversationId) {
    return repository.getMessagesStream(conversationId);
  }
}