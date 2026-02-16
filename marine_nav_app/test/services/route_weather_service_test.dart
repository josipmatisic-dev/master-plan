import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/route.dart';
import 'package:marine_nav_app/models/weather_data.dart';
import 'package:marine_nav_app/services/route_weather_service.dart';
import 'package:marine_nav_app/services/weather_api.dart';

void main() {
  group('RouteWeatherService', () {
    List<Waypoint> makeWaypoints(List<(double, double)> coords) {
      return coords
          .asMap()
          .entries
          .map((e) => Waypoint(
                id: 'wp${e.key}',
                position: ll.LatLng(e.value.$1, e.value.$2),
                name: 'WP${e.key}',
                timestamp: DateTime.now(),
              ))
          .toList();
    }

    Route makeRoute(List<(double, double)> coords) {
      return Route(
        id: 'r1',
        name: 'test',
        waypoints: makeWaypoints(coords),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    group('sample point distribution', () {
      test('returns empty for single waypoint', () {
        final points = RouteWeatherService.distributeSamplePoints(
          makeWaypoints([(43.5, 16.4)]),
        );
        expect(points, isEmpty);
      });

      test('returns at least 2 points for a short route', () {
        final points = RouteWeatherService.distributeSamplePoints(
          makeWaypoints([(43.0, 16.0), (43.01, 16.01)]),
        );
        expect(points.length, greaterThanOrEqualTo(2));
      });

      test('first point matches first waypoint', () {
        final points = RouteWeatherService.distributeSamplePoints(
          makeWaypoints([(43.0, 16.0), (44.0, 16.0)]),
        );
        expect(points.first.latitude, closeTo(43.0, 0.01));
        expect(points.first.longitude, closeTo(16.0, 0.01));
      });

      test('last point matches last waypoint', () {
        final points = RouteWeatherService.distributeSamplePoints(
          makeWaypoints([(43.0, 16.0), (44.0, 16.0)]),
        );
        expect(points.last.latitude, closeTo(44.0, 0.01));
        expect(points.last.longitude, closeTo(16.0, 0.01));
      });

      test('capped at maxSamplePoints for long routes', () {
        final points = RouteWeatherService.distributeSamplePoints(
          makeWaypoints([(30.0, 16.0), (40.0, 16.0)]),
        );
        expect(points.length, lessThanOrEqualTo(25));
      });

      test('handles zero-length route', () {
        final points = RouteWeatherService.distributeSamplePoints(
          makeWaypoints([(43.0, 16.0), (43.0, 16.0)]),
        );
        expect(points.length, 1);
        expect(points.first.latitude, closeTo(43.0, 0.01));
      });

      test('handles 3-leg route with points across all legs', () {
        final points = RouteWeatherService.distributeSamplePoints(
          makeWaypoints([
            (43.0, 16.0),
            (43.5, 16.0),
            (43.5, 16.5),
            (44.0, 16.5),
          ]),
        );
        expect(points.length, greaterThan(2));
        expect(points.first.latitude, closeTo(43.0, 0.01));
        expect(points.last.latitude, closeTo(44.0, 0.01));
      });

      test('points are ordered along north-bound route', () {
        final points = RouteWeatherService.distributeSamplePoints(
          makeWaypoints([(43.0, 16.0), (44.0, 16.0)]),
        );
        for (var i = 1; i < points.length; i++) {
          expect(
              points[i].latitude, greaterThanOrEqualTo(points[i - 1].latitude));
        }
      });
    });

    group('RouteWeatherCorridor', () {
      test('constructor stores fields', () {
        final corridor = RouteWeatherCorridor(
          weather: WeatherData.empty,
          samplePoints: [const LatLng(latitude: 43.0, longitude: 16.0)],
          totalDistanceNm: 42.5,
        );
        expect(corridor.samplePoints, hasLength(1));
        expect(corridor.totalDistanceNm, 42.5);
        expect(corridor.weather.isEmpty, isTrue);
      });

      test('empty corridor has no sample points', () {
        final corridor = RouteWeatherCorridor(
          weather: WeatherData.empty,
          samplePoints: const [],
          totalDistanceNm: 0,
        );
        expect(corridor.samplePoints, isEmpty);
        expect(corridor.totalDistanceNm, 0);
      });
    });

    group('constants', () {
      test('maxSamplePoints is 25', () {
        expect(RouteWeatherService.maxSamplePoints, 25);
      });

      test('minSpacingNm is 2.0', () {
        expect(RouteWeatherService.minSpacingNm, 2.0);
      });
    });

    group('route distance integration', () {
      test('route getTotalDistance for 1-degree north leg', () {
        final route = makeRoute([(43.0, 16.0), (44.0, 16.0)]);
        final dist = route.getTotalDistance();
        expect(dist, greaterThan(50));
        expect(dist, lessThan(70));
      });

      test('route with 3 waypoints sums all leg distances', () {
        final route = makeRoute([
          (43.0, 16.0),
          (44.0, 16.0),
          (44.0, 17.0),
        ]);
        final dist = route.getTotalDistance();
        expect(dist, greaterThan(90));
        expect(dist, lessThan(130));
      });
    });

    group('fetchRouteWeather edge cases', () {
      Route makeRoute(List<(double, double)> coords) {
        return Route(
          id: 'r1',
          name: 'test',
          waypoints: makeWaypoints(coords),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      test('empty route returns empty corridor', () async {
        final api = WeatherApiService();
        final service = RouteWeatherService(api: api);
        final route = Route(
          id: 'r1',
          name: 'empty',
          waypoints: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final result = await service.fetchRouteWeather(route);
        expect(result.samplePoints, isEmpty);
        expect(result.totalDistanceNm, 0);
        expect(result.weather.isEmpty, isTrue);
      });

      test('single waypoint returns empty corridor', () async {
        final api = WeatherApiService();
        final service = RouteWeatherService(api: api);
        final route = makeRoute([(43.5, 16.4)]);
        final result = await service.fetchRouteWeather(route);
        expect(result.samplePoints, isEmpty);
        expect(result.totalDistanceNm, 0);
        expect(result.weather.isEmpty, isTrue);
      });
    });

    group('sample point distribution — additional edge cases', () {
      test('two identical waypoints returns single point', () {
        final points = RouteWeatherService.distributeSamplePoints(
          makeWaypoints([(43.0, 16.0), (43.0, 16.0)]),
        );
        expect(points.length, 1);
      });

      test('empty waypoint list returns empty', () {
        final points = RouteWeatherService.distributeSamplePoints([]);
        expect(points, isEmpty);
      });

      test('very short route (< minSpacing) gets at least 2 points', () {
        // ~0.1nm apart
        final points = RouteWeatherService.distributeSamplePoints(
          makeWaypoints([(43.0, 16.0), (43.001, 16.001)]),
        );
        expect(points.length, greaterThanOrEqualTo(2));
      });

      test('many waypoints close together still distributes evenly', () {
        // 10 waypoints all within 0.01° of each other
        final coords =
            List.generate(10, (i) => (43.0 + i * 0.001, 16.0 + i * 0.001));
        final points = RouteWeatherService.distributeSamplePoints(
          makeWaypoints(coords),
        );
        expect(points, isNotEmpty);
        expect(points.length, lessThanOrEqualTo(25));
      });

      test('long route with many legs distributes max 25 points', () {
        // 8 waypoints spread over ~10° latitude
        final coords = List.generate(8, (i) => (30.0 + i * 1.5, 16.0));
        final points = RouteWeatherService.distributeSamplePoints(
          makeWaypoints(coords),
        );
        expect(points.length, 25);
        // First and last match endpoints
        expect(points.first.latitude, closeTo(30.0, 0.01));
        expect(points.last.latitude, closeTo(40.5, 0.1));
      });

      test('points are monotonically spaced along route', () {
        final points = RouteWeatherService.distributeSamplePoints(
          makeWaypoints([(43.0, 16.0), (43.5, 16.0), (44.0, 16.0)]),
        );
        // All points should have increasing latitude
        for (var i = 1; i < points.length; i++) {
          expect(
              points[i].latitude, greaterThanOrEqualTo(points[i - 1].latitude));
        }
      });
    });
  });
}
