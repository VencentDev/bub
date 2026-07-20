import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatLiveConnection {
  ChatLiveConnection({
    required this.apiBaseUrl,
    required this.accessToken,
    required this.onEvent,
    this.initialReconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 30),
  });

  final String apiBaseUrl;
  final Future<String?> Function() accessToken;
  final Future<void> Function(ChatLiveEvent event) onEvent;
  final Duration initialReconnectDelay;
  final Duration maxReconnectDelay;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _disposed = false;
  Duration _nextReconnectDelay = Duration.zero;

  Future<void> connect() async {
    if (_disposed || _channel != null) {
      return;
    }
    final token = await accessToken();
    if (_disposed || token == null) {
      return;
    }
    try {
      final channel = IOWebSocketChannel.connect(
        _liveUri(apiBaseUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      _channel = channel;
      _nextReconnectDelay = initialReconnectDelay;
      _subscription = channel.stream.listen(
        _handleMessage,
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }

  void _handleMessage(dynamic raw) {
    if (raw is! String) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final type = decoded['type'];
      if (type is String && type.isNotEmpty) {
        unawaited(onEvent(ChatLiveEvent(type)));
      }
    } catch (_) {
      return;
    }
  }

  void _scheduleReconnect() {
    if (_disposed) {
      return;
    }
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _reconnectTimer?.cancel();
    final delay = _nextReconnectDelay == Duration.zero
        ? initialReconnectDelay
        : _nextReconnectDelay;
    _nextReconnectDelay = Duration(
      milliseconds: (delay.inMilliseconds * 2).clamp(
        initialReconnectDelay.inMilliseconds,
        maxReconnectDelay.inMilliseconds,
      ),
    );
    _reconnectTimer = Timer(delay, () => unawaited(connect()));
  }

  Uri _liveUri(String baseUrl) {
    final base = Uri.parse(baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    return base.replace(scheme: scheme, path: '$basePath/api/v1/chat/live');
  }
}

class ChatLiveEvent {
  const ChatLiveEvent(this.type);

  final String type;
}
