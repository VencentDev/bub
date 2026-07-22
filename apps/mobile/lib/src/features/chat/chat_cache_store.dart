import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../api/generated/models/chat_attachment_response_type.dart';
import '../../api/generated/models/chat_thread_response.dart';
import '../../core/dio_provider.dart';

const chatRecentCacheLimit = 50;

typedef ChatImageEvictor = Future<void> Function(String url);

abstract interface class ChatCacheStore {
  Future<ChatThreadResponse?> readActiveLatest({required String userId});

  Future<ChatThreadResponse?> readLatest({
    required String userId,
    required String tetherConnectionId,
  });

  Future<void> writeLatest({
    required String userId,
    required ChatThreadResponse thread,
  });

  Future<void> clearTether({
    required String userId,
    required String tetherConnectionId,
  });

  Future<void> clearUser({required String userId});
}

class SecureChatCacheStore implements ChatCacheStore {
  SecureChatCacheStore(
    this._storage, {
    ChatImageEvictor imageEvictor = evictChatImageUrl,
  }) : _imageEvictor = imageEvictor;

  final FlutterSecureStorage _storage;
  final ChatImageEvictor _imageEvictor;

  @override
  Future<ChatThreadResponse?> readActiveLatest({required String userId}) async {
    final tetherConnectionId = await _storage.read(
      key: _activeTetherKey(userId),
    );
    if (tetherConnectionId == null || tetherConnectionId.isEmpty) {
      return null;
    }
    return readLatest(userId: userId, tetherConnectionId: tetherConnectionId);
  }

  @override
  Future<ChatThreadResponse?> readLatest({
    required String userId,
    required String tetherConnectionId,
  }) async {
    final raw = await _storage.read(
      key: _threadKey(userId, tetherConnectionId),
    );
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    return ChatThreadResponse.fromJson(decoded);
  }

  @override
  Future<void> writeLatest({
    required String userId,
    required ChatThreadResponse thread,
  }) async {
    final tetherConnectionId = thread.tetherConnectionId;
    if (thread.hasActiveTether != true ||
        tetherConnectionId == null ||
        tetherConnectionId.isEmpty) {
      await clearUser(userId: userId);
      return;
    }
    final recentThread = _recentOnly(thread);
    await Future.wait([
      _storage.write(key: _activeTetherKey(userId), value: tetherConnectionId),
      _storage.write(
        key: _threadKey(userId, tetherConnectionId),
        value: jsonEncode(recentThread.toJson(), toEncodable: _toJsonValue),
      ),
    ]);
  }

  @override
  Future<void> clearTether({
    required String userId,
    required String tetherConnectionId,
  }) async {
    final cached = await readLatest(
      userId: userId,
      tetherConnectionId: tetherConnectionId,
    );
    await _evictThreadImages(cached);
    final activeTether = await _storage.read(key: _activeTetherKey(userId));
    await Future.wait([
      _storage.delete(key: _threadKey(userId, tetherConnectionId)),
      if (activeTether == tetherConnectionId)
        _storage.delete(key: _activeTetherKey(userId)),
    ]);
  }

  @override
  Future<void> clearUser({required String userId}) async {
    final activeThread = await readActiveLatest(userId: userId);
    await _evictThreadImages(activeThread);
    final activeTether = activeThread?.tetherConnectionId;
    await Future.wait([
      _storage.delete(key: _activeTetherKey(userId)),
      if (activeTether != null)
        _storage.delete(key: _threadKey(userId, activeTether)),
    ]);
  }

  Future<void> _evictThreadImages(ChatThreadResponse? thread) async {
    for (final url in chatImageUrls(thread)) {
      await _imageEvictor(url);
    }
  }
}

class MemoryChatCacheStore implements ChatCacheStore {
  MemoryChatCacheStore({ChatImageEvictor? imageEvictor})
    : _imageEvictor = imageEvictor;

  final ChatImageEvictor? _imageEvictor;
  final _activeTethers = <String, String>{};
  final _threads = <String, ChatThreadResponse>{};
  final evictedImageUrls = <String>[];

  @override
  Future<ChatThreadResponse?> readActiveLatest({required String userId}) async {
    final tetherConnectionId = _activeTethers[userId];
    if (tetherConnectionId == null) {
      return null;
    }
    return readLatest(userId: userId, tetherConnectionId: tetherConnectionId);
  }

  @override
  Future<ChatThreadResponse?> readLatest({
    required String userId,
    required String tetherConnectionId,
  }) async {
    return _threads[_threadKey(userId, tetherConnectionId)];
  }

  @override
  Future<void> writeLatest({
    required String userId,
    required ChatThreadResponse thread,
  }) async {
    final tetherConnectionId = thread.tetherConnectionId;
    if (thread.hasActiveTether != true ||
        tetherConnectionId == null ||
        tetherConnectionId.isEmpty) {
      await clearUser(userId: userId);
      return;
    }
    _activeTethers[userId] = tetherConnectionId;
    _threads[_threadKey(userId, tetherConnectionId)] = _recentOnly(thread);
  }

  @override
  Future<void> clearTether({
    required String userId,
    required String tetherConnectionId,
  }) async {
    final thread = _threads.remove(_threadKey(userId, tetherConnectionId));
    if (_activeTethers[userId] == tetherConnectionId) {
      _activeTethers.remove(userId);
    }
    for (final url in chatImageUrls(thread)) {
      final imageEvictor = _imageEvictor;
      if (imageEvictor == null) {
        evictedImageUrls.add(url);
      } else {
        await imageEvictor(url);
      }
    }
  }

  @override
  Future<void> clearUser({required String userId}) async {
    final activeTether = _activeTethers.remove(userId);
    if (activeTether == null) {
      return;
    }
    await clearTether(userId: userId, tetherConnectionId: activeTether);
  }
}

Future<void> evictChatImageUrl(String url) {
  return NetworkImage(url).evict();
}

Iterable<String> chatImageUrls(ChatThreadResponse? thread) sync* {
  for (final message in thread?.messages ?? const []) {
    for (final attachment in message.attachments ?? const []) {
      if (attachment.type == ChatAttachmentResponseType.image) {
        final url = attachment.url;
        if (url != null && _isNetworkUrl(url)) {
          yield url;
        }
      }
    }
  }
}

ChatThreadResponse _recentOnly(ChatThreadResponse thread) {
  final messages = thread.messages ?? const [];
  final start = messages.length > chatRecentCacheLimit
      ? messages.length - chatRecentCacheLimit
      : 0;
  return ChatThreadResponse(
    hasActiveTether: thread.hasActiveTether,
    tetherConnectionId: thread.tetherConnectionId,
    partnerDisplayName: thread.partnerDisplayName,
    state: thread.state,
    messages: messages.sublist(start),
    hasMoreBefore: thread.hasMoreBefore,
    oldestCursor: thread.oldestCursor,
  );
}

String _activeTetherKey(String userId) => 'chat_cache_active_tether:$userId';

String _threadKey(String userId, String tetherConnectionId) {
  return 'chat_cache_thread:$userId:$tetherConnectionId';
}

bool _isNetworkUrl(String url) {
  final lower = url.toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

Object? _toJsonValue(Object? value) {
  if (value is DateTime) {
    return value.toIso8601String();
  }
  if (value is Enum) {
    final dynamic jsonEnum = value;
    return jsonEnum.toJson();
  }
  final dynamic jsonObject = value;
  return jsonObject.toJson();
}

final chatCacheStoreProvider = Provider<ChatCacheStore>(
  (ref) => SecureChatCacheStore(ref.watch(secureStorageProvider)),
);
