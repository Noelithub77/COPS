import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  Function(String) onMessageCallback;

  SocketService({required this.onMessageCallback}) {
    _initializeSocket();
  }

  void _initializeSocket() {
    socket = IO.io('http://127.0.0.1:6969', <String, dynamic>{
      'transports': ['websocket'],
    });
    
    socket.on('connect', (_) {
      onMessageCallback("Socket connected");
    });
    
    socket.on('response', (data) {
      onMessageCallback("Response: $data");
    });
    
    socket.on('disconnect', (_) {
      onMessageCallback("Socket disconnected");
    });
  }

  void sendHandle(String handle) {
    socket.emit('handle', {'handle': handle});
    onMessageCallback("Handle sent: $handle");
  }

  void toggleState(bool state, String handle) {
    socket.emit('toggle', {'state': state});
    if (!state) {
      socket.emit('handle', {'handle': handle});
    }
  }
} 