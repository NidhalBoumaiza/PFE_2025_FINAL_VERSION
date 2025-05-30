import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

abstract class AiChatbotRemoteDataSource {
  Future<String> analyzeImage(File imageFile, String taskPrompt);
  Future<String> analyzePdf(File pdfFile);
}

class AiChatbotRemoteDataSourceImpl implements AiChatbotRemoteDataSource {
  final Dio dio;
  static const String baseUrl = 'http://localhost:5000';

  AiChatbotRemoteDataSourceImpl({required this.dio});

  @override
  Future<String> analyzeImage(File imageFile, String taskPrompt) async {
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'image.${imageFile.path.split('.').last}',
          contentType: MediaType('image', imageFile.path.split('.').last),
        ),
        'task_prompt': taskPrompt,
      });

      final response = await dio.post(
        '$baseUrl/analyze-image',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Assuming the API returns a JSON with a 'result' or 'response' field
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          return responseData['result'] ?? responseData['response'] ?? 'Analysis completed';
        } else if (responseData is String) {
          return responseData;
        } else {
          return 'Analysis completed successfully';
        }
      } else {
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<String> analyzePdf(File pdfFile) async {
    try {
      FormData formData = FormData.fromMap({
        'pdf': await MultipartFile.fromFile(
          pdfFile.path,
          filename: 'document.pdf',
          contentType: MediaType('application', 'pdf'),
        ),
      });

      final response = await dio.post(
        '$baseUrl/analyze-pdf',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Assuming the API returns a JSON with a 'result' or 'response' field
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          return responseData['result'] ?? responseData['response'] ?? 'PDF analysis completed';
        } else if (responseData is String) {
          return responseData;
        } else {
          return 'PDF analysis completed successfully';
        }
      } else {
        throw Exception('Failed to analyze PDF: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
} 