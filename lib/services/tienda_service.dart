import 'package:dio/dio.dart';
import '../models/tienda_models.dart';

class TiendaService {
  static const String _baseUrl = 'https://sigbackend.up.railway.app';
  late final Dio _dio;

  TiendaService() {
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
  }

  Future<List<Tienda>> getTiendas({int skip = 0, int limit = 100}) async {
    try {
      final response = await _dio.get('/tiendas/', queryParameters: {
        'skip': skip,
        'limit': limit,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Tienda.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener tiendas: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Error del servidor: ${e.response?.statusCode}');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}
