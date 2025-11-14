import 'package:equatable/equatable.dart';
import 'chat_message.dart';

class ChatSession extends Equatable {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final List<ChatActionChip> suggestions;
  final bool isConnected;
  final bool hasPendingMessages;
  final DateTime updatedAt;

  const ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.suggestions,
    required this.isConnected,
    required this.hasPendingMessages,
    required this.updatedAt,
  });

  ChatSession copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    List<ChatActionChip>? suggestions,
    bool? isConnected,
    bool? hasPendingMessages,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      isConnected: isConnected ?? this.isConnected,
      hasPendingMessages: hasPendingMessages ?? this.hasPendingMessages,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    messages,
    suggestions,
    isConnected,
    hasPendingMessages,
    updatedAt,
  ];
}
