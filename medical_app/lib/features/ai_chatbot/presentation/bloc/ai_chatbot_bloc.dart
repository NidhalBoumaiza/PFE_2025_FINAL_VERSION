import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../data/models/chat_message_model.dart';
import '../../domain/usecases/analyze_image_usecase.dart';
import '../../domain/usecases/analyze_pdf_usecase.dart';
import '../../domain/usecases/send_text_message_usecase.dart';
import 'ai_chatbot_event.dart';
import 'ai_chatbot_state.dart';

class AiChatbotBloc extends Bloc<AiChatbotEvent, AiChatbotState> {
  final AnalyzeImageUseCase analyzeImageUseCase;
  final AnalyzePdfUseCase analyzePdfUseCase;
  final SendTextMessageUseCase sendTextMessageUseCase;

  AiChatbotBloc({
    required this.analyzeImageUseCase,
    required this.analyzePdfUseCase,
    required this.sendTextMessageUseCase,
  }) : super(const AiChatbotInitial()) {
    print('=== AI CHATBOT BLOC INITIALIZED ===');
    print('Initial state: ${state.runtimeType}');
    
    on<SendTextMessageEvent>(_onSendTextMessage);
    on<SendImageMessageEvent>(_onSendImageMessage);
    on<SendPdfMessageEvent>(_onSendPdfMessage);
    on<ClearChatEvent>(_onClearChat);
    
    print('Event handlers registered');
    print('Use cases: analyzeImage=${analyzeImageUseCase != null}, analyzePdf=${analyzePdfUseCase != null}, sendText=${sendTextMessageUseCase != null}');
  }

