class Libro {
  final int? idLibro;
  final String nombre;
  final String? abreviatura;
  final int? orden;

  Libro({this.idLibro, required this.nombre, this.abreviatura, this.orden});

  Map<String, dynamic> toMap() {
    return {
      'id_libro': idLibro,
      'nombre': nombre,
      'abreviatura': abreviatura,
      'orden': orden,
    };
  }

  factory Libro.fromMap(Map<String, dynamic> map) {
    return Libro(
      idLibro: map['id_libro'],
      nombre: map['nombre'],
      abreviatura: map['abreviatura'],
      orden: map['orden'],
    );
  }
}
