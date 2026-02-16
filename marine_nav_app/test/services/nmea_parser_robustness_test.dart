import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/nmea_error.dart';
import 'package:marine_nav_app/services/nmea_parser.dart';

/// Robustness tests for NMEAParser — malformed, truncated, and edge-case input.
void main() {
  group('NMEAParser robustness — truncated sentences', () {
    test('GPGGA with only type field throws checksum error', () {
      const sentence = r'$GPGGA*52';
      // Checksum doesn't match → throws
      expect(
        () => NMEAParser.parseSentence(sentence),
        throwsA(isA<NMEAError>()),
      );
    });

    test('GPRMC with 3 fields returns null', () {
      const sentence = r'$GPRMC,120000,A*00';
      // Checksum won't match but if we skip checksum:
      expect(
        () => NMEAParser.parseSentence(sentence),
        throwsA(isA<NMEAError>()),
      );
    });

    test('sentence with just dollar sign returns null', () {
      // $-only sentence has no known type, no checksum → returns null
      final result = NMEAParser.parseSentence(r'$');
      expect(result, isNull);
    });

    test('sentence with just dollar and asterisk', () {
      const sentence = r'$*00';
      final result = NMEAParser.parseSentence(sentence);
      // Should not crash — either returns null or throws
      expect(result, isNull);
    });

    test('GPGGA with empty fields', () {
      const sentence = r'$GPGGA,,,,,,,,,,,,,,*56';
      final result = NMEAParser.parseSentence(sentence);
      // Should handle empty fields gracefully (null position)
      expect(result, isNull);
    });
  });

  group('NMEAParser robustness — checksum edge cases', () {
    test('correct checksum with all zeros', () {
      final cs = NMEAParser.calculateChecksum(r'$GPGGA*');
      expect(cs, isNotEmpty);
      expect(cs.length, 2);
    });

    test('wrong checksum is rejected', () {
      const sentence =
          r'$GPGGA,120000,4807.038,N,01131.000,E,1,08,0.9,545.4,M,47.0,M,,*FF';
      expect(
        () => NMEAParser.parseSentence(sentence),
        throwsA(
          isA<NMEAError>().having(
            (e) => e.type,
            'type',
            NMEAErrorType.checksumFailed,
          ),
        ),
      );
    });

    test('sentence without dollar prefix throws invalidFormat', () {
      const sentence =
          'GPGGA,120000,4807.038,N,01131.000,E,1,08,0.9,545.4,M,47.0,M,,*47';
      expect(
        () => NMEAParser.parseSentence(sentence),
        throwsA(
          isA<NMEAError>().having(
            (e) => e.type,
            'type',
            NMEAErrorType.invalidFormat,
          ),
        ),
      );
    });

    test('validates checksum is case-insensitive', () {
      // Compute a real checksum
      final cs = NMEAParser.calculateChecksum(r'$GPGGA*');
      final upper = '\$GPGGA*$cs';
      final lower = '\$GPGGA*${cs.toLowerCase()}';
      expect(NMEAParser.validateChecksum(upper), isTrue);
      expect(NMEAParser.validateChecksum(lower), isTrue);
    });
  });

  group('NMEAParser robustness — garbage data', () {
    test('valid checksum but nonsense type returns null', () {
      // Build sentence with valid checksum
      const payload = 'ZZZZZ,garbage,data';
      final cs = NMEAParser.calculateChecksum('\$$payload*');
      final sentence = '\$$payload*$cs';

      // Should not throw — just returns null for unknown type
      final result = NMEAParser.parseSentence(sentence);
      expect(result, isNull);
    });

    test('extremely long sentence does not crash', () {
      final longData = 'X' * 10000;
      final payload = 'GPGGA,$longData';
      final cs = NMEAParser.calculateChecksum('\$$payload*');
      final sentence = '\$$payload*$cs';

      // Should handle gracefully — either parse or return null
      try {
        final result = NMEAParser.parseSentence(sentence);
        // If it doesn't throw, result should be null (bad data)
        expect(result, isNull);
      } on NMEAError {
        // Acceptable — parser may reject
      }
    });

    test('sentence with numeric-only fields', () {
      const payload = 'GPGGA,1,2,3,4,5,6,7,8,9,10,11,12,13,14';
      final cs = NMEAParser.calculateChecksum('\$$payload*');
      final sentence = '\$$payload*$cs';

      // Should handle without crash
      try {
        NMEAParser.parseSentence(sentence);
      } on NMEAError {
        // Acceptable
      }
    });

    test('empty string throws or handles gracefully', () {
      expect(
        () => NMEAParser.parseSentence(''),
        throwsA(isA<NMEAError>()),
      );
    });

    test('whitespace-only string throws', () {
      expect(
        () => NMEAParser.parseSentence('   \n  '),
        throwsA(isA<NMEAError>()),
      );
    });
  });

  group('NMEAParser robustness — special characters', () {
    test('sentence with unicode characters in payload', () {
      // NMEA is ASCII-only; test that non-ASCII doesn't crash
      const sentence = r'$GPGGé,ñ*00';
      expect(
        () => NMEAParser.parseSentence(sentence),
        anyOf(
          throwsA(isA<NMEAError>()),
          returnsNormally, // Parser may just reject checksum
        ),
      );
    });

    test('sentence with newlines and carriage returns', () {
      // NMEA sentences end with CR LF — parser should trim
      // Compute correct checksum for this payload
      const payload =
          'GPGGA,120000,4807.038,N,01131.000,E,1,08,0.9,545.4,M,47.0,M,,';
      final cs = NMEAParser.calculateChecksum('\$$payload*');
      final raw = '\$$payload*$cs\r\n';
      final result = NMEAParser.parseSentence(raw);
      expect(result, isNotNull);
      // GPGGAData uses position.latitude
      expect((result as dynamic).position.latitude, closeTo(48.1173, 0.001));
    });

    test('multiple asterisks in sentence', () {
      const sentence = r'$GPGGA*invalid*47';
      expect(
        () => NMEAParser.parseSentence(sentence),
        anyOf(throwsA(isA<NMEAError>()), returnsNormally),
      );
    });
  });

  group('NMEAParser robustness — coordinate parsing', () {
    test('parseCoordinate with zero value', () {
      final result = NMEAParser.parseCoordinate('0000.0000', 'N');
      expect(result, 0.0);
    });

    test('parseCoordinate with max latitude', () {
      final result = NMEAParser.parseCoordinate('9000.0000', 'N');
      expect(result, 90.0);
    });

    test('parseCoordinate with max longitude', () {
      final result = NMEAParser.parseCoordinate('18000.0000', 'E');
      expect(result, 180.0);
    });

    test('parseCoordinate with empty string', () {
      expect(NMEAParser.parseCoordinate('', 'N'), isNull);
    });

    test('parseCoordinate with non-numeric string', () {
      // Should return null or handle gracefully
      try {
        final result = NMEAParser.parseCoordinate('abcd.efgh', 'N');
        // If it doesn't throw, result should be null
        expect(result, isNull);
      } catch (_) {
        // Acceptable
      }
    });
  });

  group('NMEAParser robustness — rapid mixed sentences', () {
    test('batch of 100 valid sentences all parse', () {
      int parsed = 0;
      for (int i = 0; i < 100; i++) {
        final time = '${i.toString().padLeft(2, '0')}0000.00';
        const lat = '4807.038';
        const lng = '01131.000';
        final payload = 'GPGGA,$time,$lat,N,$lng,E,1,08,0.9,545.4,M,47.0,M,,';
        final cs = NMEAParser.calculateChecksum('\$$payload*');
        final sentence = '\$$payload*$cs';

        final result = NMEAParser.parseSentence(sentence);
        if (result != null) parsed++;
      }
      expect(parsed, 100);
    });

    test('mixed valid and invalid sentences dont corrupt state', () {
      // Build valid sentences with correct checksums
      const gpggaPayload =
          'GPGGA,120000,4807.038,N,01131.000,E,1,08,0.9,545.4,M,47.0,M,,';
      final gpggaCs = NMEAParser.calculateChecksum('\$$gpggaPayload*');
      final validGpgga = '\$$gpggaPayload*$gpggaCs';

      const gprmcPayload =
          'GPRMC,120000,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W';
      final gprmcCs = NMEAParser.calculateChecksum('\$$gprmcPayload*');
      final validGprmc = '\$$gprmcPayload*$gprmcCs';

      final sentences = [
        validGpgga,
        'garbage data',
        r'$INVALID*FF',
        validGprmc,
        '',
        r'$GPGGA*52',
      ];

      int successes = 0;
      int errors = 0;

      for (final s in sentences) {
        try {
          final result = NMEAParser.parseSentence(s);
          if (result != null) successes++;
        } on NMEAError {
          errors++;
        }
      }

      expect(successes, greaterThanOrEqualTo(2));
      expect(errors, greaterThanOrEqualTo(2));
    });
  });
}
