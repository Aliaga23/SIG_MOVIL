import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/dashboard_models.dart';

class DashboardService {
  static const String _baseUrl = 'https://sigbackend.up.railway.app';
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DashboardService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
    ));

    // Interceptor para logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    // Interceptor para agregar el token automáticamente
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<DashboardData> getProfile() async {
    try {
      final response = await _dio.get('/distribuidores/mi-perfil');

      if (response.statusCode == 200) {
        return DashboardData.fromJson(response.data);
      } else {
        throw Exception('Error al obtener el perfil: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.statusCode == 401) {
          throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
        }
        throw Exception('Error del servidor: ${e.response?.statusCode}');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}
