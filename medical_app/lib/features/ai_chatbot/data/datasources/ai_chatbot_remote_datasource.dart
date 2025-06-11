import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

abstract class AiChatbotRemoteDataSource {
  Future<String> analyzeImage(File imageFile, String taskPrompt);
  Future<String> analyzePdf(File pdfFile);
  Future<String> sendTextMessage(String message);
  Future<bool> checkServerHealth();
}

class AiChatbotRemoteDataSourceImpl implements AiChatbotRemoteDataSource {
  final Dio dio;
  
  // Only use the PC's IP address for real device testing
  static const List<String> baseUrls = [
    'http://192.168.0.188:5000',  // PC IP address on WiFi network
  ];
  
  String? _workingBaseUrl;

  AiChatbotRemoteDataSourceImpl({required this.dio}) {
    // Configure Dio with longer timeout settings for real device testing
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 30);
    
    print('=== AI CHATBOT DATASOURCE INITIALIZED ===');
    print('Target server: ${baseUrls.first}');
    print('Dio configured with 30-second timeouts for real device testing');
  }

  Future<String> _getWorkingBaseUrl() async {
    if (_workingBaseUrl != null) {
      print('=== USING CACHED SERVER URL ===');
      print('Cached URL: $_workingBaseUrl');
      return _workingBaseUrl!;
    }

    print('=== TESTING SERVER CONNECTION ===');
    final targetUrl = baseUrls.first;
    print('🎯 Testing connection to: $targetUrl');
    
    try {
      final response = await dio.get(
        '$targetUrl/health',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      print('✅ Connection successful!');
      print('📊 Status: ${response.statusCode}');
      print('📊 Response: ${response.data}');
      
      if (response.statusCode == 200) {
        _workingBaseUrl = targetUrl;
        print('✅ SERVER IS ACCESSIBLE: $targetUrl');
        return targetUrl;
      }
    } catch (e) {
      print('❌ Connection failed to $targetUrl');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error message: $e');
    }
    
    print('❌ CANNOT CONNECT TO SERVER');
    print('🔧 Make sure:');
    print('   1. Flask server is running on PC (python app.py)');
    print('   2. Both devices are on the same WiFi network');
    print('   3. Windows Firewall allows port 5000');
    throw Exception('Cannot connect to server at $targetUrl. Please ensure the AI server is running.');
  }

  @override
  Future<bool> checkServerHealth() async {
    try {
      print('=== DATASOURCE HEALTH CHECK START ===');
      print('🏥 Checking server health...');
      
      final baseUrl = await _getWorkingBaseUrl();
      print('🌐 Health check URL: $baseUrl/health');
      
      final response = await dio.get('$baseUrl/health');
      
      print('✅ Health check response received');
      print('📊 Status: ${response.statusCode}');
      print('📊 Data: ${response.data}');
      
      final isHealthy = response.statusCode == 200;
      print('🏥 Server health status: ${isHealthy ? "HEALTHY ✅" : "UNHEALTHY ❌"}');
      
      return isHealthy;
    } catch (e) {
      print('=== DATASOURCE HEALTH CHECK FAILED ===');
      print('❌ Health check error: $e');
      print('🔄 Resetting cached URL for next attempt');
      _workingBaseUrl = null; // Reset to try again next time
      return false;
    }
  }

  @override
  Future<String> sendTextMessage(String message) async {
    try {
      print('=== DATASOURCE TEXT MESSAGE START ===');
      print('📤 Outgoing message: "$message"');
      print('📤 Message length: ${message.length} characters');
      
      final baseUrl = await _getWorkingBaseUrl();
      print('🌐 Using server URL: $baseUrl');
      
      final endpoint = '$baseUrl/chat';
      print('🔗 Full endpoint: $endpoint');
      
      final requestData = {'message': message};
      print('📦 Request payload: $requestData');
      
      print('⏳ Sending POST request...');
      final response = await dio.post(
        endpoint,
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('✅ Response received!');
      print('📊 Status code: ${response.statusCode}');
      print('📊 Response headers: ${response.headers}');
      print('📊 Response data type: ${response.data.runtimeType}');
      print('📊 Raw response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        String result;
        
        if (responseData is Map<String, dynamic>) {
          result = responseData['response'] ?? 
                  responseData['result'] ?? 
                  'Message processed successfully';
          print('📥 Extracted result from Map: "$result"');
        } else if (responseData is String) {
          result = responseData;
          print('📥 Direct string response: "$result"');
        } else {
          result = 'Message processed successfully';
          print('⚠️ Unknown response type, using default message');
        }
        
        print('✅ DATASOURCE TEXT MESSAGE SUCCESS');
        print('📥 Final result length: ${result.length} characters');
        print('📥 Final result preview: "${result.length > 100 ? result.substring(0, 100) + '...' : result}"');
        
        return result;
      } else {
        print('❌ HTTP Error - Status: ${response.statusCode}');
        print('❌ Error data: ${response.data}');
        throw Exception('Server returned status ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('=== DATASOURCE DIO EXCEPTION ===');
      print('❌ DioException type: ${e.type}');
      print('❌ DioException message: ${e.message}');
      print('❌ DioException error: ${e.error}');
      
      // Reset working URL on connection errors to retry discovery
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout) {
        print('🔄 Resetting cached URL due to connection error');
        _workingBaseUrl = null;
      }
      
      if (e.response != null) {
        print('❌ Response status code: ${e.response?.statusCode}');
        print('❌ Response data: ${e.response?.data}');
        
        // Handle specific error responses from server
        if (e.response?.data is Map<String, dynamic>) {
          final errorData = e.response!.data as Map<String, dynamic>;
          final errorMessage = errorData['error'] ?? 'Server error occurred';
          throw Exception('Server error: $errorMessage');
        }
        
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        // Handle connection errors
        String errorMessage = 'Connection failed';
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
            errorMessage = 'Connection timeout. Please check if the AI server is running.';
            break;
          case DioExceptionType.sendTimeout:
            errorMessage = 'Request timeout. The server is taking too long to respond.';
            break;
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Response timeout. The server is not responding.';
            break;
          case DioExceptionType.connectionError:
            errorMessage = 'Cannot connect to AI server. Please ensure it\'s running and accessible.';
            break;
          default:
            errorMessage = 'Network error: ${e.message}';
        }
        print('❌ Connection error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      print('=== DATASOURCE GENERAL EXCEPTION ===');
      print('❌ Exception type: ${e.runtimeType}');
      print('❌ Exception message: $e');
      print('❌ Stack trace: $stackTrace');
      
      // Reset working URL on general errors to retry discovery
      _workingBaseUrl = null;
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<String> analyzeImage(File imageFile, String taskPrompt) async {
    try {
      print('=== IMAGE ANALYSIS DEBUG ===');
      print('Image file path: ${imageFile.path}');
      print('Image file exists: ${await imageFile.exists()}');
      print('Task prompt: $taskPrompt');
      
      // Validate image file
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist at path: ${imageFile.path}');
      }
      
      final fileSize = await imageFile.length();
      print('Image file size: $fileSize bytes');
      
      if (fileSize == 0) {
        throw Exception('Image file is empty');
      }
      
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        throw Exception('Image file is too large (max 10MB)');
      }
      
      // Get working base URL
      final baseUrl = await _getWorkingBaseUrl();
      print('Using base URL: $baseUrl');
      
      // Get file extension
      final extension = imageFile.path.split('.').last.toLowerCase();
      final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
      
      if (!validExtensions.contains(extension)) {
        throw Exception('Unsupported image format. Please use: ${validExtensions.join(', ')}');
      }
      
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'image.$extension',
          contentType: MediaType('image', extension == 'jpg' ? 'jpeg' : extension),
        ),
        'task_prompt': '<DETAILED_CAPTION>',
      });

      print('FormData created successfully');
      print('Making POST request to: $baseUrl/analyze-image');

      final response = await dio.post(
        '$baseUrl/analyze-image',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('Response status code: ${response.statusCode}');
      print('Response data type: ${response.data.runtimeType}');
      print('Raw response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          // Handle the nested structure: {"result": {"<DETAILED_CAPTION>": "actual text"}}
          final result = responseData['result'];
          
          if (result is Map<String, dynamic>) {
            // Extract the actual caption text from the nested structure
            String analysisText = '';
            
            // Try to get the text from the task prompt key
            if (result.containsKey('<DETAILED_CAPTION>')) {
              analysisText = result['<DETAILED_CAPTION>'].toString();
            } else if (result.containsKey('<MEDICAL_ANALYSIS>')) {
              analysisText = result['<MEDICAL_ANALYSIS>'].toString();
            } else if (result.containsKey('<CAPTION>')) {
              analysisText = result['<CAPTION>'].toString();
            } else {
              // If no specific key found, get the first value
              final values = result.values.toList();
              if (values.isNotEmpty) {
                analysisText = values.first.toString();
              } else {
                analysisText = 'Image analysis completed but no description available';
              }
            }
            
            print('✅ Extracted analysis text: "$analysisText"');
            print('Analysis result length: ${analysisText.length}');
            return analysisText;
          } else if (result is String) {
            print('✅ Direct string result: "$result"');
            return result;
          } else {
            // Fallback: try other possible keys
            final fallbackResult = responseData['response'] ?? 
                                 responseData['analysis'] ??
                                 'Image analysis completed successfully';
            print('⚠️ Using fallback result: "$fallbackResult"');
            return fallbackResult.toString();
          }
        } else if (responseData is String) {
          print('String response length: ${responseData.length}');
          return responseData;
        } else {
          print('Unknown response type: ${responseData.runtimeType}');
          return 'Image analysis completed successfully';
        }
      } else {
        print('HTTP Error - Status: ${response.statusCode}, Data: ${response.data}');
        throw Exception('Image analysis failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('=== DIO EXCEPTION ===');
      print('DioException type: ${e.type}');
      print('DioException message: ${e.message}');
      print('DioException error: ${e.error}');
      
      // Reset working URL on connection errors to retry discovery
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout) {
        _workingBaseUrl = null;
      }
      
      if (e.response != null) {
        print('Response status code: ${e.response?.statusCode}');
        print('Response data: ${e.response?.data}');
        
        if (e.response?.data is Map<String, dynamic>) {
          final errorData = e.response!.data as Map<String, dynamic>;
          final errorMessage = errorData['error'] ?? 'Image analysis failed';
          throw Exception('Server error: $errorMessage');
        }
        
        throw Exception('Image analysis failed: ${e.response?.statusCode}');
      } else {
        String errorMessage = 'Connection failed';
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Connection timeout. Please check if the AI server is running.';
            break;
          case DioExceptionType.connectionError:
            errorMessage = 'Cannot connect to AI server. Please ensure it\'s running and accessible.';
            break;
          default:
            errorMessage = 'Network error: ${e.message}';
        }
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      print('=== GENERAL EXCEPTION ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception message: $e');
      print('Stack trace: $stackTrace');
      
      // Reset working URL on general errors to retry discovery
      _workingBaseUrl = null;
      throw Exception('Image analysis error: $e');
    }
  }

  @override
  Future<String> analyzePdf(File pdfFile) async {
    try {
      print('=== PDF ANALYSIS DEBUG ===');
      print('PDF file path: ${pdfFile.path}');
      print('PDF file exists: ${await pdfFile.exists()}');
      
      // Validate PDF file
      if (!await pdfFile.exists()) {
        throw Exception('PDF file does not exist at path: ${pdfFile.path}');
      }
      
      final fileSize = await pdfFile.length();
      print('PDF file size: $fileSize bytes');
      
      if (fileSize == 0) {
        throw Exception('PDF file is empty');
      }
      
      if (fileSize > 50 * 1024 * 1024) { // 50MB limit
        throw Exception('PDF file is too large (max 50MB)');
      }
      
      // Get working base URL
      final baseUrl = await _getWorkingBaseUrl();
      print('Using base URL: $baseUrl');
      
      FormData formData = FormData.fromMap({
        'pdf': await MultipartFile.fromFile(
          pdfFile.path,
          filename: 'document.pdf',
          contentType: MediaType('application', 'pdf'),
        ),
      });

      print('FormData created successfully');
      print('Making POST request to: $baseUrl/analyze-pdf');

      final response = await dio.post(
        '$baseUrl/analyze-pdf',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('Response status code: ${response.statusCode}');
      print('Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final result = responseData['summary'] ?? 
                        responseData['result'] ?? 
                        responseData['response'] ?? 
                        responseData['analysis'] ??
                        'PDF analysis completed successfully';
          print('PDF analysis result length: ${result.toString().length}');
          return result.toString();
        } else if (responseData is String) {
          print('String response length: ${responseData.length}');
          return responseData;
        } else {
          print('Unknown response type: ${responseData.runtimeType}');
          return 'PDF analysis completed successfully';
        }
      } else {
        print('HTTP Error - Status: ${response.statusCode}, Data: ${response.data}');
        throw Exception('PDF analysis failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('=== DIO EXCEPTION ===');
      print('DioException type: ${e.type}');
      print('DioException message: ${e.message}');
      print('DioException error: ${e.error}');
      
      // Reset working URL on connection errors to retry discovery
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout) {
        _workingBaseUrl = null;
      }
      
      if (e.response != null) {
        print('Response status code: ${e.response?.statusCode}');
        print('Response data: ${e.response?.data}');
        
        if (e.response?.data is Map<String, dynamic>) {
          final errorData = e.response!.data as Map<String, dynamic>;
          final errorMessage = errorData['error'] ?? 'PDF analysis failed';
          throw Exception('Server error: $errorMessage');
        }
        
        throw Exception('PDF analysis failed: ${e.response?.statusCode}');
      } else {
        String errorMessage = 'Connection failed';
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Connection timeout. Please check if the AI server is running.';
            break;
          case DioExceptionType.connectionError:
            errorMessage = 'Cannot connect to AI server. Please ensure it\'s running and accessible.';
            break;
          default:
            errorMessage = 'Network error: ${e.message}';
        }
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      print('=== GENERAL EXCEPTION ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception message: $e');
      print('Stack trace: $stackTrace');
      
      // Reset working URL on general errors to retry discovery
      _workingBaseUrl = null;
      throw Exception('PDF analysis error: $e');
    }
  }
} 