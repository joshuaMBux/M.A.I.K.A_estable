class Usuario {
  final int? idUsuario;
  final String nombre;
  final String? email;
  final String? pwd;
  final String rol;
  final DateTime? fechaNacimiento;

  Usuario({
    this.idUsuario,
    required this.nombre,
    this.email,
    this.pwd,
    this.rol = 'joven',
    this.fechaNacimiento,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'nombre': nombre,
      'email': email,
      'pwd': pwd,
      'rol': rol,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String().split('T')[0],
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      idUsuario: map['id_usuario'],
      nombre: map['nombre'],
      email: map['email'],
      pwd: map['pwd'],
      rol: map['rol'] ?? 'joven',
      fechaNacimiento: map['fecha_nacimiento'] != null
          ? DateTime.parse(map['fecha_nacimiento'])
          : null,
    );
  }
}
