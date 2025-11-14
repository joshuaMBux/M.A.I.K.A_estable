import '../../repositories/chat_repository.dart';
import '../../entities/chat_session.dart';

class SendChatMessageUseCase {
  final ChatRepository repository;

  SendChatMessageUseCase(this.repository);

  Future<ChatSession> execute({
    required String conversationId,
    required String text,
    String? payload,
    bool fromSuggestion = false,
  }) {
    return repository.sendMessage(
      conversationId: conversationId,
      text: text,
      payload: payload,
      fromSuggestion: fromSuggestion,
    );
  }
}
