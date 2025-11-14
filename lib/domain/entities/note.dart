import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final int? id;
  final int userId;
  final int? verseId;
  final String text;
  final DateTime createdAt;

  const Note({
    this.id,
    required this.userId,
    this.verseId,
    required this.text,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, verseId, text, createdAt];
}
