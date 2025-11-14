class PlanLectura {
  final int? idPlan;
  final String nombre;
  final String? descripcion;
  final int? dias;

  PlanLectura({this.idPlan, required this.nombre, this.descripcion, this.dias});

  Map<String, dynamic> toMap() {
    return {
      'id_plan': idPlan,
      'nombre': nombre,
      'descripcion': descripcion,
      'dias': dias,
    };
  }

  factory PlanLectura.fromMap(Map<String, dynamic> map) {
    return PlanLectura(
      idPlan: map['id_plan'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      dias: map['dias'],
    );
  }
}
