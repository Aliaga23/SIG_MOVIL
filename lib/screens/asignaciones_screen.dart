import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/asignacion_provider.dart';
import '../models/asignacion_models.dart';
import '../widgets/asignacion_widgets.dart';

class AsignacionesScreen extends StatefulWidget {
  const AsignacionesScreen({super.key});

  @override
  State<AsignacionesScreen> createState() => _AsignacionesScreenState();
}

class _AsignacionesScreenState extends State<AsignacionesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AsignacionProvider>(context, listen: false).loadAsignaciones();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Consumer<AsignacionProvider>(
        builder: (context, asignacionProvider, child) {
          if (asignacionProvider.isLoading) {
            return _buildLoadingState();
          }

          if (asignacionProvider.error != null) {
            return _buildErrorState(asignacionProvider);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAsignacionesList(asignacionProvider.asignacionesActivas),
              _buildEntregasList(asignacionProvider.asignacionesConEntregas),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<AsignacionProvider>(context, listen: false).loadAsignaciones();
        },
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Mis Asignaciones',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      elevation: 0,
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        tabs: const [
          Tab(
            icon: Icon(Icons.assignment),
            text: 'Asignaciones',
          ),
          Tab(
            icon: Icon(Icons.local_shipping),
            text: 'Entregas',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitFadingCircle(
            color: Colors.blue[600],
            size: 50,
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando asignaciones...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AsignacionProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar asignaciones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadAsignaciones(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsignacionesList(List<Asignacion> asignaciones) {
    if (asignaciones.isEmpty) {
      return _buildEmptyState(
        'No hay asignaciones activas',
        'Las asignaciones pendientes y aceptadas aparecerán aquí',
        Icons.assignment_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<AsignacionProvider>(context, listen: false).loadAsignaciones();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: asignaciones.length,
        itemBuilder: (context, index) {
          final asignacion = asignaciones[index];
          return AsignacionCard(
            asignacion: asignacion,
            onTap: () => _showAsignacionDetail(asignacion),
            onAceptar: asignacion.estado == 'pendiente' ? _aceptarAsignacion : null,
            onRechazar: asignacion.estado == 'pendiente' ? _rechazarAsignacion : null,
          );
        },
      ),
    );
  }

  Widget _buildEntregasList(List<Asignacion> asignacionesConEntregas) {
    if (asignacionesConEntregas.isEmpty) {
      return _buildEmptyState(
        'No hay entregas disponibles',
        'Las entregas de tus asignaciones aparecerán aquí',
        Icons.local_shipping_outlined,
      );
    }

    // Aplanar todas las entregas de todas las asignaciones
    final List<MapEntry<Asignacion, EntregaDetalle>> entregasFlat = [];
    for (final asignacion in asignacionesConEntregas) {
      for (final entrega in asignacion.ruta.entregas) {
        entregasFlat.add(MapEntry(asignacion, entrega));
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<AsignacionProvider>(context, listen: false).loadAsignaciones();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entregasFlat.length,
        itemBuilder: (context, index) {
          final entry = entregasFlat[index];
          final asignacion = entry.key;
          final entrega = entry.value;
          return _buildEntregaCard(asignacion, entrega);
        },
      ),
    );
  }

  Widget _buildEntregaCard(Asignacion asignacion, EntregaDetalle entrega) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: () => _showEntregaDetail(asignacion, entrega),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getEntregaEstadoColor(entrega.estado),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entrega.ordenEntrega}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entrega.cliente.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getEntregaEstadoColor(entrega.estado).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getEntregaEstadoColor(entrega.estado).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        entrega.estado.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getEntregaEstadoColor(entrega.estado),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.red[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        entrega.cliente.direccion,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      entrega.cliente.telefono,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      'Bs. ${entrega.pedido.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                if (entrega.pedido.instruccionesEntrega.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entrega.pedido.instruccionesEntrega,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (entrega.estado == 'pendiente') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _completarEntrega(entrega, 'entregado'),
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Entregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _completarEntrega(entrega, 'fallida'),
                          icon: const Icon(Icons.cancel, size: 16),
                          label: const Text('Falló'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEntregaEstadoColor(String estado) {
    switch (estado) {
      case 'completada':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'fallida':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showAsignacionDetail(Asignacion asignacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Asignación ${asignacion.estado}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${asignacion.id}'),
            const SizedBox(height: 8),
            Text('Fecha: ${asignacion.fechaAsignacion}'),
            const SizedBox(height: 8),
            Text('Distancia: ${asignacion.ruta.distancia} km'),
            const SizedBox(height: 8),
            Text('Tiempo estimado: ${asignacion.ruta.tiempoEstimado}'),
            const SizedBox(height: 8),
            Text('Entregas: ${asignacion.ruta.entregas.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showEntregaDetail(Asignacion asignacion, EntregaDetalle entrega) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Entrega - ${entrega.cliente.nombreCompleto}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cliente: ${entrega.cliente.nombreCompleto}'),
              const SizedBox(height: 4),
              Text('Teléfono: ${entrega.cliente.telefono}'),
              const SizedBox(height: 4),
              Text('Email: ${entrega.cliente.email}'),
              const SizedBox(height: 8),
              Text('Dirección: ${entrega.cliente.direccion}'),
              const SizedBox(height: 4),
              Text('Coordenadas: ${entrega.coordenadasFin}'),
              const SizedBox(height: 8),
              Text('Total: Bs. ${entrega.pedido.total}'),
              const SizedBox(height: 4),
              Text('Estado pedido: ${entrega.pedido.estado}'),
              if (entrega.pedido.instruccionesEntrega.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Instrucciones: ${entrega.pedido.instruccionesEntrega}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (entrega.estado == 'pendiente')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usa la pestaña "Mapa" para ver las rutas de entrega'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Ver en Mapa'),
            ),
        ],
      ),
    );
  }

  Future<void> _aceptarAsignacion(String asignacionId) async {
    final provider = Provider.of<AsignacionProvider>(context, listen: false);
    
    final success = await provider.aceptarAsignacion(asignacionId);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asignación aceptada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Error al aceptar la asignación'),
          backgroundColor: Colors.red,
        ),
      );
      provider.clearError();
    }
  }

  Future<void> _rechazarAsignacion(String asignacionId) async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar rechazo'),
        content: const Text('¿Estás seguro de que deseas rechazar esta asignación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = Provider.of<AsignacionProvider>(context, listen: false);
      
      final success = await provider.rechazarAsignacion(asignacionId);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asignación rechazada'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Error al rechazar la asignación'),
            backgroundColor: Colors.red,
          ),
        );
        provider.clearError();
      }
    }
  }

  Future<void> _completarEntrega(EntregaDetalle entrega, String estado) async {
    try {
      // Obtener ubicación actual
      Position? position;
      try {
        // Verificar permisos de ubicación
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Permisos de ubicación denegados');
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw Exception('Permisos de ubicación denegados permanentemente');
        }

        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error obteniendo ubicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final coordenadas = '${position.latitude}, ${position.longitude}';
      
      // Mostrar diálogo para observaciones si es necesario
      String? observaciones;
      if (estado == 'fallida') {
        observaciones = await _showObservacionesDialog();
        if (observaciones == null) return; // Usuario canceló
      }

      if (!mounted) return;

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final provider = Provider.of<AsignacionProvider>(context, listen: false);
      
      final response = await provider.completarEntrega(
        entregaId: entrega.idEntrega,
        coordenadasFin: coordenadas,
        estado: estado,
        observaciones: observaciones ?? '',
      );

      if (!mounted) return;
      
      // Cerrar loading
      Navigator.of(context).pop();

      if (response != null) {
        final mensaje = estado == 'entregado' 
            ? '✅ Entrega completada exitosamente'
            : '❌ Entrega marcada como fallida';
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: estado == 'entregado' ? Colors.green : Colors.orange,
          ),
        );

        // Mostrar información adicional si está disponible
        if (response['todas_entregas_completadas'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 ¡Todas las entregas completadas!'),
              backgroundColor: Colors.blue,
            ),
          );
        } else if (response['ruta_actualizada'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🛣️ Ruta actualizada para próximas entregas'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Error al completar la entrega'),
            backgroundColor: Colors.red,
          ),
        );
        provider.clearError();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar loading si está abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showObservacionesDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Motivo del fallo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Por favor, indica el motivo por el cual la entrega falló:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ej: Cliente no estaba, dirección incorrecta, etc.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Marcar como fallida'),
          ),
        ],
      ),
    );
  }
}
