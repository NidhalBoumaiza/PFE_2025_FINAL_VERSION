import 'dart:io';
import '../../domain/repositories/ai_chatbot_repository.dart';
import '../datasources/ai_chatbot_remote_datasource.dart';

class AiChatbotRepositoryImpl implements AiChatbotRepository {
  final AiChatbotRemoteDataSource remoteDataSource;

  AiChatbotRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> analyzeImage(File imageFile, String taskPrompt) async {
    try {
      return await remoteDataSource.analyzeImage(imageFile, taskPrompt);
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
} 