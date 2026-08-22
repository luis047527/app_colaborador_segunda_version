class Usuario {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String? fotoUrl;
  final String rol;
  final String estado;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.fotoUrl,
    required this.rol,
    required this.estado,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      email: json['email'],
      fotoUrl: json['foto_url'],
      rol: json['rol'],
      estado: json['estado'],
    );
  }

  String get nombreCompleto => '$nombre $apellido';
}
