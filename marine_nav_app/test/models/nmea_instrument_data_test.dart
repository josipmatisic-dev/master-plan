import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/nmea_instrument_data.dart';

void main() {
  group('NMEA Instrument Data Models', () {
    test('MWVData (Wind) properties', () {
      const mwv = MWVData(
        angleDegrees: 45.0,
        isRelative: true,
        speedKnots: 12.5,
        valid: true,
      );
      expect(mwv.angleDegrees, 45.0);
      expect(mwv.isRelative, isTrue);
      expect(mwv.speedKnots, 12.5);
      expect(mwv.valid, isTrue);
    });

    test('DPTData (Depth) properties', () {
      const dpt = DPTData(depthMeters: 10.5, offsetMeters: 0.5);
      expect(dpt.depthMeters, 10.5);
      expect(dpt.offsetMeters, 0.5);
    });

    test('HDGData (Heading) properties', () {
      const hdg = HDGData(
        headingDegrees: 180.0,
        deviationDegrees: 2.0,
        variationDegrees: -1.0,
      );
      expect(hdg.headingDegrees, 180.0);
      expect(hdg.deviationDegrees, 2.0);
      expect(hdg.variationDegrees, -1.0);
    });

    test('MTWData (Water Temp) properties', () {
      const mtw = MTWData(temperatureCelsius: 22.5);
      expect(mtw.temperatureCelsius, 22.5);
    });
  });
}
