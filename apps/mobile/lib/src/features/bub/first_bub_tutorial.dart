import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../theme/bub_colors.dart';

typedef FirstBubTutorialLauncher =
    void Function(BuildContext context, GlobalKey targetKey);

final firstBubTutorialLauncherProvider = Provider<FirstBubTutorialLauncher>(
  (ref) => showFirstBubTutorial,
);

void showFirstBubTutorial(BuildContext context, GlobalKey targetKey) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted || targetKey.currentContext == null) {
      return;
    }

    TutorialCoachMark(
      targets: firstBubTutorialTargets(targetKey),
      colorShadow: BubColors.deepPurple,
      opacityShadow: 0.82,
      paddingFocus: 10,
      pulseEnable: false,
      textSkip: 'Done',
      onSkip: () => true,
    ).show(context: context);
  });
}

List<TargetFocus> firstBubTutorialTargets(GlobalKey targetKey) {
  return [
    TargetFocus(
      identify: 'bub-nav-heart',
      keyTarget: targetKey,
      shape: ShapeLightFocus.Circle,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          child: const _FirstBubTutorialContent(),
        ),
      ],
    ),
  ];
}

class _FirstBubTutorialContent extends StatelessWidget {
  const _FirstBubTutorialContent();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: BubColors.deepPurple.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send a Bub',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap this heart to send a private Bub to your partner. It is the one-tap signal for a quick vibration and notification.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
