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
    final panelColor = (isDark ? BubColors.darkDialog : BubColors.white)
        .withValues(alpha: isDark ? 0.72 : 0.66);
    final textColor = isDark ? BubColors.white : BubColors.textPrimaryLight;
    final softTextColor = isDark
        ? BubColors.textSecondaryDark
        : BubColors.textSecondaryLight;
    final inputFill = (isDark ? BubColors.darkSurface : BubColors.white)
        .withValues(alpha: isDark ? 0.56 : 0.68);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -28,
            right: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    BubColors.pink.withValues(alpha: isDark ? 0.44 : 0.26),
                    BubColors.pink.withValues(alpha: 0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(width: 132, height: 132),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    BubColors.violet.withValues(alpha: isDark ? 0.36 : 0.24),
                    BubColors.violet.withValues(alpha: 0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(width: 126, height: 126),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: DecoratedBox(
                key: const Key('home-mood-dialog-glass'),
                decoration: BoxDecoration(
                  color: panelColor,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            BubColors.white.withValues(alpha: 0.10),
                            BubColors.darkDialog.withValues(alpha: 0.70),
                            BubColors.pink.withValues(alpha: 0.12),
                          ]
                        : [
                            BubColors.white.withValues(alpha: 0.78),
                            const Color(0xFFFFF4FA).withValues(alpha: 0.64),
                            const Color(0xFFF5EEFF).withValues(alpha: 0.72),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: BubColors.white.withValues(
                      alpha: isDark ? 0.14 : 0.72,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BubColors.deepPurple.withValues(
                        alpha: isDark ? 0.42 : 0.16,
                      ),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: BubColors.pink.withValues(
                        alpha: isDark ? 0.18 : 0.12,
                      ),
                      blurRadius: 36,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: BubColors.bubGradient,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: BubColors.pink.withValues(
                                      alpha: 0.28,
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: BubColors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mood check',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Leave a tiny feeling for your Bub.',
                                    style: TextStyle(
                                      color: softTextColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: 'Close',
                              icon: const Icon(Icons.close_rounded),
                              color: softTextColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final mood in _quickMoods)
                              _MoodChip(
                                mood: mood,
                                selected: _controller.text.trim() == mood,
                                onTap: () {
                                  setState(() {
                                    _controller.text = mood;
                                    _controller.selection =
                                        TextSelection.collapsed(
                                          offset: mood.length,
                                        );
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const Key('home-mood-dialog-field'),
                          controller: _controller,
                          autofocus: true,
                          maxLength: 20,
                          maxLengthEnforcement: MaxLengthEnforcement.none,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: InputDecoration(
                            hintText: 'How are you feeling?',
                            prefixIcon: Icon(
                              Icons.favorite_rounded,
                              color: BubColors.pink.withValues(alpha: 0.78),
                            ),
                            counterStyle: TextStyle(color: softTextColor),
                            fillColor: inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(
                                color: BubColors.white.withValues(
                                  alpha: isDark ? 0.10 : 0.62,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(
                                color: BubColors.white.withValues(
                                  alpha: isDark ? 0.10 : 0.62,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(
                                color: BubColors.pink,
                                width: 1.5,
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
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: softTextColor,
                                  side: BorderSide(
                                    color: BubColors.white.withValues(
                                      alpha: isDark ? 0.12 : 0.58,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: BubColors.bubGradient,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: BubColors.pink.withValues(
                                        alpha: 0.28,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    minimumSize: const Size.fromHeight(48),
                                  ),
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
                              ),
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
          gradient: selected ? BubColors.bubGradient : null,
          color: selected
              ? null
              : BubColors.white.withValues(alpha: isDark ? 0.08 : 0.46),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? BubColors.white.withValues(alpha: 0.28)
                : BubColors.white.withValues(alpha: isDark ? 0.10 : 0.56),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            mood,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
