import '../../entities/chat_session.dart';
import '../../repositories/chat_repository.dart';

class LoadChatSessionUseCase {
  final ChatRepository repository;

  LoadChatSessionUseCase(this.repository);

  Future<ChatSession> execute({String? conversationId}) {
    return repository.loadSession(conversationId: conversationId);
  }
}
