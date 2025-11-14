class PlanProgress {
  final int? idProgress;
  final int userId;
  final int planId;
  final int day;
  final bool completed;
  final DateTime? completedAt;

  PlanProgress({
    this.idProgress,
    required this.userId,
    required this.planId,
    required this.day,
    required this.completed,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_progreso': idProgress,
      'id_usuario': userId,
      'id_plan': planId,
      'dia': day,
      'completado': completed ? 1 : 0,
      'completado_en': completedAt?.toIso8601String(),
    };
  }

  factory PlanProgress.fromMap(Map<String, dynamic> map) {
    return PlanProgress(
      idProgress: map['id_progreso'] as int?,
      userId: map['id_usuario'] as int,
      planId: map['id_plan'] as int,
      day: map['dia'] as int,
      completed: (map['completado'] as int? ?? 0) == 1,
      completedAt: map['completado_en'] != null
          ? DateTime.tryParse(map['completado_en'] as String)
          : null,
    );
  }
}
