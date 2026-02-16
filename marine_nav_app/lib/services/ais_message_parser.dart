/// AIS message parsing utilities for aisstream.io JSON payloads.
///
/// Extracts [AisTarget] from PositionReport, ShipStaticData,
/// and StandardClassBCSPositionReport message types.
library;

import '../models/ais_target.dart';
import '../models/lat_lng.dart';

/// Parses a raw aisstream.io JSON envelope into an [AisTarget].
///
/// Returns null if the message type is unsupported or data is invalid.
AisTarget? parseAisMessage(Map<String, dynamic> json) {
  final messageType = json['MessageType'] as String?;
  final metaData = _asStringMap(json['MetaData']);
  if (messageType == null || metaData == null) return null;

  final mmsi = metaData['MMSI'] as int? ?? 0;
  if (mmsi == 0) return null;

  final lat = (metaData['latitude'] as num?)?.toDouble() ?? 0.0;
  final lng = (metaData['longitude'] as num?)?.toDouble() ?? 0.0;
  final shipName = metaData['ShipName'] as String?;

  final timeStr = metaData['time_utc'] as String?;
  final timestamp = timeStr != null
      ? DateTime.tryParse(timeStr) ?? DateTime.now()
      : DateTime.now();

  final message = _asStringMap(json['Message']) ?? {};

  if (messageType == 'PositionReport') {
    return _parsePositionReport(
      mmsi,
      lat,
      lng,
      shipName,
      timestamp,
      message,
    );
  } else if (messageType == 'StandardClassBCSPositionReport') {
    return _parseClassBPosition(
      mmsi,
      lat,
      lng,
      shipName,
      timestamp,
      message,
    );
  } else if (messageType == 'ShipStaticData') {
    return _parseStaticData(
      mmsi,
      lat,
      lng,
      shipName,
      timestamp,
      message,
    );
  }
  return null;
}

AisTarget _parsePositionReport(
  int mmsi,
  double lat,
  double lng,
  String? name,
  DateTime ts,
  Map<String, dynamic> msg,
) {
  final report = _asStringMap(msg['PositionReport']) ?? {};
  return AisTarget(
    mmsi: mmsi,
    position: LatLng(latitude: lat, longitude: lng),
    lastUpdate: ts,
    name: name,
    sog: (report['Sog'] as num?)?.toDouble(),
    cog: (report['Cog'] as num?)?.toDouble(),
    heading: report['TrueHeading'] as int?,
    navStatus: AisNavStatus.fromCode(
      report['NavigationalStatus'] as int? ?? 15,
    ),
    rateOfTurn: (report['RateOfTurn'] as num?)?.toDouble(),
  );
}

AisTarget _parseClassBPosition(
  int mmsi,
  double lat,
  double lng,
  String? name,
  DateTime ts,
  Map<String, dynamic> msg,
) {
  final report = _asStringMap(msg['StandardClassBCSPositionReport']) ?? {};
  return AisTarget(
    mmsi: mmsi,
    position: LatLng(latitude: lat, longitude: lng),
    lastUpdate: ts,
    name: name,
    sog: (report['Sog'] as num?)?.toDouble(),
    cog: (report['Cog'] as num?)?.toDouble(),
    heading: report['TrueHeading'] as int?,
  );
}

AisTarget _parseStaticData(
  int mmsi,
  double lat,
  double lng,
  String? name,
  DateTime ts,
  Map<String, dynamic> msg,
) {
  final data = _asStringMap(msg['ShipStaticData']) ?? {};
  final dim = _asStringMap(data['Dimension']);
  List<int>? dimensions;
  if (dim != null) {
    dimensions = [
      dim['A'] as int? ?? 0,
      dim['B'] as int? ?? 0,
      dim['C'] as int? ?? 0,
      dim['D'] as int? ?? 0,
    ];
  }

  return AisTarget(
    mmsi: mmsi,
    position: LatLng(latitude: lat, longitude: lng),
    lastUpdate: ts,
    name: name,
    imo: data['ImoNumber'] as int?,
    callSign: data['CallSign'] as String?,
    shipType: data['Type'] as int? ?? 0,
    dimensions: dimensions,
    draught: (data['MaximumStaticDraught'] as num?)?.toDouble(),
    destination: data['Destination'] as String?,
  );
}

/// Safely cast a dynamic value to Map<String, dynamic>.
Map<String, dynamic>? _asStringMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
