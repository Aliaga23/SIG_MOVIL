import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_models.dart';
import '../widgets/dashboard_widgets.dart';
import 'asignaciones_screen.dart';
import 'mapa_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          const AsignacionesScreen(),
          const MapaScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: () {
          Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
        },
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ) : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final titles = ['Dashboard - SIG Shoes', 'Mis Asignaciones', 'Mapa de Entregas'];
    
    return AppBar(
      title: Text(
        titles[_currentIndex],
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notificaciones próximamente')),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'logout') {
              _handleLogout();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline),
                  SizedBox(width: 12),
                  Text('Mi Perfil'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined),
                  SizedBox(width: 12),
                  Text('Configuración'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue[600],
      unselectedItemColor: Colors.grey[600],
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Asignaciones',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Mapa',
        ),
      ],
    );
  }

  Widget _buildDashboardTab() {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.isLoading) {
          return _buildLoadingState();
        }

        if (dashboardProvider.error != null) {
          return _buildErrorState(dashboardProvider);
        }

        if (dashboardProvider.dashboardData == null) {
          return _buildEmptyState();
        }

        return _buildDashboard(dashboardProvider.dashboardData!);
      },
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
            'Cargando dashboard...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(DashboardProvider provider) {
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
              'Error al cargar datos',
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
              onPressed: () => provider.loadDashboardData(),
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

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No hay datos disponibles',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildDashboard(DashboardData data) {
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildWelcomeCard(data.perfil),
            _buildStatsGrid(data.estadisticas),
            _buildProfileCard(data.perfil),
            _buildVehicleCard(data.vehiculo),
            _buildStatusCard(data.estado),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(Perfil perfil) {
    return DashboardCard(
      title: '¡Bienvenido!',
      color: Colors.blue[600],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            perfil.nombreCompleto,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Distribuidor ${perfil.activo ? "Activo" : "Inactivo"} - ${perfil.estado}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white.withOpacity(0.9), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  perfil.ubicacion.coordenadas,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Estadisticas stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Asignaciones Hoy',
                value: stats.asignaciones.hoy.toString(),
                icon: Icons.assignment,
                color: Colors.blue[600]!,
                subtitle: 'Total: ${stats.asignaciones.total}',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Entregas Completadas',
                value: stats.entregas.completadas.toString(),
                icon: Icons.check_circle,
                color: Colors.green[600]!,
                subtitle: 'Total: ${stats.entregas.total}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Pendientes',
                value: stats.entregas.pendientes.toString(),
                icon: Icons.pending,
                color: Colors.orange[600]!,
                subtitle: 'En proceso',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Tasa de Éxito',
                value: '${stats.entregas.tasaExito.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: stats.entregas.tasaExito >= 80 ? Colors.green[600]! : Colors.red[600]!,
                subtitle: 'Promedio',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCard(Perfil perfil) {
    return DashboardCard(
      title: 'Información Personal',
      child: Column(
        children: [
          InfoRow(
            icon: Icons.person,
            label: 'Nombre',
            value: perfil.nombreCompleto,
          ),
          InfoRow(
            icon: Icons.email,
            label: 'Email',
            value: perfil.email,
          ),
          InfoRow(
            icon: Icons.phone,
            label: 'Teléfono',
            value: perfil.telefono,
          ),
          InfoRow(
            icon: Icons.credit_card,
            label: 'Carnet',
            value: perfil.carnet,
          ),
          InfoRow(
            icon: Icons.badge,
            label: 'Licencia',
            value: perfil.licencia,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Vehiculo vehiculo) {
    return DashboardCard(
      title: 'Mi Vehículo',
      child: Column(
        children: [
          InfoRow(
            icon: Icons.directions_car,
            label: 'Marca/Modelo',
            value: '${vehiculo.marca} ${vehiculo.modelo}',
          ),
          InfoRow(
            icon: Icons.calendar_today,
            label: 'Año',
            value: vehiculo.anio.toString(),
          ),
          InfoRow(
            icon: Icons.confirmation_number,
            label: 'Placa',
            value: vehiculo.placa,
          ),
          InfoRow(
            icon: Icons.local_shipping,
            label: 'Tipo',
            value: vehiculo.tipoVehiculo,
          ),
          InfoRow(
            icon: Icons.scale,
            label: 'Capacidad',
            value: '${vehiculo.capacidadCarga} kg',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Estado estado) {
    return DashboardCard(
      title: 'Estado Actual',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          StatusBadge(
            text: 'Vehículo Registrado',
            isActive: estado.tieneVehiculo,
          ),
          StatusBadge(
            text: 'Puede Trabajar',
            isActive: estado.puedeTrabajar,
          ),
          StatusBadge(
            text: 'Ubicación Configurada',
            isActive: estado.ubicacionConfigurada,
          ),
          StatusBadge(
            text: 'Disponible para Asignaciones',
            isActive: estado.disponibleParaAsignaciones,
          ),
          StatusBadge(
            text: 'Estado: ${estado.estadoDistribuidor}',
            isActive: estado.estadoDistribuidor == 'disponible',
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
              Provider.of<DashboardProvider>(context, listen: false).clearData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
