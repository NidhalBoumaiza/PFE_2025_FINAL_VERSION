import 'dart:io';
import '../datasources/ai_chatbot_remote_datasource.dart';
import '../../domain/repositories/ai_chatbot_repository.dart';

class AiChatbotRepositoryImpl implements AiChatbotRepository {
  final AiChatbotRemoteDataSource remoteDataSource;

  AiChatbotRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> analyzeImage(File imageFile, String prompt) async {
    try {
      print('=== REPOSITORY IMAGE ANALYSIS DEBUG ===');
      print('Image file path: ${imageFile.path}');
      print('Prompt: $prompt');
      print('Calling remoteDataSource.analyzeImage...');
      
      final result = await remoteDataSource.analyzeImage(imageFile, prompt);
      
      print('Repository received result: $result');
      return result;
    } catch (e, stackTrace) {
      print('=== REPOSITORY IMAGE ANALYSIS EXCEPTION ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception message: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to analyze image: $e');
    }
  }

  @override
  Future<String> analyzePdf(File pdfFile) async {
    try {
      print('=== REPOSITORY PDF ANALYSIS DEBUG ===');
      print('PDF file path: ${pdfFile.path}');
      print('Calling remoteDataSource.analyzePdf...');
      
      final result = await remoteDataSource.analyzePdf(pdfFile);
      
      print('Repository received result: $result');
      return result;
    } catch (e, stackTrace) {
      print('=== REPOSITORY PDF ANALYSIS EXCEPTION ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception message: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to analyze PDF: $e');
    }
  }

  @override
  Future<String> sendTextMessage(String message) async {
    try {
      print('=== REPOSITORY TEXT MESSAGE DEBUG ===');
      print('Message: $message');
      print('Calling remoteDataSource.sendTextMessage...');
      
      final result = await remoteDataSource.sendTextMessage(message);
      
      print('Repository received result: $result');
      return result;
    } catch (e, stackTrace) {
      print('=== REPOSITORY TEXT MESSAGE EXCEPTION ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception message: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to send message: $e');
    }
  }
}