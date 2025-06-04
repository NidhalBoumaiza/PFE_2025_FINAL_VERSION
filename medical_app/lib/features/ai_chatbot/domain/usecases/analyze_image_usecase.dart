import 'dart:io';
import '../repositories/ai_chatbot_repository.dart';

class AnalyzeImageUseCase {
  final AiChatbotRepository repository;

  AnalyzeImageUseCase({required this.repository});

  Future<String> call(File imageFile, String prompt) async {
    return await repository.analyzeImage(imageFile, prompt);
  }
} 