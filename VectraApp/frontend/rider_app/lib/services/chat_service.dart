import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'rides_api.dart'; // To get baseUrl

class ChatService {
  late IO.Socket _socket;
  final StreamController<Map<String, dynamic>> _messageStreamController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;

  void connect(String tripId, String userId) {
    // Construct namespace URL: http://localhost:3000/chat
    final String uri = '${RidesApi.baseUrl}/chat';
    
    _socket = IO.io(uri, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect() // We connect manually
        .build());

    _socket.connect();

    _socket.onConnect((_) {
      print('Connected to Chat Namespace');
      _joinRoom(tripId, userId);
    });

    _socket.on('new_message', (data) {
      _messageStreamController.add(data);
    });

    _socket.onDisconnect((_) => print('Disconnected from Chat'));
  }

  void _joinRoom(String tripId, String userId) {
    _socket.emit('join_trip', {'tripId': tripId, 'userId': userId});
  }

  void sendMessage(String tripId, String userId, String message) {
    _socket.emit('send_message', {
      'tripId': tripId, 
      'senderId': userId, 
      'message': message
    });
  }

  void dispose() {
    _socket.dispose();
    _messageStreamController.close();
  }
}
