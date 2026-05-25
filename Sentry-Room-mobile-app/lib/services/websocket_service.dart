import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final _messages = StreamController<Map<String, dynamic>>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  String? _url;
  bool _closedByUser = false;

  Stream<Map<String, dynamic>> get messages => _messages.stream;

  void connect(String url) {
    _url = url;
    _closedByUser = false;
    _open();
  }

  void _open() {
    final url = _url;
    if (url == null || _closedByUser) return;

    _subscription?.cancel();
    _channel?.sink.close();

    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      _channel = channel;
      _subscription = channel.stream.listen(
        _handleMessage,
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (error) {
      debugPrint('WebSocket connection failed: $error');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic rawMessage) {
    try {
      final data = json.decode(rawMessage.toString());
      if (data is Map<String, dynamic>) {
        _messages.add(data);
      }
    } catch (error) {
      debugPrint('Invalid WebSocket message: $error');
    }
  }

  void _scheduleReconnect() {
    if (_closedByUser || _reconnectTimer?.isActive == true) return;
    _reconnectTimer = Timer(const Duration(seconds: 5), _open);
  }

  void dispose() {
    _closedByUser = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _messages.close();
  }
}
