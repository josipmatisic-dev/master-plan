import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import '../models/nmea_data.dart';
import '../models/nmea_error.dart';
import 'nmea_isolate_messages.dart';
import 'nmea_parser.dart';

/// NMEA Service - Background isolate for socket I/O and sentence parsing
/// Prevents UI blocking by processing NMEA data in a separate isolate.
///
/// Usage:
/// ```dart
/// final service = NMEAService();
/// service.dataStream.listen((data) => print(data));
/// service.errorStream.listen((error) => print(error));
/// await service.connect(config);
/// ```
class NMEAService {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;

  final _dataController = StreamController<NMEAData>.broadcast();
  final _errorController = StreamController<NMEAError>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  /// Stream of parsed NMEA data (batched every 200ms)
  Stream<NMEAData> get dataStream => _dataController.stream;

  /// Stream of parsing and connection errors
  Stream<NMEAError> get errorStream => _errorController.stream;

  /// Stream of connection status changes
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  bool _isRunning = false;

  /// Start the NMEA service with the given configuration
  Future<void> connect(ConnectionConfig config) async {
    if (_isRunning) {
      throw StateError('Service already running');
    }

    try {
      _statusController.add(ConnectionStatus.connecting);

      // Create receive port for isolate communication
      _receivePort = ReceivePort();

      // Spawn isolate with entry point
      _isolate = await Isolate.spawn(
        _isolateEntryPoint,
        IsolateStartupMessage(
          sendPort: _receivePort!.sendPort,
          config: config,
        ),
      );

      // Listen for messages from isolate
      _receivePort!.listen(_handleIsolateMessage);

      _isRunning = true;
    } catch (e) {
      _statusController.add(ConnectionStatus.error);
      _errorController.add(NMEAError(
        type: NMEAErrorType.connectionError,
        message: 'Failed to start NMEA service: $e',
      ));
      rethrow;
    }
  }

  /// Disconnect and clean up resources
  Future<void> disconnect() async {
    if (!_isRunning) return;

    // Send shutdown command to isolate
    _sendPort?.send(IsolateCommand.shutdown);

    // Wait a bit for graceful shutdown
    await Future.delayed(const Duration(milliseconds: 100));

    // Force cleanup
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;

    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;

    if (!_statusController.isClosed) {
      _statusController.add(ConnectionStatus.disconnected);
    }
    _isRunning = false;
  }

  /// Handle messages from the isolate
  void _handleIsolateMessage(dynamic message) {
    if (message is SendPort) {
      // First message is the isolate's send port
      _sendPort = message;
      return;
    }

    if (message is IsolateDataMessage) {
      if (!_dataController.isClosed) {
        _dataController.add(message.data);
      }
      return;
    }

    if (message is IsolateErrorMessage) {
      if (!_errorController.isClosed) {
        _errorController.add(message.error);
      }
      return;
    }

    if (message is IsolateStatusMessage) {
      if (!_statusController.isClosed) {
        _statusController.add(message.status);
      }
      return;
    }
  }

  /// Isolate entry point - runs in background thread
  static Future<void> _isolateEntryPoint(IsolateStartupMessage startup) async {
    final receivePort = ReceivePort();
    final context = IsolateContext(
      sendPort: startup.sendPort,
      config: startup.config,
    );

    // Send our SendPort back to main isolate
    startup.sendPort.send(receivePort.sendPort);

    // Start connection
    await _runConnection(context);

    // Listen for commands from main isolate
    await for (final message in receivePort) {
      if (message == IsolateCommand.shutdown) {
        await context.socket?.close();
        receivePort.close();
        break;
      }
    }
  }

  /// Run the socket connection and process NMEA sentences
  static Future<void> _runConnection(IsolateContext context) async {
    Socket? socket;
    final buffer = StringBuffer();
    NMEAData? currentData;
    Timer? batchTimer;

    try {
      // Connect to NMEA source
      context.sendStatus(ConnectionStatus.connecting);

      if (context.config.type == ConnectionType.tcp) {
        socket = await Socket.connect(
          context.config.host,
          context.config.port,
          timeout: context.config.timeout,
        );
      } else {
        // UDP not yet implemented
        throw UnimplementedError('UDP support coming soon');
      }

      context.socket = socket;
      context.sendStatus(ConnectionStatus.connected);

      // Set up batch update timer (200ms intervals)
      batchTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (currentData != null) {
          context.sendData(currentData!);
          currentData = null;
        }
      });

      // Process incoming data
      await for (final data in socket) {
        final chunk = String.fromCharCodes(data);
        buffer.write(chunk);

        // Process complete sentences (ending with \n or \r\n)
        while (buffer.toString().contains('\n')) {
          final text = buffer.toString();
          final lineEnd = text.indexOf('\n');
          final sentence = text.substring(0, lineEnd).trim();
          buffer.clear();
          buffer.write(text.substring(lineEnd + 1));

          if (sentence.isEmpty) continue;

          // Parse sentence
          try {
            final parsed = NMEAParser.parseSentence(sentence);
            if (parsed != null) {
              currentData = _updateNMEAData(currentData, parsed);
            }
          } on NMEAError catch (e) {
            context.sendError(e);
          } catch (e) {
            context.sendError(NMEAError(
              type: NMEAErrorType.parseError,
              message: 'Parse error: $e',
              sentence: sentence,
            ));
          }
        }

        // Check for buffer overflow (prevent memory leak)
        if (buffer.length > 4096) {
          context.sendError(NMEAError(
            type: NMEAErrorType.bufferOverflow,
            message: 'Buffer overflow - no line terminator found',
          ));
          buffer.clear();
        }
      }
    } on SocketException catch (e) {
      context.sendStatus(ConnectionStatus.error);
      context.sendError(NMEAError(
        type: NMEAErrorType.connectionError,
        message: 'Socket error: $e',
      ));
    } on TimeoutException catch (e) {
      context.sendStatus(ConnectionStatus.error);
      context.sendError(NMEAError(
        type: NMEAErrorType.timeout,
        message: 'Connection timeout: $e',
      ));
    } catch (e) {
      context.sendStatus(ConnectionStatus.error);
      context.sendError(NMEAError(
        type: NMEAErrorType.unknown,
        message: 'Unknown error: $e',
      ));
    } finally {
      batchTimer?.cancel();
      await socket?.close();
      context.sendStatus(ConnectionStatus.disconnected);
    }
  }

  /// Update NMEAData with new parsed sentence
  static NMEAData _updateNMEAData(NMEAData? current, dynamic parsed) {
    final base = current ?? NMEAData(timestamp: DateTime.now());

    if (parsed is GPGGAData) {
      return base.copyWith(gpgga: parsed, timestamp: DateTime.now());
    } else if (parsed is GPRMCData) {
      return base.copyWith(gprmc: parsed, timestamp: DateTime.now());
    } else if (parsed is GPVTGData) {
      return base.copyWith(gpvtg: parsed, timestamp: DateTime.now());
    } else if (parsed is MWVData) {
      return base.copyWith(mwv: parsed, timestamp: DateTime.now());
    } else if (parsed is DPTData) {
      return base.copyWith(dpt: parsed, timestamp: DateTime.now());
    }

    return base;
  }

  /// Dispose and clean up all resources
  void dispose() {
    disconnect();
    _dataController.close();
    _errorController.close();
    _statusController.close();
  }
}
