import 'package:equatable/equatable.dart';

class Devotional extends Equatable {
  final int id;
  final String title;
  final String content;
  final DateTime date;
  final String? author;
  final String? verseReference;
  final String? verseText;

  const Devotional({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.author,
    this.verseReference,
    this.verseText,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    date,
    author,
    verseReference,
    verseText,
  ];
}
