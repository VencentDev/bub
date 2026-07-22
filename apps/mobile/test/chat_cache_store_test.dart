import 'package:bub/src/api/generated/models/chat_message_response.dart';
import 'package:bub/src/api/generated/models/chat_message_response_type.dart';
import 'package:bub/src/api/generated/models/chat_attachment_response.dart';
import 'package:bub/src/api/generated/models/chat_attachment_response_type.dart';
import 'package:bub/src/api/generated/models/chat_thread_response.dart';
import 'package:bub/src/features/chat/chat_cache_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'cache returns only records for the active user and tether pair',
    () async {
      final store = MemoryChatCacheStore();
      final aliceTether = _thread(
        tetherConnectionId: 'tether-a',
        messageId: 'alice-message',
      );
      final bobTether = _thread(
        tetherConnectionId: 'tether-b',
        messageId: 'bob-message',
      );

      await store.writeLatest(userId: 'alice@example.com', thread: aliceTether);
      await store.writeLatest(userId: 'bob@example.com', thread: bobTether);

      final cached = await store.readLatest(
        userId: 'alice@example.com',
        tetherConnectionId: 'tether-a',
      );

      expect(cached?.messages?.single.id, 'alice-message');
      expect(
        await store.readLatest(
          userId: 'alice@example.com',
          tetherConnectionId: 'tether-b',
        ),
        isNull,
      );
    },
  );

  test('cache clear removes records for removed tether', () async {
    final store = MemoryChatCacheStore();
    await store.writeLatest(
      userId: 'alice@example.com',
      thread: _thread(tetherConnectionId: 'tether-a', messageId: 'one'),
    );

    await store.clearTether(
      userId: 'alice@example.com',
      tetherConnectionId: 'tether-a',
    );

    expect(await store.readActiveLatest(userId: 'alice@example.com'), isNull);
    expect(store.evictedImageUrls, ['https://example.com/one.png']);
  });

  test('cache keeps only the latest recent messages', () async {
    final store = MemoryChatCacheStore();

    await store.writeLatest(
      userId: 'alice@example.com',
      thread: ChatThreadResponse(
        hasActiveTether: true,
        tetherConnectionId: 'tether-a',
        messages: [
          for (var index = 0; index < 55; index++)
            ChatMessageResponse(
              id: 'message-$index',
              type: ChatMessageResponseType.text,
              createdAt: DateTime.utc(2026, 7, 20, 9, index),
            ),
        ],
      ),
    );

    final cached = await store.readActiveLatest(userId: 'alice@example.com');

    expect(cached?.messages, hasLength(chatRecentCacheLimit));
    expect(cached?.messages?.first.id, 'message-5');
    expect(cached?.messages?.last.id, 'message-54');
  });
}

ChatThreadResponse _thread({
  required String tetherConnectionId,
  required String messageId,
}) {
  return ChatThreadResponse(
    hasActiveTether: true,
    tetherConnectionId: tetherConnectionId,
    partnerDisplayName: 'Bob',
    hasMoreBefore: true,
    oldestCursor: '2026-07-20T09:00:00Z',
    messages: [
      ChatMessageResponse(
        id: messageId,
        type: ChatMessageResponseType.media,
        createdAt: DateTime.utc(2026, 7, 20, 9),
        attachments: const [
          ChatAttachmentResponse(
            id: 'image-one',
            type: ChatAttachmentResponseType.image,
            url: 'https://example.com/one.png',
          ),
        ],
      ),
    ],
  );
}
