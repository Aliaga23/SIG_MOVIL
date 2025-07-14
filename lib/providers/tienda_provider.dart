import 'package:flutter/foundation.dart';
import '../models/tienda_models.dart';
import '../services/tienda_service.dart';

class TiendaProvider extends ChangeNotifier {
  final TiendaService _tiendaService = TiendaService();

  List<Tienda> _tiendas = [];
  bool _isLoading = false;
  String? _error;

  List<Tienda> get tiendas => _tiendas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Tienda? get tiendaPrincipal => _tiendas.isNotEmpty ? _tiendas.first : null;

  Future<void> loadTiendas() async {
    _setLoading(true);
    _error = null;

    try {
      _tiendas = await _tiendaService.getTiendas();
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
    _tiendas = [];
    _error = null;
    notifyListeners();
  }
}
