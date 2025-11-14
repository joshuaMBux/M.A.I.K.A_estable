import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> sendMessage(String message, String sender);
  Future<List<ChatMessage>> getChatHistory();
  Future<void> saveChatHistory(List<ChatMessage> messages);
  Future<void> clearChatHistory();
}
