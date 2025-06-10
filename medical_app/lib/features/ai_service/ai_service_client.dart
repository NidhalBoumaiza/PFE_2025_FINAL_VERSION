import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class AiServiceClient {
  final String baseUrl;
  static const Duration timeoutDuration = Duration(seconds: 60);

  AiServiceClient({required this.baseUrl});

  /// Check if the AI service is available
  Future<bool> isServiceAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      print('Error checking AI service availability: $e');
      return false;
    }
  }

  /// Send a text message to the AI service and get a response
  Future<String> sendTextMessage(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message}),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'No response from AI service';
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get AI response');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
          'Cannot connect to AI service. Please check if the service is running.',
        );
      }
      throw Exception('Error communicating with AI service: $e');
    }
  }

  /// Analyze an image file with the Florence-2 model
  Future<String> analyzeImage(File imageFile, String prompt) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/analyze-image'),
      );

      // Add file to the request
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      final filename = path.basename(imageFile.path);
      final fileExtension = path
          .extension(filename)
          .toLowerCase()
          .replaceAll('.', '');

      final multipartFile = http.MultipartFile(
        'image',
        fileStream,
        fileLength,
        filename: filename,
        contentType: MediaType('image', fileExtension),
      );

      request.files.add(multipartFile);

      // Add form fields
      request.fields['task_prompt'] = '<MEDICAL_ANALYSIS>';
      request.fields['text_input'] = prompt;

      // Send the request
      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] ?? 'No analysis result from AI service';
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to analyze image');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
          'Cannot connect to AI service. Please check if the service is running.',
        );
      }
      throw Exception('Error analyzing image: $e');
    }
  }

  /// Analyze a PDF file
  Future<String> analyzePdf(File pdfFile) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/analyze-pdf'),
      );

      // Add file to the request
      final fileStream = http.ByteStream(pdfFile.openRead());
      final fileLength = await pdfFile.length();
      final filename = path.basename(pdfFile.path);

      final multipartFile = http.MultipartFile(
        'pdf',
        fileStream,
        fileLength,
        filename: filename,
        contentType: MediaType('application', 'pdf'),
      );

      request.files.add(multipartFile);

      // Send the request
      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['summary'] ?? 'No summary from AI service';
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to analyze PDF');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
          'Cannot connect to AI service. Please check if the service is running.',
        );
      }
      throw Exception('Error analyzing PDF: $e');
    }
  }
}
