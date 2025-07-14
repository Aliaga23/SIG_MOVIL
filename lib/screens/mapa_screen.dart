import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/asignacion_models.dart';
import '../models/tienda_models.dart';
import '../providers/tienda_provider.dart';
import '../providers/asignacion_provider.dart';
import '../services/route_service.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoadingLocation = true;
  bool _isLoadingRoute = false;
  bool _showDeliveryList = false;
  List<EntregaDetalle> _entregasPendientes = [];
  RouteResponse? _currentRoute;
  Tienda? _selectedTienda;
  Asignacion? _asignacionActiva; // Nueva variable para la asignación activa
  
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  // Responsive breakpoints
  bool get isTablet => MediaQuery.of(context).size.width > 600;
  bool get isLargeScreen => MediaQuery.of(context).size.width > 900;
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;

  // Theme colors
  static const primaryColor = Color(0xFF2563EB);
  static const secondaryColor = Color(0xFF10B981);
  static const accentColor = Color(0xFFF59E0B);
  static const errorColor = Color(0xFFEF4444);
  static const surfaceColor = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeMap();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadData();
    await _createMarkersAndRoute();
    _fadeController.forward();
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Servicios de ubicación deshabilitados');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos denegados permanentemente');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showErrorSnackBar('Error de ubicación: $e');
    }
  }

  Future<void> _loadData() async {
    final tiendaProvider = Provider.of<TiendaProvider>(context, listen: false);
    final asignacionProvider = Provider.of<AsignacionProvider>(context, listen: false);

    await Future.wait([
      tiendaProvider.loadTiendas(),
      asignacionProvider.loadAsignaciones(),
    ]);

    final entregas = <EntregaDetalle>[];
    Asignacion? asignacionActiva;
    for (final asignacion in asignacionProvider.asignacionesConEntregas) {
      if (asignacion.estado == 'aceptada') {
        final entregasPendientes = asignacion.ruta.entregas.where((e) => e.estado == 'pendiente').toList();
        if (entregasPendientes.isNotEmpty) {
          entregas.addAll(entregasPendientes);
          asignacionActiva = asignacion; // Guardar la asignación activa para usar sus coordenadas
        }
      }
    }

    setState(() {
      _entregasPendientes = entregas..sort((a, b) => a.ordenEntrega.compareTo(b.ordenEntrega));
      _asignacionActiva = asignacionActiva; // Nuevo estado para guardar la asignación
    });
  }

  Future<void> _createMarkersAndRoute() async {
    final tiendaProvider = Provider.of<TiendaProvider>(context, listen: false);
    final tienda = tiendaProvider.tiendaPrincipal;
    if (tienda == null) return;

    setState(() {
      _selectedTienda = tienda;
    });

    final markers = <Marker>{};

    // Marcador de tienda
    markers.add(Marker(
      markerId: const MarkerId('tienda'),
      position: LatLng(tienda.latitud, tienda.longitud),
      infoWindow: InfoWindow(
        title: '🏪 ${tienda.nombre}',
        snippet: tienda.direccion,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));

    // Marcador de inicio dinámico (si es diferente de la tienda)
    if (_asignacionActiva?.ruta.coordenadasInicio.isNotEmpty == true) {
      final coords = _asignacionActiva!.ruta.coordenadasInicio.split(',');
      if (coords.length >= 2) {
        final lat = double.tryParse(coords[0].trim());
        final lng = double.tryParse(coords[1].trim());
        if (lat != null && lng != null) {
          final inicioPos = LatLng(lat, lng);
          final tiendaPos = LatLng(tienda.latitud, tienda.longitud);
          
          // Solo agregar marcador si está en una ubicación diferente a la tienda
          if ((inicioPos.latitude - tiendaPos.latitude).abs() > 0.0001 || 
              (inicioPos.longitude - tiendaPos.longitude).abs() > 0.0001) {
            markers.add(Marker(
              markerId: const MarkerId('inicio_dinamico'),
              position: inicioPos,
              infoWindow: const InfoWindow(
                title: '🚩 Punto de inicio',
                snippet: 'Ubicación actual para próxima entrega',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            ));
          }
        }
      }
    }

    // Marcador de ubicación actual
    if (_currentPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('distribuidor'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        infoWindow: const InfoWindow(
          title: '📍 Mi ubicación',
          snippet: 'Ubicación actual',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    // Marcadores de entregas con colores mejorados
    for (int i = 0; i < _entregasPendientes.length; i++) {
      final entrega = _entregasPendientes[i];
      final coords = entrega.coordenadasFin.split(',');
      if (coords.length >= 2) {
        final lat = double.tryParse(coords[0].trim());
        final lng = double.tryParse(coords[1].trim());
        if (lat != null && lng != null) {
          markers.add(Marker(
            markerId: MarkerId('entrega_${entrega.idEntrega}'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: '${i + 1}. ${entrega.cliente.nombreCompleto}',
              snippet: '${entrega.cliente.direccion}\nBs. ${entrega.pedido.total.toStringAsFixed(2)}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(i)),
          ));
        }
      }
    }

    setState(() => _markers = markers);

    if (_entregasPendientes.isNotEmpty) {
      await _createOrderedRoute(tienda);
    }

    _fitMarkersToScreen();
  }

  Future<void> _createOrderedRoute(Tienda tienda) async {
    setState(() => _isLoadingRoute = true);

    try {
      // Crear ruta siguiendo el orden específico de la asignación
      // Desde las coordenadas de inicio dinámicas hasta la última entrega (SIN RETORNO a la tienda)
      // NO optimizar el orden, pero SÍ calcular la ruta más eficiente para ese orden
      
      LatLng origin;
      
      // Usar las coordenadas de inicio de la ruta si están disponibles, si no, usar la tienda
      if (_asignacionActiva?.ruta.coordenadasInicio.isNotEmpty == true) {
        final coords = _asignacionActiva!.ruta.coordenadasInicio.split(',');
        if (coords.length >= 2) {
          final lat = double.tryParse(coords[0].trim());
          final lng = double.tryParse(coords[1].trim());
          if (lat != null && lng != null) {
            origin = LatLng(lat, lng);
            print('🚀 Usando coordenadas de inicio dinámicas: ${_asignacionActiva!.ruta.coordenadasInicio}');
          } else {
            origin = LatLng(tienda.latitud, tienda.longitud);
            print('⚠️ Error parseando coordenadas dinámicas, usando tienda');
          }
        } else {
          origin = LatLng(tienda.latitud, tienda.longitud);
          print('⚠️ Coordenadas dinámicas mal formateadas, usando tienda');
        }
      } else {
        origin = LatLng(tienda.latitud, tienda.longitud);
        print('📍 Usando coordenadas de tienda (primera vez)');
      }
      final waypoints = <LatLng>[];
      
      // Agregar cada entrega en el orden específico (ya están ordenadas por ordenEntrega)
      for (final entrega in _entregasPendientes) {
        final coords = entrega.coordenadasFin.split(',');
        if (coords.length >= 2) {
          final lat = double.tryParse(coords[0].trim());
          final lng = double.tryParse(coords[1].trim());
          if (lat != null && lng != null) {
            waypoints.add(LatLng(lat, lng));
          }
        }
      }

      if (waypoints.isEmpty) return;

      // SIEMPRE: tienda -> entrega1 -> entrega2 -> ... -> última entrega (SIN VOLVER)
      // Respetamos el orden específico de la asignación pero NO optimizamos waypoints
      final routeWaypoints = waypoints.sublist(0, waypoints.length - 1); // Todos menos el último
      final destination = waypoints.last; // La última entrega es el destino final

      // IMPORTANTE: NO usar optimización de orden, pero SÍ obtener ruta óptima para el orden dado
      final routeResponse = await RouteService.getOptimizedRoute(
        origin: origin,
        waypoints: routeWaypoints,
        destination: destination,
        optimizeWaypoints: false, // NO cambiar el orden, pero sí calcular ruta óptima
      );

      // Crear polylines con gradientes mejorados
      final polylines = <Polyline>{};
      final colors = [
        primaryColor,
        accentColor,
        secondaryColor,
        const Color(0xFF8B5CF6),
        const Color(0xFFEC4899),
      ];

      for (int i = 0; i < routeResponse.legs.length; i++) {
        final leg = routeResponse.legs[i];
        polylines.add(Polyline(
          polylineId: PolylineId('route_$i'),
          points: leg.polylinePoints,
          color: colors[i % colors.length],
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ));
      }

      setState(() {
        _polylines = polylines;
        _currentRoute = routeResponse;
      });

      final totalKm = routeResponse.getFormattedDistance();
      final totalTime = routeResponse.getFormattedDuration();
      final avgSpeed = (routeResponse.totalDistance / (routeResponse.totalDuration / 3600.0)).toStringAsFixed(0);
      
      // Determinar el tipo de inicio para el mensaje
      final esInicioTienda = _asignacionActiva?.ruta.coordenadasInicio.isEmpty == true ||
          _asignacionActiva?.ruta.coordenadasInicio == '${tienda.latitud}, ${tienda.longitud}';
      
      final tipoInicio = esInicioTienda ? 'desde tienda' : 'desde ubicación actual';
      
      _showSuccessSnackBar(
          '🛣️ Ruta calculada: $totalKm en $totalTime (${avgSpeed} km/h) - $tipoInicio'
      );
    } catch (e) {
      _showErrorSnackBar('Error calculando ruta: ${e.toString().contains('API') ? 'Problema con Google Maps API' : 'Error de conexión'}');
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }

  void _fitMarkersToScreen() {
    if (_markers.isEmpty || _mapController == null) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (final marker in _markers) {
      minLat = math.min(minLat, marker.position.latitude);
      maxLat = math.max(maxLat, marker.position.latitude);
      minLng = math.min(minLng, marker.position.longitude);
      maxLng = math.max(maxLng, marker.position.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    final padding = isTablet ? 120.0 : 80.0;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  void _toggleDeliveryList() {
    setState(() => _showDeliveryList = !_showDeliveryList);
    if (_showDeliveryList) {
      _slideController.forward();
    } else {
      _slideController.reverse();
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
            ),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(isTablet ? 20 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
            ),
          ],
        ),
        backgroundColor: secondaryColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(isTablet ? 20 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  double _getMarkerHue(int index) {
    const hues = [
      BitmapDescriptor.hueRed,
      BitmapDescriptor.hueOrange,
      BitmapDescriptor.hueYellow,
      BitmapDescriptor.hueMagenta,
      BitmapDescriptor.hueViolet,
      BitmapDescriptor.hueCyan,
    ];
    return hues[index % hues.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: _buildAppBar(),
      body: _isLoadingLocation
          ? _buildLoadingScreen()
          : _buildMapContent(),
      floatingActionButton: _entregasPendientes.isNotEmpty
          ? _buildFloatingButtons()
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      title: Text(
        'Mapa de Entregas',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: isTablet ? 22 : 18,
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: isTablet ? 20 : 16),
          child: IconButton(
            icon: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isLoadingRoute ? _pulseAnimation.value : 1.0,
                  child: Icon(
                    Icons.refresh_rounded,
                    size: isTablet ? 28 : 24,
                  ),
                );
              },
            ),
            onPressed: _isLoadingRoute ? null : _initializeMap,
            tooltip: 'Actualizar',
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 32 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: isTablet ? 60 : 40,
                  height: isTablet ? 60 : 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                SizedBox(height: isTablet ? 24 : 16),
                Text(
                  'Obteniendo ubicación...',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                Text(
                  'Por favor, espera un momento',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    return Consumer<TiendaProvider>(
      builder: (context, tiendaProvider, child) {
        if (tiendaProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (tiendaProvider.error != null) {
          return _buildErrorScreen(tiendaProvider.error!);
        }

        if (_entregasPendientes.isEmpty) {
          return _buildEmptyState();
        }

        return Stack(
          children: [
            _buildGoogleMap(),
            if (_isLoadingRoute) _buildLoadingOverlay(),
            _buildRouteInfoCard(),
            _buildRouteInfoBottomPanel(),
            if (_showDeliveryList) _buildDeliveryListSlider(),
          ],
        );
      },
    );
  }

  Widget _buildErrorScreen(String error) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(isTablet ? 40 : 32),
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: isTablet ? 80 : 64,
              color: errorColor.withOpacity(0.7),
            ),
            SizedBox(height: isTablet ? 24 : 16),
            Text(
              'Oops! Algo salió mal',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isTablet ? 32 : 24),
            ElevatedButton.icon(
              onPressed: _initializeMap,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 24,
                  vertical: isTablet ? 16 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Stack(
      children: [
        _buildGoogleMap(),
        Center(
          child: Container(
            margin: EdgeInsets.all(isTablet ? 40 : 32),
            padding: EdgeInsets.all(isTablet ? 32 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    size: isTablet ? 64 : 48,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: isTablet ? 24 : 16),
                Text(
                  'No hay entregas pendientes',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: isTablet ? 16 : 12),
                Text(
                  'Acepta asignaciones para ver las rutas aquí',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      onMapCreated: (controller) => _mapController = controller,
      initialCameraPosition: CameraPosition(
        target: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(-17.770231, -63.177627),
        zoom: isTablet ? 15 : 14,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapType: MapType.normal,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
      style: '''[
        {
          "featureType": "poi",
          "elementType": "labels",
          "stylers": [{"visibility": "off"}]
        },
        {
          "featureType": "transit",
          "elementType": "labels",
          "stylers": [{"visibility": "off"}]
        }
      ]''',
    );
  }

  Widget _buildLoadingOverlay() {
  return Positioned(
    top: isTablet ? 20 : 12,
    left: isTablet ? 20 : 12,
    right: isTablet ? 20 : 12,
    child: FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 12 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: isTablet ? 18 : 16,
              height: isTablet ? 18 : 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            SizedBox(width: isTablet ? 12 : 10),
            Text(
              'Calculando ruta...',
              style: TextStyle(
                fontSize: isTablet ? 14 : 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildRouteInfoCard() {
  return Positioned(
    top: isTablet ? 20 : 12,
    left: isTablet ? 20 : 12,
    right: isTablet ? 20 : 12,
    child: FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 12 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 8 : 6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.route,
                color: primaryColor,
                size: isTablet ? 18 : 16,
              ),
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ruta Asignada',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 14 : 13,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    '${_entregasPendientes.length} entregas',
                    style: TextStyle(
                      fontSize: isTablet ? 12 : 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 8 : 6,
                vertical: isTablet ? 4 : 3,
              ),
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: isTablet ? 12 : 10,
                    color: secondaryColor,
                  ),
                  SizedBox(width: isTablet ? 4 : 3),
                  Text(
                    'Activa',
                    style: TextStyle(
                      fontSize: isTablet ? 10 : 9,
                      fontWeight: FontWeight.w600,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildDeliveryListSlider() {
    final listHeight = screenHeight * (isTablet ? 0.5 : 0.4);
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: listHeight,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: isTablet ? 60 : 40,
                height: isTablet ? 6 : 4,
                margin: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
                child: Row(
                  children: [
                    Text(
                      'Lista de Entregas',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _toggleDeliveryList,
                      icon: Icon(
                        Icons.close,
                        size: isTablet ? 28 : 24,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
                  itemCount: _entregasPendientes.length,
                  itemBuilder: (context, index) {
                    final entrega = _entregasPendientes[index];
                    return _buildDeliveryCard(entrega, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(EntregaDetalle entrega, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(isTablet ? 20 : 16),
        leading: Container(
          width: isTablet ? 48 : 40,
          height: isTablet ? 48 : 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          entrega.cliente.nombreCompleto,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 16 : 15,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isTablet ? 8 : 6),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: isTablet ? 16 : 14,
                  color: Colors.grey[500],
                ),
                SizedBox(width: isTablet ? 6 : 4),
                Expanded(
                  child: Text(
                    entrega.cliente.direccion,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 8 : 6),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 10 : 8,
                    vertical: isTablet ? 4 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Bs. ${entrega.pedido.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: secondaryColor,
                      fontSize: isTablet ? 14 : 13,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: isTablet ? 14 : 12,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: isTablet ? 4 : 2),
                    Text(
                      entrega.cliente.telefono,
                      style: TextStyle(
                        fontSize: isTablet ? 13 : 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: isTablet ? 18 : 16,
        ),
        onTap: () => _focusOnDelivery(entrega),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "list",
          onPressed: _toggleDeliveryList,
          backgroundColor: Colors.white,
          foregroundColor: primaryColor,
          elevation: 8,
          child: AnimatedRotation(
            turns: _showDeliveryList ? 0.5 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _showDeliveryList ? Icons.close : Icons.list_alt,
              size: isTablet ? 28 : 24,
            ),
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        FloatingActionButton(
          heroTag: "location",
          onPressed: () {
            if (_currentPosition != null && _mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    zoom: 16,
                  ),
                ),
              );
            }
          },
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 8,
          child: Icon(
            Icons.my_location,
            size: isTablet ? 28 : 24,
          ),
        ),
      ],
    );
  }

  void _focusOnDelivery(EntregaDetalle entrega) {
    final coords = entrega.coordenadasFin.split(',');
    if (coords.length >= 2) {
      final lat = double.tryParse(coords[0].trim());
      final lng = double.tryParse(coords[1].trim());
      if (lat != null && lng != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(lat, lng),
              zoom: isTablet ? 18 : 17,
              bearing: 0,
              tilt: 45,
            ),
          ),
        );
        _showSuccessSnackBar('Enfocando: ${entrega.cliente.nombreCompleto}');
        _toggleDeliveryList(); // Cerrar la lista después de seleccionar
      }
    }
  }

  Widget _buildRouteInfoBottomPanel() {
  if (_currentRoute == null || _selectedTienda == null) {
    return const SizedBox.shrink();
  }

  final route = _currentRoute!;
  final tienda = _selectedTienda!;
  final bottomPosition = _showDeliveryList 
      ? screenHeight * (isTablet ? 0.5 : 0.4) + 16
      : isTablet ? 90 : 70;

  return Positioned(
    bottom: bottomPosition.toDouble(),
    left: isTablet ? 16 : 8,
    right: isTablet ? 16 : 8,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: _buildCompactRouteInfo(route, tienda),
    ),
  );
}

// Agregar este nuevo método para la información compacta de la ruta:

Widget _buildCompactRouteInfo(RouteResponse route, Tienda tienda) {
  return Container(
    padding: EdgeInsets.all(isTablet ? 12 : 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header compacto
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 8 : 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.route,
                color: Colors.white,
                size: isTablet ? 16 : 14,
              ),
            ),
            SizedBox(width: isTablet ? 10 : 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tienda.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 14 : 13,
                      color: Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_entregasPendientes.length} entregas - sin retorno',
                    style: TextStyle(
                      fontSize: isTablet ? 11 : 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 8 : 6,
                vertical: isTablet ? 4 : 3,
              ),
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(route.totalDistance / (route.totalDuration / 3600.0)).toStringAsFixed(0)} km/h',
                style: TextStyle(
                  fontSize: isTablet ? 10 : 9,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 10 : 8),
        // Información en fila compacta
        Row(
          children: [
            Expanded(
              child: _buildCompactInfoItem(
                Icons.straighten,
                route.getFormattedDistance(),
                primaryColor,
              ),
            ),
            SizedBox(width: isTablet ? 8 : 6),
            Expanded(
              child: _buildCompactInfoItem(
                Icons.access_time,
                route.getFormattedDuration(),
                accentColor,
              ),
            ),
            SizedBox(width: isTablet ? 8 : 6),
            Expanded(
              child: _buildCompactInfoItem(
                Icons.local_shipping,
                '${_entregasPendientes.length}',
                const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// Agregar este método para los items compactos:

Widget _buildCompactInfoItem(IconData icon, String value, Color color) {
  return Container(
    padding: EdgeInsets.symmetric(
      vertical: isTablet ? 8 : 6,
      horizontal: isTablet ? 6 : 4,
    ),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: isTablet ? 16 : 14,
        ),
        SizedBox(height: isTablet ? 4 : 3),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 11 : 10,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
}
