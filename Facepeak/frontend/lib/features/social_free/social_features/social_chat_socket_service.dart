import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:frontend/features/social_free/services/social_message_service.dart';

class SocialChatSocketService {
  SocialChatSocketService._();

  static final SocialChatSocketService instance = SocialChatSocketService._();

  static const String _wsBaseUrl =
      'ws://192.168.88.100:8000/api/v1/ws/social-chat';

  WebSocketChannel? _channel;
  StreamSubscription? _socketSub;

  final StreamController<Map<String, dynamic>> _eventsController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventsController.stream;

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  bool _connecting = false;
  bool _connected = false;
  bool _manuallyClosed = false;

  int _reconnectAttempt = 0;

  bool get isConnected => _connected;

  Future<void> connect() async {
    if (_connected || _connecting) return;

    _connecting = true;
    _manuallyClosed = false;

    try {
      final token = await SocialMessageService.getAuthTokenForSocket();
      final encodedToken = Uri.encodeComponent(token);

      final uri = Uri.parse('$_wsBaseUrl?token=$encodedToken');

      debugPrint("🔌 SOCIAL_WS connecting...");

      final channel = WebSocketChannel.connect(uri);
      _channel = channel;

      _socketSub = channel.stream.listen(
        _handleRawEvent,
        onDone: _handleDisconnected,
        onError: (error) {
          debugPrint("❌ SOCIAL_WS error: $error");
          _handleDisconnected();
        },
        cancelOnError: true,
      );

      _connected = true;
      _connecting = false;
      _reconnectAttempt = 0;

      _startHeartbeat();

      debugPrint("✅ SOCIAL_WS connected");
    } catch (e) {
      debugPrint("❌ SOCIAL_WS connect failed: $e");

      _connected = false;
      _connecting = false;

      _scheduleReconnect();
    }
  }

  void _handleRawEvent(dynamic raw) {
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;

      if (decoded is! Map) return;

      final event = Map<String, dynamic>.from(decoded);

      final type = event["type"];

      if (type == "pong") {
        return;
      }

      _eventsController.add(event);
    } catch (e) {
      debugPrint("❌ SOCIAL_WS decode error: $e");
    }
  }

  void sendDeliveredAck({
    required int messageId,
  }) {
    if (messageId <= 0) return;

    send({
      "type": "delivered_ack",
      "message_id": messageId,
    });
  }

  void sendSeen({
    required int conversationId,
  }) {
    if (conversationId <= 0) return;

    send({
      "type": "seen",
      "conversation_id": conversationId,
    });
  }

  void send(Map<String, dynamic> data) {
    if (!_connected || _channel == null) {
      debugPrint("⚠️ SOCIAL_WS send skipped, not connected: $data");
      return;
    }

    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint("❌ SOCIAL_WS send failed: $e");
      _handleDisconnected();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        send({
          "type": "heartbeat",
        });
      },
    );
  }

  void _handleDisconnected() {
    if (_manuallyClosed) return;

    if (!_connected && !_connecting) {
      _scheduleReconnect();
      return;
    }

    debugPrint("⚠️ SOCIAL_WS disconnected");

    _connected = false;
    _connecting = false;

    _heartbeatTimer?.cancel();
    _socketSub?.cancel();
    _socketSub = null;
    _channel = null;

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manuallyClosed) return;
    if (_reconnectTimer?.isActive == true) return;

    _reconnectAttempt++;

    final seconds = _reconnectAttempt <= 1
        ? 2
        : _reconnectAttempt <= 2
            ? 4
            : _reconnectAttempt <= 3
                ? 8
                : 15;

    debugPrint("🔁 SOCIAL_WS reconnect in ${seconds}s");

    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      if (_manuallyClosed) return;
      connect();
    });
  }

  Future<void> disconnect() async {
    _manuallyClosed = true;

    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    await _socketSub?.cancel();
    _socketSub = null;

    try {
      await _channel?.sink.close();
    } catch (_) {}

    _channel = null;
    _connected = false;
    _connecting = false;

    debugPrint("🔌 SOCIAL_WS manually disconnected");
  }

  void dispose() {
    disconnect();
    _eventsController.close();
  }
}