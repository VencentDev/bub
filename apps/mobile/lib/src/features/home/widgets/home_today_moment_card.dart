import 'package:flutter/material.dart';

import '../../../api/generated/models/home_today_moment_response.dart';
import '../../../theme/bub_colors.dart';

class HomeTodayMomentCard extends StatelessWidget {
  const HomeTodayMomentCard({
    super.key,
    required this.moment,
    required this.onReact,
  });

  final HomeTodayMomentResponse? moment;
  final VoidCallback onReact;

  @override
  Widget build(BuildContext context) {
    final current = moment;
    return _HomeCard(
      key: const Key('home-today-moment-card'),
      minHeight: 208,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Moment",
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                if (current == null)
                  const Text(
                    "Once you're tethered, your daily photo moments will sparkle here.",
                  )
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      current.photoUrl,
                      key: const Key('home-today-moment-photo'),
                      height: 124,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 124,
                        width: double.infinity,
                        alignment: Alignment.center,
                        color: BubColors.partnerBubbleLight,
                        child: const Icon(Icons.photo_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text(current.localDate)),
                      if (current.partnerReaction != null)
                        Text(
                          current.partnerReaction!,
                          style: const TextStyle(fontSize: 22),
                        )
                      else
                        IconButton(
                          onPressed: onReact,
                          icon: const Icon(Icons.favorite_rounded),
                          color: BubColors.heart,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Image.asset(
            'assets/illustrations/bears/bear3.png',
            key: const Key('home-today-moment-bear'),
            width: 104,
            height: 136,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
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
