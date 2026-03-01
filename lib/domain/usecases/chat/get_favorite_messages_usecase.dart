import '../../entities/chat_message.dart';
import '../../repositories/chat_repository.dart';

class GetFavoriteMessagesUseCase {
  final ChatRepository repository;

  GetFavoriteMessagesUseCase(this.repository);

  Future<List<ChatMessage>> execute({String? conversationId}) {
    return repository.getFavoriteMessages(conversationId: conversationId);
  }
}

