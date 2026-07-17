import 'package:flutter/material.dart';

import '../../../api/generated/models/home_latest_bub_response.dart';
import '../../../theme/bub_colors.dart';
import 'home_card_shell.dart';

class HomeLatestBubCard extends StatelessWidget {
  const HomeLatestBubCard({
    super.key,
    required this.latestBub,
    required this.isTethered,
    required this.onFirstBubPressed,
    this.now,
  });

  final HomeLatestBubResponse latestBub;
  final bool isTethered;
  final VoidCallback onFirstBubPressed;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final hasDirectionalActivity =
        latestBub.viewerLastSentAt != null ||
        latestBub.partnerLastSentAt != null;
    final hasActivity = latestBub.hasActivity == true || hasDirectionalActivity;
    return HomeCardShell(
      key: const Key('home-latest-bub-card'),
      treatment: HomeCardTreatment.latestBub,
      minHeight: hasActivity ? 150 : 116,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/onboarding/bub.png',
            key: const Key('home-latest-bub-art'),
            width: hasActivity ? 88 : 72,
            height: hasActivity ? 96 : 78,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasActivity
                      ? 'Latest Bub'
                      : isTethered
                      ? latestBub.copy ?? 'Send your first Bub'
                      : latestBub.copy ?? 'Tether to send bub',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!hasActivity) ...[
                  const SizedBox(height: 6),
                  if (isTethered)
                    FilledButton.icon(
                      key: const Key('home-first-bub-button'),
                      onPressed: onFirstBubPressed,
                      icon: const Icon(Icons.favorite_rounded, size: 16),
                      label: const Text('Send your first Bub'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: BubColors.partnerBubbleLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: BubColors.heart,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Ready after tethering',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
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
                ] else ...[
                  const SizedBox(height: 5),
                  ..._activityRows(),
                ],
              ],
            ),
          ),
          if (latestBub.partnerLastSentAt != null) ...[
            const SizedBox(width: 8),
            _PartnerBubStreak(streakDays: latestBub.streakDays ?? 0),
          ],
        ],
      ),
    );
  }

  List<Widget> _activityRows() {
    final rows = <Widget>[];
    if (latestBub.partnerLastSentAt != null) {
      rows.add(
        _BubActivityRow(
          key: const Key('home-latest-bub-partner-sent-row'),
          icon: Icons.call_received_rounded,
          copy: latestBub.partnerLastSentCopy ?? 'Your partner Bubbed you',
          relativeTime: _relativeTime(latestBub.partnerLastSentAt!),
        ),
      );
    }
    if (latestBub.viewerLastSentAt != null) {
      rows.add(
        _BubActivityRow(
          key: const Key('home-latest-bub-viewer-sent-row'),
          icon: Icons.call_made_rounded,
          copy: latestBub.viewerLastSentCopy ?? 'You Bubbed them',
          relativeTime: _relativeTime(latestBub.viewerLastSentAt!),
        ),
      );
    }
    if (rows.isEmpty && latestBub.occurredAt != null) {
      rows.add(
        _BubActivityRow(
          icon: Icons.bolt_rounded,
          copy: latestBub.copy ?? 'Latest Bub',
          relativeTime: _relativeTime(latestBub.occurredAt!),
        ),
      );
    }
    return rows.expand((row) sync* {
      if (rows.indexOf(row) > 0) {
        yield const SizedBox(height: 4);
      }
      yield row;
    }).toList();
  }

  String _relativeTime(DateTime occurredAt) {
    final minutes = (now ?? DateTime.now()).difference(occurredAt).inMinutes;
    if (minutes < 1) {
      return 'Just now';
    }
    if (minutes < 60) {
      return '$minutes mins ago';
    }
    final hours = minutes ~/ 60;
    return '$hours hours ago';
  }
}

class _PartnerBubStreak extends StatelessWidget {
  const _PartnerBubStreak({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('home-latest-bub-streak'),
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/onboarding/heart.png',
            key: const Key('home-latest-bub-heart'),
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
          Text(
            '$streakDays',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: BubColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              shadows: [
                Shadow(
                  color: BubColors.pink.withValues(alpha: 0.95),
                  blurRadius: 12,
                ),
                Shadow(
                  color: BubColors.deepPurple.withValues(alpha: 0.45),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BubActivityRow extends StatelessWidget {
  const _BubActivityRow({
    super.key,
    required this.icon,
    required this.copy,
    required this.relativeTime,
  });

  final IconData icon;
  final String copy;
  final String relativeTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: BubColors.purple, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 1),
              Text(
                relativeTime,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
