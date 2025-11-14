import '../../entities/note.dart';
import '../../repositories/note_repository.dart';

class GetNotesForVerseUseCase {
  final NoteRepository repository;

  GetNotesForVerseUseCase(this.repository);

  Future<List<Note>> call({required int userId, required int verseId}) {
    return repository.getNotesForVerse(userId: userId, verseId: verseId);
  }
}
