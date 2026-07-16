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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Moment",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (current == null)
            const Text('Add today\'s photo when you are ready.')
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                current.photoUrl,
                key: const Key('home-today-moment-photo'),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  width: double.infinity,
                  alignment: Alignment.center,
                  color: BubColors.partnerBubbleLight,
                  child: const Icon(Icons.photo_rounded),
                ),
              ),
            ),
            const SizedBox(height: 10),
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
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BubColors.divider),
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}
