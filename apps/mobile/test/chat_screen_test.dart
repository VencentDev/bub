import 'package:bub/src/api/generated/models/chat_message_response.dart';
import 'package:bub/src/api/generated/models/chat_message_response_delivery_state.dart';
import 'package:bub/src/api/generated/models/chat_message_response_type.dart';
import 'package:bub/src/api/generated/models/chat_presence_response.dart';
import 'package:bub/src/api/generated/models/chat_presence_response_status.dart';
import 'package:bub/src/api/generated/models/chat_send_message_request_type.dart';
import 'package:bub/src/api/generated/models/chat_state_response.dart';
import 'package:bub/src/api/generated/models/chat_thread_response.dart';
import 'package:bub/src/features/chat/chat_controller.dart';
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
    expect(find.text('Seen'), findsOneWidget);
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
    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pump();
    expect(controller.sentBodies, isEmpty);

    await tester.enterText(
      find.byKey(const Key('chat-composer-field')),
      'hello',
    );
    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();

    expect(controller.sentBodies, ['hello']);
    expect(find.text('hello'), findsNothing);
  });

  testWidgets('message actions expose reply and reactions', (tester) async {
    final controller = _FakeChatController(_thread());
    await tester.pumpWidget(_appWithController(controller));
    await tester.pump();

    await tester.tap(find.byKey(const Key('chat-message-actions-mine')));
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete for everyone'), findsOneWidget);
    expect(find.text('🔥'), findsOneWidget);

    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-reply-preview')), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-message-actions-mine')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🔥'));
    await tester.pumpAndSettle();
    expect(controller.reactions, ['🔥']);
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

Widget _appWithController(_FakeChatController controller) {
  return ProviderScope(
    overrides: [chatThreadProvider.overrideWith(() => controller)],
    child: MaterialApp(
      theme: BubTheme.light,
      home: const Scaffold(body: ChatSection()),
    ),
  );
}

ChatThreadResponse _thread() {
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
        editable: true,
        deletableForEveryone: true,
      ),
      const ChatMessageResponse(
        id: 'partner',
        viewerMessage: false,
        type: ChatMessageResponseType.emoji,
        body: '❤️',
      ),
      const ChatMessageResponse(
        id: 'gif',
        viewerMessage: false,
        type: ChatMessageResponseType.gif,
        gifUrl: 'https://cdn.example.com/gif.gif',
      ),
      const ChatMessageResponse(
        id: 'deleted',
        viewerMessage: false,
        type: ChatMessageResponseType.text,
        deletedForEveryone: true,
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
}
