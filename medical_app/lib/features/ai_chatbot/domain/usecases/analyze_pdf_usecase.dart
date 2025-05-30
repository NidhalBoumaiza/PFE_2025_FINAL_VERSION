import 'dart:io';
import '../repositories/ai_chatbot_repository.dart';

class AnalyzePdfUseCase {
  final AiChatbotRepository repository;

  AnalyzePdfUseCase({required this.repository});

  Future<String> call(File pdfFile) async {
    return await repository.analyzePdf(pdfFile);
  }
} 