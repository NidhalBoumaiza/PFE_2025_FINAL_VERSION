import 'dart:io';
import '../repositories/ai_chatbot_repository.dart';

class AnalyzeImageUseCase {
  final AiChatbotRepository repository;

  AnalyzeImageUseCase({required this.repository});

  Future<String> call(File imageFile, String prompt) async {
    try {
      print('=== USE CASE IMAGE ANALYSIS DEBUG ===');
      print('Image file path: ${imageFile.path}');
      print('Prompt: $prompt');
      print('Calling repository.analyzeImage...');
      
      final result = await repository.analyzeImage(imageFile, prompt);
      
      print('Use case received result: $result');
      return result;
    } catch (e, stackTrace) {
      print('=== USE CASE IMAGE ANALYSIS EXCEPTION ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception message: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
} 