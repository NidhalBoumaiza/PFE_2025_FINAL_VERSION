import '../repositories/ai_chatbot_repository.dart';

class SendTextMessageUseCase {
  final AiChatbotRepository repository;

  SendTextMessageUseCase({required this.repository});

  Future<String> call(String message) async {
    try {
      print('=== USE CASE TEXT MESSAGE DEBUG ===');
      print('Message: $message');
      print('Calling repository.sendTextMessage...');
      
      final result = await repository.sendTextMessage(message);
      
      print('Use case received result: $result');
      return result;
    } catch (e, stackTrace) {
      print('=== USE CASE TEXT MESSAGE EXCEPTION ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception message: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
} 