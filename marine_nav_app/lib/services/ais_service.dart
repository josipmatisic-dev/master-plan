/// AIS WebSocket service for aisstream.io real-time vessel data.
///
/// Connects to wss://stream.aisstream.io/v0/stream, sends subscription
/// with API key and bounding box, receives JSON AIS messages.
library;

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/ais_target.dart';
import 'ais_message_parser.dart';

/// Connection state for the AIS WebSocket.
enum AisConnectionState {
  /// Not connected.
  disconnected,

  /// Establishing connection.
  connecting,

  /// Connected and receiving data.
  connected,

  /// Connection error.
  error
}

/// Parsed message from aisstream.io.
class AisMessage {
  /// The type of AIS message (e.g., 'PositionReport').
  final String messageType;

  /// The MMSI of the vessel.
  final int mmsi;

  /// The name of the vessel, if available.
  final String? shipName;

  /// Latitude of the vessel.
  final double latitude;

  /// Longitude of the vessel.
  final double longitude;

  /// Timestamp of the message.
  final DateTime timestamp;

  /// Raw payload of the message.
  final Map<String, dynamic> payload;

  /// Creates a new [AisMessage].
  const AisMessage({
    required this.messageType,
    required this.mmsi,
    this.shipName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.payload,
  });
}

/// Service that manages aisstream.io WebSocket connection.
class AisService {
  static const _wsUrl = 'wss://stream.aisstream.io/v0/stream';

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  final _targetController = StreamController<AisTarget>.broadcast();
  final _stateController = StreamController<AisConnectionState>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  AisConnectionState _state = AisConnectionState.disconnected;
  String? _apiKey;
  List<List<List<double>>>? _boundingBoxes;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 5;

  /// Stream of received AIS targets.
  Stream<AisTarget> get targetStream => _targetController.stream;

  /// Stream of connection state changes.
  Stream<AisConnectionState> get stateStream => _stateController.stream;

  /// Stream of error messages.
  Stream<String> get errorStream => _errorController.stream;

  /// Current connection state.
  AisConnectionState get state => _state;

  /// Connect to aisstream.io with the given API key and bounding boxes.
  Future<void> connect({
    required String apiKey,
    required List<List<List<double>>> boundingBoxes,
  }) async {
    _apiKey = apiKey;
    _boundingBoxes = boundingBoxes;
    _reconnectAttempts = 0;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_apiKey == null || _boundingBoxes == null) return;

    _setState(AisConnectionState.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      await _channel!.ready;

      _setState(AisConnectionState.connected);
      _reconnectAttempts = 0;

      // Send subscription message
      final subscription = jsonEncode({
        'APIKey': _apiKey,
        'BoundingBoxes': _boundingBoxes,
        'FilterMessageTypes': [
          'PositionReport',
          'ShipStaticData',
          'StandardClassBCSPositionReport',
        ],
      });
      _channel!.sink.add(subscription);

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      _setState(AisConnectionState.error);
      _errorController.add('Connection failed: $e');
      _scheduleReconnect();
    }
  }

  /// Update the subscription bounding boxes (e.g., on viewport change).
  Future<void> updateBoundingBoxes(
    List<List<List<double>>> boundingBoxes,
  ) async {
    _boundingBoxes = boundingBoxes;
    if (_state == AisConnectionState.connected && _channel != null) {
      // Reconnect with new bounding box
      await disconnect();
      await _doConnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final String raw;
      if (message is List<int>) {
        raw = utf8.decode(message);
      } else {
        raw = message.toString();
      }

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final target = parseAisMessage(json);
      if (target != null) {
        _targetController.add(target);
      }
    } catch (e) {
      _errorController.add('Parse error: $e');
    }
  }

  void _onError(Object error) {
    _setState(AisConnectionState.error);
    _errorController.add('WebSocket error: $error');
    _scheduleReconnect();
  }

  void _onDone() {
    _setState(AisConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _errorController.add('Max reconnect attempts reached');
      return;
    }
    _reconnectAttempts++;
    final delay = Duration(
      seconds: _reconnectAttempts * _reconnectAttempts * 2,
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _doConnect);
  }

  void _setState(AisConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Disconnect from aisstream.io.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setState(AisConnectionState.disconnected);
  }

  /// Dispose all resources.
  void dispose() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _targetController.close();
    _stateController.close();
    _errorController.close();
  }
}
