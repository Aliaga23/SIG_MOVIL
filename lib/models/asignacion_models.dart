class Cliente {
  final String id;
  final String nombre;
  final String apellido;
  final String telefono;
  final String email;
  final String direccion;
  final String coordenadas;

  Cliente({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.coordenadas,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      direccion: json['direccion'] ?? '',
      coordenadas: json['coordenadas'] ?? '',
    );
  }

  String get nombreCompleto => '$nombre $apellido'.trim();
}

class DetallePedido {
  final String id;
  final String productoId;
  final int cantidad;

  DetallePedido({
    required this.id,
    required this.productoId,
    required this.cantidad,
  });

  factory DetallePedido.fromJson(Map<String, dynamic> json) {
    return DetallePedido(
      id: json['id'] ?? '',
      productoId: json['producto_id'] ?? '',
      cantidad: json['cantidad'] ?? 0,
    );
  }
}

class Pedido {
  final String id;
  final String fechaPedido;
  final String estado;
  final double total;
  final String clienteId;
  final String instruccionesEntrega;
  final List<DetallePedido> detalles;

  Pedido({
    required this.id,
    required this.fechaPedido,
    required this.estado,
    required this.total,
    required this.clienteId,
    required this.instruccionesEntrega,
    required this.detalles,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['id'] ?? '',
      fechaPedido: json['fecha_pedido'] ?? '',
      estado: json['estado'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      clienteId: json['cliente_id'] ?? '',
      instruccionesEntrega: json['instrucciones_entrega'] ?? '',
      detalles: (json['detalles'] as List<dynamic>?)
          ?.map((e) => DetallePedido.fromJson(e))
          .toList() ?? [],
    );
  }
}

class EntregaDetalle {
  final String idEntrega;
  final String fechaHoraReg;
  final String coordenadasFin;
  final String estado;
  final String? observaciones;
  final int ordenEntrega;
  final Cliente cliente;
  final Pedido pedido;

  EntregaDetalle({
    required this.idEntrega,
    required this.fechaHoraReg,
    required this.coordenadasFin,
    required this.estado,
    this.observaciones,
    required this.ordenEntrega,
    required this.cliente,
    required this.pedido,
  });

  factory EntregaDetalle.fromJson(Map<String, dynamic> json) {
    return EntregaDetalle(
      idEntrega: json['id_entrega'] ?? '',
      fechaHoraReg: json['fecha_hora_reg'] ?? '',
      coordenadasFin: json['coordenadas_fin'] ?? '',
      estado: json['estado'] ?? '',
      observaciones: json['observaciones'],
      ordenEntrega: json['orden_entrega'] ?? 0,
      cliente: Cliente.fromJson(json['cliente'] ?? {}),
      pedido: Pedido.fromJson(json['pedido'] ?? {}),
    );
  }
}

class Ruta {
  final String rutaId;
  final String coordenadasInicio;
  final String coordenadasFin;
  final double distancia;
  final String tiempoEstimado;
  final List<EntregaDetalle> entregas;

  Ruta({
    required this.rutaId,
    required this.coordenadasInicio,
    required this.coordenadasFin,
    required this.distancia,
    required this.tiempoEstimado,
    required this.entregas,
  });

  factory Ruta.fromJson(Map<String, dynamic> json) {
    return Ruta(
      rutaId: json['ruta_id'] ?? '',
      coordenadasInicio: json['coordenadas_inicio'] ?? '',
      coordenadasFin: json['coordenadas_fin'] ?? '',
      distancia: (json['distancia'] ?? 0).toDouble(),
      tiempoEstimado: json['tiempo_estimado'] ?? '',
      entregas: (json['entregas'] as List<dynamic>?)
          ?.map((e) => EntregaDetalle.fromJson(e))
          .toList() ?? [],
    );
  }
}

class Asignacion {
  final String id;
  final String fechaAsignacion;
  final String estado;
  final Ruta ruta;

  Asignacion({
    required this.id,
    required this.fechaAsignacion,
    required this.estado,
    required this.ruta,
  });

  factory Asignacion.fromJson(Map<String, dynamic> json) {
    return Asignacion(
      id: json['id'] ?? '',
      fechaAsignacion: json['fecha_asignacion'] ?? '',
      estado: json['estado'] ?? '',
      ruta: Ruta.fromJson(json['ruta'] ?? {}),
    );
  }

  Asignacion copyWith({
    String? id,
    String? fechaAsignacion,
    String? estado,
    Ruta? ruta,
  }) {
    return Asignacion(
      id: id ?? this.id,
      fechaAsignacion: fechaAsignacion ?? this.fechaAsignacion,
      estado: estado ?? this.estado,
      ruta: ruta ?? this.ruta,
    );
  }

  bool get esPendienteOAceptada => estado == 'pendiente' || estado == 'aceptada';
  bool get tieneEntregas => ruta.entregas.isNotEmpty;
}
