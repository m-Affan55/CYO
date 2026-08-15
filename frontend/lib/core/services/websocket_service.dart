import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  // Callback for when a message is received
  Function(Map<String, dynamic>)? onMessageReceived;
  Function()? onDisconnected;

  void connect(String roomCode, String userId) {
    final wsUrl = Uri.parse('ws://127.0.0.1:8000/api/game/ws/$roomCode/$userId');
    _channel = WebSocketChannel.connect(wsUrl);

    _subscription = _channel!.stream.listen(
      (message) {
        if (onMessageReceived != null) {
          final data = jsonDecode(message);
          onMessageReceived!(data);
        }
      },
      onDone: () {
        if (onDisconnected != null) onDisconnected!();
      },
      onError: (error) {
        print('WebSocket Error: $error');
        if (onDisconnected != null) onDisconnected!();
      },
    );
  }

  void sendAction(String action, [Map<String, dynamic>? payload]) {
    if (_channel != null) {
      final message = {
        'action': action,
        ...?payload,
      };
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
