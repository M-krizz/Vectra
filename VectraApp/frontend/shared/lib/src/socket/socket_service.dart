import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';

/// Socket service for real-time communication
class SocketService {
  static SocketService? _instance;
  io.Socket? _socket;
  String? _authToken;

  SocketService._internal();

  static SocketService getInstance() {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  /// Initialize socket connection with auth token
  void connect(String authToken) {
    _authToken = authToken;

    _socket = io.io(
      ApiConstants.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $authToken'})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!.onConnect((_) {
      print('Socket connected');
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });

    _socket!.onConnectError((error) {
      print('Socket connection error: $error');
    });

    _socket!.onError((error) {
      print('Socket error: $error');
    });
  }

  /// Disconnect socket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _authToken = null;
  }

  /// Check if socket is connected
  bool get isConnected => _socket?.connected ?? false;

  /// Emit an event
  void emit(String event, dynamic data) {
    if (_socket != null && isConnected) {
      _socket!.emit(event, data);
    }
  }

  /// Listen to an event
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  /// Remove event listener
  void off(String event) {
    _socket?.off(event);
  }

  /// Reconnect with new token
  void reconnect(String authToken) {
    disconnect();
    connect(authToken);
  }

  /// Get the socket instance
  io.Socket? get socket => _socket;
}
