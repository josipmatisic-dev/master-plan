import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll2;
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/nmea_data.dart';
import 'package:marine_nav_app/providers/boat_provider.dart';
import 'package:marine_nav_app/providers/map_provider.dart';
import 'package:marine_nav_app/providers/nmea_provider.dart';
import 'package:mockito/mockito.dart';

// Manual Mocks
class MockNMEAProvider extends Mock implements NMEAProvider {
  @override
  bool get isConnected => super.noSuchMethod(
        Invocation.getter(#isConnected),
        returnValue: false,
      );

  @override
  NMEAData? get currentData => super.noSuchMethod(
        Invocation.getter(#currentData),
        returnValue: null,
      );

  @override
  void addListener(VoidCallback? listener) {
    super.noSuchMethod(
      Invocation.method(#addListener, [listener]),
    );
  }

  @override
  void removeListener(VoidCallback? listener) {
    super.noSuchMethod(
      Invocation.method(#removeListener, [listener]),
    );
  }
}

class MockMapProvider extends Mock implements MapProvider {
  @override
  void setCenter(LatLng? center) {
    super.noSuchMethod(
      Invocation.method(#setCenter, [center]),
    );
  }
}

void main() {
  late BoatProvider boatProvider;
  late MockNMEAProvider mockNmeaProvider;
  late MockMapProvider mockMapProvider;
  late VoidCallback nmeaListener;

  setUp(() {
    mockNmeaProvider = MockNMEAProvider();
    mockMapProvider = MockMapProvider();
    
    // Stub connected state
    when(mockNmeaProvider.isConnected).thenReturn(true);
    when(mockNmeaProvider.currentData).thenReturn(null);
    when(mockMapProvider.setCenter(any)).thenReturn(null);
    
    // Capture listener
    when(mockNmeaProvider.addListener(any)).thenAnswer((invocation) {
      nmeaListener = invocation.positionalArguments[0] as VoidCallback;
    });
    when(mockNmeaProvider.removeListener(any)).thenReturn(null);

    boatProvider = BoatProvider(
      nmeaProvider: mockNmeaProvider,
      mapProvider: mockMapProvider,
    );
  });

  test('BoatProvider smooths position updates', () {
    // Initial position
    final startPos = NMEAData(
      timestamp: DateTime.now(),
      gprmc: GPRMCData(
        position: const ll2.LatLng(10.0, 10.0),
        time: DateTime.now(),
        valid: true,
        speedKnots: 10.0,
        trackTrue: 45.0,
      ),
    );

    // 1. Initial update (sets baseline)
    when(mockNmeaProvider.currentData).thenReturn(startPos);
    nmeaListener();
    
    expect(boatProvider.currentPosition!.latitude, 10.0);
    expect(boatProvider.currentPosition!.longitude, 10.0);

    // 2. Jump update (should be smoothed)
    // Jump 0.0001 degrees (~11m in 1s = 11m/s < 50m/s limit)
    final jumpPos = NMEAData(
      timestamp: DateTime.now().add(const Duration(seconds: 1)),
      gprmc: GPRMCData(
        position: const ll2.LatLng(10.0001, 10.0001),
        time: DateTime.now(),
        valid: true,
        speedKnots: 12.0,
        trackTrue: 50.0,
      ),
    );

    when(mockNmeaProvider.currentData).thenReturn(jumpPos);
    nmeaListener();

    // Check smoothing
    // Alpha = 0.3
    // expected = 10.0 + (10.0001 - 10.0) * 0.3 = 10.00003
    expect(boatProvider.currentPosition!.latitude, closeTo(10.00003, 0.000001));
    expect(boatProvider.currentPosition!.longitude, closeTo(10.00003, 0.000001));
    
    // Check heading smoothing
    // Alpha = 0.2
    // expected = 45 + (50 - 45) * 0.2 = 46.0
    expect(boatProvider.currentPosition!.courseTrue, closeTo(46.0, 0.1));
  });
}
