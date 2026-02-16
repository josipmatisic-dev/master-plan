/// Trip logging service — records sailing trips and exports GPX/KML.
///
/// Manages trip lifecycle: start → record waypoints → stop → export.
/// Persists trip logs via CacheService for offline access.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/boat_position.dart';
import '../models/trip_log.dart';
import '../services/cache_service.dart';

/// Service for recording, storing, and exporting trip logs.
class TripLogService extends ChangeNotifier {
  final CacheService? _cache;
  TripLog? _activeTrip;
  final List<TripLog> _savedTrips = [];

  /// Minimum distance (meters) between waypoints to record.
  static const double minWaypointDistanceM = 10.0;

  /// Cache key prefix for saved trips.
  static const String _cacheKeyPrefix = 'trip_';

  /// Cache key for the trip index.
  static const String _indexKey = 'trip_index';

  /// Creates a trip log service with optional cache backend.
  TripLogService({CacheService? cacheService}) : _cache = cacheService;

  /// The currently recording trip, or null.
  TripLog? get activeTrip => _activeTrip;

  /// Whether a trip is being recorded.
  bool get isRecording => _activeTrip != null;

  /// All saved (completed) trips.
  List<TripLog> get savedTrips => List.unmodifiable(_savedTrips);

  /// Load saved trips from cache.
  Future<void> init() async {
    if (_cache == null || !_cache.isInitialized) return;
    final indexJson = _cache.get(_indexKey);
    if (indexJson == null) return;

    try {
      final ids = indexJson.split(',').where((s) => s.isNotEmpty);
      for (final id in ids) {
        final json = _cache.getJson('$_cacheKeyPrefix$id');
        if (json != null) {
          _savedTrips.add(TripLog.fromJson(json));
        }
      }
      debugPrint('TripLogService: Loaded ${_savedTrips.length} saved trips');
    } catch (e) {
      debugPrint('TripLogService: Failed to load trips — $e');
    }
  }

