import 'dart:io';

import 'package:bub/src/api/generated/models/chat_attachment_response.dart';
import 'package:bub/src/api/generated/models/chat_attachment_response_type.dart';
import 'package:bub/src/api/generated/models/chat_message_response.dart';
import 'package:bub/src/api/generated/models/chat_message_response_delivery_state.dart';
import 'package:bub/src/api/generated/models/chat_message_response_type.dart';
import 'package:bub/src/api/generated/models/chat_presence_response.dart';
import 'package:bub/src/api/generated/models/chat_presence_response_status.dart';
import 'package:bub/src/api/generated/models/chat_reaction_summary_response.dart';
import 'package:bub/src/api/generated/models/chat_reply_preview_response.dart';
import 'package:bub/src/api/generated/models/chat_send_message_request_type.dart';
import 'package:bub/src/api/generated/models/chat_state_response.dart';
import 'package:bub/src/api/generated/models/chat_thread_response.dart';
import 'package:bub/src/features/chat/chat_controller.dart';
import 'package:bub/src/features/chat/chat_media_picker.dart';
import 'package:bub/src/features/chat/chat_section.dart';
import 'package:bub/src/theme/bub_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chat section renders loading and retry states', (tester) async {
    await tester.pumpWidget(_app(const AsyncLoading()));

    expect(find.byKey(const Key('chat-loading')), findsOneWidget);

    await tester.pumpWidget(
      _app(AsyncError(Exception('nope'), StackTrace.empty)),
    );

    expect(find.text('Chat could not load'), findsOneWidget);
    expect(find.byKey(const Key('chat-retry-button')), findsOneWidget);
  });

  testWidgets('untethered chat renders tether image and no composer', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const AsyncData(
          ChatThreadResponse(hasActiveTether: false, messages: []),
        ),
      ),
    );
    await tester.pump();

    final image = tester.widget<Image>(
      find.byKey(const Key('chat-empty-image')),
    );
    expect(
      (image.image as AssetImage).assetName,
      'assets/onboarding/tether.png',
    );
    expect(
      find.text('Tether someone to start your conversation'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-composer-field')), findsNothing);
  });

  testWidgets('thread renders message types, delivery, typing, and presence', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AsyncData(_thread())));
    await tester.pump();

    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Typing...'), findsOneWidget);
    expect(find.text('hi'), findsOneWidget);
    expect(find.text('❤️'), findsWidgets);
    expect(find.text('GIF'), findsOneWidget);
    expect(find.text('This message was deleted'), findsOneWidget);
    expect(find.text('Seen'), findsNothing);
    expect(find.byKey(const Key('chat-message-row-mine')), findsOneWidget);
    expect(find.byKey(const Key('chat-message-row-partner')), findsOneWidget);
  });

  testWidgets('blank send is ignored and valid text send clears input', (
    tester,
  ) async {
    final controller = _FakeChatController(_thread());
    await tester.pumpWidget(_appWithController(controller));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('chat-composer-field')), '   ');
    await tester.pump();
    expect(find.byKey(const Key('chat-send-button')), findsNothing);
    expect(controller.sentBodies, isEmpty);

    await tester.enterText(
      find.byKey(const Key('chat-composer-field')),
      'hello',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();

    expect(controller.sentBodies, ['hello']);
    expect(find.text('hello'), findsNothing);
  });

  testWidgets(
    'composer is minimal and swaps emoji action for send while typing',
    (tester) async {
      final controller = _FakeChatController(_thread());
      await tester.pumpWidget(_appWithController(controller));
      await tester.pump();

      expect(find.byKey(const Key('chat-gif-button')), findsNothing);
      expect(find.byKey(const Key('chat-send-button')), findsNothing);
      expect(find.byKey(const Key('chat-emoji-button')), findsOneWidget);
      expect(find.byKey(const Key('chat-attachment-button')), findsOneWidget);
      expect(
        find.byKey(const Key('chat-quick-reaction-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('chat-emoji-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-emoji-picker')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('chat-composer-field')),
        'hey',
      );
      await tester.pump();

      expect(find.byKey(const Key('chat-emoji-button')), findsNothing);
      expect(find.byKey(const Key('chat-attachment-button')), findsNothing);
      expect(find.byKey(const Key('chat-send-button')), findsOneWidget);
      expect(find.byKey(const Key('chat-quick-reaction-button')), findsNothing);
    },
  );

  testWidgets('quick reaction sends an emoji from the send slot', (
    tester,
  ) async {
    final controller = _FakeChatController(_thread());
    await tester.pumpWidget(_appWithController(controller));
    await tester.pump();

    await tester.tap(find.byKey(const Key('chat-quick-reaction-button')));
    await tester.pumpAndSettle();

    expect(controller.sentBodies, ['❤️']);
  });

  testWidgets('attachment button opens inline media picker below composer', (
    tester,
  ) async {
    final controller = _FakeChatController(_thread());
    final picker = _FakeChatMediaPicker(
      media: [
        ChatMediaItem(id: 'one', file: File('/tmp/one.png')),
        ChatMediaItem(id: 'clip', file: File('/tmp/clip.mp4'), isVideo: true),
      ],
    );
    await tester.pumpWidget(
      _appWithController(controller, mediaPicker: picker),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('chat-attachment-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-inline-media-picker')), findsOneWidget);
    expect(
      find.byKey(const Key('chat-inline-media-quick-mode')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('chat-inline-media-safe-mode')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-inline-media-item-one')), findsOneWidget);
    expect(
      find.byKey(const Key('chat-inline-media-item-clip')),
      findsOneWidget,
    );
    expect(picker.recentMediaCount, 1);
  });

  testWidgets('inline media picker uses a 3-column grid and expands height', (
    tester,
  ) async {
    final controller = _FakeChatController(_thread());
    final picker = _FakeChatMediaPicker(
      media: [
        for (var index = 0; index < 12; index += 1)
          ChatMediaItem(id: 'item-$index', file: File('/tmp/item-$index.png')),
      ],
    );
    await tester.pumpWidget(
      _appWithController(controller, mediaPicker: picker),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('chat-attachment-button')));
    await tester.pumpAndSettle();

    final collapsedGrid = tester.widget<GridView>(
      find.byKey(const Key('chat-inline-media-grid')),
    );
    final collapsedDelegate =
        collapsedGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(collapsedDelegate.crossAxisCount, 3);
    final collapsedHeight = tester
        .getSize(find.byKey(const Key('chat-inline-media-grid-frame')))
        .height;

    await tester.tap(find.byKey(const Key('chat-inline-media-expand-button')));
    await tester.pumpAndSettle();

    final expandedHeight = tester
        .getSize(find.byKey(const Key('chat-inline-media-grid-frame')))
        .height;
    expect(expandedHeight, greaterThan(collapsedHeight));
  });

  testWidgets('safe media stages from inline picker before notice', (
    tester,
  ) async {
    final controller = _FakeChatController(_thread());
    final picker = _FakeChatMediaPicker(
      media: [ChatMediaItem(id: 'one', file: File('/tmp/one.png'))],
    );
    await tester.pumpWidget(
      _appWithController(controller, mediaPicker: picker),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('chat-attachment-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-inline-media-safe-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-inline-media-item-one')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-staged-media-tray')), findsOneWidget);
    expect(find.byKey(const Key('chat-staged-media-0')), findsOneWidget);
    expect(find.text('New media added to Safe'), findsNothing);
    expect(controller.uploadedPaths, isEmpty);
    expect(picker.recentMediaCount, 1);

    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('New media added to Safe'), findsOneWidget);
    expect(find.byKey(const Key('chat-staged-media-tray')), findsNothing);
    expect(controller.uploadedPaths, isEmpty);
  });

  testWidgets('quick media attachment stages previews before upload', (
    tester,
  ) async {
    final controller = _FakeChatController(_thread());
    final picker = _FakeChatMediaPicker(
      media: [
        ChatMediaItem(id: 'one', file: File('/tmp/one.png')),
        ChatMediaItem(id: 'clip', file: File('/tmp/clip.mp4'), isVideo: true),
      ],
    );
    await tester.pumpWidget(
      _appWithController(controller, mediaPicker: picker),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('chat-attachment-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-inline-media-item-one')));
    await tester.tap(find.byKey(const Key('chat-inline-media-item-clip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-staged-media-tray')), findsOneWidget);
    expect(find.byKey(const Key('chat-staged-media-0')), findsOneWidget);
    expect(find.byKey(const Key('chat-staged-media-1')), findsOneWidget);
    expect(controller.uploadedPaths, isEmpty);
    expect(picker.recentMediaCount, 1);

    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();

    expect(controller.uploadedPaths, ['/tmp/one.png', '/tmp/clip.mp4']);
    expect(find.byKey(const Key('chat-staged-media-tray')), findsNothing);
    expect(picker.recentMediaCount, 1);
  });

  testWidgets('composer keeps focus while typing and clearing text', (
    tester,
  ) async {
    final controller = _FakeChatController(_thread());
    await tester.pumpWidget(_appWithController(controller));
    await tester.pump();

    await tester.tap(find.byKey(const Key('chat-composer-field')));
    await tester.pump();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);

    await tester.enterText(find.byKey(const Key('chat-composer-field')), 'h');
    await tester.pump();
    await tester.pump();
    expect(editable.focusNode.hasFocus, isTrue);

    await tester.enterText(find.byKey(const Key('chat-composer-field')), '');
    await tester.pump();
    await tester.pump();
    expect(editable.focusNode.hasFocus, isTrue);
  });

  testWidgets('mobile back hides emoji picker before leaving chat', (
    tester,
  ) async {
    var backCount = 0;
    final controller = _FakeChatController(_thread());
    await tester.pumpWidget(
      _appWithController(
        controller,
        onBack: () {
          backCount += 1;
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('chat-emoji-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-emoji-picker')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-emoji-picker')), findsNothing);
    expect(backCount, 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(backCount, 1);
  });

  testWidgets('delivery checks only render below latest outgoing message', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AsyncData(_threadWithOutgoingRun())));
    await tester.pump();

    expect(find.byKey(const Key('chat-delivery-checks-mine-1')), findsNothing);
    expect(
      find.byKey(const Key('chat-delivery-checks-mine-2')),
      findsOneWidget,
    );
    expect(find.text('Seen'), findsNothing);
  });

  testWidgets('delivery checks disappear after partner replies', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AsyncData(_threadWithPartnerReply())));
    await tester.pump();

    expect(find.byKey(const Key('chat-delivery-checks-mine-2')), findsNothing);
  });

  testWidgets('time dividers appear only after five minute message gaps', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AsyncData(_threadWithTimeGap())));
    await tester.pump();

    expect(
      find.byKey(const Key('chat-time-divider-mine-late')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('chat-time-divider-leading-line-mine-late')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('chat-time-divider-trailing-line-mine-late')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-time-divider-mine-2')), findsNothing);
  });

  testWidgets('message reactions float at the bubble corner', (tester) async {
    await tester.pumpWidget(_app(AsyncData(_threadWithReaction())));
    await tester.pump();

    final bubble = tester.getRect(
      find.byKey(const Key('chat-message-bubble-reacted')),
    );
    final reactions = tester.getRect(
      find.byKey(const Key('chat-message-reactions-reacted')),
    );

    expect(find.text('😂 2'), findsOneWidget);
    expect(reactions.top, greaterThan(bubble.center.dy));
    expect(reactions.right, greaterThan(bubble.right - 40));
  });

  testWidgets('deleted messages do not render reaction badges', (tester) async {
    await tester.pumpWidget(_app(AsyncData(_threadWithDeletedReaction())));
    await tester.pump();

    expect(find.text('This message was deleted'), findsOneWidget);
    expect(
      find.byKey(const Key('chat-message-reactions-deleted')),
      findsNothing,
    );
    expect(find.text('😂 2'), findsNothing);
  });

  testWidgets('reply previews overlap above the message bubble', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AsyncData(_threadWithReply())));
    await tester.pump();

    final reply = tester.getRect(
      find.byKey(const Key('chat-reply-overlap-replying')),
    );
    final bubble = tester.getRect(
      find.byKey(const Key('chat-message-bubble-replying')),
    );
    final body = tester.getRect(find.text('reply body'));

    expect(find.text('original message'), findsOneWidget);
    expect(reply.bottom, greaterThan(bubble.top));
    expect(reply.top, lessThan(bubble.top));
    expect(body.top, greaterThan(reply.bottom + 4));
    expect(body.top - bubble.top, lessThan(16));
    expect(
      find.byKey(const Key('chat-reply-overlap-accent-replying')),
      findsNothing,
    );
  });

  testWidgets('swiping partner message starts a reply', (tester) async {
    final controller = _FakeChatController(_thread());
    await tester.pumpWidget(_appWithController(controller));
    await tester.pump();

    await tester.drag(
      find.byKey(const Key('chat-message-row-partner')),
      const Offset(96, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-reply-preview')), findsOneWidget);
  });

  testWidgets('swiping viewer message starts a reply', (tester) async {
    final controller = _FakeChatController(_thread());
    await tester.pumpWidget(_appWithController(controller));
    await tester.pump();

    await tester.drag(
      find.byKey(const Key('chat-message-row-mine')),
      const Offset(-96, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-reply-preview')), findsOneWidget);
  });

  testWidgets('long press opens Messenger-style message actions', (
    tester,
  ) async {
    final controller = _FakeChatController(_thread());
    await tester.pumpWidget(_appWithController(controller));
    await tester.pump();

    expect(find.byKey(const Key('chat-message-actions-mine')), findsNothing);
    expect(find.byKey(const Key('chat-message-actions-partner')), findsNothing);

    await tester.longPress(find.byKey(const Key('chat-message-row-mine')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-message-action-sheet')), findsOneWidget);
    expect(find.byKey(const Key('chat-reaction-row')), findsOneWidget);
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete for me'), findsOneWidget);
    expect(find.text('Delete for everyone'), findsOneWidget);
    expect(find.text('🔥'), findsOneWidget);

    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-reply-preview')), findsOneWidget);

    await tester.longPress(find.byKey(const Key('chat-message-row-mine')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🔥'));
    await tester.pumpAndSettle();
    expect(controller.reactions, ['🔥']);
  });

  testWidgets('media messages render image stacks and separate video tiles', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AsyncData(_threadWithMedia())));
    await tester.pump();

    expect(
      find.byKey(const Key('chat-image-stack-media-images')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('chat-video-attachment-video-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('chat-image-stack-media-images')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-media-viewer')), findsOneWidget);
  });
}

Widget _app(AsyncValue<ChatThreadResponse> state) {
  return ProviderScope(
    overrides: [
      chatThreadProvider.overrideWith(() => _StateChatController(state)),
    ],
    child: MaterialApp(
      theme: BubTheme.light,
      home: const Scaffold(body: ChatSection()),
    ),
  );
}

Widget _appWithController(
  _FakeChatController controller, {
  VoidCallback? onBack,
  ChatMediaPicker? mediaPicker,
}) {
  return ProviderScope(
    overrides: [
      chatThreadProvider.overrideWith(() => controller),
      if (mediaPicker != null)
        chatMediaPickerProvider.overrideWithValue(mediaPicker),
    ],
    child: MaterialApp(
      theme: BubTheme.light,
      home: Scaffold(body: ChatSection(onBack: onBack)),
    ),
  );
}

ChatThreadResponse _thread() {
  final baseTime = DateTime(2026, 7, 20, 9);
  return ChatThreadResponse(
    hasActiveTether: true,
    partnerDisplayName: 'Bob',
    state: const ChatStateResponseFixture().typingOnline,
    messages: [
      ChatMessageResponse(
        id: 'mine',
        viewerMessage: true,
        type: ChatMessageResponseType.text,
        body: 'hi',
        deliveryState: ChatMessageResponseDeliveryState.seen,
        createdAt: baseTime,
        editable: true,
        deletableForEveryone: true,
      ),
      ChatMessageResponse(
        id: 'partner',
        viewerMessage: false,
        type: ChatMessageResponseType.emoji,
        body: '❤️',
        createdAt: baseTime.add(const Duration(minutes: 1)),
      ),
      ChatMessageResponse(
        id: 'gif',
        viewerMessage: false,
        type: ChatMessageResponseType.gif,
        gifUrl: 'https://cdn.example.com/gif.gif',
        createdAt: baseTime.add(const Duration(minutes: 2)),
      ),
      ChatMessageResponse(
        id: 'deleted',
        viewerMessage: false,
        type: ChatMessageResponseType.text,
        deletedForEveryone: true,
        createdAt: baseTime.add(const Duration(minutes: 3)),
      ),
    ],
  );
}

ChatThreadResponse _threadWithOutgoingRun() {
  final baseTime = DateTime(2026, 7, 20, 9);
  return ChatThreadResponse(
    hasActiveTether: true,
    partnerDisplayName: 'Bob',
    messages: [
      ChatMessageResponse(
        id: 'mine-1',
        viewerMessage: true,
        type: ChatMessageResponseType.text,
        body: 'one',
        deliveryState: ChatMessageResponseDeliveryState.delivered,
        createdAt: baseTime,
      ),
      ChatMessageResponse(
        id: 'mine-2',
        viewerMessage: true,
        type: ChatMessageResponseType.text,
        body: 'two',
        deliveryState: ChatMessageResponseDeliveryState.seen,
        createdAt: baseTime.add(const Duration(minutes: 1)),
      ),
    ],
  );
}

ChatThreadResponse _threadWithPartnerReply() {
  final baseTime = DateTime(2026, 7, 20, 9);
  return ChatThreadResponse(
    hasActiveTether: true,
    partnerDisplayName: 'Bob',
    messages: [
      ChatMessageResponse(
        id: 'mine-2',
        viewerMessage: true,
        type: ChatMessageResponseType.text,
        body: 'two',
        deliveryState: ChatMessageResponseDeliveryState.seen,
        createdAt: baseTime,
      ),
      ChatMessageResponse(
        id: 'partner-reply',
        viewerMessage: false,
        type: ChatMessageResponseType.text,
        body: 'reply',
        createdAt: baseTime.add(const Duration(minutes: 1)),
      ),
    ],
  );
}

ChatThreadResponse _threadWithTimeGap() {
  final baseTime = DateTime(2026, 7, 20, 9);
  return ChatThreadResponse(
    hasActiveTether: true,
    partnerDisplayName: 'Bob',
    messages: [
      ChatMessageResponse(
        id: 'mine-1',
        viewerMessage: true,
        type: ChatMessageResponseType.text,
        body: 'one',
        createdAt: baseTime,
      ),
      ChatMessageResponse(
        id: 'mine-2',
        viewerMessage: true,
        type: ChatMessageResponseType.text,
        body: 'two',
        createdAt: baseTime.add(const Duration(minutes: 1)),
      ),
      ChatMessageResponse(
        id: 'mine-late',
        viewerMessage: true,
        type: ChatMessageResponseType.text,
        body: 'late',
        createdAt: baseTime.add(const Duration(minutes: 6)),
      ),
    ],
  );
}

ChatThreadResponse _threadWithReaction() {
  return ChatThreadResponse(
    hasActiveTether: true,
    partnerDisplayName: 'Bob',
    messages: [
      ChatMessageResponse(
        id: 'reacted',
        viewerMessage: true,
        type: ChatMessageResponseType.text,
        body: 'react to this',
        createdAt: DateTime(2026, 7, 20, 9),
        reactions: const [
          ChatReactionSummaryResponse(reaction: '😂', count: 2),
        ],
      ),
    ],
  );
}

ChatThreadResponse _threadWithDeletedReaction() {
  return ChatThreadResponse(
    hasActiveTether: true,
    partnerDisplayName: 'Bob',
    messages: [
      ChatMessageResponse(
        id: 'deleted',
        viewerMessage: true,
        type: ChatMessageResponseType.text,
        body: 'gone',
        deletedForEveryone: true,
        createdAt: DateTime(2026, 7, 20, 9),
        reactions: const [
          ChatReactionSummaryResponse(reaction: '😂', count: 2),
        ],
      ),
    ],
  );
}

ChatThreadResponse _threadWithReply() {
  return ChatThreadResponse(
    hasActiveTether: true,
    partnerDisplayName: 'Bob',
    messages: [
      ChatMessageResponse(
        id: 'replying',
        viewerMessage: true,
        type: ChatMessageResponseType.text,
        body: 'reply body',
        createdAt: DateTime(2026, 7, 20, 9),
        reply: const ChatReplyPreviewResponse(
          id: 'original',
          snippet: 'original message',
        ),
      ),
    ],
  );
}

ChatThreadResponse _threadWithMedia() {
  final baseTime = DateTime(2026, 7, 20, 9);
  return ChatThreadResponse(
    hasActiveTether: true,
    partnerDisplayName: 'Bob',
    messages: [
      ChatMessageResponse(
        id: 'media-images',
        viewerMessage: true,
        type: ChatMessageResponseType.media,
        createdAt: baseTime,
        attachments: const [
          ChatAttachmentResponse(
            id: 'image-1',
            type: ChatAttachmentResponseType.image,
            url: 'https://example.com/one.png',
          ),
          ChatAttachmentResponse(
            id: 'image-2',
            type: ChatAttachmentResponseType.image,
            url: 'https://example.com/two.png',
          ),
        ],
      ),
      ChatMessageResponse(
        id: 'media-video',
        viewerMessage: false,
        type: ChatMessageResponseType.media,
        createdAt: baseTime.add(const Duration(minutes: 1)),
        attachments: const [
          ChatAttachmentResponse(
            id: 'video-1',
            type: ChatAttachmentResponseType.video,
            url: 'https://example.com/one.mp4',
          ),
        ],
      ),
    ],
  );
}

class ChatStateResponseFixture {
  const ChatStateResponseFixture();

  ChatStateResponse get typingOnline => const ChatStateResponse(
    partnerTyping: true,
    partnerPresence: ChatPresenceResponse(
      status: ChatPresenceResponseStatus.online,
    ),
  );
}

class _StateChatController extends ChatThreadController {
  _StateChatController(this.initial);

  final AsyncValue<ChatThreadResponse> initial;

  @override
  Future<ChatThreadResponse> build() async {
    if (initial case AsyncData(:final value)) {
      return value;
    }
    if (initial case AsyncError(:final error, :final stackTrace)) {
      Error.throwWithStackTrace(error, stackTrace);
    }
    return Future<ChatThreadResponse>.delayed(const Duration(seconds: 30));
  }
}

class _FakeChatController extends ChatThreadController {
  _FakeChatController(this.initial);

  final ChatThreadResponse initial;
  final sentBodies = <String>[];
  final reactions = <String>[];
  final uploadedPaths = <String>[];

  @override
  Future<ChatThreadResponse> build() async => initial;

  @override
  Future<void> sendMessage({
    required ChatSendMessageRequestType type,
    String? body,
    String? gifUrl,
    String? gifProviderId,
    String? replyToMessageId,
  }) async {
    if (body != null) {
      sentBodies.add(body);
    }
  }

  @override
  Future<void> reactToMessage(String messageId, String reaction) async {
    reactions.add(reaction);
  }

  @override
  Future<void> uploadMedia({
    required List<File> files,
    String? replyToMessageId,
  }) async {
    uploadedPaths.addAll(files.map((file) => file.path));
  }
}

class _FakeChatMediaPicker implements ChatMediaPicker {
  _FakeChatMediaPicker({this.media = const []});

  final List<ChatMediaItem> media;
  var recentMediaCount = 0;

  @override
  Future<List<ChatMediaItem>> recentMedia() async {
    recentMediaCount += 1;
    return media;
  }
}
