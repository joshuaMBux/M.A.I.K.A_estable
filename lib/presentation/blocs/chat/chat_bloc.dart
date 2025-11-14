import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/chat_session.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/usecases/chat/load_chat_session_usecase.dart';
import '../../../domain/usecases/chat/send_message_usecase.dart';
import '../../../domain/usecases/chat/sync_pending_messages_usecase.dart';
import '../../../domain/usecases/chat/toggle_favorite_message_usecase.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required LoadChatSessionUseCase loadChatSessionUseCase,
    required SendChatMessageUseCase sendChatMessageUseCase,
    required SyncPendingMessagesUseCase syncPendingMessagesUseCase,
    required ToggleFavoriteMessageUseCase toggleFavoriteMessageUseCase,
    required ChatRepository chatRepository,
  }) : _loadChatSessionUseCase = loadChatSessionUseCase,
       _sendChatMessageUseCase = sendChatMessageUseCase,
       _syncPendingMessagesUseCase = syncPendingMessagesUseCase,
       _toggleFavoriteMessageUseCase = toggleFavoriteMessageUseCase,
       _chatRepository = chatRepository,
       super(
         ChatState.initial(suggestions: chatRepository.defaultSuggestions()),
       ) {
    on<ChatStarted>(_onChatStarted);
    on<ChatMessageSubmitted>(_onMessageSubmitted);
    on<ChatSuggestionPressed>(_onSuggestionPressed);
    on<ChatPendingRetryRequested>(_onPendingRetryRequested);
    on<ChatFavoriteToggled>(_onFavoriteToggled);
    on<ChatConnectionStatusChanged>(_onConnectionStatusChanged);

    _connectionSubscription = _chatRepository.watchConnection().listen(
      (isConnected) => add(ChatConnectionStatusChanged(isConnected)),
    );
  }

  final LoadChatSessionUseCase _loadChatSessionUseCase;
  final SendChatMessageUseCase _sendChatMessageUseCase;
  final SyncPendingMessagesUseCase _syncPendingMessagesUseCase;
  final ToggleFavoriteMessageUseCase _toggleFavoriteMessageUseCase;
  final ChatRepository _chatRepository;

  StreamSubscription<bool>? _connectionSubscription;

  Future<void> _onChatStarted(
    ChatStarted event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ChatViewStatus.loading,
        resetError: true,
        suggestions: _chatRepository.defaultSuggestions(),
      ),
    );

    final session = await _loadChatSessionUseCase.execute(
      conversationId: event.conversationId,
    );
    emit(_stateFromSession(session, ChatViewStatus.idle));

    if (session.hasPendingMessages && session.isConnected) {
      add(const ChatPendingRetryRequested());
    }
  }

  Future<void> _onMessageSubmitted(
    ChatMessageSubmitted event,
    Emitter<ChatState> emit,
  ) async {
    final trimmed = event.text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    if (state.conversationId.isEmpty) {
      add(const ChatStarted());
      return;
    }

    emit(
      state.copyWith(
        status: ChatViewStatus.sending,
        isTyping: true,
        resetError: true,
      ),
    );

    try {
      final session = await _sendChatMessageUseCase.execute(
        conversationId: state.conversationId,
        text: trimmed,
        payload: event.payload,
        fromSuggestion: event.fromSuggestion,
      );

      final resolvedStatus = session.isConnected
          ? ChatViewStatus.idle
          : ChatViewStatus.offline;

      emit(
        _stateFromSession(session, resolvedStatus).copyWith(isTyping: false),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ChatViewStatus.error,
          isTyping: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onSuggestionPressed(
    ChatSuggestionPressed event,
    Emitter<ChatState> emit,
  ) {
    add(
      ChatMessageSubmitted(
        text: event.chip.title,
        payload: event.chip.payload,
        fromSuggestion: true,
      ),
    );
  }

  Future<void> _onPendingRetryRequested(
    ChatPendingRetryRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (state.conversationId.isEmpty) {
      return;
    }
    emit(state.copyWith(status: ChatViewStatus.sending, resetError: true));
    final session = await _syncPendingMessagesUseCase.execute(
      state.conversationId,
    );
    emit(_stateFromSession(session, ChatViewStatus.idle));
  }

  Future<void> _onFavoriteToggled(
    ChatFavoriteToggled event,
    Emitter<ChatState> emit,
  ) async {
    await _toggleFavoriteMessageUseCase.execute(
      messageId: event.messageId,
      isFavorite: event.isFavorite,
      note: event.note,
    );

    final updatedMessages = state.messages
        .map(
          (message) => message.id == event.messageId
              ? ChatMessage(
                  id: message.id,
                  conversationId: message.conversationId,
                  text: message.text,
                  type: message.type,
                  contentType: message.contentType,
                  status: message.status,
                  timestamp: message.timestamp,
                  senderId: message.senderId,
                  imageUrl: message.imageUrl,
                  listItems: message.listItems,
                  quickReplies: message.quickReplies,
                  generated: message.generated,
                  isFavorite: event.isFavorite,
                  favoriteNote: event.note ?? message.favoriteNote,
                  metadata: message.metadata,
                )
              : message,
        )
        .toList();

    emit(state.copyWith(messages: updatedMessages));
  }

  void _onConnectionStatusChanged(
    ChatConnectionStatusChanged event,
    Emitter<ChatState> emit,
  ) {
    final status = event.isConnected
        ? (state.status == ChatViewStatus.error
              ? ChatViewStatus.error
              : ChatViewStatus.idle)
        : ChatViewStatus.offline;
    emit(state.copyWith(isConnected: event.isConnected, status: status));
  }

  ChatState _stateFromSession(ChatSession session, ChatViewStatus status) {
    return state.copyWith(
      status: status,
      conversationId: session.id,
      messages: session.messages,
      suggestions: session.suggestions,
      isConnected: session.isConnected,
      hasPendingMessages: session.hasPendingMessages,
      lastUpdated: session.updatedAt,
    );
  }

  @override
  Future<void> close() async {
    await _connectionSubscription?.cancel();
    return super.close();
  }
}
