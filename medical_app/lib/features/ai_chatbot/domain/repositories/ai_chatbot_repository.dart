import 'dart:io';

abstract class AiChatbotRepository {
  Future<String> analyzeImage(File imageFile, String taskPrompt);
  Future<String> analyzePdf(File pdfFile);
} 