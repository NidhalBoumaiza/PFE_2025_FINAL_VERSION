import 'dart:io';
import 'package:medical_app/features/ai_service/ai_service_client.dart';
import '../../domain/repositories/ai_chatbot_repository.dart';

class AiChatbotRepositoryImpl implements AiChatbotRepository {
  final AiServiceClient aiServiceClient;

  AiChatbotRepositoryImpl({required this.aiServiceClient});

  @override
  Future<String> analyzeImage(File imageFile, String prompt) async {
    try {
      return await aiServiceClient.analyzeImage(imageFile, prompt);
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }

  @override
  Future<String> analyzePdf(File pdfFile) async {
    try {
      return await aiServiceClient.analyzePdf(pdfFile);
    } catch (e) {
      throw Exception('Failed to analyze PDF: $e');
    }
  }

  @override
  Future<String> sendTextMessage(String message) async {
    try {
      return await aiServiceClient.sendTextMessage(message);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
} 