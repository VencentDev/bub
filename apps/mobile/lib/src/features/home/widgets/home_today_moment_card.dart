import 'package:flutter/material.dart';

import '../../../api/generated/models/home_mood_summary_response.dart';
import '../../../api/generated/models/home_today_moment_response.dart';
import '../../../theme/bub_colors.dart';
import 'home_card_shell.dart';
import 'home_mood_dialog.dart';

class HomeTodayMomentCard extends StatelessWidget {
  const HomeTodayMomentCard({
    super.key,
    required this.moment,
    required this.onReact,
    this.mood,
    this.onSaveMood,
    this.showMoodPill = false,
  });

  final HomeTodayMomentResponse? moment;
  final VoidCallback onReact;
  final HomeMoodSummaryResponse? mood;
  final ValueChanged<String>? onSaveMood;
  final bool showMoodPill;

  @override
  Widget build(BuildContext context) {
    final current = moment;
    return HomeCardShell(
      key: const Key('home-today-moment-card'),
      treatment: HomeCardTreatment.todayMoment,
      minHeight: 208,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        "Today's Moment",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (showMoodPill)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: _TodayMoodPill(
                          mood: mood,
                          onSaveMood: onSaveMood,
                        ),
                      ),
                  ],
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
                      current.photoUrl ?? '',
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
                      Expanded(child: Text(_dateLabel(current.localDate))),
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

String _dateLabel(DateTime? date) {
  if (date == null) {
    return '';
  }
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class _TodayMoodPill extends StatelessWidget {
  const _TodayMoodPill({required this.mood, required this.onSaveMood});

  final HomeMoodSummaryResponse? mood;
  final ValueChanged<String>? onSaveMood;

  @override
  Widget build(BuildContext context) {
    final currentMood = mood?.mood?.trim();
    final hasMood = currentMood != null && currentMood.isNotEmpty;
    final label = hasMood ? 'Mood: $currentMood' : 'Add mood';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('home-today-moment-mood-pill'),
        borderRadius: BorderRadius.circular(999),
        onTap: () async {
          final saveMood = onSaveMood;
          if (saveMood == null) {
            return;
          }
          final result = await showHomeMoodDialog(
            context,
            initialMood: hasMood ? currentMood : '',
          );
          if (result != null) {
            saveMood(result);
          }
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: BubColors.white.withValues(alpha: 0.64),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: BubColors.pink.withValues(alpha: 0.26)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mood_rounded,
                    color: BubColors.heart,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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
        ),
      ),
    );
  }
}
