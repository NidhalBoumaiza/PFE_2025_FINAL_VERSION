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
    on<SendTextMessageEvent>(_onSendTextMessage);
    on<SendImageMessageEvent>(_onSendImageMessage);
    on<SendPdfMessageEvent>(_onSendPdfMessage);
    on<ClearChatEvent>(_onClearChat);
  }

  void _onSendTextMessage(
    SendTextMessageEvent event,
    Emitter<AiChatbotState> emit,
  ) async {
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

    try {
      // Get AI response from service
      final response = await sendTextMessageUseCase.call(event.message);

      // Add AI response
      final aiResponse = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      final finalMessages = [...updatedMessages, aiResponse];
      emit(AiChatbotLoaded(messages: finalMessages, isLoading: false));
    } catch (e) {
      emit(AiChatbotError(
        message: 'Error: $e',
        messages: updatedMessages,
      ));
    }
  }

  void _onSendImageMessage(
    SendImageMessageEvent event,
    Emitter<AiChatbotState> emit,
  ) async {
    final currentState = state;
    List<ChatMessageModel> currentMessages = [];

    if (currentState is AiChatbotLoaded) {
      currentMessages = currentState.messages;
    }

    // Add user message with image
    final userMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.taskPrompt,
      isUser: true,
      timestamp: DateTime.now(),
      imageUrl: event.imageFile.path,
    );

    final updatedMessages = [...currentMessages, userMessage];
    emit(AiChatbotLoaded(messages: updatedMessages, isLoading: true));

    try {
      // Analyze image
      final response = await analyzeImageUseCase.call(
        event.imageFile,
        event.taskPrompt,
      );

      // Add AI response
      final aiResponse = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      final finalMessages = [...updatedMessages, aiResponse];
      emit(AiChatbotLoaded(messages: finalMessages, isLoading: false));
    } catch (e) {
      emit(AiChatbotError(
        message: 'ai_image_analysis_error'.tr + ': $e',
        messages: updatedMessages,
      ));
    }
  }

  void _onSendPdfMessage(
    SendPdfMessageEvent event,
    Emitter<AiChatbotState> emit,
  ) async {
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

    try {
      // Analyze PDF
      final response = await analyzePdfUseCase.call(event.pdfFile);

      // Add AI response
      final aiResponse = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      final finalMessages = [...updatedMessages, aiResponse];
      emit(AiChatbotLoaded(messages: finalMessages, isLoading: false));
    } catch (e) {
      emit(AiChatbotError(
        message: 'ai_pdf_analysis_error'.tr + ': $e',
        messages: updatedMessages,
      ));
    }
  }

  void _onClearChat(
    ClearChatEvent event,
    Emitter<AiChatbotState> emit,
  ) {
    emit(const AiChatbotLoaded(messages: []));
  }
} 