import '../../repositories/chat_repository.dart';

class ToggleFavoriteMessageUseCase {
  final ChatRepository repository;

  ToggleFavoriteMessageUseCase(this.repository);

  Future<void> execute({
    required String messageId,
    required bool isFavorite,
    String? note,
  }) {
    return repository.toggleFavorite(
      messageId: messageId,
      isFavorite: isFavorite,
      note: note,
    );
  }
}
