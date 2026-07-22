import 'package:bub/src/features/notifications/notification_controller.dart';
import 'package:bub/src/features/notifications/notification_panel.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('notification panel renders loading state', (tester) async {
    await tester.pumpWidget(
      _notificationAppWithController(_LoadingNotificationListController()),
    );
    await tester.pump();

    expect(find.byKey(const Key('notifications-loading')), findsOneWidget);
    expect(find.text('Loading notifications'), findsOneWidget);
  });

  testWidgets('notification panel renders error retry state', (tester) async {
    final controller = _ErrorNotificationListController();
    await tester.pumpWidget(_notificationAppWithController(controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notifications-error')), findsOneWidget);
    expect(find.text('Notifications could not load'), findsOneWidget);

    await tester.tap(find.byKey(const Key('notifications-retry-button')));
    await tester.pump();

    expect(controller.refreshCount, 1);
  });

  testWidgets('notification panel renders empty state', (tester) async {
    await tester.pumpWidget(
      _notificationApp(const NotificationListState(items: [], hasMore: false)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification-panel')), findsOneWidget);
    expect(find.byKey(const Key('notifications-empty')), findsOneWidget);
    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('tapping unread notification marks it read', (tester) async {
    final controller = _ReadyNotificationListController(
      const NotificationListState(
        items: [
          NotificationItem(
            id: 'notice-1',
            category: NotificationCategory.safe,
            title: 'Safe updated',
            body: 'A memory was added to Safe',
            linkPath: '/safe',
            createdAt: '2026-07-22T09:00:00Z',
          ),
        ],
        hasMore: false,
      ),
    );

    await tester.pumpWidget(_notificationApp(controller.initial, controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notification-item-notice-1')));
    await tester.pumpAndSettle();

    expect(controller.readIds, ['notice-1']);
    expect(
      find.byKey(const Key('notification-unread-dot-notice-1')),
      findsNothing,
    );
  });
}

Widget _notificationApp(
  NotificationListState state, [
  _ReadyNotificationListController? controller,
]) {
  return _notificationAppWithController(
    controller ?? _ReadyNotificationListController(state),
  );
}

Widget _notificationAppWithController(NotificationListController controller) {
  return ProviderScope(
    overrides: [notificationListProvider.overrideWith(() => controller)],
    child: const MaterialApp(home: Scaffold(body: NotificationPanel())),
  );
}

class _ReadyNotificationListController extends NotificationListController {
  _ReadyNotificationListController(this.initial);

  final NotificationListState initial;
  final readIds = <String>[];

  @override
  Future<NotificationListState> build() async => initial;

  @override
  Future<void> markRead(String notificationId) async {
    readIds.add(notificationId);
    final current = state.value ?? initial;
    state = AsyncData(
      current.copyWith(
        items: [
          for (final item in current.items)
            item.id == notificationId
                ? item.copyWith(readAt: '2026-07-22T09:01:00Z')
                : item,
        ],
      ),
    );
  }
}

class _LoadingNotificationListController extends NotificationListController {
  final _completer = Completer<NotificationListState>();

  @override
  Future<NotificationListState> build() {
    return _completer.future;
  }
}

class _ErrorNotificationListController extends NotificationListController {
  var refreshCount = 0;

  @override
  Future<NotificationListState> build() {
    throw StateError('nope');
  }

  @override
  Future<void> refresh() async {
    refreshCount += 1;
  }
}
