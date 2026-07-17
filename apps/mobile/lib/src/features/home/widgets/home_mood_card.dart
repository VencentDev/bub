import 'package:flutter/material.dart';

import '../../../api/generated/models/home_mood_summary_response.dart';
import '../../../theme/bub_colors.dart';

class HomeMoodCard extends StatelessWidget {
  const HomeMoodCard({super.key, required this.mood, required this.onSaveMood});

  final HomeMoodSummaryResponse mood;
  final ValueChanged<String> onSaveMood;

  @override
  Widget build(BuildContext context) {
    final currentMood = mood.mood?.trim();

    return _HomeCard(
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
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _MoodDialog(initialMood: initialMood),
    );

    if (result != null) {
      onSaveMood(result);
    }
  }
}

class _MoodDialog extends StatefulWidget {
  const _MoodDialog({required this.initialMood});

  final String initialMood;

  @override
  State<_MoodDialog> createState() => _MoodDialogState();
}

class _MoodDialogState extends State<_MoodDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMood);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mood'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('home-mood-dialog-field'),
          controller: _controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(hintText: 'How are you?'),
          validator: (value) {
            final mood = value?.trim() ?? '';
            if (mood.isEmpty) {
              return 'Mood is required';
            }
            if (mood.length > 20) {
              return 'Use 20 characters or fewer';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
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
