import 'package:flutter/material.dart';

class BubLoadingState extends StatelessWidget {
  const BubLoadingState({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 132),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class BubErrorState extends StatelessWidget {
  const BubErrorState({
    super.key,
    required this.title,
    required this.onRetry,
    this.retryLabel = 'Retry',
    this.retryKey,
  });

  final String title;
  final VoidCallback onRetry;
  final String retryLabel;
  final Key? retryKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 132),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: retryKey,
              onPressed: onRetry,
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class BubEmptyState extends StatelessWidget {
  const BubEmptyState({
    super.key,
    required this.title,
    this.icon,
    this.image,
    this.subtitle,
  });

  final String title;
  final IconData? icon;
  final Widget? image;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final media = image ?? (icon == null ? null : Icon(icon, size: 42));
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 132),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (media != null) ...[media, const SizedBox(height: 14)],
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
