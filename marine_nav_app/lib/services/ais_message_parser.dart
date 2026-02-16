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
    final metaData = json['MetaData'] as Map<String, dynamic>?;
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

    final message = json['Message'] as Map<String, dynamic>? ?? {};

    if (messageType == 'PositionReport') {
      return _parsePositionReport(
        mmsi, lat, lng, shipName, timestamp, message,
      );
    } else if (messageType == 'StandardClassBCSPositionReport') {
      return _parseClassBPosition(
        mmsi, lat, lng, shipName, timestamp, message,
      );
    } else if (messageType == 'ShipStaticData') {
      return _parseStaticData(
        mmsi, lat, lng, shipName, timestamp, message,
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
    final report = msg['PositionReport'] as Map<String, dynamic>? ?? {};
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
    final report =
        msg['StandardClassBCSPositionReport'] as Map<String, dynamic>? ?? {};
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
    final data = msg['ShipStaticData'] as Map<String, dynamic>? ?? {};
    final dim = data['Dimension'] as Map<String, dynamic>?;
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
