import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:marine_nav_app/models/nmea_data.dart';
import 'package:marine_nav_app/models/nmea_instrument_data.dart';

void main() {
  group('NMEAData', () {
    final now = DateTime.now();
    const pos = LatLng(45.0, 14.0);

    test('position getter prefers GPRMC over GPGGA', () {
      final data = NMEAData(
        timestamp: now,
        gprmc: GPRMCData(
          position: const LatLng(45.0, 14.0),
          time: now,
          valid: true,
        ),
        gpgga: GPGGAData(
          position: const LatLng(46.0, 15.0),
          time: now,
          fixQuality: 1,
          satellites: 5,
        ),
      );
      // GPRMC is preferred
      expect(data.position, const LatLng(45.0, 14.0));
    });

    test('speedOverGroundKnots combines GPRMC and GPVTG', () {
      final dataOnlyRMC = NMEAData(
        timestamp: now,
        gprmc: GPRMCData(position: pos, time: now, valid: true, speedKnots: 10.5),
      );
      expect(dataOnlyRMC.speedOverGroundKnots, 10.5);

      final dataOnlyVTG = NMEAData(
        timestamp: now,
        gpvtg: const GPVTGData(speedKnots: 12.0),
      );
      expect(dataOnlyVTG.speedOverGroundKnots, 12.0);
    });

    test('courseOverGroundDegrees combines GPRMC and GPVTG', () {
      final dataOnlyRMC = NMEAData(
        timestamp: now,
        gprmc: GPRMCData(position: pos, time: now, valid: true, trackTrue: 180.0),
      );
      expect(dataOnlyRMC.courseOverGroundDegrees, 180.0);

      final dataOnlyVTG = NMEAData(
        timestamp: now,
        gpvtg: const GPVTGData(trackTrue: 90.0),
      );
      expect(dataOnlyVTG.courseOverGroundDegrees, 90.0);
    });


    test('depthMeters returns value from DPT', () {
      final data = NMEAData(
        timestamp: now,
        dpt: const DPTData(depthMeters: 15.5),
      );
      expect(data.depthMeters, 15.5);
    });

    test('wind properties return values from MWV', () {
      final data = NMEAData(
        timestamp: now,
        mwv: const MWVData(
          angleDegrees: 45.0,
          isRelative: true,
          speedKnots: 12.5,
          valid: true,
        ),
      );
      expect(data.windSpeedKnots, 12.5);
      expect(data.windDirectionDegrees, 45.0);
    });

    test('headingMagnetic returns value from HDG', () {
      final data = NMEAData(
        timestamp: now,
        hdg: const HDGData(headingDegrees: 270.0),
      );
      expect(data.headingMagnetic, 270.0);
    });

    test('headingTrue calculates correctly from HDG data', () {
      // Mag 270, Dev +5, Var +2 => True 277
      final data = NMEAData(
        timestamp: now,
        hdg: const HDGData(
          headingDegrees: 270.0,
          deviationDegrees: 5.0,
          variationDegrees: 2.0,
        ),
      );
      // Assuming logic: Mag + Dev + Var = True
      expect(data.headingTrue, 277.0);
    });

    test('waterTempCelsius returns value from MTW', () {
      final data = NMEAData(
        timestamp: now,
        mtw: const MTWData(temperatureCelsius: 22.5),
      );
      expect(data.waterTempCelsius, 22.5);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = NMEAData(timestamp: now);
      final updated = original.copyWith(
        dpt: const DPTData(depthMeters: 10.0),
      );

      expect(original.dpt, isNull);
      expect(updated.dpt?.depthMeters, 10.0);
      expect(updated.timestamp, now);
    });
  });
}
