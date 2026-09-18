import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/generated/models/chat_edit_message_request.dart';
import '../../api/generated/models/chat_partner_nickname_request.dart';
import '../../api/generated/models/chat_reaction_request.dart';
import '../../api/generated/models/chat_read_request.dart';
import '../../api/generated/models/chat_send_message_request.dart';
import '../../api/generated/models/chat_send_message_request_type.dart';
import '../../api/generated/models/chat_state_response.dart';
import '../../api/generated/models/chat_thread_response.dart';
import '../../api/generated/models/chat_typing_request.dart';
import '../../core/dio_provider.dart';
import '../../core/env.dart';
import 'chat_cache_store.dart';
import 'chat_live_connection.dart';

class ChatThreadController extends AsyncNotifier<ChatThreadResponse> {
  ChatLiveConnection? _liveConnection;
  bool _refreshingFromLive = false;
  bool _loadingOlder = false;
  String? _userId;

  @override
  Future<ChatThreadResponse> build() async {
    ref.onDispose(() => _liveConnection?.dispose());
    final userId = await ref.read(authServiceProvider).cacheUserId();
    _userId = userId;
    if (userId != null) {
      final cached = await ref
          .read(chatCacheStoreProvider)
          .readActiveLatest(userId: userId);
      if (cached != null) {
        _syncLiveConnection(cached);
        unawaited(_refreshCachedThread(userId: userId));
        return cached;
      }
    }
    return _refreshFromNetwork(userId: userId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final userId = _userId ?? await ref.read(authServiceProvider).cacheUserId();
    _userId = userId;
    state = await AsyncValue.guard(() => _refreshFromNetwork(userId: userId));
  }

  Future<void> loadOlder() async {
    if (_loadingOlder) {
      return;
    }
    final current = switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final cursor = current?.oldestCursor;
    if (current?.hasMoreBefore != true || cursor == null || cursor.isEmpty) {
      return;
    }
    _loadingOlder = true;
    try {
      final older = await _fetchThread(beforeCreatedAt: cursor);
      final merged = _mergeOlderMessages(current!, older);
      await _cacheThread(merged);
      _syncLiveConnection(merged);
      state = AsyncData(merged);
    } finally {
      _loadingOlder = false;
    }
  }

  Future<void> loadAroundDate(DateTime date) async {
    state = await AsyncValue.guard(() async {
      final thread = await _fetchThread(aroundDate: date);
      await _cacheThread(thread);
      _syncLiveConnection(thread);
      return thread;
    });
  }

  Future<void> sendMessage({
    required ChatSendMessageRequestType type,
    String? body,
    String? gifUrl,
    String? gifProviderId,
    String? replyToMessageId,
  }) async {
    final trimmedBody = body?.trim();
    if ((type == ChatSendMessageRequestType.text ||
            type == ChatSendMessageRequestType.emoji) &&
        (trimmedBody == null || trimmedBody.isEmpty)) {
      return;
    }
    if (type == ChatSendMessageRequestType.gif &&
        ((gifUrl == null || gifUrl.trim().isEmpty) ||
            (gifProviderId == null || gifProviderId.trim().isEmpty))) {
      return;
    }

    await _mutateAndRefresh(() {
      return ref
          .read(restClientProvider)
          .chatController
          .sendChatMessage(
            body: ChatSendMessageRequest(
              type: type,
              body: trimmedBody,
              gifUrl: gifUrl?.trim(),
              gifProviderId: gifProviderId?.trim(),
              replyToMessageId: replyToMessageId,
            ),
          );
    });
  }

  Future<void> uploadMedia({
    required List<File> files,
    String? replyToMessageId,
  }) async {
    if (files.isEmpty) {
      return;
    }
    await _mutateAndRefresh(() {
      return ref
          .read(restClientProvider)
          .chatController
          .uploadChatMediaMessage(
            files: files,
            replyToMessageId: replyToMessageId,
          );
    });
  }

  Future<void> editMessage(String messageId, String body) async {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      return;
    }
    await _mutateAndRefresh(() {
      return ref
          .read(restClientProvider)
          .chatController
          .editChatMessage(
            messageId: messageId,
            body: ChatEditMessageRequest(body: trimmedBody),
          );
    });
  }

  Future<void> deleteForMe(String messageId) async {
    await _mutateAndRefresh(() {
      return ref
          .read(restClientProvider)
          .chatController
          .deleteChatMessageForMe(messageId: messageId);
    });
  }

  Future<void> deleteForEveryone(String messageId) async {
    await _mutateAndRefresh(() {
      return ref
          .read(restClientProvider)
          .chatController
          .deleteChatMessageForEveryone(messageId: messageId);
    });
  }

  Future<void> reactToMessage(String messageId, String reaction) async {
    await _mutateAndRefresh(() {
      return ref
          .read(restClientProvider)
          .chatController
          .reactToChatMessage(
            messageId: messageId,
            body: ChatReactionRequest(reaction: reaction),
          );
    });
  }

