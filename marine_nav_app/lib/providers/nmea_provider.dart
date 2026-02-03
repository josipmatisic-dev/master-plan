import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/nmea_data.dart';
import '../models/nmea_error.dart';
import '../services/nmea_service.dart';
import 'cache_provider.dart';
import 'settings_provider.dart';

/// NMEA Provider - Layer 2 Provider
/// Manages NMEA data stream connection and provides parsed navigation data to UI.
/// 
/// Dependencies:
/// - Layer 0: SettingsProvider (for future connection config)
/// - Layer 1: CacheProvider (for future cached NMEA data)
/// 
/// Usage:
/// ```dart
/// final nmea = Provider.of<NMEAProvider>(context);
/// if (nmea.isConnected) {
///   final sog = nmea.currentData?.speedOverGroundKnots;
/// }
/// ```
class NMEAProvider extends ChangeNotifier {
  // ignore: unused_field
  final SettingsProvider _settingsProvider; // Reserved for future use
  // ignore: unused_field
  final CacheProvider _cacheProvider; // Reserved for future use
  final NMEAService _service;

  NMEAData? _currentData;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  NMEAError? _lastError;
  DateTime? _lastUpdateTime;
  
  StreamSubscription<NMEAData>? _dataSubscription;
  StreamSubscription<NMEAError>? _errorSubscription;
  StreamSubscription<ConnectionStatus>? _statusSubscription;
  
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  /// Create NMEA provider with required dependencies
  NMEAProvider({
    required SettingsProvider settingsProvider,
    required CacheProvider cacheProvider,
    NMEAService? service,
  })  : _settingsProvider = settingsProvider,
        _cacheProvider = cacheProvider,
        _service = service ?? NMEAService() {
    _initialize();
  }

  /// Current NMEA data (may be null if no data received yet)
  NMEAData? get currentData => _currentData;

  /// Connection status
  ConnectionStatus get status => _status;

  /// Last error (if any)
  NMEAError? get lastError => _lastError;

  /// Whether currently connected
  bool get isConnected => _status == ConnectionStatus.connected;

  /// Whether connection is active (connecting/connected/reconnecting)
  bool get isActive => _status.isActive;

  /// Last data update timestamp
  DateTime? get lastUpdateTime => _lastUpdateTime;

  /// Number of reconnection attempts
  int get reconnectAttempts => _reconnectAttempts;

  /// Initialize provider and load cached data
  void _initialize() {
    // Load cached NMEA data if available
    _loadCachedData();

    // Subscribe to service streams
    _dataSubscription = _service.dataStream.listen(_handleData);
    _errorSubscription = _service.errorStream.listen(_handleError);
    _statusSubscription = _service.statusStream.listen(_handleStatus);

    // Auto-connect if enabled in settings
    if (_settingsProvider.autoConnectNMEA) {
      connect();
    }
  }

  /// Load cached NMEA data from previous session
  Future<void> _loadCachedData() async {
    try {
      final cached = await _cacheProvider.get<NMEAData>('nmea_last_data');
      if (cached != null) {
        _currentData = cached;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load cached NMEA data: $e');
    }
  }

  /// Connect to NMEA data source
  Future<void> connect() async {
    if (isActive) {
      debugPrint('Already connecting or connected');
      return;
    }

    try {
      final config = _getConnectionConfig();
      await _service.connect(config);
      _reconnectAttempts = 0;
    } catch (e) {
      _lastError = NMEAError(
        type: NMEAErrorType.connectionError,
        message: 'Failed to connect: $e',
      );
      notifyListeners();
    }
  }

  /// Disconnect from NMEA data source
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    
    await _service.disconnect();
  }

  /// Get connection configuration from settings
  ConnectionConfig _getConnectionConfig() {
    return ConnectionConfig(
      type: _settingsProvider.nmeaConnectionType,
      host: _settingsProvider.nmeaHost,
      port: _settingsProvider.nmeaPort,
      timeout: const Duration(seconds: 15),
      reconnectDelay: const Duration(seconds: 5),
    );
  }

  /// Handle incoming NMEA data
  void _handleData(NMEAData data) {
    _currentData = data;
    _lastUpdateTime = DateTime.now();
    _lastError = null;

    // TODO: Cache latest data when cache API is available
    // _cacheProvider.set('nmea_last_data', data, ttl: const Duration(hours: 1));

    notifyListeners();
  }

  /// Handle NMEA errors
  void _handleError(NMEAError error) {
    _lastError = error;
    debugPrint('NMEA Error: $error');
    notifyListeners();
  }

  /// Handle connection status changes
  void _handleStatus(ConnectionStatus newStatus) {
    final oldStatus = _status;
    _status = newStatus;

    // Handle disconnection - attempt reconnect
    // TODO: Make auto-reconnect configurable in settings
    if (oldStatus.isConnected && 
        newStatus == ConnectionStatus.disconnected) {
      _scheduleReconnect();
    }

    // Reset reconnect counter on successful connection
    if (newStatus == ConnectionStatus.connected) {
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    }

    notifyListeners();
  }

  /// Schedule automatic reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached');
      _lastError = NMEAError(
        type: NMEAErrorType.connectionError,
        message: 'Failed to reconnect after $_maxReconnectAttempts attempts',
      );
      notifyListeners();
      return;
    }

    _reconnectAttempts++;
    
    // Exponential backoff: 5s, 10s, 20s, 40s, ... max 2 minutes
    final delay = Duration(
      seconds: (5 * (1 << (_reconnectAttempts - 1))).clamp(5, 120),
    );

    debugPrint('Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!isActive) {
        connect();
      }
    });
  }

  /// Clear last error
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _dataSubscription?.cancel();
    _errorSubscription?.cancel();
    _statusSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