  /// Start recording a new trip.
  void startTrip({String name = 'Trip'}) {
    if (_activeTrip != null) {
      debugPrint('TripLogService: Already recording — stop first');
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _activeTrip = TripLog(
      id: id,
      name: name,
      startTime: DateTime.now(),
      waypoints: const [],
    );
    notifyListeners();
    debugPrint('TripLogService: Started trip "$name" ($id)');
  }

  /// Stop the active trip and save it.
  Future<TripLog?> stopTrip() async {
    if (_activeTrip == null) return null;

    final completed = _activeTrip!.copyWith(endTime: DateTime.now());
    _savedTrips.add(completed);
    _activeTrip = null;

    await _persistTrip(completed);
    notifyListeners();
    debugPrint(
      'TripLogService: Stopped trip "${completed.name}" — '
      '${completed.waypoints.length} waypoints, '
      '${completed.distanceNm.toStringAsFixed(1)} nm',
    );
    return completed;
  }

  /// Add a waypoint from a boat position fix.
  void addWaypoint(BoatPosition position) {
    if (_activeTrip == null) return;

    final waypoints = _activeTrip!.waypoints;

    // Distance filter: skip if too close to last waypoint
    if (waypoints.isNotEmpty) {
      final last = waypoints.last;
      final distM = _haversineMeters(
        last.lat,
        last.lng,
        position.latitude,
        position.longitude,
      );
      if (distM < minWaypointDistanceM) return;
    }

    final newWp = TripWaypoint.fromPosition(position);
    final newWaypoints = [...waypoints, newWp];

    // Update cumulative distance
    double addedNm = 0;
    if (waypoints.isNotEmpty) {
      final last = waypoints.last;
      addedNm = _haversineMeters(
            last.lat,
            last.lng,
            newWp.lat,
            newWp.lng,
          ) /
          1852.0;
    }

    _activeTrip = _activeTrip!.copyWith(
      waypoints: newWaypoints,
      distanceNm: _activeTrip!.distanceNm + addedNm,
    );
    notifyListeners();
  }

  /// Delete a saved trip by ID.
  Future<void> deleteTrip(String id) async {
    _savedTrips.removeWhere((t) => t.id == id);
    await _cache?.delete('$_cacheKeyPrefix$id');
    await _persistIndex();
    notifyListeners();
  }

  // ============ Export ============

  /// Export a trip as GPX XML string with summary metadata.
  String exportGpx(TripLog trip) {
    final buf = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<gpx version="1.1" creator="SailStream"')
      ..writeln('  xmlns="http://www.topografix.com/GPX/1/1">')
      ..writeln('  <metadata>')
      ..writeln('    <name>${_xmlEscape(trip.name)}</name>')
      ..writeln('    <desc>Distance: ${trip.distanceNm.toStringAsFixed(2)} nm, '
          'Avg speed: ${trip.avgSpeedKnots.toStringAsFixed(1)} kts, '
          'Max speed: ${trip.maxSpeedKnots.toStringAsFixed(1)} kts, '
          'Waypoints: ${trip.waypoints.length}</desc>')
      ..writeln('    <time>${trip.startTime.toUtc().toIso8601String()}</time>')
      ..writeln('  </metadata>')
      ..writeln('  <trk>')
      ..writeln('    <name>${_xmlEscape(trip.name)}</name>')
      ..writeln('    <trkseg>');

    for (final wp in trip.waypoints) {
      buf.writeln(
        '      <trkpt lat="${wp.lat}" lon="${wp.lng}">'
        '<time>${wp.timestamp}</time>'
        '<speed>${wp.speedKnots}</speed>'
        '</trkpt>',
      );
    }

    buf
      ..writeln('    </trkseg>')
      ..writeln('  </trk>')
      ..writeln('</gpx>');

    return buf.toString();
  }

  /// Export a trip as KML XML string with summary metadata.
  String exportKml(TripLog trip) {
    final buf = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<kml xmlns="http://www.opengis.net/kml/2.2">')
      ..writeln('  <Document>')
      ..writeln('    <name>${_xmlEscape(trip.name)}</name>')
      ..writeln('    <description>Distance: '
          '${trip.distanceNm.toStringAsFixed(2)} nm, '
          'Avg speed: ${trip.avgSpeedKnots.toStringAsFixed(1)} kts, '
          'Max speed: ${trip.maxSpeedKnots.toStringAsFixed(1)} kts, '
          'Waypoints: ${trip.waypoints.length}</description>')
      ..writeln('    <Placemark>')
      ..writeln('      <name>Track</name>')
      ..writeln('      <LineString>')
      ..writeln('        <coordinates>');

    for (final wp in trip.waypoints) {
      buf.writeln('          ${wp.lng},${wp.lat},0');
    }

    buf
      ..writeln('        </coordinates>')
      ..writeln('      </LineString>')
      ..writeln('    </Placemark>')
      ..writeln('  </Document>')
      ..writeln('</kml>');

    return buf.toString();
  }

  /// Export a trip as CSV string with header row.
  String exportCsv(TripLog trip) {
    final buf = StringBuffer()
      ..writeln('timestamp,latitude,longitude,speed_knots,cog_degrees');
    for (final wp in trip.waypoints) {
      final cog = wp.cogDegrees?.toStringAsFixed(1) ?? '';
      buf.writeln(
        '${_csvEscape(wp.timestamp)},${wp.lat},${wp.lng},'
        '${wp.speedKnots},$cog',
      );
    }
    return buf.toString();
  }

  // ============ Persistence ============

  Future<void> _persistTrip(TripLog trip) async {
    if (_cache == null || !_cache.isInitialized) return;
    await _cache.putJson(
      '$_cacheKeyPrefix${trip.id}',
      trip.toJson(),
    );
    await _persistIndex();
  }

  Future<void> _persistIndex() async {
    if (_cache == null || !_cache.isInitialized) return;
    final ids = _savedTrips.map((t) => t.id).join(',');
    await _cache.put(_indexKey, ids);
  }

  // ============ Utilities ============

  /// Haversine distance in meters between two points.
  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusM = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadiusM * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;

  static String _xmlEscape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// Escapes a CSV field — quotes if it contains comma, quote, or newline.
  static String _csvEscape(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  @override
  void dispose() {
    // Stop recording if active
    if (_activeTrip != null) {
      stopTrip();
    }
    super.dispose();
  }
}
