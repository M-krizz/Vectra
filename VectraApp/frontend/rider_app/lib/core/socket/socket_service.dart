import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared/shared.dart';

class SocketService {
  io.Socket? _socket;
  final StorageService _storageService;

  bool _isConnected = false;

  final StreamController<Map<String, dynamic>> _rideStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _driverLocationController =
      StreamController<Map<String, dynamic>>.broadcast();

  SocketService({required StorageService storageService})
      : _storageService = storageService;

  Stream<Map<String, dynamic>> get rideStatusStream =>
      _rideStatusController.stream;
  Stream<Map<String, dynamic>> get driverLocationStream =>
      _driverLocationController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_socket != null && _isConnected) return;

    final accessToken = await _storageService.getAccessToken();
    if (accessToken == null) return;

    _socket = io.io(
      ApiConstants.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': accessToken})
          .build(),
    );

    _setupEventHandlers();
    _socket!.connect();
  }

  void _setupEventHandlers() {
    final socket = _socket!;

    socket.onConnect((_) {
      _isConnected = true;
      socket.emit('authenticate', {'token': 'auto'});
    });

    socket.onDisconnect((_) {
      _isConnected = false;
    });

    socket.on('ride:status', (data) {
      _rideStatusController.add(Map<String, dynamic>.from(data));
    });

    socket.on('driver:location_update', (data) {
      _driverLocationController.add(Map<String, dynamic>.from(data));
    });

    // General events
    socket.on('ride:accepted', (data) {
       _rideStatusController.add({'status': 'ARRIVING', 'data': data});
    });

    socket.on('ride:completed', (data) {
       _rideStatusController.add({'status': 'COMPLETED', 'data': data});
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _rideStatusController.close();
    _driverLocationController.close();
  }
}
