import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/services/ais_message_parser.dart';

void main() {
  group('parseAisMessage', () {
    test('returns null for missing MessageType', () {
      final result = parseAisMessage({'MetaData': <String, dynamic>{}});
      expect(result, isNull);
    });

    test('returns null for missing MetaData', () {
      final result = parseAisMessage({'MessageType': 'PositionReport'});
      expect(result, isNull);
    });

    test('returns null for MMSI == 0', () {
      final result = parseAisMessage({
        'MessageType': 'PositionReport',
        'MetaData': {'MMSI': 0, 'latitude': 43.5, 'longitude': 16.4},
        'Message': {},
      });
      expect(result, isNull);
    });

    test('returns null for unsupported message type', () {
      final result = parseAisMessage({
        'MessageType': 'AidToNavigation',
        'MetaData': <String, dynamic>{
          'MMSI': 123456789,
          'latitude': 43.5,
          'longitude': 16.4,
        },
        'Message': <String, dynamic>{},
      });
      expect(result, isNull);
    });

    test('parses PositionReport with full data', () {
      final result = parseAisMessage({
        'MessageType': 'PositionReport',
        'MetaData': {
          'MMSI': 211234567,
          'latitude': 43.512,
          'longitude': 16.440,
          'ShipName': 'TEST VESSEL',
          'time_utc': '2026-02-16T12:00:00Z',
        },
        'Message': {
          'PositionReport': {
            'Sog': 12.5,
            'Cog': 270.0,
            'TrueHeading': 268,
            'NavigationalStatus': 0,
            'RateOfTurn': -5.2,
          },
        },
      });

      expect(result, isNotNull);
      expect(result!.mmsi, 211234567);
      expect(result.position.latitude, 43.512);
      expect(result.position.longitude, 16.440);
      expect(result.name, 'TEST VESSEL');
      expect(result.sog, 12.5);
      expect(result.cog, 270.0);
      expect(result.heading, 268);
      expect(result.rateOfTurn, -5.2);
    });

    test('parses PositionReport with missing optional fields', () {
      final result = parseAisMessage({
        'MessageType': 'PositionReport',
        'MetaData': {
          'MMSI': 111111111,
          'latitude': 0.0,
          'longitude': 0.0,
        },
        'Message': {'PositionReport': {}},
      });

      expect(result, isNotNull);
      expect(result!.mmsi, 111111111);
      expect(result.sog, isNull);
      expect(result.cog, isNull);
      expect(result.heading, isNull);
      expect(result.name, isNull);
    });

    test('parses ClassB position report', () {
      final result = parseAisMessage({
        'MessageType': 'StandardClassBCSPositionReport',
        'MetaData': {
          'MMSI': 222222222,
          'latitude': 44.0,
          'longitude': 15.0,
          'ShipName': 'SMALL BOAT',
        },
        'Message': {
          'StandardClassBCSPositionReport': {
            'Sog': 6.3,
            'Cog': 90.0,
            'TrueHeading': 92,
          },
        },
      });

      expect(result, isNotNull);
      expect(result!.mmsi, 222222222);
      expect(result.sog, 6.3);
      expect(result.cog, 90.0);
      expect(result.name, 'SMALL BOAT');
    });

    test('parses ShipStaticData with dimensions', () {
      final result = parseAisMessage({
        'MessageType': 'ShipStaticData',
        'MetaData': {
          'MMSI': 333333333,
          'latitude': 45.0,
          'longitude': 14.0,
          'ShipName': 'CARGO SHIP',
        },
        'Message': {
          'ShipStaticData': {
            'ImoNumber': 9876543,
            'CallSign': 'D5AB7',
            'Type': 70,
            'Dimension': {'A': 100, 'B': 50, 'C': 15, 'D': 15},
            'MaximumStaticDraught': 8.5,
            'Destination': 'SPLIT',
          },
        },
      });

      expect(result, isNotNull);
      expect(result!.mmsi, 333333333);
      expect(result.imo, 9876543);
      expect(result.callSign, 'D5AB7');
      expect(result.shipType, 70);
      expect(result.dimensions, [100, 50, 15, 15]);
      expect(result.draught, 8.5);
      expect(result.destination, 'SPLIT');
    });

    test('ShipStaticData without dimensions', () {
      final result = parseAisMessage({
        'MessageType': 'ShipStaticData',
        'MetaData': {'MMSI': 444, 'latitude': 0.0, 'longitude': 0.0},
        'Message': {'ShipStaticData': {}},
      });
      expect(result, isNotNull);
      expect(result!.dimensions, isNull);
      expect(result.shipType, 0);
    });

    test('handles missing time_utc gracefully', () {
      final before = DateTime.now();
      final result = parseAisMessage({
        'MessageType': 'PositionReport',
        'MetaData': {'MMSI': 555, 'latitude': 1.0, 'longitude': 2.0},
        'Message': {'PositionReport': {}},
      });
      expect(result, isNotNull);
      expect(result!.lastUpdate.isAfter(before.subtract(
        const Duration(seconds: 1),
      )), isTrue);
    });

    test('handles invalid time_utc string', () {
      final result = parseAisMessage({
        'MessageType': 'PositionReport',
        'MetaData': {
          'MMSI': 666,
          'latitude': 1.0,
          'longitude': 2.0,
          'time_utc': 'not-a-date',
        },
        'Message': {'PositionReport': {}},
      });
      expect(result, isNotNull); // Falls back to DateTime.now()
    });

    test('handles binary message (List<int>)', () {
      // Parser receives pre-decoded JSON, but verify it handles edge types
      final result = parseAisMessage({
        'MessageType': 'PositionReport',
        'MetaData': {
          'MMSI': 777,
          'latitude': 43.0,
          'longitude': 16.0,
          'MMSI_String': 777, // Extra field — ignored
        },
        'Message': {'PositionReport': {'Sog': 0}},
      });
      expect(result, isNotNull);
      expect(result!.sog, 0.0);
    });
  });
}
