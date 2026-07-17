import 'package:flutter/material.dart';

import '../../../api/generated/models/home_latest_bub_response.dart';
import '../../../theme/bub_colors.dart';
import 'home_card_shell.dart';

class HomeLatestBubCard extends StatelessWidget {
  const HomeLatestBubCard({super.key, required this.latestBub});

  final HomeLatestBubResponse latestBub;

  @override
  Widget build(BuildContext context) {
    final hasActivity = latestBub.hasActivity == true;
    return HomeCardShell(
      key: const Key('home-latest-bub-card'),
      treatment: HomeCardTreatment.latestBub,
      minHeight: hasActivity ? 166 : 132,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/onboarding/bub.png',
            key: const Key('home-latest-bub-art'),
            width: hasActivity ? 120 : 98,
            height: hasActivity ? 128 : 104,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasActivity) ...[
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: BubColors.purple,
                        size: 18,
                      ),
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
                ],
                Text(
                  hasActivity
                      ? latestBub.copy ?? 'Latest Bub'
                      : 'Tether to send bub',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!hasActivity) ...[
                  const SizedBox(height: 10),
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
