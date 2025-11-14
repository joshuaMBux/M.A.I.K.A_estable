import '../../entities/chat_session.dart';
import '../../repositories/chat_repository.dart';

class SyncPendingMessagesUseCase {
  final ChatRepository repository;

  SyncPendingMessagesUseCase(this.repository);

  Future<ChatSession> execute(String conversationId) {
    return repository.syncPending(conversationId);
  }
}
