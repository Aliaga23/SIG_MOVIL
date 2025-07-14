import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/asignacion_models.dart';

class AsignacionService {
  static const String _baseUrl = 'https://sigbackend.up.railway.app';
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AsignacionService() {
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

  Future<List<Asignacion>> getMisEntregas() async {
    try {
      final response = await _dio.get('/entregas/mis-entregas');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Asignacion.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener asignaciones: ${response.statusCode}');
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

  Future<Map<String, dynamic>> aceptarAsignacion(String asignacionId) async {
    try {
      final response = await _dio.patch('/entregas/asignacion/$asignacionId/aceptar');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error al aceptar asignación: ${response.statusCode}');
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

  Future<Map<String, dynamic>> rechazarAsignacion(String asignacionId) async {
    try {
      final response = await _dio.patch('/entregas/asignacion/$asignacionId/rechazar');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error al rechazar asignación: ${response.statusCode}');
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

  Future<Map<String, dynamic>> completarEntrega({
    required String entregaId,
    required String coordenadasFin,
    required String estado, // 'entregado' o 'fallida'
    String observaciones = '',
  }) async {
    try {
      final response = await _dio.patch(
        '/entregas/completar/$entregaId',
        data: {
          'coordenadas_fin': coordenadasFin,
          'estado': estado,
          'observaciones': observaciones,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error al completar entrega: ${response.statusCode}');
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
