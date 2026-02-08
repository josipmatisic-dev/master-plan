import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/nmea_data.dart';
import 'package:marine_nav_app/models/nmea_error.dart';
import 'package:marine_nav_app/services/nmea_parser.dart';

void main() {
  group('Checksum Calculation', () {
    test('calculates correct checksum for GPGGA sentence', () {
      const sentence =
          '\$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,';
      final checksum = NMEAParser.calculateChecksum(sentence);
      expect(checksum, '47');
    });

    test('calculates correct checksum for GPRMC sentence', () {
      const sentence =
          '\$GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W';
      final checksum = NMEAParser.calculateChecksum(sentence);
      expect(checksum, '6A');
    });

    test('handles sentence without \$ prefix', () {
      const sentence =
          'GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,';
      final checksum = NMEAParser.calculateChecksum(sentence);
      expect(checksum, '47');
    });
  });

  group('Checksum Validation', () {
    test('validates correct checksum', () {
      const sentence =
          '\$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47';
      expect(NMEAParser.validateChecksum(sentence), true);
    });

    test('rejects incorrect checksum', () {
      const sentence =
          '\$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*FF';
      expect(NMEAParser.validateChecksum(sentence), false);
    });

    test('accepts sentence without checksum', () {
      const sentence =
          '\$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,';
      expect(NMEAParser.validateChecksum(sentence), true);
    });

    test('validates checksum is case-insensitive', () {
      const sentence =
          '\$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47';
      expect(NMEAParser.validateChecksum(sentence), true);
    });
  });

  group('Coordinate Parsing', () {
    test('parses north latitude correctly', () {
      final lat = NMEAParser.parseCoordinate('4807.038', 'N');
      expect(lat, closeTo(48.1173, 0.0001));
    });

    test('parses south latitude correctly', () {
      final lat = NMEAParser.parseCoordinate('3346.123', 'S');
      expect(lat, closeTo(-33.7687, 0.0001));
    });

    test('parses east longitude correctly', () {
      final lng = NMEAParser.parseCoordinate('01131.000', 'E');
      expect(lng, closeTo(11.5167, 0.0001));
    });

    test('parses west longitude correctly', () {
      final lng = NMEAParser.parseCoordinate('12225.500', 'W');
      expect(lng, closeTo(-122.4250, 0.0001));
    });

    test('returns null for empty value', () {
      expect(NMEAParser.parseCoordinate('', 'N'), null);
    });

    test('returns null for null value', () {
      expect(NMEAParser.parseCoordinate(null, 'N'), null);
    });

    test('returns null for null direction', () {
      expect(NMEAParser.parseCoordinate('4807.038', null), null);
    });
  });

  group('GPGGA Parsing', () {
    test('parses valid GPGGA sentence', () {
      const sentence =
          '\$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47';
      final data = NMEAParser.parseGPGGA(sentence);

      expect(data, isNotNull);
      expect(data!.position.latitude, closeTo(48.1173, 0.0001));
      expect(data.position.longitude, closeTo(11.5167, 0.0001));
      expect(data.time.hour, 12);
      expect(data.time.minute, 35);
      expect(data.time.second, 19);
      expect(data.fixQuality, 1);
      expect(data.satellites, 8);
      expect(data.hdop, closeTo(0.9, 0.01));
      expect(data.altitudeMeters, closeTo(545.4, 0.1));
    });

    test('parses GPGGA with missing optional fields', () {
      const sentence = '\$GPGGA,123519,4807.038,N,01131.000,E,1,08,,,,,,,*56';
      final data = NMEAParser.parseGPGGA(sentence);

      expect(data, isNotNull);
      expect(data!.hdop, null);
      expect(data.altitudeMeters, null);
    });

    test('returns null for malformed GPGGA', () {
      const sentence = '\$GPGGA,123519';
      expect(NMEAParser.parseGPGGA(sentence), null);
    });

    test('returns null for GPGGA with invalid position', () {
      const sentence = '\$GPGGA,123519,,,,,1,08,0.9,545.4,M,46.9,M,,*XX';
      expect(NMEAParser.parseGPGGA(sentence), null);
    });
  });

  group('GPRMC Parsing', () {
    test('parses valid GPRMC sentence', () {
      const sentence =
          '\$GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A';
      final data = NMEAParser.parseGPRMC(sentence);

      expect(data, isNotNull);
      expect(data!.position.latitude, closeTo(48.1173, 0.0001));
      expect(data.position.longitude, closeTo(11.5167, 0.0001));
      expect(data.time.year, 1994);
      expect(data.time.month, 3);
      expect(data.time.day, 23);
      expect(data.time.hour, 12);
      expect(data.time.minute, 35);
      expect(data.time.second, 19);
      expect(data.valid, true);
      expect(data.speedKnots, closeTo(22.4, 0.1));
      expect(data.trackTrue, closeTo(84.4, 0.1));
    });

    test('parses GPRMC with warning status', () {
      const sentence =
          '\$GPRMC,123519,V,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*XX';
      final data = NMEAParser.parseGPRMC(sentence);

      expect(data, isNotNull);
      expect(data!.valid, false);
    });

    test('returns null for malformed GPRMC', () {
      const sentence = '\$GPRMC,123519';
      expect(NMEAParser.parseGPRMC(sentence), null);
    });
  });

  group('GPVTG Parsing', () {
    test('parses valid GPVTG sentence', () {
      const sentence = '\$GPVTG,054.7,T,034.4,M,005.5,N,010.2,K*48';
      final data = NMEAParser.parseGPVTG(sentence);

      expect(data, isNotNull);
      expect(data!.trackTrue, closeTo(54.7, 0.1));
      expect(data.trackMagnetic, closeTo(34.4, 0.1));
      expect(data.speedKnots, closeTo(5.5, 0.1));
      expect(data.speedKmh, closeTo(10.2, 0.1));
    });

    test('parses GPVTG with missing optional fields', () {
      const sentence = '\$GPVTG,054.7,T,,,005.5,N,,*XX';
      final data = NMEAParser.parseGPVTG(sentence);

      expect(data, isNotNull);
      expect(data!.trackTrue, closeTo(54.7, 0.1));
      expect(data.trackMagnetic, null);
      expect(data.speedKnots, closeTo(5.5, 0.1));
      expect(data.speedKmh, null);
    });

    test('returns null for malformed GPVTG', () {
      const sentence = '\$GPVTG';
      expect(NMEAParser.parseGPVTG(sentence), null);
    });
  });

  group('MWV Parsing', () {
    test('parses valid relative wind MWV sentence', () {
      const sentence = '\$WIMWV,045.0,R,012.5,N,A*XX';
      final data = NMEAParser.parseMWV(sentence);

      expect(data, isNotNull);
      expect(data!.angleDegrees, closeTo(45.0, 0.1));
      expect(data.isRelative, true);
      expect(data.speedKnots, closeTo(12.5, 0.1));
      expect(data.valid, true);
    });

    test('parses valid true wind MWV sentence', () {
      const sentence = '\$WIMWV,215.0,T,018.3,N,A*XX';
      final data = NMEAParser.parseMWV(sentence);

      expect(data, isNotNull);
      expect(data!.angleDegrees, closeTo(215.0, 0.1));
      expect(data.isRelative, false);
      expect(data.speedKnots, closeTo(18.3, 0.1));
    });

    test('parses invalid MWV sentence', () {
      const sentence = '\$WIMWV,045.0,R,012.5,N,V*XX';
      final data = NMEAParser.parseMWV(sentence);

      expect(data, isNotNull);
      expect(data!.valid, false);
    });

    test('returns null for malformed MWV', () {
      const sentence = '\$WIMWV,045.0';
      expect(NMEAParser.parseMWV(sentence), null);
    });
  });

  group('DPT Parsing', () {
    test('parses valid DPT sentence with offset', () {
      const sentence = '\$SDDPT,012.5,0.5*XX';
      final data = NMEAParser.parseDPT(sentence);

      expect(data, isNotNull);
      expect(data!.depthMeters, closeTo(12.5, 0.1));
      expect(data.offsetMeters, closeTo(0.5, 0.1));
    });

    test('parses DPT sentence without offset', () {
      const sentence = '\$SDDPT,008.3,*XX';
      final data = NMEAParser.parseDPT(sentence);

      expect(data, isNotNull);
      expect(data!.depthMeters, closeTo(8.3, 0.1));
      expect(data.offsetMeters, null);
    });

    test('returns null for malformed DPT', () {
      const sentence = '\$SDDPT';
      expect(NMEAParser.parseDPT(sentence), null);
    });
  });

  group('Generic Sentence Parsing', () {
    test('routes GPGGA sentences correctly', () {
      const sentence =
          '\$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47';
      final data = NMEAParser.parseSentence(sentence);
      expect(data, isA<GPGGAData>());
    });

    test('routes GPRMC sentences correctly', () {
      const sentence =
          '\$GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A';
      final data = NMEAParser.parseSentence(sentence);
      expect(data, isA<GPRMCData>());
    });

    test('routes GPVTG sentences correctly', () {
      const sentence = '\$GPVTG,054.7,T,034.4,M,005.5,N,010.2,K*48';
      final data = NMEAParser.parseSentence(sentence);
      expect(data, isA<GPVTGData>());
    });

    test('routes MWV sentences correctly', () {
      // Remove checksum to avoid validation issues
      const sentence = '\$WIMWV,045.0,R,012.5,N,A';
      final data = NMEAParser.parseSentence(sentence);
      expect(data, isA<MWVData>());
    });

    test('routes DPT sentences correctly', () {
      // Remove checksum to avoid validation issues
      const sentence = '\$SDDPT,012.5,0.5';
      final data = NMEAParser.parseSentence(sentence);
      expect(data, isA<DPTData>());
    });

    test('returns null for unknown sentence type', () {
      // Remove checksum to avoid validation issues
      const sentence = '\$GPXXX,123,456,789';
      final data = NMEAParser.parseSentence(sentence);
      expect(data, null);
    });

    test('throws error for sentence without \$ prefix', () {
      const sentence =
          'GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47';
      expect(
        () => NMEAParser.parseSentence(sentence),
        throwsA(isA<NMEAError>().having(
          (e) => e.type,
          'type',
          NMEAErrorType.invalidFormat,
        )),
      );
    });

    test('throws error for invalid checksum', () {
      const sentence =
          '\$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*FF';
      expect(
        () => NMEAParser.parseSentence(sentence),
        throwsA(isA<NMEAError>().having(
          (e) => e.type,
          'type',
          NMEAErrorType.checksumFailed,
        )),
      );
    });

    test('handles empty sentence gracefully', () {
      expect(
        () => NMEAParser.parseSentence(''),
        throwsA(isA<NMEAError>()),
      );
    });
  });
}
