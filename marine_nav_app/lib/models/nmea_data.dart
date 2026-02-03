import 'package:latlong2/latlong.dart';

/// Aggregate model containing all parsed NMEA data from various sentence types.
/// Updated whenever new sentences are received and parsed.
class NMEAData {
  /// GPS position fix data (from GPGGA)
  final GPGGAData? gpgga;

  /// Recommended minimum position data (from GPRMC)
  final GPRMCData? gprmc;

  /// Track and ground speed data (from GPVTG)
  final GPVTGData? gpvtg;

  /// Wind data (from MWV)
  final MWVData? mwv;

  /// Depth data (from DPT)
  final DPTData? dpt;

  /// Timestamp when this data was last updated
  final DateTime timestamp;

  const NMEAData({
    this.gpgga,
    this.gprmc,
    this.gpvtg,
    this.mwv,
    this.dpt,
    required this.timestamp,
  });

  /// Convenience getter for current position
  /// Prefers GPRMC (includes COG/SOG) over GPGGA
  LatLng? get position => gprmc?.position ?? gpgga?.position;

  /// Convenience getter for speed over ground (knots)
  double? get speedOverGroundKnots => gpvtg?.speedKnots ?? gprmc?.speedKnots;

  /// Convenience getter for course over ground (degrees true)
  double? get courseOverGroundDegrees => gpvtg?.trackTrue ?? gprmc?.trackTrue;

  /// Convenience getter for depth (meters)
  double? get depthMeters => dpt?.depthMeters;

  /// Convenience getter for wind speed (knots)
  double? get windSpeedKnots => mwv?.speedKnots;

  /// Convenience getter for wind direction (degrees)
  double? get windDirectionDegrees => mwv?.angleDegrees;

  /// Create a copy with updated fields
  NMEAData copyWith({
    GPGGAData? gpgga,
    GPRMCData? gprmc,
    GPVTGData? gpvtg,
    MWVData? mwv,
    DPTData? dpt,
    DateTime? timestamp,
  }) {
    return NMEAData(
      gpgga: gpgga ?? this.gpgga,
      gprmc: gprmc ?? this.gprmc,
      gpvtg: gpvtg ?? this.gpvtg,
      mwv: mwv ?? this.mwv,
      dpt: dpt ?? this.dpt,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// GPGGA - Global Positioning System Fix Data
/// Provides position, fix quality, and satellite information
class GPGGAData {
  final LatLng position;
  final DateTime time;
  final int fixQuality; // 0=invalid, 1=GPS, 2=DGPS
  final int satellites;
  final double? hdop; // Horizontal dilution of precision
  final double? altitudeMeters;

  const GPGGAData({
    required this.position,
    required this.time,
    required this.fixQuality,
    required this.satellites,
    this.hdop,
    this.altitudeMeters,
  });
}

/// GPRMC - Recommended Minimum Navigation Information
/// Provides position, speed, and course
class GPRMCData {
  final LatLng position;
  final DateTime time;
  final bool valid; // A=valid, V=warning
  final double? speedKnots;
  final double? trackTrue; // Course over ground (degrees true)

  const GPRMCData({
    required this.position,
    required this.time,
    required this.valid,
    this.speedKnots,
    this.trackTrue,
  });
}

/// GPVTG - Track and Ground Speed
/// Provides detailed speed and track information
class GPVTGData {
  final double? trackTrue; // Course over ground (degrees true)
  final double? trackMagnetic; // Course over ground (degrees magnetic)
  final double? speedKnots; // Speed over ground (knots)
  final double? speedKmh; // Speed over ground (km/h)

  const GPVTGData({
    this.trackTrue,
    this.trackMagnetic,
    this.speedKnots,
    this.speedKmh,
  });
}

/// MWV - Wind Speed and Angle
/// Provides wind direction and speed (relative or true)
class MWVData {
  final double angleDegrees; // Wind angle (0-359)
  final bool isRelative; // true=relative to bow, false=true wind
  final double speedKnots;
  final bool valid; // A=valid, V=invalid

  const MWVData({
    required this.angleDegrees,
    required this.isRelative,
    required this.speedKnots,
    required this.valid,
  });
}

/// DPT - Depth of Water
/// Provides depth below transducer
class DPTData {
  final double depthMeters; // Depth below transducer
  final double? offsetMeters; // Offset from transducer (+ = down)

  const DPTData({
    required this.depthMeters,
    this.offsetMeters,
  });
}
