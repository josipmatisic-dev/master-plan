import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/services/nmea_parser_instruments.dart';

void main() {
  group('NMEAInstrumentParser', () {
    group('MWV (Wind)', () {
      test('parses valid sentence', () {
        // $WIMWV,214.8,R,0.1,K,A*28
        const sentence = '\$WIMWV,214.8,R,0.1,K,A*28';
        final data = NMEAInstrumentParser.parseMWV(sentence);
        
        expect(data, isNotNull);
        expect(data!.angleDegrees, 214.8);
        expect(data.isRelative, isTrue);
        expect(data.speedKnots, 0.1);
        expect(data.valid, isTrue);
      });

      test('returns null for invalid sentence', () {
        expect(NMEAInstrumentParser.parseMWV('invalid'), isNull);
        expect(NMEAInstrumentParser.parseMWV('\$WIMWV,1,2,3'), isNull); // too short
      });
    });

    group('DPT (Depth)', () {
      test('parses valid sentence with offset', () {
        // $SDDPT,3.7,0.0,*5E
        const sentence = '\$SDDPT,3.7,0.5,*5E';
        final data = NMEAInstrumentParser.parseDPT(sentence);

        expect(data, isNotNull);
        expect(data!.depthMeters, 3.7);
        expect(data.offsetMeters, 0.5);
      });

      test('parses valid sentence without offset', () {
        const sentence = '\$SDDPT,3.7,,*5E';
        final data = NMEAInstrumentParser.parseDPT(sentence);

        expect(data, isNotNull);
        expect(data!.depthMeters, 3.7);
        expect(data.offsetMeters, isNull);
      });
    });

    group('HDG (Heading)', () {
      test('parses valid sentence', () {
        // $HCHDG,101.1,,,7.1,W*3C
        const sentence = '\$HCHDG,101.1,,,7.1,W*3C';
        final data = NMEAInstrumentParser.parseHDG(sentence);

        expect(data, isNotNull);
        expect(data!.headingDegrees, 101.1);
        expect(data.variationDegrees, -7.1); // W = negative
        expect(data.deviationDegrees, isNull);
      });

       test('parses sentence with deviation and variation', () {
        // $HCHDG,101.1,1.0,E,7.1,W*3C
        const sentence = '\$HCHDG,101.1,1.0,E,7.1,W*3C';
        final data = NMEAInstrumentParser.parseHDG(sentence);

        expect(data, isNotNull);
        expect(data!.headingDegrees, 101.1);
        expect(data.deviationDegrees, 1.0);
        expect(data.variationDegrees, -7.1);
      });
    });

    group('MTW (Water Temp)', () {
      test('parses valid sentence', () {
        // $YXMTW,17.7,C*1D
        const sentence = '\$YXMTW,17.7,C*1D';
        final data = NMEAInstrumentParser.parseMTW(sentence);

        expect(data, isNotNull);
        expect(data!.temperatureCelsius, 17.7);
      });
    });
  });
}
