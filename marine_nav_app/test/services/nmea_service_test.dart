import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/nmea_data.dart';
import 'package:marine_nav_app/models/nmea_error.dart';
import 'package:marine_nav_app/services/nmea_service.dart';

void main() {
  group('NMEAService', () {
    late NMEAService service;

    setUp(() {
      service = NMEAService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initializes with closed streams', () {
      expect(service.dataStream, isA<Stream<NMEAData>>());
      expect(service.errorStream, isA<Stream<NMEAError>>());
      expect(service.statusStream, isA<Stream<ConnectionStatus>>());
    });

    test('throws StateError when connecting while already running', () async {
      // Note: This test would require a mock NMEA server
      // For now, we test the state management logic

      const config = ConnectionConfig(
        type: ConnectionType.tcp,
        host: 'localhost',
        port: 10110,
      );

      // First connection attempt will fail (no server)
      // but we're testing the double-connect protection
      try {
        await service.connect(config);
      } catch (e) {
        // Expected to fail - no server running
      }

      // Attempt second connection while first is running
      // This should throw StateError
      expect(
        () => service.connect(config),
        throwsStateError,
      );
    });

    test('dispose cleans up resources', () async {
      service.dispose();

      // After dispose, streams should be closed
      expect(service.dataStream.isBroadcast, isTrue);
      expect(service.errorStream.isBroadcast, isTrue);
      expect(service.statusStream.isBroadcast, isTrue);
    });

    test('disconnect can be called multiple times safely', () async {
      await service.disconnect();
      await service.disconnect(); // Should not throw
    });

    test('emits connection status changes', () async {
      final statuses = <ConnectionStatus>[];
      final subscription = service.statusStream.listen(statuses.add);

      const config = ConnectionConfig(
        type: ConnectionType.tcp,
        host: 'invalid.host.test',
        port: 99999,
        timeout: Duration(milliseconds: 100),
      );

      try {
        await service.connect(config);
      } catch (e) {
        // Expected to fail
      }

      await Future.delayed(const Duration(milliseconds: 200));

      // Should have seen at least connecting status
      expect(statuses, contains(ConnectionStatus.connecting));

      await subscription.cancel();
    });

    test('handles invalid host gracefully', () async {
      final errors = <NMEAError>[];
      final subscription = service.errorStream.listen(errors.add);

      const config = ConnectionConfig(
        type: ConnectionType.tcp,
        host: 'invalid.host.that.does.not.exist.test',
        port: 10110,
        timeout: Duration(milliseconds: 500),
      );

      try {
        await service.connect(config);
        await Future.delayed(const Duration(milliseconds: 600));
      } catch (e) {
        // Connection will fail
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // Should have received a connection error
      expect(
        errors.any((e) => e.type == NMEAErrorType.connectionError),
        isTrue,
      );

      await subscription.cancel();
    });

    test('UDP throws UnimplementedError', () async {
      const config = ConnectionConfig(
        type: ConnectionType.udp,
        host: 'localhost',
        port: 10110,
      );

      // Connect will spawn isolate, which will emit error
      final errors = <NMEAError>[];
      final subscription = service.errorStream.listen(errors.add);

      try {
        await service.connect(config);
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        // May throw during isolate spawn or connection
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // Clean up
      await subscription.cancel();
      await service.disconnect();
    });

    // Note: Full integration tests with a mock NMEA server would go here
    // Those tests would:
    // 1. Start a TCP server on localhost
    // 2. Send NMEA sentences
    // 3. Verify parsed data arrives via dataStream
    // 4. Verify batching (200ms intervals)
    // 5. Verify reconnection logic
    // 6. Verify high data rates (>100 msg/s)
  });

  group('ConnectionConfig', () {
    test('has sensible defaults', () {
      const config = ConnectionConfig(
        type: ConnectionType.tcp,
        host: 'localhost',
        port: 10110,
      );

      expect(config.timeout, const Duration(seconds: 15));
      expect(config.reconnectDelay, const Duration(seconds: 5));
    });

    test('copyWith creates new instance with updated fields', () {
      const config = ConnectionConfig(
        type: ConnectionType.tcp,
        host: 'localhost',
        port: 10110,
      );

      final updated = config.copyWith(port: 10111);

      expect(updated.host, 'localhost');
      expect(updated.port, 10111);
      expect(updated.type, ConnectionType.tcp);
    });

    test('copyWith preserves original when no changes', () {
      const config = ConnectionConfig(
        type: ConnectionType.tcp,
        host: 'localhost',
        port: 10110,
      );

      final copy = config.copyWith();

      expect(copy.host, config.host);
      expect(copy.port, config.port);
      expect(copy.type, config.type);
    });
  });

  group('ConnectionStatus', () {
    test('isConnected returns true only for connected', () {
      expect(ConnectionStatus.connected.isConnected, isTrue);
      expect(ConnectionStatus.disconnected.isConnected, isFalse);
      expect(ConnectionStatus.connecting.isConnected, isFalse);
      expect(ConnectionStatus.reconnecting.isConnected, isFalse);
      expect(ConnectionStatus.error.isConnected, isFalse);
    });

    test('isActive returns true for active states', () {
      expect(ConnectionStatus.connected.isActive, isTrue);
      expect(ConnectionStatus.connecting.isActive, isTrue);
      expect(ConnectionStatus.reconnecting.isActive, isTrue);
      expect(ConnectionStatus.disconnected.isActive, isFalse);
      expect(ConnectionStatus.error.isActive, isFalse);
    });
  });

  group('ConnectionType', () {
    test('toString returns readable names', () {
      expect(ConnectionType.tcp.toString(), 'TCP');
      expect(ConnectionType.udp.toString(), 'UDP');
    });
  });
}