  void _onSendTextMessage(
    SendTextMessageEvent event,
    Emitter<AiChatbotState> emit,
  ) async {
    print('=== BLOC RECEIVED TEXT MESSAGE EVENT ===');
    print('Event type: ${event.runtimeType}');
    print('Message: "${event.message}"');
    
    try {
      print('=== BLOC TEXT MESSAGE DEBUG ===');
      print('Message: ${event.message}');
      
      final currentState = state;
      List<ChatMessageModel> currentMessages = [];

      if (currentState is AiChatbotLoaded) {
        currentMessages = currentState.messages;
      }

      // Add user message
      final userMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: event.message,
        isUser: true,
        timestamp: DateTime.now(),
      );

      final updatedMessages = [...currentMessages, userMessage];
      emit(AiChatbotLoaded(messages: updatedMessages, isLoading: true));

      print('Calling sendTextMessageUseCase...');
      // Get AI response from service
      final response = await sendTextMessageUseCase.call(event.message);
      print('Received response: $response');

      // Add AI response
      final aiResponse = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      final finalMessages = [...updatedMessages, aiResponse];
      emit(AiChatbotLoaded(messages: finalMessages, isLoading: false));
      print('Text message completed successfully');
    } catch (e, stackTrace) {
      print('=== BLOC TEXT MESSAGE EXCEPTION ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception message: $e');
      print('Stack trace: $stackTrace');
      
      final currentState = state;
      List<ChatMessageModel> currentMessages = [];
      if (currentState is AiChatbotLoaded) {
        currentMessages = currentState.messages;
      }
      
      emit(AiChatbotError(
        message: 'Error: $e',
        messages: currentMessages,
      ));
    }
  }

  void _onSendImageMessage(
    SendImageMessageEvent event,
    Emitter<AiChatbotState> emit,
  ) async {
    print('=== BLOC RECEIVED IMAGE MESSAGE EVENT ===');
    print('Event type: ${event.runtimeType}');
    print('Image file: ${event.imageFile.path}');
    print('Task prompt: "${event.taskPrompt}"');
    
    try {
      print('=== BLOC IMAGE MESSAGE DEBUG ===');
      print('Image file path: ${event.imageFile.path}');
      print('Task prompt: ${event.taskPrompt}');
      print('Image file exists: ${await event.imageFile.exists()}');
      
      final currentState = state;
      List<ChatMessageModel> currentMessages = [];

      if (currentState is AiChatbotLoaded) {
        currentMessages = currentState.messages;
        print('Current messages count: ${currentMessages.length}');
      } else {
        print('Current state is not AiChatbotLoaded: ${currentState.runtimeType}');
      }

      // Add user message with image
      final userMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: event.taskPrompt,
        isUser: true,
        timestamp: DateTime.now(),
        imageUrl: event.imageFile.path,
      );

      print('=== USER MESSAGE CREATED ===');
      print('User message ID: ${userMessage.id}');
      print('User message content: ${userMessage.content}');
      print('User message imageUrl: ${userMessage.imageUrl}');
      print('User message isUser: ${userMessage.isUser}');

      final updatedMessages = [...currentMessages, userMessage];
      print('Updated messages count: ${updatedMessages.length}');
      
      // Emit state with user message and loading
      print('=== EMITTING LOADING STATE ===');
      emit(AiChatbotLoaded(messages: updatedMessages, isLoading: true));

      print('Calling analyzeImageUseCase...');
      // Analyze image
      final response = await analyzeImageUseCase.call(
        event.imageFile,
        event.taskPrompt,
      );
      print('Received image analysis response: $response');

      // Add AI response
      final aiResponse = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      print('=== AI RESPONSE CREATED ===');
      print('AI response ID: ${aiResponse.id}');
      print('AI response content: ${aiResponse.content}');
      print('AI response isUser: ${aiResponse.isUser}');

      final finalMessages = [...updatedMessages, aiResponse];
      print('Final messages count: ${finalMessages.length}');
      
      // Final messages debug
      for (int i = 0; i < finalMessages.length; i++) {
        print('Message $i: ${finalMessages[i].isUser ? "User" : "AI"} - ${finalMessages[i].content.substring(0, finalMessages[i].content.length.clamp(0, 50))}...');
        if (finalMessages[i].imageUrl != null) {
          print('  -> Has image: ${finalMessages[i].imageUrl}');
        }
      }
      
      print('=== EMITTING FINAL STATE ===');
      emit(AiChatbotLoaded(messages: finalMessages, isLoading: false));
      print('Image analysis completed successfully');
    } catch (e, stackTrace) {
      print('=== BLOC IMAGE MESSAGE EXCEPTION ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception message: $e');
      print('Stack trace: $stackTrace');
      
      final currentState = state;
      List<ChatMessageModel> currentMessages = [];
      if (currentState is AiChatbotLoaded) {
        currentMessages = currentState.messages;
      }
      
      emit(AiChatbotError(
        message: 'ai_image_analysis_error'.tr + ': $e',
        messages: currentMessages,
      ));
    }
  }

  void _onSendPdfMessage(
    SendPdfMessageEvent event,
    Emitter<AiChatbotState> emit,
  ) async {
    print('=== BLOC RECEIVED PDF MESSAGE EVENT ===');
    print('Event type: ${event.runtimeType}');
    print('PDF file: ${event.pdfFile.path}');
    
    try {
      print('=== BLOC PDF MESSAGE DEBUG ===');
      print('PDF file path: ${event.pdfFile.path}');
      print('PDF file exists: ${await event.pdfFile.exists()}');
      
      final currentState = state;
      List<ChatMessageModel> currentMessages = [];

      if (currentState is AiChatbotLoaded) {
        currentMessages = currentState.messages;
      }

      // Add user message with PDF
      final userMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'ai_pdf_uploaded'.tr,
        isUser: true,
        timestamp: DateTime.now(),
        pdfUrl: event.pdfFile.path,
      );

      final updatedMessages = [...currentMessages, userMessage];
      emit(AiChatbotLoaded(messages: updatedMessages, isLoading: true));

      print('Calling analyzePdfUseCase...');
      // Analyze PDF
      final response = await analyzePdfUseCase.call(event.pdfFile);
      print('Received PDF analysis response: $response');

      // Add AI response
      final aiResponse = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      final finalMessages = [...updatedMessages, aiResponse];
      emit(AiChatbotLoaded(messages: finalMessages, isLoading: false));
      print('PDF analysis completed successfully');
    } catch (e, stackTrace) {
      print('=== BLOC PDF MESSAGE EXCEPTION ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception message: $e');
      print('Stack trace: $stackTrace');
      
      final currentState = state;
      List<ChatMessageModel> currentMessages = [];
      if (currentState is AiChatbotLoaded) {
        currentMessages = currentState.messages;
      }
      
      emit(AiChatbotError(
        message: 'ai_pdf_analysis_error'.tr + ': $e',
        messages: currentMessages,
      ));
    }
  }

  void _onClearChat(
    ClearChatEvent event,
    Emitter<AiChatbotState> emit,
  ) {
    print('=== BLOC RECEIVED CLEAR CHAT EVENT ===');
    print('Clearing chat messages');
    emit(const AiChatbotLoaded(messages: []));
    print('Chat cleared successfully');
  }
} 