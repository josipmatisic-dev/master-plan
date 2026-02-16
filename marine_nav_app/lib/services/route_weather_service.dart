/// Route weather corridor service.
///
/// Samples weather data along a planned navigation route by
/// distributing query points at regular intervals along the
/// route legs, then fetching weather for those points.
library;

import 'dart:math';

import '../models/lat_lng.dart' as models;
import '../models/route.dart';
import '../models/weather_data.dart';
import 'geo_utils.dart';
import 'weather_api.dart';

/// Weather data sampled along a route corridor.
class RouteWeatherCorridor {
  /// Weather data for sampled points along the route.
  final WeatherData weather;

  /// The sample points used (lat, lng).
  final List<models.LatLng> samplePoints;

  /// Total route distance in nautical miles.
  final double totalDistanceNm;

  /// Creates a route weather corridor result.
  const RouteWeatherCorridor({
    required this.weather,
    required this.samplePoints,
    required this.totalDistanceNm,
  });
}

/// Fetches weather along a navigation route corridor.
class RouteWeatherService {
  final WeatherApiService _api;

  /// Maximum sample points per route to avoid API overload.
  static const int maxSamplePoints = 25;

  /// Minimum spacing between sample points in nautical miles.
  static const double minSpacingNm = 2.0;

  /// Creates a route weather service.
  RouteWeatherService({required WeatherApiService api}) : _api = api;

  /// Fetches weather data along the given [route].
  Future<RouteWeatherCorridor> fetchRouteWeather(Route route) async {
    if (route.waypoints.length < 2) {
      return RouteWeatherCorridor(
        weather: WeatherData.empty,
        samplePoints: const [],
        totalDistanceNm: 0,
      );
    }

    final samplePoints = distributeSamplePoints(route.waypoints);
    final totalNm = route.getTotalDistance();
    if (samplePoints.isEmpty) {
      return RouteWeatherCorridor(
        weather: WeatherData.empty,
        samplePoints: const [],
        totalDistanceNm: totalNm,
      );
    }

    final bbox = _computeBbox(samplePoints);

    final weather = await _api.fetchWeatherData(
      south: bbox.south,
      north: bbox.north,
      west: bbox.west,
      east: bbox.east,
      zoomLevel: 8,
    );

    return RouteWeatherCorridor(
      weather: weather,
      samplePoints: samplePoints,
      totalDistanceNm: totalNm,
    );
  }

  /// Distributes sample points along route legs proportional to distance.
  static List<models.LatLng> distributeSamplePoints(List<Waypoint> waypoints) {
    if (waypoints.length < 2) return [];

    final legDistances = <double>[];
    double totalNm = 0;
    for (var i = 0; i < waypoints.length - 1; i++) {
      final d = GeoUtils.distanceBetween(
        waypoints[i].position,
        waypoints[i + 1].position,
      );
      legDistances.add(d);
      totalNm += d;
    }

    if (totalNm < 0.01) {
      final _p = waypoints.first.position; return [models.LatLng(latitude: _p.latitude, longitude: _p.longitude)];
    }

    final idealPoints = max(2, (totalNm / minSpacingNm).ceil() + 1);
    final pointCount = min(idealPoints, maxSamplePoints);
    final spacing = totalNm / (pointCount - 1);

    final points = <models.LatLng>[];
    double traveled = 0;
    var legIdx = 0;

    for (var i = 0; i < pointCount; i++) {
      final targetDist = i * spacing;

      while (legIdx < legDistances.length - 1 &&
          traveled + legDistances[legIdx] < targetDist) {
        traveled += legDistances[legIdx];
        legIdx++;
      }

      final remaining = targetDist - traveled;
      final legDist = legDistances[legIdx];
      final fraction = legDist > 0 ? remaining / legDist : 0.0;

      final from = waypoints[legIdx].position;
      final to = waypoints[legIdx + 1].position;
      final lat = from.latitude + (to.latitude - from.latitude) * fraction;
      final lng = from.longitude + (to.longitude - from.longitude) * fraction;

      points.add(models.LatLng(latitude: lat, longitude: lng));
    }

    return points;
  }

  static _Bbox _computeBbox(List<models.LatLng> points) {
    double south = 90, north = -90, west = 180, east = -180;
    for (final p in points) {
      south = min(south, p.latitude);
      north = max(north, p.latitude);
      west = min(west, p.longitude);
      east = max(east, p.longitude);
    }
    const pad = 0.08;
    return _Bbox(
      south: south - pad,
      north: north + pad,
      west: west - pad,
      east: east + pad,
    );
  }
}

class _Bbox {
  final double south, north, west, east;
  const _Bbox({
    required this.south,
    required this.north,
    required this.west,
    required this.east,
  });
}
