import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/async_state_widgets.dart';
import '../../theme/bub_colors.dart';
import 'notification_controller.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(notificationSummaryProvider);
    final unreadCount = summary.asData?.value.unreadCount ?? 0;
    return IconButton(
      key: const Key('notifications-button'),
      tooltip: 'Notifications',
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_rounded),
          if (unreadCount > 0)
            Positioned(
              key: const Key('notifications-badge'),
              right: -8,
              top: -8,
              child: _NotificationBadge(count: unreadCount),
            ),
        ],
      ),
    );
  }
}

class NotificationPanel extends ConsumerWidget {
  const NotificationPanel({super.key, this.onOpenLink});

  final ValueChanged<String>? onOpenLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationListProvider);
    return SafeArea(
      child: SizedBox(
        key: const Key('notification-panel'),
        height: MediaQuery.sizeOf(context).height * 0.74,
        child: notifications.when(
          loading: () => const BubLoadingState(
            key: Key('notifications-loading'),
            label: 'Loading notifications',
          ),
          error: (_, _) => _NotificationError(
            onRetry: () =>
                ref.read(notificationListProvider.notifier).refresh(),
          ),
          data: (state) {
            if (state.items.isEmpty) {
              return const _NotificationEmpty();
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              itemCount: state.items.length + 1,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                }
                final item = state.items[index - 1];
                return _NotificationTile(
                  item: item,
                  onTap: () async {
                    await ref
                        .read(notificationListProvider.notifier)
                        .markRead(item.id);
                    final linkPath = item.linkPath;
                    if (linkPath != null && linkPath.isNotEmpty) {
                      onOpenLink?.call(linkPath);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BubColors.coral,
        shape: BoxShape.circle,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: BubColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('notification-item-${item.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      onTap: onTap,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            backgroundColor: BubColors.purple.withValues(alpha: 0.12),
            child: Icon(_categoryIcon(item.category), color: BubColors.purple),
          ),
          if (item.unread)
            Positioned(
              key: Key('notification-unread-dot-${item.id}'),
              right: -1,
              top: -1,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: BubColors.coral,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 10, height: 10),
              ),
            ),
        ],
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        item.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  IconData _categoryIcon(NotificationCategory category) {
    return switch (category) {
      NotificationCategory.bub => Icons.favorite_rounded,
      NotificationCategory.safe => Icons.lock_rounded,
      NotificationCategory.tether => Icons.link_rounded,
      NotificationCategory.system => Icons.info_rounded,
      NotificationCategory.message => Icons.chat_bubble_rounded,
    };
  }
}

class _NotificationEmpty extends StatelessWidget {
  const _NotificationEmpty();

  @override
  Widget build(BuildContext context) {
    return const BubEmptyState(
      key: Key('notifications-empty'),
      title: 'No notifications yet',
      icon: Icons.notifications_none_rounded,
    );
  }
}

class _NotificationError extends StatelessWidget {
  const _NotificationError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BubErrorState(
      key: const Key('notifications-error'),
      title: 'Notifications could not load',
      onRetry: onRetry,
      retryKey: const Key('notifications-retry-button'),
    );
  }
}
