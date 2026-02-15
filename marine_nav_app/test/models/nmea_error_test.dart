import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/nmea_error.dart';

void main() {
  group('ConnectionConfig', () {
    test('constructor assigns values correctly', () {
      const config = ConnectionConfig(
        type: ConnectionType.tcp,
        host: '192.168.1.1',
        port: 10110,
        timeout: Duration(seconds: 5),
        reconnectDelay: Duration(seconds: 2),
      );

      expect(config.type, ConnectionType.tcp);
      expect(config.host, '192.168.1.1');
      expect(config.port, 10110);
      expect(config.timeout, const Duration(seconds: 5));
      expect(config.reconnectDelay, const Duration(seconds: 2));
    });

    test('copyWith creates new instance with updated fields', () {
      const original = ConnectionConfig(
        type: ConnectionType.tcp,
        host: '192.168.1.1',
        port: 10110,
      );

      final copy = original.copyWith(
        host: '10.0.0.1',
        port: 2000,
      );

      expect(copy.host, '10.0.0.1');
      expect(copy.port, 2000);
      expect(copy.type, ConnectionType.tcp); // Preserved
    });

    test('equality works', () {
      const c1 = ConnectionConfig(type: ConnectionType.tcp, host: 'a', port: 1);
      const c2 = ConnectionConfig(type: ConnectionType.tcp, host: 'a', port: 1);
      const c3 = ConnectionConfig(type: ConnectionType.udp, host: 'a', port: 1);

      expect(c1, equals(c2));
      expect(c1, isNot(equals(c3)));
    });
  });

  group('ConnectionStatus', () {
    test('isConnected returns true only for connected state', () {
      expect(ConnectionStatus.connected.isConnected, isTrue);
      expect(ConnectionStatus.disconnected.isConnected, isFalse);
      expect(ConnectionStatus.connecting.isConnected, isFalse);
    });

    test('isActive returns true for non-idle states', () {
      expect(ConnectionStatus.connected.isActive, isTrue);
      expect(ConnectionStatus.connecting.isActive, isTrue);
      expect(ConnectionStatus.disconnected.isActive, isFalse);
      expect(ConnectionStatus.error.isActive, isFalse);
    });
  });

  group('NMEAError', () {
    test('constructor assigns values', () {
      final error = NMEAError(
        type: NMEAErrorType.checksumFailed,
        message: 'Bad checksum',
        sentence: '\$GPGGA...',
      );

      expect(error.type, NMEAErrorType.checksumFailed);
      expect(error.message, 'Bad checksum');
      expect(error.sentence, '\$GPGGA...');
      expect(error.timestamp, isNotNull);
    });

    test('toString contains error details', () {
      final error = NMEAError(
        type: NMEAErrorType.timeout,
        message: 'Connection timed out',
      );
      expect(error.toString(), contains('timeout'));
      expect(error.toString(), contains('Connection timed out'));
    });
  });
}
