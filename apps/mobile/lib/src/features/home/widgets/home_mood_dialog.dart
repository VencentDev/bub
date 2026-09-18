import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/bub_colors.dart';
import '../../../widgets/bub_dialog_sheet.dart';

Future<String?> showHomeMoodDialog(
  BuildContext context, {
  String initialMood = '',
}) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (context) => _HomeMoodDialog(initialMood: initialMood),
  );
}

class _HomeMoodDialog extends StatefulWidget {
  const _HomeMoodDialog({required this.initialMood});

  final String initialMood;

  @override
  State<_HomeMoodDialog> createState() => _HomeMoodDialogState();
}

class _HomeMoodDialogState extends State<_HomeMoodDialog> {
  static const _quickMoods = ['Cozy', 'Happy', 'Miss you', 'Sleepy'];

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? BubColors.white : BubColors.textPrimaryLight;
    final softTextColor = isDark
        ? BubColors.textSecondaryDark
        : BubColors.textSecondaryLight;
    final inputFill = isDark
        ? BubColors.darkSurface
        : BubColors.purple.withValues(alpha: 0.04);

    return BubDialogSheet(
      key: const Key('home-mood-dialog-glass'),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BubDialogHeader(
              icon: Icons.favorite_border_rounded,
              title: 'Mood check',
              subtitle: 'A tiny feeling for your Bub.',
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final mood in _quickMoods)
                  _MoodChip(
                    mood: mood,
                    selected: _controller.text.trim() == mood,
                    onTap: () {
                      setState(() {
                        _controller.text = mood;
                        _controller.selection = TextSelection.collapsed(
                          offset: mood.length,
                        );
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('home-mood-dialog-field'),
              controller: _controller,
              autofocus: true,
              maxLength: 20,
              maxLengthEnforcement: MaxLengthEnforcement.none,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'How are you feeling?',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                prefixIcon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: BubColors.purple.withValues(alpha: 0.70),
                ),
                counterStyle: TextStyle(color: softTextColor, fontSize: 11),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: BubColors.purple.withValues(alpha: 0.14),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: BubColors.purple.withValues(alpha: 0.14),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: BubColors.purple,
                    width: 1.4,
                  ),
                ),
              ),
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
            const SizedBox(height: 6),
            BubDialogActions(
              onCancel: () => Navigator.of(context).pop(),
              confirmLabel: 'Save',
              onConfirm: () {
                if (_formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(_controller.text.trim());
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final String mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = selected
        ? BubColors.white
        : isDark
        ? BubColors.textSecondaryDark
        : BubColors.deepPurple;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? BubColors.purple
              : BubColors.purple.withValues(alpha: isDark ? 0.14 : 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? BubColors.purple
                : BubColors.purple.withValues(alpha: isDark ? 0.20 : 0.14),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            mood,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
