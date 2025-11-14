import '../../repositories/note_repository.dart';
import '../../entities/note.dart';

class AddNoteUseCase {
  final NoteRepository repository;

  AddNoteUseCase(this.repository);

  Future<Note> call({required int userId, required String text, int? verseId}) {
    return repository.addNote(userId: userId, text: text, verseId: verseId);
  }
}
