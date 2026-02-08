import 'package:latlong2/latlong.dart';
import '../models/nmea_data.dart';
import '../models/nmea_error.dart';

/// NMEA 0183 sentence parser
/// Handles checksum validation and parsing of supported sentence types:
/// - GPGGA: GPS Fix Data
/// - GPRMC: Recommended Minimum Navigation Information
/// - GPVTG: Track and Ground Speed
/// - MWV: Wind Speed and Angle
/// - DPT: Depth of Water
///
/// This utility class uses only static members to group NMEA parsing functionality.
// ignore_for_file: avoid_classes_with_only_static_members
class NMEAParser {
  /// Calculate NMEA checksum for a sentence (excluding $ and *)
  /// XOR of all characters between $ and *
  static String calculateChecksum(String sentence) {
    // Remove $ prefix and everything after *
    final start = sentence.startsWith('\$') ? 1 : 0;
    final end = sentence.indexOf('*');
    final payload = sentence.substring(start, end != -1 ? end : null);

    int checksum = 0;
    for (int i = 0; i < payload.length; i++) {
      checksum ^= payload.codeUnitAt(i);
    }

    return checksum.toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  /// Validate NMEA sentence checksum
  /// Returns true if checksum is valid or missing (some devices don't include it)
  static bool validateChecksum(String sentence) {
    final checksumIndex = sentence.indexOf('*');
    if (checksumIndex == -1) {
      // No checksum present - some devices don't include it
      return true;
    }

    final providedChecksum = sentence.substring(checksumIndex + 1).trim();
    final calculatedChecksum = calculateChecksum(sentence);

    return providedChecksum.toUpperCase() == calculatedChecksum;
  }

  /// Parse NMEA 0183 coordinate (DDMM.MMMM or DDDMM.MMMM format) to decimal degrees
  /// direction is 'N', 'S', 'E', or 'W'
  static double? parseCoordinate(String? value, String? direction) {
    if (value == null || value.isEmpty || direction == null) {
      return null;
    }

    try {
      // Latitude is DDMM.MMMM (2 digit degrees), Longitude is DDDMM.MMMM (3 digit degrees)
      final isLatitude = direction == 'N' || direction == 'S';
      final degreeDigits = isLatitude ? 2 : 3;

      final degrees = int.parse(value.substring(0, degreeDigits));
      final minutes = double.parse(value.substring(degreeDigits));
      var decimal = degrees + (minutes / 60.0);

      if (direction == 'S' || direction == 'W') {
        decimal = -decimal;
      }

      return decimal;
    } catch (e) {
      return null;
    }
  }

  /// Parse GPGGA sentence
  /// Format: $GPGGA,hhmmss.ss,llll.ll,a,yyyyy.yy,a,x,xx,x.x,x.x,M,x.x,M,x.x,xxxx*hh
  static GPGGAData? parseGPGGA(String sentence) {
    try {
      final fields = sentence.split(',');
      if (fields.length < 15) return null;

      // Parse time (hhmmss.ss)
      final timeStr = fields[1];
      if (timeStr.isEmpty) return null;

      final hour = int.parse(timeStr.substring(0, 2));
      final minute = int.parse(timeStr.substring(2, 4));
      final second = double.parse(timeStr.substring(4));

      final now = DateTime.now().toUtc();
      final time = DateTime.utc(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
        second.floor(),
        ((second % 1) * 1000).floor(),
      );

      // Parse position
      final lat = parseCoordinate(fields[2], fields[3]);
      final lng = parseCoordinate(fields[4], fields[5]);
      if (lat == null || lng == null) return null;

      // Parse fix quality and satellites
      final fixQuality = int.tryParse(fields[6]) ?? 0;
      final satellites = int.tryParse(fields[7]) ?? 0;

      // Parse HDOP and altitude (optional)
      final hdop = double.tryParse(fields[8]);
      final altitude = double.tryParse(fields[9]);

      return GPGGAData(
        position: LatLng(lat, lng),
        time: time,
        fixQuality: fixQuality,
        satellites: satellites,
        hdop: hdop,
        altitudeMeters: altitude,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse GPRMC sentence
  /// Format: $GPRMC,hhmmss.ss,A,llll.ll,a,yyyyy.yy,a,x.x,x.x,ddmmyy,x.x,a*hh
  static GPRMCData? parseGPRMC(String sentence) {
    try {
      final fields = sentence.split(',');
      if (fields.length < 12) return null;

      // Parse time
      final timeStr = fields[1];
      if (timeStr.isEmpty) return null;

      final hour = int.parse(timeStr.substring(0, 2));
      final minute = int.parse(timeStr.substring(2, 4));
      final second = double.parse(timeStr.substring(4));

      // Parse date (ddmmyy)
      final dateStr = fields[9];
      final day = int.parse(dateStr.substring(0, 2));
      final month = int.parse(dateStr.substring(2, 4));
      final yearTwoDigit = int.parse(dateStr.substring(4, 6));
      // NMEA uses 2-digit years: 00-99 maps to 2000-2099 (Y2K compatible)
      // But for historical data, years 70-99 are 1970-1999
      final year =
          yearTwoDigit >= 70 ? 1900 + yearTwoDigit : 2000 + yearTwoDigit;

      final time = DateTime.utc(
        year,
        month,
        day,
        hour,
        minute,
        second.floor(),
        ((second % 1) * 1000).floor(),
      );

      // Parse validity
      final valid = fields[2] == 'A';

      // Parse position
      final lat = parseCoordinate(fields[3], fields[4]);
      final lng = parseCoordinate(fields[5], fields[6]);
      if (lat == null || lng == null) return null;

      // Parse speed and track
      final speedKnots = double.tryParse(fields[7]);
      final trackTrue = double.tryParse(fields[8]);

      return GPRMCData(
        position: LatLng(lat, lng),
        time: time,
        valid: valid,
        speedKnots: speedKnots,
        trackTrue: trackTrue,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse GPVTG sentence
  /// Format: $GPVTG,x.x,T,x.x,M,x.x,N,x.x,K,a*hh
  static GPVTGData? parseGPVTG(String sentence) {
    try {
      final fields = sentence.split(',');
      if (fields.length < 9) return null;

      final trackTrue = double.tryParse(fields[1]);
      final trackMagnetic = double.tryParse(fields[3]);
      final speedKnots = double.tryParse(fields[5]);
      final speedKmh = double.tryParse(fields[7]);

      return GPVTGData(
        trackTrue: trackTrue,
        trackMagnetic: trackMagnetic,
        speedKnots: speedKnots,
        speedKmh: speedKmh,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse MWV sentence (Wind Speed and Angle)
  /// Format: $WIMWV,x.x,a,x.x,a,A*hh
  static MWVData? parseMWV(String sentence) {
    try {
      final fields = sentence.split(',');
      if (fields.length < 6) return null;

      final angleDegrees = double.tryParse(fields[1]);
      if (angleDegrees == null) return null;

      final isRelative = fields[2] == 'R'; // R = relative, T = true
      final speedKnots = double.tryParse(fields[3]);
      if (speedKnots == null) return null;

      final valid = fields[5].startsWith('A');

      return MWVData(
        angleDegrees: angleDegrees,
        isRelative: isRelative,
        speedKnots: speedKnots,
        valid: valid,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse DPT sentence (Depth of Water)
  /// Format: $SDDPT,x.x,x.x*hh
  static DPTData? parseDPT(String sentence) {
    try {
      final fields = sentence.split(',');
      if (fields.length < 3) return null;

      final depthMeters = double.tryParse(fields[1]);
      if (depthMeters == null) return null;

      // Field 2 may contain checksum delimiter
      final offsetField = fields[2].split('*')[0];
      final offsetMeters =
          offsetField.isEmpty ? null : double.tryParse(offsetField);

      return DPTData(
        depthMeters: depthMeters,
        offsetMeters: offsetMeters,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse any supported NMEA sentence
  /// Returns appropriate data type or null if unknown/malformed
  static dynamic parseSentence(String sentence) {
    final trimmed = sentence.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('\$')) {
      throw NMEAError(
        type: NMEAErrorType.invalidFormat,
        message: 'Sentence must start with \$',
        sentence: trimmed,
      );
    }

    // Validate checksum
    if (!validateChecksum(trimmed)) {
      throw NMEAError(
        type: NMEAErrorType.checksumFailed,
        message: 'Checksum validation failed',
        sentence: trimmed,
      );
    }

    // Determine sentence type
    if (trimmed.contains('GPGGA')) {
      return parseGPGGA(trimmed);
    } else if (trimmed.contains('GPRMC')) {
      return parseGPRMC(trimmed);
    } else if (trimmed.contains('GPVTG')) {
      return parseGPVTG(trimmed);
    } else if (trimmed.contains('MWV')) {
      return parseMWV(trimmed);
    } else if (trimmed.contains('DPT')) {
      return parseDPT(trimmed);
    } else {
      // Unknown sentence type - not an error, just ignore
      return null;
    }
  }
}
