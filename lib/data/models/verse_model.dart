import '../../domain/entities/verse.dart';

class VerseModel extends Verse {
  const VerseModel({
    required super.id,
    required super.book,
    required super.chapter,
    required super.verse,
    required super.text,
    super.translation,
    super.tags,
    super.isFavorite,
  });

  factory VerseModel.fromJson(Map<String, dynamic> json) {
    return VerseModel(
      id: json['id'] as String,
      book: json['book'] as String,
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
      text: json['text'] as String,
      translation: json['translation'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'text': text,
      'translation': translation,
      'tags': tags,
      'is_favorite': isFavorite,
    };
  }
}
