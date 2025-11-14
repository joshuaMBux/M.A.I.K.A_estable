class ActividadUsuario {
  final int? idActividad;
  final int? idUsuario;
  final DateTime fecha;
  final String? tipo;
  final int valor;

  ActividadUsuario({
    this.idActividad,
    this.idUsuario,
    required this.fecha,
    this.tipo,
    this.valor = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_actividad': idActividad,
      'id_usuario': idUsuario,
      'fecha': fecha.toIso8601String().split('T')[0],
      'tipo': tipo,
      'valor': valor,
    };
  }

  factory ActividadUsuario.fromMap(Map<String, dynamic> map) {
    return ActividadUsuario(
      idActividad: map['id_actividad'],
      idUsuario: map['id_usuario'],
      fecha: map['fecha'] != null
          ? DateTime.parse(map['fecha'])
          : DateTime.now(),
      tipo: map['tipo'],
      valor: map['valor'] ?? 1,
    );
  }
}
