import 'dart:io';
import '../datasources/ai_chatbot_remote_datasource.dart';
import '../../domain/repositories/ai_chatbot_repository.dart';

class AiChatbotRepositoryImpl implements AiChatbotRepository {
  final AiChatbotRemoteDataSource remoteDataSource;

  AiChatbotRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> analyzeImage(File imageFile, String prompt) async {
    try {
      return await remoteDataSource.analyzeImage(imageFile, prompt);
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }

  @override
  Future<String> analyzePdf(File pdfFile) async {
    try {
      return await remoteDataSource.analyzePdf(pdfFile);
    } catch (e) {
      throw Exception('Failed to analyze PDF: $e');
    }
  }

  @override
  Future<String> sendTextMessage(String message) async {
    try {
      return await remoteDataSource.sendTextMessage(message);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}