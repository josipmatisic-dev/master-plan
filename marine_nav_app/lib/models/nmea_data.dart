import 'package:latlong2/latlong.dart';

/// Aggregate model containing all parsed NMEA 0183 sentence data.
///
/// This immutable model consolidates navigation data from multiple NMEA sentence types,
/// providing a single source of truth for all vessel tracking information.
/// Fields are nullable as not all sentence types are always available.
/// Updated whenever new sentences are received and successfully parsed.
///
/// Typical usage:
/// ```dart
/// final nmea = NMEAData(
///   gpgga: gpsFixData,
///   gprmc: minNavData,
///   timestamp: DateTime.now(),
/// );
/// final position = nmea.position; // Prefers GPRMC, falls back to GPGGA
/// ```
class NMEAData {
  /// GPS position fix data parsed from GPGGA sentence (null if not received)
  final GPGGAData? gpgga;

  /// Recommended minimum position data parsed from GPRMC sentence (null if not received)
  final GPRMCData? gprmc;

  /// Track and ground speed data parsed from GPVTG sentence (null if not received)
  final GPVTGData? gpvtg;

  /// Wind data parsed from MWV sentence (null if not received)
  final MWVData? mwv;

  /// Depth data parsed from DPT sentence (null if not received)
  final DPTData? dpt;

  /// Timestamp when this aggregated data was last updated
  /// Used to track data staleness and synchronize UI updates
  final DateTime timestamp;

  /// Creates an immutable instance of [NMEAData] with optional NMEA sentence data.
  ///
  /// [timestamp] is required to track when this data was created/updated.
  /// All sentence data ([gpgga], [gprmc], [gpvtg], [mwv], [dpt]) is optional
  /// as sentences may arrive asynchronously or not at all.
  const NMEAData({
    this.gpgga,
    this.gprmc,
    this.gpvtg,
    this.mwv,
    this.dpt,
    required this.timestamp,
  });

  /// Returns the current vessel position (latitude/longitude).
  ///
  /// Prefers GPRMC position (includes COG/SOG) over GPGGA position for accuracy.
  /// Falls back to GPGGA if GPRMC is not available.
  /// Returns null if neither sentence type has been received.
  LatLng? get position => gprmc?.position ?? gpgga?.position;

  /// Returns the speed over ground in knots.
  ///
  /// Prioritizes GPVTG for dedicated speed data, falls back to GPRMC if available.
  /// Returns null if no speed data is available from either sentence type.
  double? get speedOverGroundKnots => gpvtg?.speedKnots ?? gprmc?.speedKnots;

  /// Returns the course over ground (true heading) in degrees (0-359).
  ///
  /// Prioritizes GPVTG data over GPRMC data.
  /// Returns null if neither sentence provides track data.
  double? get courseOverGroundDegrees => gpvtg?.trackTrue ?? gprmc?.trackTrue;

  /// Returns the water depth below transducer in meters.
  ///
  /// Returns null if DPT sentence has not been received.
  double? get depthMeters => dpt?.depthMeters;

  /// Returns the wind speed in knots.
  ///
  /// Returns null if MWV sentence has not been received.
  double? get windSpeedKnots => mwv?.speedKnots;

  /// Returns the wind direction in degrees (0-359).
  ///
  /// Direction interpretation depends on [MWVData.isRelative]:
  /// - true: angle relative to vessel bow
  /// - false: absolute true wind direction
  /// Returns null if MWV sentence has not been received.
  double? get windDirectionDegrees => mwv?.angleDegrees;

  /// Returns a copy of this [NMEAData] with specified fields replaced.
  ///
  /// Null arguments are not replaced, allowing selective updates.
  /// Example: `data.copyWith(gpgga: newGpsData)` updates only the GPS data.
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

/// GPGGA - Global Positioning System Fix Data (NMEA 0183 sentence).
///
/// Provides absolute position, fix quality indicator, satellite count, and altitude.
/// This sentence is typically emitted by GPS receivers every 1-2 seconds.
/// Used for accurate positioning and fix quality assessment.
///
/// Reference: https://en.wikipedia.org/wiki/NMEA_0183#GGA
class GPGGAData {
  /// Geographic position in WGS84 format (latitude/longitude)
  final LatLng position;

  /// UTC time of the fix
  final DateTime time;

