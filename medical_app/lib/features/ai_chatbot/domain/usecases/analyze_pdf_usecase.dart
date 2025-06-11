import 'dart:io';
import '../repositories/ai_chatbot_repository.dart';

class AnalyzePdfUseCase {
  final AiChatbotRepository repository;

  AnalyzePdfUseCase({required this.repository});

  Future<String> call(File pdfFile) async {
    try {
      print('=== USE CASE PDF ANALYSIS DEBUG ===');
      print('PDF file path: ${pdfFile.path}');
      print('Calling repository.analyzePdf...');
      
      final result = await repository.analyzePdf(pdfFile);
      
      print('Use case received result: $result');
      return result;
    } catch (e, stackTrace) {
      print('=== USE CASE PDF ANALYSIS EXCEPTION ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception message: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
} 