import '../entities/chat_message.dart';
import '../entities/chat_session.dart';

abstract class ChatRepository {
  Future<ChatSession> loadSession({String? conversationId});

  Future<ChatSession> sendMessage({
    required String conversationId,
    required String text,
    String? payload,
    bool fromSuggestion = false,
  });

  Future<ChatSession> syncPending(String conversationId);

  Future<void> toggleFavorite({
    required String messageId,
    required bool isFavorite,
    String? note,
  });

  Future<List<ChatMessage>> getFavoriteMessages({String? conversationId});

  Stream<bool> watchConnection();

  List<ChatActionChip> defaultSuggestions();
}
