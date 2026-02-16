import 'dart:io';
import 'dart:isolate';

import '../models/nmea_data.dart';
import '../models/nmea_error.dart';

/// Context for NMEA isolate execution.
class IsolateContext {
  /// Port for sending messages back to the main isolate.
  final SendPort sendPort;

  /// Connection configuration.
  final ConnectionConfig config;

  /// Active socket connection.
  Socket? socket;

  /// Active UDP socket connection.
  RawDatagramSocket? udpSocket;

  /// Creates an [IsolateContext].
  IsolateContext({required this.sendPort, required this.config});

  /// Send parsed NMEA data to the main isolate.
  void sendData(NMEAData data) => sendPort.send(IsolateDataMessage(data));

  /// Send an error to the main isolate.
  void sendError(NMEAError error) => sendPort.send(IsolateErrorMessage(error));

  /// Send a connection status change to the main isolate.
  void sendStatus(ConnectionStatus status) =>
      sendPort.send(IsolateStatusMessage(status));
}

/// Startup message for the NMEA isolate.
class IsolateStartupMessage {
  /// Port for sending messages back.
  final SendPort sendPort;

  /// Connection configuration.
  final ConnectionConfig config;

  /// Creates an [IsolateStartupMessage].
  IsolateStartupMessage({required this.sendPort, required this.config});
}

/// Commands sent to the NMEA isolate.
enum IsolateCommand {
  /// Gracefully shut down the isolate.
  shutdown,
}

/// Data message from the NMEA isolate.
class IsolateDataMessage {
  /// The parsed NMEA data.
  final NMEAData data;

  /// Creates an [IsolateDataMessage].
  IsolateDataMessage(this.data);
}

/// Error message from the NMEA isolate.
class IsolateErrorMessage {
  /// The NMEA error.
  final NMEAError error;

  /// Creates an [IsolateErrorMessage].
  IsolateErrorMessage(this.error);
}

/// Status message from the NMEA isolate.
class IsolateStatusMessage {
  /// The connection status.
  final ConnectionStatus status;

  /// Creates an [IsolateStatusMessage].
  IsolateStatusMessage(this.status);
}
