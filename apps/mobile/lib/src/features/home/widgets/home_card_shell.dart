import 'package:flutter/material.dart';

import '../../../theme/bub_colors.dart';

enum HomeCardTreatment { todayMoment, partner, latestBub, mood }

class HomeCardShell extends StatelessWidget {
  const HomeCardShell({
    super.key,
    required this.child,
    required this.treatment,
    this.minHeight,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final HomeCardTreatment treatment;
  final double? minHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: switch (treatment) {
          HomeCardTreatment.todayMoment => BubColors.homeTodayMomentGradient(
            brightness,
          ),
          HomeCardTreatment.partner => BubColors.homePartnerGradient(
            brightness,
          ),
          HomeCardTreatment.latestBub => BubColors.homeLatestBubGradient(
            brightness,
          ),
          HomeCardTreatment.mood => BubColors.homeMoodGradient(brightness),
        },
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: brightness == Brightness.dark
              ? BubColors.white.withValues(alpha: 0.10)
              : BubColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: BubColors.deepPurple.withValues(
              alpha: brightness == Brightness.dark ? 0.28 : 0.10,
            ),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight ?? 0),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
