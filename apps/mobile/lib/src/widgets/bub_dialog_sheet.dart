import 'package:flutter/material.dart';

import '../theme/bub_colors.dart';

/// Soft solid dialog surface — minimal, cute, no glass/blur chrome.
class BubDialogSheet extends StatelessWidget {
  const BubDialogSheet({
    super.key,
    required this.child,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 28,
      vertical: 24,
    ),
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
  });

  final Widget child;
  final EdgeInsets insetPadding;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: insetPadding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? BubColors.darkDialog : BubColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? BubColors.white.withValues(alpha: 0.10)
                : BubColors.purple.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: BubColors.deepPurple.withValues(
                alpha: isDark ? 0.36 : 0.10,
              ),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class BubDialogHeader extends StatelessWidget {
  const BubDialogHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onClose,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? BubColors.white : BubColors.textPrimaryLight;
    final softTextColor = isDark
        ? BubColors.textSecondaryDark
        : BubColors.textSecondaryLight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BubColors.purple.withValues(alpha: isDark ? 0.22 : 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: BubColors.purple, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: softTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        if (onClose != null)
          IconButton(
            onPressed: onClose,
            tooltip: 'Close',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            icon: const Icon(Icons.close_rounded, size: 20),
            color: softTextColor,
          ),
      ],
    );
  }
}

class BubDialogActions extends StatelessWidget {
  const BubDialogActions({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.confirmKey,
    this.enabled = true,
    this.busy = false,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final String cancelLabel;
  final Key? confirmKey;
  final bool enabled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softTextColor = isDark
        ? BubColors.textSecondaryDark
        : BubColors.textSecondaryLight;
    final canConfirm = enabled && !busy;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: busy ? null : onCancel,
            style: TextButton.styleFrom(
              foregroundColor: softTextColor,
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            key: confirmKey,
            onPressed: canConfirm ? onConfirm : null,
            style: FilledButton.styleFrom(
              backgroundColor: BubColors.purple,
              foregroundColor: BubColors.white,
              disabledBackgroundColor: BubColors.purple.withValues(alpha: 0.42),
              disabledForegroundColor: BubColors.white.withValues(alpha: 0.86),
              elevation: 0,
              shadowColor: Colors.transparent,
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BubColors.white,
                    ),
                  )
                : Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}
