import '../repositories/ai_chatbot_repository.dart';

class SendTextMessageUseCase {
  final AiChatbotRepository repository;

  SendTextMessageUseCase({required this.repository});

  Future<String> call(String message) async {
    return await repository.sendTextMessage(message);
  }
} 