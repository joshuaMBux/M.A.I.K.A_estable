class Versiculo {
  final int? idVersiculo;
  final int idLibro;
  final int capitulo;
  final int versiculo;
  final String texto;
  final String version;
  final String? nombreLibro;
  final String? abreviaturaLibro;

  Versiculo({
    this.idVersiculo,
    required this.idLibro,
    required this.capitulo,
    required this.versiculo,
    required this.texto,
    this.version = 'RVR1960',
    this.nombreLibro,
    this.abreviaturaLibro,
  });

  String get referencia =>
      '${abreviaturaLibro ?? 'Libro'} $capitulo:$versiculo';

  Map<String, dynamic> toMap() {
    return {
      'id_versiculo': idVersiculo,
      'id_libro': idLibro,
      'capitulo': capitulo,
      'versiculo': versiculo,
      'texto': texto,
      'version': version,
    };
  }

  factory Versiculo.fromMap(Map<String, dynamic> map) {
    return Versiculo(
      idVersiculo: map['id_versiculo'] as int?,
      idLibro: map['id_libro'] as int,
      capitulo: map['capitulo'] as int,
      versiculo: map['versiculo'] as int,
      texto: map['texto'] as String,
      version: map['version'] as String? ?? 'RVR1960',
      nombreLibro: map['nombre_libro'] as String?,
      abreviaturaLibro: map['abreviatura_libro'] as String?,
    );
  }
}
