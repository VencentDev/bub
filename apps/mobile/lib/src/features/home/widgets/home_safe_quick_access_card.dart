import 'package:flutter/material.dart';

import '../../../api/generated/models/home_safe_summary_response.dart';
import '../../../theme/bub_colors.dart';

class HomeSafeQuickAccessCard extends StatelessWidget {
  const HomeSafeQuickAccessCard({
    super.key,
    required this.safe,
    required this.onOpenSafe,
  });

  final HomeSafeSummaryResponse safe;
  final VoidCallback onOpenSafe;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: BubColors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safe',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                Text(safe.copy, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          TextButton(onPressed: onOpenSafe, child: Text(safe.ctaLabel)),
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
