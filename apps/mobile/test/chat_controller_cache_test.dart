import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bub/src/api/generated/models/chat_message_response.dart';
import 'package:bub/src/api/generated/models/chat_message_response_type.dart';
import 'package:bub/src/api/generated/models/chat_thread_response.dart';
import 'package:bub/src/auth/auth_service.dart';
import 'package:bub/src/auth/token_store.dart';
import 'package:bub/src/core/dio_provider.dart';
import 'package:bub/src/features/chat/chat_cache_store.dart';
import 'package:bub/src/features/chat/chat_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  test('controller returns cached recent thread while refreshing', () async {
    final store = MemoryChatCacheStore();
    await store.writeLatest(
      userId: 'alice@example.com',
      thread: _thread(messageId: 'cached', body: 'cached message'),
    );
    final adapter = _PendingThreadAdapter(
      _thread(messageId: 'network', body: 'network message'),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(_CachedAuthService()),
        chatCacheStoreProvider.overrideWithValue(store),
        dioProvider.overrideWithValue(dio),
      ],
    );
    addTearDown(container.dispose);

    final cached = await container.read(chatThreadProvider.future);
    await Future<void>.delayed(Duration.zero);

    expect(cached.messages?.single.body, 'cached message');
    await adapter.firstRequest.timeout(const Duration(seconds: 1));
    expect(adapter.requests.single.queryParameters['limit'], 50);

    adapter.complete();
    final refreshed = await _waitForThreadBody(container, 'network message');
    expect(refreshed?.messages?.single.body, 'network message');
  });
}

Future<ChatThreadResponse?> _waitForThreadBody(
  ProviderContainer container,
  String body,
) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    final thread = switch (container.read(chatThreadProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (thread?.messages?.single.body == body) {
      return thread;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return switch (container.read(chatThreadProvider)) {
    AsyncData(:final value) => value,
    _ => null,
  };
}

ChatThreadResponse _thread({required String messageId, required String body}) {
  return ChatThreadResponse(
    hasActiveTether: true,
    tetherConnectionId: 'tether-a',
    partnerDisplayName: 'Bob',
    hasMoreBefore: false,
    oldestCursor: '2026-07-20T09:00:00Z',
    messages: [
      ChatMessageResponse(
        id: messageId,
        type: ChatMessageResponseType.text,
        body: body,
        createdAt: DateTime.utc(2026, 7, 20, 9),
      ),
    ],
  );
}

class _CachedAuthService extends AuthService {
  _CachedAuthService()
    : super(GoogleSignIn.instance, TokenStore(const FlutterSecureStorage()));

  @override
  Future<String?> cacheUserId() async => 'alice@example.com';

  @override
  Future<String?> validAccessToken() async => null;
}

class _PendingThreadAdapter implements HttpClientAdapter {
  _PendingThreadAdapter(this.thread);

  final ChatThreadResponse thread;
  final requests = <RequestOptions>[];
  final _completer = Completer<ResponseBody>();
  final _firstRequest = Completer<RequestOptions>();

  Future<RequestOptions> get firstRequest => _firstRequest.future;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    if (!_firstRequest.isCompleted) {
      _firstRequest.complete(options);
    }
    return _completer.future;
  }

  void complete() {
    if (_completer.isCompleted) {
      return;
    }
    _completer.complete(
      ResponseBody.fromString(
        jsonEncode(_threadJson(thread)),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _threadJson(ChatThreadResponse thread) {
  return {
    'hasActiveTether': thread.hasActiveTether,
    'tetherConnectionId': thread.tetherConnectionId,
    'partnerDisplayName': thread.partnerDisplayName,
    'state': thread.state,
    'hasMoreBefore': thread.hasMoreBefore,
    'oldestCursor': thread.oldestCursor,
    'messages': [
      for (final message in thread.messages ?? const [])
        {
          'id': message.id,
          'senderUserId': message.senderUserId,
          'viewerMessage': message.viewerMessage,
          'type': message.type?.toJson(),
          'body': message.body,
          'createdAt': message.createdAt?.toIso8601String(),
        },
    ],
  };
}
