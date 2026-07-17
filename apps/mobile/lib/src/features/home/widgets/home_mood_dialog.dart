import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/bub_colors.dart';

Future<String?> showHomeMoodDialog(
  BuildContext context, {
  String initialMood = '',
}) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.34),
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
    final panelColor = (isDark ? BubColors.darkDialog : BubColors.white)
        .withValues(alpha: isDark ? 0.82 : 0.78);
    final textColor = isDark ? BubColors.white : BubColors.textPrimaryLight;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -18,
            right: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BubColors.pink.withValues(alpha: isDark ? 0.28 : 0.18),
                borderRadius: BorderRadius.circular(52),
              ),
              child: const SizedBox(width: 94, height: 74),
            ),
          ),
          Positioned(
            bottom: -16,
            left: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BubColors.violet.withValues(alpha: isDark ? 0.24 : 0.18),
                borderRadius: BorderRadius.circular(46),
              ),
              child: const SizedBox(width: 82, height: 66),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                key: const Key('home-mood-dialog-glass'),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: (isDark ? BubColors.white : BubColors.deepPurple)
                        .withValues(alpha: 0.14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BubColors.deepPurple.withValues(
                        alpha: isDark ? 0.38 : 0.18,
                      ),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: BubColors.bubGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.mood_rounded,
                                color: BubColors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Mood',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('home-mood-dialog-field'),
                          controller: _controller,
                          autofocus: true,
                          maxLength: 20,
                          maxLengthEnforcement: MaxLengthEnforcement.none,
                          decoration: InputDecoration(
                            hintText: 'How are you?',
                            fillColor:
                                (isDark
                                        ? BubColors.darkSurface
                                        : BubColors.white)
                                    .withValues(alpha: 0.72),
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
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  Navigator.of(
                                    context,
                                  ).pop(_controller.text.trim());
                                }
                              },
                              child: const Text('Save mood'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
