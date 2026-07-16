import 'package:flutter/material.dart';

import '../../../api/generated/models/home_latest_bub_response.dart';
import '../../../theme/bub_colors.dart';

class HomeLatestBubCard extends StatelessWidget {
  const HomeLatestBubCard({super.key, required this.latestBub});

  final HomeLatestBubResponse latestBub;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: BubColors.purple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  latestBub.copy,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (latestBub.occurredAt != null)
                  Text(_relativeTime(latestBub.occurredAt!)),
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
