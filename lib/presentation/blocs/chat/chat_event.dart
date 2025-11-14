part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatStarted extends ChatEvent {
  const ChatStarted({this.conversationId});

  final String? conversationId;

  @override
  List<Object?> get props => [conversationId];
}

class ChatMessageSubmitted extends ChatEvent {
  const ChatMessageSubmitted({
    required this.text,
    this.payload,
    this.fromSuggestion = false,
  });

  final String text;
  final String? payload;
  final bool fromSuggestion;

  @override
  List<Object?> get props => [text, payload, fromSuggestion];
}

class ChatSuggestionPressed extends ChatEvent {
  const ChatSuggestionPressed(this.chip);

  final ChatActionChip chip;

  @override
  List<Object?> get props => [chip];
}

class ChatPendingRetryRequested extends ChatEvent {
  const ChatPendingRetryRequested();
}

class ChatFavoriteToggled extends ChatEvent {
  const ChatFavoriteToggled({
    required this.messageId,
    required this.isFavorite,
    this.note,
  });

  final String messageId;
  final bool isFavorite;
  final String? note;

  @override
  List<Object?> get props => [messageId, isFavorite, note];
}

class ChatConnectionStatusChanged extends ChatEvent {
  const ChatConnectionStatusChanged(this.isConnected);

  final bool isConnected;

  @override
  List<Object?> get props => [isConnected];
}
