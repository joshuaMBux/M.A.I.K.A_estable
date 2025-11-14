class RachaUsuario {
  final int idUsuario;
  final int rachaActual;
  final DateTime? ultimaFecha;

  RachaUsuario({
    required this.idUsuario,
    this.rachaActual = 0,
    this.ultimaFecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'racha_actual': rachaActual,
      'ultima_fecha': ultimaFecha?.toIso8601String().split('T')[0],
    };
  }

  factory RachaUsuario.fromMap(Map<String, dynamic> map) {
    return RachaUsuario(
      idUsuario: map['id_usuario'],
      rachaActual: map['racha_actual'] ?? 0,
      ultimaFecha: map['ultima_fecha'] != null
          ? DateTime.parse(map['ultima_fecha'])
          : null,
    );
  }
}
