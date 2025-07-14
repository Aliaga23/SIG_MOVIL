class Ubicacion {
  final double latitud;
  final double longitud;
  final String coordenadas;

  Ubicacion({
    required this.latitud,
    required this.longitud,
    required this.coordenadas,
  });

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      latitud: json['latitud']?.toDouble() ?? 0.0,
      longitud: json['longitud']?.toDouble() ?? 0.0,
      coordenadas: json['coordenadas'] ?? '',
    );
  }
}

class Perfil {
  final String id;
  final String nombre;
  final String apellido;
  final String nombreCompleto;
  final String carnet;
  final String telefono;
  final String email;
  final String licencia;
  final bool activo;
  final String estado;
  final Ubicacion ubicacion;

  Perfil({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.nombreCompleto,
    required this.carnet,
    required this.telefono,
    required this.email,
    required this.licencia,
    required this.activo,
    required this.estado,
    required this.ubicacion,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      carnet: json['carnet'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      licencia: json['licencia'] ?? '',
      activo: json['activo'] ?? false,
      estado: json['estado'] ?? '',
      ubicacion: Ubicacion.fromJson(json['ubicacion'] ?? {}),
    );
  }
}

class Vehiculo {
  final String id;
  final String marca;
  final String modelo;
  final String placa;
  final int capacidadCarga;
  final String tipoVehiculo;
  final int anio;
  final String descripcionCompleta;

  Vehiculo({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.placa,
    required this.capacidadCarga,
    required this.tipoVehiculo,
    required this.anio,
    required this.descripcionCompleta,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['id'] ?? '',
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      placa: json['placa'] ?? '',
      capacidadCarga: json['capacidad_carga'] ?? 0,
      tipoVehiculo: json['tipo_vehiculo'] ?? '',
      anio: json['anio'] ?? 0,
      descripcionCompleta: json['descripcion_completa'] ?? '',
    );
  }
}

class Asignaciones {
  final int total;
  final int pendientes;
  final int aceptadas;
  final int rechazadas;
  final int hoy;

  Asignaciones({
    required this.total,
    required this.pendientes,
    required this.aceptadas,
    required this.rechazadas,
    required this.hoy,
  });

  factory Asignaciones.fromJson(Map<String, dynamic> json) {
    return Asignaciones(
      total: json['total'] ?? 0,
      pendientes: json['pendientes'] ?? 0,
      aceptadas: json['aceptadas'] ?? 0,
      rechazadas: json['rechazadas'] ?? 0,
      hoy: json['hoy'] ?? 0,
    );
  }
}

class Entregas {
  final int total;
  final int completadas;
  final int pendientes;
  final int fallidas;
  final double tasaExito;

  Entregas({
    required this.total,
    required this.completadas,
    required this.pendientes,
    required this.fallidas,
    required this.tasaExito,
  });

  factory Entregas.fromJson(Map<String, dynamic> json) {
    return Entregas(
      total: json['total'] ?? 0,
      completadas: json['completadas'] ?? 0,
      pendientes: json['pendientes'] ?? 0,
      fallidas: json['fallidas'] ?? 0,
      tasaExito: (json['tasa_exito'] ?? 0).toDouble(),
    );
  }
}

class Estadisticas {
  final Asignaciones asignaciones;
  final Entregas entregas;

  Estadisticas({
    required this.asignaciones,
    required this.entregas,
  });

  factory Estadisticas.fromJson(Map<String, dynamic> json) {
    return Estadisticas(
      asignaciones: Asignaciones.fromJson(json['asignaciones'] ?? {}),
      entregas: Entregas.fromJson(json['entregas'] ?? {}),
    );
  }
}

class Estado {
  final bool tieneVehiculo;
  final bool puedeTrabajar;
  final String estadoDistribuidor;
  final bool disponibleParaAsignaciones;
  final bool asignacionesPendientesDisponibles;
  final bool ubicacionConfigurada;

  Estado({
    required this.tieneVehiculo,
    required this.puedeTrabajar,
    required this.estadoDistribuidor,
    required this.disponibleParaAsignaciones,
    required this.asignacionesPendientesDisponibles,
    required this.ubicacionConfigurada,
  });

  factory Estado.fromJson(Map<String, dynamic> json) {
    return Estado(
      tieneVehiculo: json['tiene_vehiculo'] ?? false,
      puedeTrabajar: json['puede_trabajar'] ?? false,
      estadoDistribuidor: json['estado_distribuidor'] ?? '',
      disponibleParaAsignaciones: json['disponible_para_asignaciones'] ?? false,
      asignacionesPendientesDisponibles: json['asignaciones_pendientes_disponibles'] ?? false,
      ubicacionConfigurada: json['ubicacion_configurada'] ?? false,
    );
  }
}

class DashboardData {
  final Perfil perfil;
  final Vehiculo vehiculo;
  final Estadisticas estadisticas;
  final Estado estado;
  final String ultimaActualizacion;

  DashboardData({
    required this.perfil,
    required this.vehiculo,
    required this.estadisticas,
    required this.estado,
    required this.ultimaActualizacion,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      perfil: Perfil.fromJson(json['perfil'] ?? {}),
      vehiculo: Vehiculo.fromJson(json['vehiculo'] ?? {}),
      estadisticas: Estadisticas.fromJson(json['estadisticas'] ?? {}),
      estado: Estado.fromJson(json['estado'] ?? {}),
      ultimaActualizacion: json['ultima_actualizacion'] ?? '',
    );
  }
}