  /// Fix quality indicator (0=invalid, 1=GPS fix, 2=DGPS fix, higher=RTK modes)
  final int fixQuality;

  /// Number of satellites currently used in the fix (0-12+)
  final int satellites;

  /// Horizontal dilution of precision - lower values indicate better accuracy
  final double? hdop;

  /// Altitude above mean sea level (meters)
  final double? altitudeMeters;

  /// Creates an immutable instance of [GPGGAData] from GPS fix information.
  const GPGGAData({
    required this.position,
    required this.time,
    required this.fixQuality,
    required this.satellites,
    this.hdop,
    this.altitudeMeters,
  });
}

/// GPRMC - Recommended Minimum Navigation Information (NMEA 0183 sentence).
///
/// Provides position, speed over ground (SOG), and course over ground (COG).
/// This is one of the most commonly transmitted sentences and provides
/// essential navigation data for course and speed calculations.
///
/// Reference: https://en.wikipedia.org/wiki/NMEA_0183#RMC
class GPRMCData {
  /// Geographic position in WGS84 format (latitude/longitude)
  final LatLng position;

  /// UTC time of the position fix
  final DateTime time;

  /// Fix validity indicator (true=valid fix, false=warning/invalid)
  final bool valid;

  /// Speed over ground (knots), null if not available
  final double? speedKnots;

  /// Course over ground (true heading, degrees 0-359), null if not available
  final double? trackTrue;

  /// Creates an immutable instance of [GPRMCData] with navigation information.
  const GPRMCData({
    required this.position,
    required this.time,
    required this.valid,
    this.speedKnots,
    this.trackTrue,
  });
}

/// GPVTG - Track and Ground Speed (NMEA 0183 sentence).
///
/// Provides detailed velocity information including true and magnetic track,
/// and speed in both knots and km/h. More specific than GPRMC for speed/track data.
///
/// Reference: https://en.wikipedia.org/wiki/NMEA_0183#VTG
class GPVTGData {
  /// Course over ground (true heading, degrees 0-359), null if unavailable
  final double? trackTrue;

  /// Course over ground (magnetic heading, degrees 0-359), null if unavailable
  final double? trackMagnetic;

  /// Speed over ground (knots), null if unavailable
  final double? speedKnots;

  /// Speed over ground (kilometers per hour), null if unavailable
  final double? speedKmh;

  /// Creates an immutable instance of [GPVTGData] with track and speed information.
  const GPVTGData({
    this.trackTrue,
    this.trackMagnetic,
    this.speedKnots,
    this.speedKmh,
  });
}

/// MWV - Wind Speed and Angle (NMEA 0183 sentence).
///
/// Provides wind direction and speed information. Wind can be relative to the vessel
/// or absolute (true wind). Relative wind is calculated from the vessel's speed and
/// heading; true wind must be calculated from multiple sources (speed, course, relative wind).
///
/// Reference: https://en.wikipedia.org/wiki/NMEA_0183#MWV
class MWVData {
  /// Wind angle (degrees 0-359 from reference direction)
  /// Reference depends on [isRelative]: vessel bow if relative, true north if absolute
  final double angleDegrees;

  /// Wind reference frame (true=relative to vessel bow, false=true/absolute wind)
  final bool isRelative;

  /// Wind speed (knots)
  final double speedKnots;

  /// Data validity (true=valid, false=invalid/error)
  final bool valid;

  /// Creates an immutable instance of [MWVData] with wind information.
  const MWVData({
    required this.angleDegrees,
    required this.isRelative,
    required this.speedKnots,
    required this.valid,
  });
}

/// DPT - Depth of Water (NMEA 0183 sentence).
///
/// Provides water depth measurement from a sounder/transducer. The transducer is typically
/// located at the lowest point of the hull. Offset can be used to calculate depth from
/// a different reference point (e.g., surface, waterline).
///
/// Reference: https://en.wikipedia.org/wiki/NMEA_0183#DBT,_DBK,_DPT
class DPTData {
  /// Water depth below transducer (meters)
  final double depthMeters;

  /// Transducer offset from reference point (positive=below waterline, negative=above)
  /// Used to calculate depth from different reference points (e.g., keel, waterline)
  final double? offsetMeters;

  /// Creates an immutable instance of [DPTData] with depth information.
  const DPTData({
    required this.depthMeters,
    this.offsetMeters,
  });
}
