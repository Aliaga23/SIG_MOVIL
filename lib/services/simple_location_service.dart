import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SimpleLocationService {
  static SimpleLocationService? _instance;
  static SimpleLocationService get instance => _instance ??= SimpleLocationService._();
  
  SimpleLocationService._();

  Timer? _timer;
  bool _isRunning = false;
  final _dio = Dio(BaseOptions(baseUrl: 'https://sigbackend.up.railway.app'));
  final _storage = const FlutterSecureStorage();

  void startBackgroundTracking() async {
    if (_isRunning) return;
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;
    
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 7), (timer) async {
      await _sendLocation();
    });
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
  }

  Future<void> _sendLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      final token = await _storage.read(key: 'access_token');
      if (token == null) return;

      final perfilResponse = await _dio.get(
        '/distribuidores/mi-perfil',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      final distribuidorId = perfilResponse.data['perfil']['id'];
      
      await _dio.patch(
        '/distribuidores/$distribuidorId/ubicacion',
        queryParameters: {
          'latitud': position.latitude,
          'longitud': position.longitude,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

    } catch (e) {
      // Silenciar errores
    }
  }

  bool get isRunning => _isRunning;
}
