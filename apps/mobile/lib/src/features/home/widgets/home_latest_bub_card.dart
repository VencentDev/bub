import 'package:flutter/material.dart';

import '../../../api/generated/models/home_latest_bub_response.dart';
import '../../../theme/bub_colors.dart';

class HomeLatestBubCard extends StatelessWidget {
  const HomeLatestBubCard({super.key, required this.latestBub});

  final HomeLatestBubResponse latestBub;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      key: const Key('home-latest-bub-card'),
      minHeight: 166,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/onboarding/bub.png',
            key: const Key('home-latest-bub-art'),
            width: 120,
            height: 128,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, color: BubColors.purple, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Latest Bub',
                      style: TextStyle(
                        color: BubColors.purple,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  latestBub.copy,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!latestBub.hasActivity) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Once you're tethered, tiny Bubs from your person will land here.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: BubColors.partnerBubbleLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: BubColors.heart,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Ready for the first Bub',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: BubColors.deepPurple,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (latestBub.occurredAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_relativeTime(latestBub.occurredAt!)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime occurredAt) {
    final minutes = DateTime.now().difference(occurredAt).inMinutes;
    if (minutes < 1) {
      return 'Just now';
    }
    if (minutes < 60) {
      return '$minutes mins ago';
    }
    final hours = minutes ~/ 60;
    return '$hours hours ago';
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({super.key, required this.child, required this.minHeight});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BubColors.divider),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}
