class Tienda {
  final String id;
  final String nombre;
  final String direccion;
  final String telefono;
  final String email;
  final double latitud;
  final double longitud;
  final String descripcion;

  Tienda({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.email,
    required this.latitud,
    required this.longitud,
    required this.descripcion,
  });

  factory Tienda.fromJson(Map<String, dynamic> json) {
    return Tienda(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      latitud: (json['latitud'] ?? 0).toDouble(),
      longitud: (json['longitud'] ?? 0).toDouble(),
      descripcion: json['descripcion'] ?? '',
    );
  }
}
