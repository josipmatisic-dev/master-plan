/// AIS WebSocket service for aisstream.io real-time vessel data.
///
/// Connects to wss://stream.aisstream.io/v0/stream, sends subscription
/// with API key and bounding box, receives JSON AIS messages.
library;

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/ais_target.dart';
import '../models/lat_lng.dart';

/// Connection state for the AIS WebSocket.
enum AisConnectionState { disconnected, connecting, connected, error }

/// Parsed message from aisstream.io.
class AisMessage {
  final String messageType;
  final int mmsi;
  final String? shipName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

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

  Stream<AisTarget> get targetStream => _targetController.stream;
  Stream<AisConnectionState> get stateStream => _stateController.stream;
  Stream<String> get errorStream => _errorController.stream;
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
      final target = _parseAisMessage(json);
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

  AisTarget? _parseAisMessage(Map<String, dynamic> json) {
    final messageType = json['MessageType'] as String?;
    final metaData = json['MetaData'] as Map<String, dynamic>?;
    if (messageType == null || metaData == null) return null;

    final mmsi = metaData['MMSI'] as int? ?? 0;
    if (mmsi == 0) return null;

    final lat = (metaData['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (metaData['longitude'] as num?)?.toDouble() ?? 0.0;
    final shipName = metaData['ShipName'] as String?;

    final timeStr = metaData['time_utc'] as String?;
    final timestamp = timeStr != null
        ? DateTime.tryParse(timeStr) ?? DateTime.now()
        : DateTime.now();

    final message = json['Message'] as Map<String, dynamic>? ?? {};

    if (messageType == 'PositionReport') {
      return _parsePositionReport(
        mmsi,
        lat,
        lng,
        shipName,
        timestamp,
        message,
      );
    } else if (messageType == 'StandardClassBCSPositionReport') {
      return _parseClassBPosition(
        mmsi,
        lat,
        lng,
        shipName,
        timestamp,
        message,
      );
    } else if (messageType == 'ShipStaticData') {
      return _parseStaticData(
        mmsi,
        lat,
        lng,
        shipName,
        timestamp,
        message,
      );
    }
    return null;
  }

  AisTarget _parsePositionReport(
    int mmsi,
    double lat,
    double lng,
    String? name,
    DateTime ts,
    Map<String, dynamic> msg,
  ) {
    final report = msg['PositionReport'] as Map<String, dynamic>? ?? {};
    return AisTarget(
      mmsi: mmsi,
      position: LatLng(latitude: lat, longitude: lng),
      lastUpdate: ts,
      name: name,
      sog: (report['Sog'] as num?)?.toDouble(),
      cog: (report['Cog'] as num?)?.toDouble(),
      heading: report['TrueHeading'] as int?,
      navStatus: AisNavStatus.fromCode(
        report['NavigationalStatus'] as int? ?? 15,
      ),
      rateOfTurn: (report['RateOfTurn'] as num?)?.toDouble(),
    );
  }

  AisTarget _parseClassBPosition(
    int mmsi,
    double lat,
    double lng,
    String? name,
    DateTime ts,
    Map<String, dynamic> msg,
  ) {
    final report =
        msg['StandardClassBCSPositionReport'] as Map<String, dynamic>? ?? {};
    return AisTarget(
      mmsi: mmsi,
      position: LatLng(latitude: lat, longitude: lng),
      lastUpdate: ts,
      name: name,
      sog: (report['Sog'] as num?)?.toDouble(),
      cog: (report['Cog'] as num?)?.toDouble(),
      heading: report['TrueHeading'] as int?,
    );
  }

  AisTarget _parseStaticData(
    int mmsi,
    double lat,
    double lng,
    String? name,
    DateTime ts,
    Map<String, dynamic> msg,
  ) {
    final data = msg['ShipStaticData'] as Map<String, dynamic>? ?? {};
    final dim = data['Dimension'] as Map<String, dynamic>?;
    List<int>? dimensions;
    if (dim != null) {
      dimensions = [
        dim['A'] as int? ?? 0,
        dim['B'] as int? ?? 0,
        dim['C'] as int? ?? 0,
        dim['D'] as int? ?? 0,
      ];
    }

    return AisTarget(
      mmsi: mmsi,
      position: LatLng(latitude: lat, longitude: lng),
      lastUpdate: ts,
      name: name,
      imo: data['ImoNumber'] as int?,
      callSign: data['CallSign'] as String?,
      shipType: data['Type'] as int? ?? 0,
      dimensions: dimensions,
      draught: (data['MaximumStaticDraught'] as num?)?.toDouble(),
      destination: data['Destination'] as String?,
    );
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
