import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../services/simple_location_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Método para login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _authService.login(request);

      // Guardar token de forma segura
      await _storage.write(key: 'access_token', value: response.accessToken);
      await _storage.write(key: 'token_type', value: response.tokenType);

      _user = User(email: email, role: 'distribuidor');

      // Iniciar tracking GPS automáticamente después del login
      SimpleLocationService.instance.startBackgroundTracking();

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Método para logout
  Future<void> logout() async {
    // Detener tracking GPS
    SimpleLocationService.instance.stop();
    
    await _storage.deleteAll();
    _user = null;
    notifyListeners();
  }

  // Verificar si el usuario ya está autenticado
  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      _user = User(email: '', role: '');
      notifyListeners();
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
}
