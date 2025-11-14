import '../entities/note.dart';

abstract class NoteRepository {
  Future<Note> addNote({
    required int userId,
    required String text,
    int? verseId,
  });

  Future<List<Note>> getNotesForVerse({
    required int userId,
    required int verseId,
  });

  Future<List<Note>> getNotesForUser(int userId);
}
