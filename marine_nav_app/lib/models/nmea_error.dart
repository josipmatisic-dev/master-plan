/// NMEA connection configuration
class ConnectionConfig {
  /// Connection type (TCP/UDP)
  final ConnectionType type;
  /// Server hostname or IP address
  final String host;
  /// Server port number
  final int port;
  /// Connection timeout duration
  final Duration timeout;
  /// Delay between reconnection attempts
  final Duration reconnectDelay;

  /// Creates an instance of [ConnectionConfig] with connection settings
  const ConnectionConfig({
    required this.type,
    required this.host,
    required this.port,
    this.timeout = const Duration(seconds: 15),
    this.reconnectDelay = const Duration(seconds: 5),
  });

  /// Returns a copy of this configuration with specified fields replaced
  ConnectionConfig copyWith({
    ConnectionType? type,
    String? host,
    int? port,
    Duration? timeout,
    Duration? reconnectDelay,
  }) {
    return ConnectionConfig(
      type: type ?? this.type,
      host: host ?? this.host,
      port: port ?? this.port,
      timeout: timeout ?? this.timeout,
      reconnectDelay: reconnectDelay ?? this.reconnectDelay,
    );
  }
}

/// Connection type (TCP or UDP)
enum ConnectionType {
  /// TCP connection (reliable, ordered)
  tcp,
  /// UDP connection (fast, unreliable)
  udp;

  /// Returns the string representation of this connection type
  @override
  String toString() {
    switch (this) {
      case ConnectionType.tcp:
        return 'TCP';
      case ConnectionType.udp:
        return 'UDP';
    }
  }
}

/// Connection status
enum ConnectionStatus {
  /// Not connected to NMEA device
  disconnected,
  /// Attempting to connect
  connecting,
  /// Successfully connected
  connected,
  /// Attempting to reconnect after disconnection
  reconnecting,
  /// Error state

  error;

  /// Whether currently connected
  bool get isConnected => this == ConnectionStatus.connected;
  /// Whether connection is active (connected, connecting, or reconnecting)
  bool get isActive =>
      this == ConnectionStatus.connected ||
      this == ConnectionStatus.connecting ||
      this == ConnectionStatus.reconnecting;
}

/// NMEA parsing or connection error
class NMEAError {
  /// Error category/type
  final NMEAErrorType type;
  /// Error description message
  final String message;
  /// Original sentence that caused the error
  final String? sentence;
  /// When the error occurred
  final DateTime timestamp;

  /// Creates an instance of [NMEAError] with error details
  NMEAError({
    required this.type,
    required this.message,
    this.sentence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'NMEAError(${type.name}): $message';
}

/// Types of NMEA errors
enum NMEAErrorType {
  /// Checksum validation failed
  checksumFailed,

  /// Sentence format is invalid
  invalidFormat,

  /// Unknown or unsupported sentence type
  unknownSentence,

  /// Required field is missing
  missingField,

  /// Field value cannot be parsed
  parseError,

  /// Network connection error
  connectionError,

  /// Socket timeout
  timeout,

  /// Receive buffer overflow
  bufferOverflow,

  /// Unknown/other error
  unknown;

  @override
  String toString() {
    switch (this) {
      case NMEAErrorType.checksumFailed:
        return 'Checksum Failed';
      case NMEAErrorType.invalidFormat:
        return 'Invalid Format';
      case NMEAErrorType.unknownSentence:
        return 'Unknown Sentence';
      case NMEAErrorType.missingField:
        return 'Missing Field';
      case NMEAErrorType.parseError:
        return 'Parse Error';
      case NMEAErrorType.connectionError:
        return 'Connection Error';
      case NMEAErrorType.timeout:
        return 'Timeout';
      case NMEAErrorType.bufferOverflow:
        return 'Buffer Overflow';
      case NMEAErrorType.unknown:
        return 'Unknown Error';
    }
  }
}
