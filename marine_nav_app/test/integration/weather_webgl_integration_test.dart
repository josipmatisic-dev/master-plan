import 'package:flutter/material.dart' hide Viewport;
import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/viewport.dart';
import 'package:marine_nav_app/models/weather_data.dart';
import 'package:marine_nav_app/providers/map_provider.dart';
import 'package:marine_nav_app/providers/route_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/providers/weather_provider.dart';
import 'package:marine_nav_app/services/wind_texture_generator.dart';
import 'package:marine_nav_app/widgets/map/map_webview.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'weather_webgl_integration_test.mocks.dart';

@GenerateMocks([
  MapProvider,
  WeatherProvider,
  RouteProvider,
  SettingsProvider,
  WebViewController,
])
void main() {
  late MockMapProvider mockMapProvider;
  late MockWeatherProvider mockWeatherProvider;
  late MockRouteProvider mockRouteProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockWebViewController mockWebViewController;

  setUp(() {
    mockMapProvider = MockMapProvider();
    mockWeatherProvider = MockWeatherProvider();
    mockRouteProvider = MockRouteProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockWebViewController = MockWebViewController();

    when(mockMapProvider.settingsProvider).thenReturn(mockSettingsProvider);
    when(mockSettingsProvider.hasMapTilerApiKey).thenReturn(false);
    when(mockSettingsProvider.mapTilerApiKey).thenReturn('');
    when(mockMapProvider.viewport).thenReturn(const Viewport(
      center: LatLng(latitude: 0, longitude: 0),
      zoom: 10,
      rotation: 0,
      size: Size(800, 600),
    ));

    // Stubs for WeatherProvider
    when(mockWeatherProvider.hasData).thenReturn(true);
    when(mockWeatherProvider.isWindVisible).thenReturn(true);
    when(mockWeatherProvider.isWaveVisible).thenReturn(false);
    
    // Sample wind data
    final windPoints = [
      const WindDataPoint(
        position: LatLng(latitude: 10, longitude: 10),
        speedKnots: 20,
        directionDegrees: 90,
      ),
    ];
    final weatherData = WeatherData(
      fetchedAt: DateTime.now(),
      windPoints: windPoints,
      wavePoints: const [],
    );
    when(mockWeatherProvider.data).thenReturn(weatherData);

    // Mock wind texture
    const mockTexture = WindTextureData(
      base64Png: 'dummy_base64',
      uMin: -10,
      uMax: 10,
      vMin: -10,
      vMax: 10,
      width: 64,
      height: 64,
      south: 0,
      north: 10,
      west: 0,
      east: 10,
    );
    when(mockWeatherProvider.windTexture).thenReturn(mockTexture);

    // Stubs for WebViewController
    when(mockWebViewController.runJavaScript(any)).thenAnswer((_) async {});
    // Mock loadFlutterAsset call in initState if it happens (though we pass controller)
    when(mockWebViewController.loadFlutterAsset(any)).thenAnswer((_) async {});
    when(mockWebViewController.setJavaScriptMode(any)).thenAnswer((_) async {});
    when(mockWebViewController.setBackgroundColor(any)).thenAnswer((_) async {});
    when(mockWebViewController.addJavaScriptChannel(any, onMessageReceived: anyNamed('onMessageReceived')))
        .thenAnswer((_) async {});
    when(mockWebViewController.setNavigationDelegate(any)).thenAnswer((_) async {});
  });

  testWidgets('MapWebView triggers texture generation and calls setWindTexture', (tester) async {
    // We pass our mock controller to bypass initialization logic and verify calls
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MapProvider>.value(value: mockMapProvider),
          ChangeNotifierProvider<WeatherProvider>.value(value: mockWeatherProvider),
          ChangeNotifierProvider<RouteProvider>.value(value: mockRouteProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MapWebView(
              testController: mockWebViewController,
            ),
          ),
        ),
      ),
    );

    // Verify initial build
    expect(find.byType(MapWebView), findsOneWidget);

    // Trigger WeatherProvider update to simulate texture generation flow.
    // MapWebView adds listener to WeatherProvider in initState.
    // Since mockWeatherProvider is a Mock, it doesn't hold listeners unless we verify addListener call
    // and extract the callback.
    
    // Verify addListener was called
    final verification = verify(mockWeatherProvider.addListener(captureAny));
    expect(verification.callCount, greaterThan(0));
    final listener = verification.captured.last as VoidCallback;

    // Trigger the listener (simulate update)
    listener();
    
    // Allow async texture generation to complete
    await tester.pumpAndSettle();
    
    // Verify that runJavaScript was called with setWindTexture
    // We expect a call containing "window.mapBridge.setWindTexture"
    verify(mockWebViewController.runJavaScript(argThat(contains('window.mapBridge.setWindTexture')))).called(greaterThan(0));
  });
}

