class PlanItem {
  final int? idItem;
  final int idPlan;
  final int day;
  final int? bookId;
  final int? startChapter;
  final int? startVerse;
  final int? endChapter;
  final int? endVerse;
  final String? comment;
  final String? bookName;
  final String? bookAbbreviation;

  PlanItem({
    this.idItem,
    required this.idPlan,
    required this.day,
    this.bookId,
    this.startChapter,
    this.startVerse,
    this.endChapter,
    this.endVerse,
    this.comment,
    this.bookName,
    this.bookAbbreviation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_item': idItem,
      'id_plan': idPlan,
      'dia': day,
      'id_libro': bookId,
      'capitulo_inicio': startChapter,
      'versiculo_inicio': startVerse,
      'capitulo_fin': endChapter,
      'versiculo_fin': endVerse,
      'comentario': comment,
    };
  }

  factory PlanItem.fromMap(Map<String, dynamic> map) {
    return PlanItem(
      idItem: map['id_item'] as int?,
      idPlan: map['id_plan'] as int,
      day: map['dia'] as int,
      bookId: map['id_libro'] as int?,
      startChapter: map['capitulo_inicio'] as int?,
      startVerse: map['versiculo_inicio'] as int?,
      endChapter: map['capitulo_fin'] as int?,
      endVerse: map['versiculo_fin'] as int?,
      comment: map['comentario'] as String?,
      bookName: map['nombre_libro'] as String? ?? map['book_name'] as String?,
      bookAbbreviation:
          map['abreviatura'] as String? ?? map['book_abbreviation'] as String?,
    );
  }
}
