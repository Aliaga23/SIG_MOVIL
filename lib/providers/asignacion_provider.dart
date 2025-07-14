import 'package:flutter/foundation.dart';
import '../models/asignacion_models.dart';
import '../services/asignacion_service.dart';

class AsignacionProvider extends ChangeNotifier {
  final AsignacionService _asignacionService = AsignacionService();

  List<Asignacion> _asignaciones = [];
  bool _isLoading = false;
  String? _error;

  List<Asignacion> get asignaciones => _asignaciones;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtrar solo asignaciones pendientes y aceptadas
  List<Asignacion> get asignacionesActivas =>
      _asignaciones.where((a) => a.esPendienteOAceptada).toList();

  // Asignaciones con entregas
  List<Asignacion> get asignacionesConEntregas =>
      asignacionesActivas.where((a) => a.tieneEntregas).toList();

  Future<void> loadAsignaciones() async {
    _setLoading(true);
    _error = null;

    try {
      _asignaciones = await _asignacionService.getMisEntregas();
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _asignaciones = [];
    _error = null;
    notifyListeners();
  }
  Future<bool> aceptarAsignacion(String asignacionId) async {
    try {
      await _asignacionService.aceptarAsignacion(asignacionId);
      
      // Actualizar el estado local de la asignación
      final index = _asignaciones.indexWhere((a) => a.id == asignacionId);
      if (index != -1) {
        _asignaciones[index] = _asignaciones[index].copyWith(estado: 'aceptada');
        notifyListeners();
      }
      
      // Recargar todas las asignaciones para obtener el estado más actualizado
      await loadAsignaciones();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rechazarAsignacion(String asignacionId) async {
    try {
      await _asignacionService.rechazarAsignacion(asignacionId);
      
      // Actualizar el estado local de la asignación
      final index = _asignaciones.indexWhere((a) => a.id == asignacionId);
      if (index != -1) {
        _asignaciones[index] = _asignaciones[index].copyWith(estado: 'rechazada');
        notifyListeners();
      }
      
      // Recargar todas las asignaciones para obtener el estado más actualizado
      await loadAsignaciones();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> completarEntrega({
    required String entregaId,
    required String coordenadasFin,
    required String estado, // 'entregado' o 'fallida'
    String observaciones = '',
  }) async {
    try {
      final response = await _asignacionService.completarEntrega(
        entregaId: entregaId,
        coordenadasFin: coordenadasFin,
        estado: estado,
        observaciones: observaciones,
      );
      
      // Recargar todas las asignaciones para obtener el estado más actualizado
      // Esto incluirá las nuevas coordenadas de inicio y la ruta reoptimizada
      await loadAsignaciones();
      
      return response;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
