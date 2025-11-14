class Favorito {
  final int? idFavorito;
  final int idUsuario;
  final int idVersiculo;
  final DateTime? creadoEn;
  final String? textoVersiculo;
  final String? referenciaVersiculo;

  Favorito({
    this.idFavorito,
    required this.idUsuario,
    required this.idVersiculo,
    this.creadoEn,
    this.textoVersiculo,
    this.referenciaVersiculo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_favorito': idFavorito,
      'id_usuario': idUsuario,
      'id_versiculo': idVersiculo,
      'creado_en': creadoEn?.toIso8601String(),
    };
  }

  factory Favorito.fromMap(Map<String, dynamic> map) {
    return Favorito(
      idFavorito: map['id_favorito'],
      idUsuario: map['id_usuario'],
      idVersiculo: map['id_versiculo'],
      creadoEn: map['creado_en'] != null
          ? DateTime.parse(map['creado_en'])
          : null,
      textoVersiculo: map['texto_versiculo'],
      referenciaVersiculo: map['referencia_versiculo'],
    );
  }
}
