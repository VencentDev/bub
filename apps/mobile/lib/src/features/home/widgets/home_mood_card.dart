import 'package:flutter/material.dart';

import '../../../api/generated/models/home_mood_summary_response.dart';
import '../../../theme/bub_colors.dart';
import 'home_card_shell.dart';
import 'home_mood_dialog.dart';

class HomeMoodCard extends StatelessWidget {
  const HomeMoodCard({super.key, required this.mood, required this.onSaveMood});

  final HomeMoodSummaryResponse mood;
  final ValueChanged<String> onSaveMood;

  @override
  Widget build(BuildContext context) {
    final currentMood = mood.mood?.trim();

    return HomeCardShell(
      key: const Key('home-mood-card'),
      treatment: HomeCardTreatment.mood,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.mood_rounded, color: BubColors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mood',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                Text(mood.copy, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (currentMood == null || currentMood.isEmpty)
            FilledButton(
              key: const Key('home-mood-empty-button'),
              onPressed: () => _showMoodDialog(context),
              child: const Text('Add'),
            )
          else
            InkWell(
              key: const Key('home-mood-value'),
              borderRadius: BorderRadius.circular(999),
              onTap: () => _showMoodDialog(context, initialMood: currentMood),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: BubColors.pink.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  child: Text(
                    currentMood,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BubColors.heart,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showMoodDialog(
    BuildContext context, {
    String initialMood = '',
  }) async {
    final result = await showHomeMoodDialog(context, initialMood: initialMood);

    if (result != null) {
      onSaveMood(result);
    }
  }
}
