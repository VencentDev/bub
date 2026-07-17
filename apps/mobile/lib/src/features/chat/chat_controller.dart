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

class ChatThreadController extends AsyncNotifier<ChatThreadResponse> {
  @override
  Future<ChatThreadResponse> build() {
    return ref.read(restClientProvider).chatController.getChatThread();
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
      return ref.read(restClientProvider).chatController.getChatThread();
    });
  }
}

final chatThreadProvider =
    AsyncNotifierProvider<ChatThreadController, ChatThreadResponse>(
      ChatThreadController.new,
    );
