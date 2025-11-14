class Devocional {
  final int? idDevocional;
  final String? titulo;
  final String? cuerpo;
  final DateTime? fecha;
  final String? autor;
  final int? idVersiculo;

  Devocional({
    this.idDevocional,
    this.titulo,
    this.cuerpo,
    this.fecha,
    this.autor,
    this.idVersiculo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_devocional': idDevocional,
      'titulo': titulo,
      'cuerpo': cuerpo,
      'fecha': fecha?.toIso8601String().split('T')[0],
      'autor': autor,
      'id_versiculo': idVersiculo,
    };
  }

  factory Devocional.fromMap(Map<String, dynamic> map) {
    return Devocional(
      idDevocional: map['id_devocional'],
      titulo: map['titulo'],
      cuerpo: map['cuerpo'],
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha']) : null,
      autor: map['autor'],
      idVersiculo: map['id_versiculo'],
    );
  }
}
