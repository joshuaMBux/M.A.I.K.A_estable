import 'package:equatable/equatable.dart';

class ReadingPlanDay extends Equatable {
  final int day;
  final String book;
  final int? startChapter;
  final int? startVerse;
  final int? endChapter;
  final int? endVerse;
  final String? comment;
  final bool completed;

  const ReadingPlanDay({
    required this.day,
    required this.book,
    this.startChapter,
    this.startVerse,
    this.endChapter,
    this.endVerse,
    this.comment,
    this.completed = false,
  });

  String get reference {
    if (startChapter == null) {
      return book;
    }

    final start = '$startChapter${startVerse != null ? ':$startVerse' : ''}';
    final hasEndChapter = endChapter != null && endChapter != startChapter;
    final end = endChapter == null
        ? startChapter != null
              ? '$startChapter${endVerse != null ? ':$endVerse' : ''}'
              : null
        : '${endChapter!}${endVerse != null ? ':$endVerse' : ''}';

    if (end == null || end == start) {
      return '$book $start';
    }

    return hasEndChapter
        ? '$book $start-$end'
        : '$book $start-${end.split(':').last}';
  }

  ReadingPlanDay copyWith({bool? completed}) {
    return ReadingPlanDay(
      day: day,
      book: book,
      startChapter: startChapter,
      startVerse: startVerse,
      endChapter: endChapter,
      endVerse: endVerse,
      comment: comment,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [
    day,
    book,
    startChapter,
    startVerse,
    endChapter,
    endVerse,
    comment,
    completed,
  ];
}
