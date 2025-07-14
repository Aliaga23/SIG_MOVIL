import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class RouteService {
  static const String _apiKey = 'AIzaSyDgf7HvH-3Ay8UKFx2FabB2Ym8xN1QMRAQ'; 
  
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  static Future<RouteResponse> getOptimizedRoute({
    required LatLng origin,
    required List<LatLng> waypoints,
    LatLng? destination,
    bool optimizeWaypoints = true,
  }) async {
    try {
      if (waypoints.length == 1 && destination == null) {
        final singleDestination = waypoints.first;
        final params = {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${singleDestination.latitude},${singleDestination.longitude}',
          'mode': 'driving',
          'language': 'es',
          'region': 'bo',
          'units': 'metric',
          'traffic_model': 'best_guess',
          'departure_time': 'now',
          'key': _apiKey,
        };

        final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
        
        print('🚗 Calculando ruta simple: origen -> destino (1 entrega)');
        final response = await http.get(uri);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
            final routeResponse = RouteResponse.fromJson(data);
            print(' Ruta simple calculada: ${routeResponse.getFormattedDistance()} en ${routeResponse.getFormattedDuration()}');
            return routeResponse;
          } else {
            print(' Error de Google Directions: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
            throw Exception('Google Directions API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          }
        } else {
          print(' HTTP Error: ${response.statusCode}');
          throw Exception('HTTP Error: ${response.statusCode}');
        }
      }

      final waypointsString = waypoints
          .map((point) => '${point.latitude},${point.longitude}')
          .join('|');
      
      final params = {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': destination != null
            ? '${destination.latitude},${destination.longitude}'
            : '${waypoints.last.latitude},${waypoints.last.longitude}', // Último waypoint como destino
        'waypoints': waypoints.length > 1 && optimizeWaypoints 
            ? 'optimize:true|$waypointsString'
            : waypointsString,
        'mode': 'driving', // Modo de conducción para auto/moto
        'language': 'es',
        'region': 'bo', // Bolivia
        'units': 'metric',
        'traffic_model': 'best_guess', // Considerar tráfico
        'departure_time': 'now', // Partir ahora para cálculo de tráfico real
        'alternatives': 'false', // Solo la mejor ruta
        'key': _apiKey,
      };

      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
      
      print('🚗 Calculando ruta optimizada para vehículo...');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final routeResponse = RouteResponse.fromJson(data);
          print('✅ Ruta calculada: ${routeResponse.getFormattedDistance()} en ${routeResponse.getFormattedDuration()}');
          return routeResponse;
        } else {
          print('⚠️ Error de Google Directions: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          throw Exception('Google Directions API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error getting route: $e');
      // Fallback: crear una ruta simple pero más realista
      return _createRealisticFallbackRoute(origin, waypoints, destination);
    }
  }

  static List<LatLng> decodePolyline(String encoded) {
    try {
      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(encoded);
      
      return decodedPoints
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } catch (e) {
      print('Error decoding polyline: $e');
      return [];
    }
  }

  /// Crea una ruta realista como fallback cuando la API falla
  static RouteResponse _createRealisticFallbackRoute(
    LatLng origin, 
    List<LatLng> waypoints, 
    LatLng? destination
  ) {
    final allPoints = [origin, ...waypoints];
    if (destination != null) allPoints.add(destination);
    
    // Crear segmentos con estimaciones más realistas para Bolivia
    final legs = <RouteLeg>[];
    for (int i = 0; i < allPoints.length - 1; i++) {
      final start = allPoints[i];
      final end = allPoints[i + 1];
      
      final distanceKm = _calculateDistance(start, end);
      
      legs.add(RouteLeg(
        startLocation: start,
        endLocation: end,
        distance: distanceKm,
        duration: _estimateRealisticDuration(distanceKm, i == 0), // Primer tramo vs entregas
        polylinePoints: [start, end], // Línea recta como fallback
      ));
    }
    
    return RouteResponse(
      legs: legs,
      optimizedWaypointOrder: List.generate(waypoints.length, (index) => index),
      totalDistance: legs.fold(0.0, (sum, leg) => sum + leg.distance),
      totalDuration: legs.fold(0, (sum, leg) => sum + leg.duration),
    );
  }

  /// Estima la duración realista del viaje considerando condiciones de Bolivia
  static int _estimateRealisticDuration(double distanceKm, bool isMainRoute) {
    double speedKmh;
    
    if (isMainRoute) {
      // Ruta principal: velocidad más alta en avenidas
      if (distanceKm <= 2) {
        speedKmh = 25.0; // Tráfico urbano denso
      } else if (distanceKm <= 5) {
        speedKmh = 35.0; // Avenidas principales
      } else {
        speedKmh = 45.0; // Carreteras
      }
    } else {
      // Entre entregas: velocidad reducida por calles residenciales
      if (distanceKm <= 1) {
        speedKmh = 20.0; // Calles residenciales
      } else if (distanceKm <= 3) {
        speedKmh = 30.0; // Calles secundarias
      } else {
        speedKmh = 40.0; // Avenidas
      }
    }
    
    // Agregar tiempo extra por paradas, semáforos, etc.
    final baseTime = (distanceKm / speedKmh) * 3600; // en segundos
    final extraTime = distanceKm * 30; // 30 segundos extra por km para paradas
    
    return (baseTime + extraTime).round();
  }

  /// Calcula la distancia aproximada entre dos puntos (fórmula de Haversine)
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Radio de la Tierra en km
    
    final lat1Rad = point1.latitude * (math.pi / 180);
    final lat2Rad = point2.latitude * (math.pi / 180);
    final deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    final deltaLngRad = (point2.longitude - point1.longitude) * (math.pi / 180);
    
    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * 
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    
    final c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  static Future<bool> verifyApiKey() async {
    try {
      final params = {
        'origin': '-17.770231,-63.177627', // Coordenadas de Santa Cruz
        'destination': '-17.780231,-63.187627', // Punto cercano
        'mode': 'driving',
        'key': _apiKey,
      };

      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          print('✅ API Key de Google Maps verificada correctamente');
          return true;
        } else if (data['status'] == 'REQUEST_DENIED') {
          print('❌ API Key inválida o sin permisos: ${data['error_message']}');
          return false;
        } else {
          print('⚠️ Respuesta inesperada de Google API: ${data['status']}');
          return false;
        }
      } else {
        print('❌ Error HTTP al verificar API Key: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 Error verificando API Key: $e');
      return false;
    }
  }
}

class RouteResponse {
  final List<RouteLeg> legs;
  final List<int> optimizedWaypointOrder;
  final double totalDistance;
  final int totalDuration;

  RouteResponse({
    required this.legs,
    required this.optimizedWaypointOrder,
    required this.totalDistance,
    required this.totalDuration,
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    final route = json['routes'][0];
    final legs = <RouteLeg>[];
    
    // Procesar cada tramo de la ruta
    for (final legData in route['legs']) {
      legs.add(RouteLeg.fromJson(legData));
    }

    // Extraer el orden optimizado de waypoints si está disponible
    final waypointOrder = <int>[];
    if (route['waypoint_order'] != null) {
      for (final index in route['waypoint_order']) {
        waypointOrder.add(index as int);
      }
    }

    // Calcular totales a partir de los datos reales de Google
    double totalDistance = 0;
    int totalDuration = 0;
    
    for (final leg in legs) {
      totalDistance += leg.distance;
      totalDuration += leg.duration;
    }

    print('Ruta procesada: ${totalDistance.toStringAsFixed(2)} km en ${(totalDuration/60).toStringAsFixed(0)} min');

    return RouteResponse(
      legs: legs,
      optimizedWaypointOrder: waypointOrder,
      totalDistance: totalDistance,
      totalDuration: totalDuration,
    );
  }

  List<LatLng> getAllRoutePoints() {
    final allPoints = <LatLng>[];
    for (final leg in legs) {
      allPoints.addAll(leg.polylinePoints);
    }
    return allPoints;
  }

  /// Obtiene la duración total formateada
  String getFormattedDuration() {
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  /// Obtiene la distancia total formateada
  String getFormattedDistance() {
    if (totalDistance >= 1) {
      return '${totalDistance.toStringAsFixed(1)} km';
    } else {
      return '${(totalDistance * 1000).round()} m';
    }
  }
}

/// Modelo para un tramo de la ruta
class RouteLeg {
  final LatLng startLocation;
  final LatLng endLocation;
  final double distance; // en kilómetros
  final int duration; // en segundos
  final List<LatLng> polylinePoints;

  RouteLeg({
    required this.startLocation,
    required this.endLocation,
    required this.distance,
    required this.duration,
    required this.polylinePoints,
  });

  factory RouteLeg.fromJson(Map<String, dynamic> json) {
    final startLoc = json['start_location'];
    final endLoc = json['end_location'];
    
    final start = LatLng(startLoc['lat'].toDouble(), startLoc['lng'].toDouble());
    final end = LatLng(endLoc['lat'].toDouble(), endLoc['lng'].toDouble());
    
    final distanceKm = json['distance']['value'] / 1000.0; // Convertir de metros a km
    final durationSec = json['duration']['value'] as int; 
    
    print(' Tramo: ${distanceKm.toStringAsFixed(2)} km, ${(durationSec/60).toStringAsFixed(0)} min');
    
    final polylinePoints = <LatLng>[];
    
    // Primero agregar el punto de inicio
    polylinePoints.add(start);
    
    // Procesar cada paso (step) de la ruta
    if (json['steps'] != null) {
      for (final step in json['steps']) {
        if (step['polyline'] != null && step['polyline']['points'] != null) {
          final encodedPolyline = step['polyline']['points'] as String;
          final decodedPoints = RouteService.decodePolyline(encodedPolyline);
          
          // Agregar todos los puntos decodificados
          for (final point in decodedPoints) {
            // Evitar duplicados comparando con el último punto agregado
            if (polylinePoints.isEmpty || 
                (polylinePoints.last.latitude != point.latitude || 
                 polylinePoints.last.longitude != point.longitude)) {
              polylinePoints.add(point);
            }
          }
        }
      }
    }
    
    // Asegurar que el punto final esté incluido
    if (polylinePoints.isEmpty || 
        (polylinePoints.last.latitude != end.latitude || 
         polylinePoints.last.longitude != end.longitude)) {
      polylinePoints.add(end);
    }
    
    print('📍 Puntos de ruta: ${polylinePoints.length} coordenadas');
    
    return RouteLeg(
      startLocation: start,
      endLocation: end,
      distance: distanceKm,
      duration: durationSec,
      polylinePoints: polylinePoints,
    );
  }
}
