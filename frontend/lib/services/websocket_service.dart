import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class WebSocketService {
  late WebSocketChannel _channel;
  bool _isConnected = false;

  // Connect to the WebSocket server
  void connect(String userId) {
    if (_isConnected) return; // Avoid multiple connections

    _channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.0.102:3000'), // Replace with your backend WebSocket URL
    );

    // Send userId to the server to establish the WebSocket connection
    _channel.sink.add(json.encode({'userId': userId}));
    _isConnected = true;

    // Listen for incoming messages
    _channel.stream.listen(
      (message) {
        _handleMessage(message);
      },
      onError: (error) {
        print('Error in WebSocket connection: $error');
        _isConnected = false;
      },
      onDone: () {
        print('WebSocket connection closed');
        _isConnected = false;
      },
    );
  }

  // Handle different types of messages
void _handleMessage(dynamic message) {
  final decodedMessage = json.decode(message);
  if (decodedMessage.containsKey('message')) {
    print(decodedMessage['message']);  // This will print only "Your request has been accepted."
  }
}


  // Listen for messages from the server
  Stream<dynamic> get messages => _channel.stream;

  // Send a message (e.g., for notifications)
  void sendMessage(String message) {
    if (_isConnected) {
      _channel.sink.add(json.encode({'message': message}));
    } else {
      print('WebSocket is not connected');
    }
  }

  // Close the connection
  void close() {
    if (_isConnected) {
      _channel.sink.close();
      _isConnected = false;
    }
  }
}
