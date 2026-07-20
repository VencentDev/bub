import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/generated/models/chat_edit_message_request.dart';
import '../../api/generated/models/chat_reaction_request.dart';
import '../../api/generated/models/chat_read_request.dart';
import '../../api/generated/models/chat_send_message_request.dart';
import '../../api/generated/models/chat_send_message_request_type.dart';
import '../../api/generated/models/chat_state_response.dart';
import '../../api/generated/models/chat_thread_response.dart';
import '../../api/generated/models/chat_typing_request.dart';
import '../../core/dio_provider.dart';
import '../../core/env.dart';
import 'chat_live_connection.dart';

class ChatThreadController extends AsyncNotifier<ChatThreadResponse> {
  ChatLiveConnection? _liveConnection;
  bool _refreshingFromLive = false;

  @override
  Future<ChatThreadResponse> build() async {
    ref.onDispose(() => _liveConnection?.dispose());
    final thread = await ref
        .read(restClientProvider)
        .chatController
        .getChatThread();
    _syncLiveConnection(thread);
    return thread;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
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
      final thread = await ref
          .read(restClientProvider)
          .chatController
          .getChatThread();
      _syncLiveConnection(thread);
      return thread;
    });
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
      final thread = await ref
          .read(restClientProvider)
          .chatController
          .getChatThread();
      _syncLiveConnection(thread);
      state = AsyncData(thread);
    } catch (_) {
      // Background live refresh failures should not replace the visible thread.
    } finally {
      _refreshingFromLive = false;
    }
  }
}

final chatThreadProvider =
    AsyncNotifierProvider<ChatThreadController, ChatThreadResponse>(
      ChatThreadController.new,
    );
