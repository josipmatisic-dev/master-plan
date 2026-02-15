/// NMEA 0183 Instrument Sentence Data Models
///
/// Contains data classes for non-GPS instrument sentences:
/// MWV (wind), DPT (depth), HDG (heading), MTW (water temperature).

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

/// HDG - Heading, Deviation & Variation (NMEA 0183 sentence).
///
/// Provides magnetic compass heading with optional deviation and magnetic
/// variation corrections. True heading can be computed as:
/// trueHeading = heading + deviation + variation
///
/// Reference: https://gpsd.gitlab.io/gpsd/NMEA.html#_hdg_heading_deviation_variation
class HDGData {
  /// Magnetic sensor heading (degrees 0-359)
  final double headingDegrees;

  /// Magnetic deviation (degrees, E positive / W negative), null if unknown
  final double? deviationDegrees;

  /// Magnetic variation (degrees, E positive / W negative), null if unknown
  final double? variationDegrees;

  /// Creates an immutable instance of [HDGData] with heading information.
  const HDGData({
    required this.headingDegrees,
    this.deviationDegrees,
    this.variationDegrees,
  });
}

/// MTW - Mean Temperature of Water (NMEA 0183 sentence).
///
/// Provides water temperature from a hull-mounted sensor.
///
/// Reference: https://gpsd.gitlab.io/gpsd/NMEA.html#_mtw_mean_temperature_of_water
class MTWData {
  /// Water temperature in degrees Celsius
  final double temperatureCelsius;

  /// Creates an immutable instance of [MTWData] with temperature information.
  const MTWData({
    required this.temperatureCelsius,
  });
}
