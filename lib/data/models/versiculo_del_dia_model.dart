class VersiculoDelDia {
  final DateTime fecha;
  final int idVersiculo;
  final String? fuente;
  final String? tema;

  VersiculoDelDia({
    required this.fecha,
    required this.idVersiculo,
    this.fuente,
    this.tema,
  });

  Map<String, dynamic> toMap() {
    return {
      'fecha': fecha.toIso8601String().split('T')[0],
      'id_versiculo': idVersiculo,
      'fuente': fuente,
      'tema': tema,
    };
  }

  factory VersiculoDelDia.fromMap(Map<String, dynamic> map) {
    return VersiculoDelDia(
      fecha: DateTime.parse(map['fecha']),
      idVersiculo: map['id_versiculo'],
      fuente: map['fuente'],
      tema: map['tema'],
    );
  }
}
