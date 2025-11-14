import 'package:equatable/equatable.dart';

class Verse extends Equatable {
  final String id;
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final String? translation;
  final List<String>? tags;
  final bool isFavorite;

  const Verse({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    this.translation,
    this.tags,
    this.isFavorite = false,
  });

  String get reference => '$book $chapter:$verse';

  @override
  List<Object?> get props => [
    id,
    book,
    chapter,
    verse,
    text,
    translation,
    tags,
    isFavorite,
  ];
}
