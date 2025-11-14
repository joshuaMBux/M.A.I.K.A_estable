class HistorialConversacion {
  final int? idHistorial;
  final int? idUsuario;
  final String? textoUsuario;
  final String? textoBot;
  final String? intent;
  final String? entitiesJson;
  final double? confidence;
  final DateTime? fecha;

  HistorialConversacion({
    this.idHistorial,
    this.idUsuario,
    this.textoUsuario,
    this.textoBot,
    this.intent,
    this.entitiesJson,
    this.confidence,
    this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_historial': idHistorial,
      'id_usuario': idUsuario,
      'texto_usuario': textoUsuario,
      'texto_bot': textoBot,
      'intent': intent,
      'entities_json': entitiesJson,
      'confidence': confidence,
      'fecha': fecha?.toIso8601String(),
    };
  }

  factory HistorialConversacion.fromMap(Map<String, dynamic> map) {
    return HistorialConversacion(
      idHistorial: map['id_historial'],
      idUsuario: map['id_usuario'],
      textoUsuario: map['texto_usuario'],
      textoBot: map['texto_bot'],
      intent: map['intent'],
      entitiesJson: map['entities_json'],
      confidence: map['confidence']?.toDouble(),
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha']) : null,
    );
  }
}
