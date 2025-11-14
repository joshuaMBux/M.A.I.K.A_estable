import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final DatabaseHelper? _dbHelper;

  NoteRepositoryImpl(DatabaseHelper? databaseHelper)
    : _dbHelper = kIsWeb ? null : databaseHelper;

  @override
  Future<Note> addNote({
    required int userId,
    required String text,
    int? verseId,
  }) async {
    if (kIsWeb) {
      final note = Note(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: userId,
        verseId: verseId,
        text: text,
        createdAt: DateTime.now(),
      );
      return note;
    }

    final db = await _dbHelper!.database;
    final noteModel = NoteModel(userId: userId, verseId: verseId, text: text);
    final id = await db.insert('nota', noteModel.toMap());
    return Note(
      id: id,
      userId: userId,
      verseId: verseId,
      text: text,
      createdAt: noteModel.createdAt,
    );
  }

  @override
  Future<List<Note>> getNotesForVerse({
    required int userId,
    required int verseId,
  }) async {
    if (kIsWeb) {
      return [];
    }

    final db = await _dbHelper!.database;
    final rows = await db.query(
      'nota',
      where: 'id_usuario = ? AND id_versiculo = ?',
      whereArgs: [userId, verseId],
      orderBy: 'creada_en DESC',
    );

    return rows
        .map((row) => NoteModel.fromMap(row))
        .map(
          (model) => Note(
            id: model.id,
            userId: model.userId,
            verseId: model.verseId,
            text: model.text,
            createdAt: model.createdAt,
          ),
        )
        .toList();
  }

  @override
  Future<List<Note>> getNotesForUser(int userId) async {
    if (kIsWeb) {
      return [];
    }

    final db = await _dbHelper!.database;
    final rows = await db.query(
      'nota',
      where: 'id_usuario = ?',
      whereArgs: [userId],
      orderBy: 'creada_en DESC',
    );

    return rows
        .map((row) => NoteModel.fromMap(row))
        .map(
          (model) => Note(
            id: model.id,
            userId: model.userId,
            verseId: model.verseId,
            text: model.text,
            createdAt: model.createdAt,
          ),
        )
        .toList();
  }
}