  Future<void> removeReaction(String messageId) async {
    await _mutateAndRefresh(() {
      return ref
          .read(restClientProvider)
          .chatController
          .removeChatMessageReaction(messageId: messageId);
    });
  }

  Future<void> updatePartnerNickname(String nickname) async {
    state = await AsyncValue.guard(() async {
      final thread = await ref
          .read(restClientProvider)
          .chatController
          .updateChatPartnerNickname(
            body: ChatPartnerNicknameRequest(nickname: nickname.trim()),
          );
      _syncLiveConnection(thread);
      return thread;
    });
  }

  Future<void> markRead(String upToMessageId) async {
    await _mutateAndRefresh(() {
      return ref
          .read(restClientProvider)
          .chatController
          .markChatMessagesRead(
            body: ChatReadRequest(upToMessageId: upToMessageId),
          );
    });
  }

  Future<ChatStateResponse?> setTyping(bool typing) async {
    final response = await ref
        .read(restClientProvider)
        .chatController
        .setChatTyping(body: ChatTypingRequest(typing: typing));
    return response;
  }

  Future<ChatStateResponse?> refreshState() {
    return ref.read(restClientProvider).chatController.getChatState();
  }

  Future<void> _mutateAndRefresh(Future<Object?> Function() mutation) async {
    state = await AsyncValue.guard(() async {
      await mutation();
      return _refreshFromNetwork(userId: _userId);
    });
  }

  Future<ChatThreadResponse> _refreshFromNetwork({
    required String? userId,
  }) async {
    final thread = await _fetchThread();
    await _cacheThread(thread, userId: userId);
    _syncLiveConnection(thread);
    return thread;
  }

  Future<void> _refreshCachedThread({required String userId}) async {
    try {
      final thread = await _refreshFromNetwork(userId: userId);
      state = AsyncData(thread);
    } catch (_) {
      // Cached chat should remain visible if the background refresh fails.
    }
  }

  Future<ChatThreadResponse> _fetchThread({
    String? beforeCreatedAt,
    DateTime? aroundDate,
  }) async {
    final response = await ref
        .read(dioProvider)
        .get<Map<String, Object?>>(
          '/api/v1/chat/thread',
          queryParameters: {
            'limit': chatRecentCacheLimit,
            'beforeCreatedAt': ?beforeCreatedAt,
            if (aroundDate != null) 'aroundDate': _dateOnly(aroundDate),
          },
        );
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Chat thread response was empty.',
      );
    }
    return ChatThreadResponse.fromJson(data);
  }

  Future<void> _cacheThread(ChatThreadResponse thread, {String? userId}) async {
    final resolvedUserId =
        userId ?? _userId ?? await ref.read(authServiceProvider).cacheUserId();
    _userId = resolvedUserId;
    if (resolvedUserId == null) {
      return;
    }
    await ref
        .read(chatCacheStoreProvider)
        .writeLatest(userId: resolvedUserId, thread: thread);
  }

  ChatThreadResponse _mergeOlderMessages(
    ChatThreadResponse current,
    ChatThreadResponse older,
  ) {
    final currentMessages = current.messages ?? const [];
    final existingIds = {
      for (final message in currentMessages)
        if (message.id != null) message.id!,
    };
    final olderMessages = [
      for (final message in older.messages ?? const [])
        if (message.id == null || !existingIds.contains(message.id)) message,
    ];
    return ChatThreadResponse(
      hasActiveTether: older.hasActiveTether ?? current.hasActiveTether,
      tetherConnectionId:
          older.tetherConnectionId ?? current.tetherConnectionId,
      partnerDisplayName:
          older.partnerDisplayName ?? current.partnerDisplayName,
      state: older.state ?? current.state,
      messages: [...olderMessages, ...currentMessages],
      hasMoreBefore: older.hasMoreBefore,
      oldestCursor: older.oldestCursor ?? current.oldestCursor,
    );
  }

  void _syncLiveConnection(ChatThreadResponse thread) {
    if (thread.hasActiveTether != true) {
      _liveConnection?.dispose();
      _liveConnection = null;
      return;
    }
    if (_liveConnection != null) {
      return;
    }
    _liveConnection = ChatLiveConnection(
      apiBaseUrl: Env.apiBaseUrl,
      accessToken: ref.read(authServiceProvider).validAccessToken,
      onEvent: (_) => _refreshFromLive(),
    );
    _liveConnection!.connect();
  }

  Future<void> _refreshFromLive() async {
    if (_refreshingFromLive) {
      return;
    }
    _refreshingFromLive = true;
    try {
      final thread = await _refreshFromNetwork(userId: _userId);
      state = AsyncData(thread);
    } catch (_) {
      // Background live refresh failures should not replace the visible thread.
    } finally {
      _refreshingFromLive = false;
    }
  }
}

String _dateOnly(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

final chatThreadProvider =
    AsyncNotifierProvider<ChatThreadController, ChatThreadResponse>(
      ChatThreadController.new,
    );
