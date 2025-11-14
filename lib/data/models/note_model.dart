class NoteModel {
  final int? id;
  final int userId;
  final int? verseId;
  final String text;
  final DateTime createdAt;

  NoteModel({
    this.id,
    required this.userId,
    required this.text,
    this.verseId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id_nota': id,
      'id_usuario': userId,
      'id_versiculo': verseId,
      'texto': text,
      'creada_en': createdAt.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id_nota'] as int?,
      userId: map['id_usuario'] as int,
      verseId: map['id_versiculo'] as int?,
      text: map['texto'] as String? ?? '',
      createdAt: map['creada_en'] != null
          ? DateTime.tryParse(map['creada_en'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
