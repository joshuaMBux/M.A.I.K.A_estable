import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<ChatMessage>> sendMessage(String message, String sender) async {
    try {
      // Enviar mensaje a Rasa
      final responses = await _apiClient.sendMessageToRasa(message, sender);

      final chatMessages = <ChatMessage>[];

      // Agregar mensaje del usuario
      chatMessages.add(
        ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: message,
          type: MessageType.user,
          timestamp: DateTime.now(),
          senderId: sender,
        ),
      );

      // Agregar respuestas de Rasa
      for (final response in responses) {
        if (response['text'] != null) {
          chatMessages.add(
            ChatMessageModel(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_bot',
              message: response['text'] as String,
              type: MessageType.bot,
              timestamp: DateTime.now(),
              metadata: response,
            ),
          );
        }
      }

      // Guardar en historial local
      await saveChatHistory(chatMessages);

      return chatMessages;
    } catch (e) {
      // En caso de error, devolver mensaje de error
      return [
        ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message:
              'Lo siento, no pude procesar tu mensaje. Inténtalo de nuevo.',
          type: MessageType.bot,
          timestamp: DateTime.now(),
        ),
      ];
    }
  }

  @override
  Future<List<ChatMessage>> getChatHistory() async {
    // Por ahora devolver mensaje de bienvenida
    return [
      ChatMessageModel(
        id: 'welcome',
        message:
            '¡Hola! Soy Maika, tu asistente bíblico personal. ¿En qué puedo ayudarte hoy?',
        type: MessageType.bot,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  @override
  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final history = messages.map((msg) => msg.message).toList();
    await prefs.setStringList('chat_history', history);
  }

  @override
  Future<void> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
  }
}
