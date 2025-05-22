import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_app/core/utils/map_failure_to_message.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';
import 'package:medical_app/features/messagerie/domain/use_cases/get_conversations.dart';
import 'conversations_event.dart';
import 'conversations_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final GetConversationsUseCase getConversationsUseCase;
  List<ConversationEntity> _currentConversations = [];
  StreamSubscription<List<ConversationEntity>>? _conversationsSubscription;

  ConversationsBloc({required this.getConversationsUseCase})
    : super(const ConversationsInitial()) {
    on<FetchConversationsEvent>(_onFetchConversations);
    on<SubscribeToConversationsEvent>(_onSubscribeToConversations);
    on<ConversationsUpdatedEvent>(_onConversationsUpdated);
    on<ConversationsStreamErrorEvent>(_onConversationsStreamError);
    on<MarkAllConversationsReadEvent>(_onMarkAllConversationsRead);
  }

  Future<void> _onFetchConversations(
    FetchConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(ConversationsLoading(conversations: _currentConversations));
    final failureOrConversations = await getConversationsUseCase(
      userId: event.userId,
      isDoctor: event.isDoctor,
    );
    failureOrConversations.fold(
      (failure) => emit(
        ConversationsError(
          message: mapFailureToMessage(failure),
          conversations: _currentConversations,
        ),
      ),
      (conversations) {
        _currentConversations = conversations;
        emit(ConversationsLoaded(conversations: conversations));
      },
    );
  }

  Future<void> _onSubscribeToConversations(
    SubscribeToConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(ConversationsLoading(conversations: _currentConversations));
    try {
      await _conversationsSubscription?.cancel();
      final stream = getConversationsUseCase.getConversationsStream(
        userId: event.userId,
        isDoctor: event.isDoctor,
      );
      _conversationsSubscription = stream.listen(
        (conversations) {
          add(ConversationsUpdatedEvent(conversations: conversations));
        },
        onError: (error) {
          add(ConversationsStreamErrorEvent(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        ConversationsError(
          message: 'Failed to subscribe to conversations: $e',
          conversations: _currentConversations,
        ),
      );
    }
  }

  void _onConversationsUpdated(
    ConversationsUpdatedEvent event,
    Emitter<ConversationsState> emit,
  ) {
    // Handle read status updates more intelligently
    final updatedConversations =
        event.conversations.map((serverConversation) {
          // Try to find the same conversation in our current list
          final existingConversation = _currentConversations.firstWhere(
            (c) => c.id == serverConversation.id,
            orElse: () => serverConversation,
          );

          // If this is an existing conversation and the only thing that changed is the read status,
          // prioritize the local version if the local version shows it as read
          if (existingConversation.id == serverConversation.id &&
              existingConversation.lastMessageRead &&
              !serverConversation.lastMessageRead) {
            print(
              'Preserving local read status for conversation ${serverConversation.id}',
            );
            return existingConversation;
          }

          // Otherwise use the server version
          return serverConversation;
        }).toList();

    _currentConversations = updatedConversations;
    emit(ConversationsLoaded(conversations: updatedConversations));
  }

  void _onConversationsStreamError(
    ConversationsStreamErrorEvent event,
    Emitter<ConversationsState> emit,
  ) {
    emit(
      ConversationsError(
        message: 'Stream error: ${event.error}',
        conversations: _currentConversations,
      ),
    );
  }

  // Marks all conversations as read for a user
  Future<void> _onMarkAllConversationsRead(
    MarkAllConversationsReadEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    try {
      print('Marking all conversations as read for user: ${event.userId}');

      // Update local conversations
      final updatedConversations =
          _currentConversations.map((conversation) {
            return conversation.lastMessageRead
                ? conversation
                : ConversationEntity.create(
                  id: conversation.id,
                  patientId: conversation.patientId,
                  doctorId: conversation.doctorId,
                  patientName: conversation.patientName,
                  doctorName: conversation.doctorName,
                  lastMessage: conversation.lastMessage,
                  lastMessageType: conversation.lastMessageType,
                  lastMessageTime: conversation.lastMessageTime,
                  lastMessageUrl: conversation.lastMessageUrl,
                  lastMessageRead: true,
                );
          }).toList();

      _currentConversations = updatedConversations;
      emit(ConversationsLoaded(conversations: updatedConversations));

      // Update Firestore
      final firestore = FirebaseFirestore.instance;

      // Find conversations where this user is either patient or doctor
      final patientConversations =
          await firestore
              .collection('conversations')
              .where('patientId', isEqualTo: event.userId)
              .get();

      final doctorConversations =
          await firestore
              .collection('conversations')
              .where('doctorId', isEqualTo: event.userId)
              .get();

      // Only proceed with batch update if there are conversations to update
      final allDocs = [
        ...patientConversations.docs,
        ...doctorConversations.docs,
      ];
      if (allDocs.isNotEmpty) {
        final batch = firestore.batch();

        // Mark all as read in batch
        for (final doc in allDocs) {
          batch.update(doc.reference, {'lastMessageRead': true});
        }

        await batch.commit();
        print(
          'Successfully marked ${allDocs.length} conversations as read in Firestore',
        );
      } else {
        print('No conversations found to mark as read');
      }
    } catch (e) {
      print('Error marking conversations as read: $e');
      emit(
        ConversationsError(
          message: 'Failed to mark conversations as read: $e',
          conversations: _currentConversations,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _conversationsSubscription?.cancel();
    return super.close();
  }
}
