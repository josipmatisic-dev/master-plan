/// NMEA connection configuration
class ConnectionConfig {
  final ConnectionType type;
  final String host;
  final int port;
  final Duration timeout;
  final Duration reconnectDelay;

  const ConnectionConfig({
    required this.type,
    required this.host,
    required this.port,
    this.timeout = const Duration(seconds: 15),
    this.reconnectDelay = const Duration(seconds: 5),
  });

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
  tcp,
  udp;

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
  disconnected,
  connecting,
  connected,
  reconnecting,
  error;

  bool get isConnected => this == ConnectionStatus.connected;
  bool get isActive =>
      this == ConnectionStatus.connected ||
      this == ConnectionStatus.connecting ||
      this == ConnectionStatus.reconnecting;
}

/// NMEA parsing or connection error
class NMEAError {
  final NMEAErrorType type;
  final String message;
  final String? sentence; // Original sentence that caused error
  final DateTime timestamp;

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
