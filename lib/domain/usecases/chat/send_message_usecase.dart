import '../../entities/chat_message.dart';
import '../../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<List<ChatMessage>> execute(String message, String sender) {
    return repository.sendMessage(message, sender);
  }
}
