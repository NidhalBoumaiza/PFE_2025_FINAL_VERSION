import 'dart:io';

abstract class AiChatbotRepository {
  Future<String> sendTextMessage(String message);
  Future<String> analyzeImage(File imageFile, String prompt);
  Future<String> analyzePdf(File pdfFile);
} 