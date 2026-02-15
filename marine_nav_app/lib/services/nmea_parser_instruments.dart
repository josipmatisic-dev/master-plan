/// NMEA 0183 Instrument Sentence Parsers
///
/// Parses non-GPS instrument sentences: MWV (wind), DPT (depth),
/// HDG (heading), MTW (water temperature).
// ignore_for_file: avoid_classes_with_only_static_members

import '../models/nmea_data.dart';

/// Parsers for marine instrument NMEA sentences.
class NMEAInstrumentParser {
  /// Parse MWV sentence (Wind Speed and Angle)
  /// Format: $WIMWV,x.x,a,x.x,a,A*hh
  static MWVData? parseMWV(String sentence) {
    try {
      final fields = sentence.split(',');
      if (fields.length < 6) return null;

      final angleDegrees = double.tryParse(fields[1]);
      if (angleDegrees == null) return null;

      final isRelative = fields[2] == 'R';
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

  /// Parse HDG sentence (Heading, Deviation & Variation)
  /// Format: $HCHDG,x.x,x.x,a,x.x,a*hh
  static HDGData? parseHDG(String sentence) {
    try {
      final fields = sentence.split(',');
      if (fields.length < 6) return null;

      final heading = double.tryParse(fields[1]);
      if (heading == null) return null;

      double? deviation;
      final devVal = double.tryParse(fields[2]);
      if (devVal != null && fields[3].isNotEmpty) {
        deviation = fields[3] == 'W' ? -devVal : devVal;
      }

      double? variation;
      final varVal = double.tryParse(fields[4]);
      final varDir = fields[5].split('*')[0];
      if (varVal != null && varDir.isNotEmpty) {
        variation = varDir == 'W' ? -varVal : varVal;
      }

      return HDGData(
        headingDegrees: heading,
        deviationDegrees: deviation,
        variationDegrees: variation,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse MTW sentence (Mean Temperature of Water)
  /// Format: $YXMTW,x.x,C*hh
  static MTWData? parseMTW(String sentence) {
    try {
      final fields = sentence.split(',');
      if (fields.length < 3) return null;

      final temp = double.tryParse(fields[1]);
      if (temp == null) return null;

      return MTWData(temperatureCelsius: temp);
    } catch (e) {
      return null;
    }
  }
}
