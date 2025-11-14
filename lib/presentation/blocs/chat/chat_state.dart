part of 'chat_bloc.dart';

enum ChatViewStatus { idle, loading, sending, receiving, offline, error }

class ChatState extends Equatable {
  const ChatState({
    required this.status,
    required this.conversationId,
    required this.messages,
    required this.suggestions,
    required this.isTyping,
    required this.isConnected,
    required this.hasPendingMessages,
    required this.errorMessage,
    required this.lastUpdated,
  });

  factory ChatState.initial({List<ChatActionChip>? suggestions}) {
    return ChatState(
      status: ChatViewStatus.loading,
      conversationId: '',
      messages: const [],
      suggestions: suggestions ?? const [],
      isTyping: false,
      isConnected: false,
      hasPendingMessages: false,
      errorMessage: null,
      lastUpdated: null,
    );
  }

  final ChatViewStatus status;
  final String conversationId;
  final List<ChatMessage> messages;
  final List<ChatActionChip> suggestions;
  final bool isTyping;
  final bool isConnected;
  final bool hasPendingMessages;
  final String? errorMessage;
  final DateTime? lastUpdated;

  ChatState copyWith({
    ChatViewStatus? status,
    String? conversationId,
    List<ChatMessage>? messages,
    List<ChatActionChip>? suggestions,
    bool? isTyping,
    bool? isConnected,
    bool? hasPendingMessages,
    String? errorMessage,
    bool resetError = false,
    DateTime? lastUpdated,
  }) {
    return ChatState(
      status: status ?? this.status,
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      isTyping: isTyping ?? this.isTyping,
      isConnected: isConnected ?? this.isConnected,
      hasPendingMessages: hasPendingMessages ?? this.hasPendingMessages,
      errorMessage: resetError ? null : (errorMessage ?? this.errorMessage),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    status,
    conversationId,
    messages,
    suggestions,
    isTyping,
    isConnected,
    hasPendingMessages,
    errorMessage,
    lastUpdated,
  ];
}
