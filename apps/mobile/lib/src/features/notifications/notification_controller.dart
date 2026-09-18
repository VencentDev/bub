import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_provider.dart';

enum NotificationCategory {
  message,
  bub,
  safe,
  tether,
  system;

  static NotificationCategory fromJson(String? value) {
    return switch (value?.toUpperCase()) {
      'BUB' => NotificationCategory.bub,
      'SAFE' => NotificationCategory.safe,
      'TETHER' => NotificationCategory.tether,
      'SYSTEM' => NotificationCategory.system,
      _ => NotificationCategory.message,
    };
  }
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.linkPath,
    this.readAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? '',
      category: NotificationCategory.fromJson(json['category'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      linkPath: json['linkPath'] as String?,
      readAt: json['readAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  final String id;
  final NotificationCategory category;
  final String title;
  final String body;
  final String? linkPath;
  final String? readAt;
  final String createdAt;

  bool get unread => readAt == null;

  NotificationItem copyWith({String? readAt}) {
    return NotificationItem(
      id: id,
      category: category,
      title: title,
      body: body,
      linkPath: linkPath,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}

class NotificationSummary {
  const NotificationSummary({required this.unreadCount, this.latest});

  factory NotificationSummary.fromJson(Map<String, dynamic> json) {
    final latest = json['latest'];
    return NotificationSummary(
      unreadCount: json['unreadCount'] as int? ?? 0,
      latest: latest is Map<String, dynamic>
          ? NotificationItem.fromJson(latest)
          : null,
    );
  }

  final int unreadCount;
  final NotificationItem? latest;
}

class NotificationListState {
  const NotificationListState({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  factory NotificationListState.fromJson(Map<String, dynamic> json) {
    return NotificationListState(
      items: [
        for (final item in (json['items'] as List? ?? const []))
          if (item is Map<String, dynamic>) NotificationItem.fromJson(item),
      ],
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] == true,
    );
  }

  final List<NotificationItem> items;
  final String? nextCursor;
  final bool hasMore;

  NotificationListState copyWith({
    List<NotificationItem>? items,
    String? nextCursor,
    bool? hasMore,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class NotificationSummaryController extends AsyncNotifier<NotificationSummary> {
  @override
  Future<NotificationSummary> build() async {
    final response = await ref
        .read(dioProvider)
        .get<Map<String, dynamic>>('/api/v1/notifications/summary');
    return NotificationSummary.fromJson(response.data ?? const {});
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(build);
  }
}

class NotificationListController extends AsyncNotifier<NotificationListState> {
  @override
  Future<NotificationListState> build() async {
    final response = await ref
        .read(dioProvider)
        .get<Map<String, dynamic>>(
          '/api/v1/notifications',
          queryParameters: {'limit': 20},
        );
    return NotificationListState.fromJson(response.data ?? const {});
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> markRead(String notificationId) async {
    await ref
        .read(dioProvider)
        .post<Map<String, dynamic>>(
          '/api/v1/notifications/$notificationId/read',
        );
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          items: [
            for (final item in current.items)
              item.id == notificationId
                  ? item.copyWith(
                      readAt: DateTime.now().toUtc().toIso8601String(),
                    )
                  : item,
          ],
        ),
      );
    }
    ref.invalidate(notificationSummaryProvider);
  }

  Future<void> markAllRead() async {
    await ref
        .read(dioProvider)
        .post<Map<String, dynamic>>('/api/v1/notifications/read-all');
    final current = state.value;
    if (current != null) {
      final readAt = DateTime.now().toUtc().toIso8601String();
      state = AsyncData(
        current.copyWith(
          items: [
            for (final item in current.items) item.copyWith(readAt: readAt),
          ],
        ),
      );
    }
    ref.invalidate(notificationSummaryProvider);
  }
}

final notificationSummaryProvider =
    AsyncNotifierProvider<NotificationSummaryController, NotificationSummary>(
      NotificationSummaryController.new,
    );

final notificationListProvider =
    AsyncNotifierProvider<NotificationListController, NotificationListState>(
      NotificationListController.new,
    );
