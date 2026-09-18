import 'dart:async';

import 'package:flutter/material.dart';

import '../../../api/generated/models/home_tether_card_response.dart';
import '../../../features/tether_onboarding/tether_onboarding_screens.dart';
import '../../../theme/bub_colors.dart';

class HomePartnerCard extends StatelessWidget {
  const HomePartnerCard({super.key, required this.tether});

  final HomeTetherCardResponse tether;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('home-partner-card'),
      child: tether.hasActiveTether == true
          ? _TetheredPartnerHero(tether: tether)
          : const _UntetheredPartnerHero(),
    );
  }
}

class _TetheredPartnerHero extends StatelessWidget {
  const _TetheredPartnerHero({required this.tether});

  final HomeTetherCardResponse tether;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeroIllustration(
          asset: 'assets/illustrations/bears/bear-tethered.png',
          assetKey: const Key('home-tether-bear'),
        ),
        const SizedBox(height: 4),
        _TetherDurationPill(tetheredSince: tether.tetheredSince),
      ],
    );
  }
}

class _TetherDurationPill extends StatefulWidget {
  const _TetherDurationPill({required this.tetheredSince});

  final DateTime? tetheredSince;

  @override
  State<_TetherDurationPill> createState() => _TetherDurationPillState();
}

class _TetherDurationPillState extends State<_TetherDurationPill> {
  Timer? _ticker;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant _TetherDurationPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tetheredSince != widget.tetheredSince) {
      _now = DateTime.now();
      _syncTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker() {
    _ticker?.cancel();
    final start = widget.tetheredSince;
    if (start == null) {
      return;
    }
    final age = DateTime.now().difference(start);
    if (age.inDays >= 1) {
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _now = DateTime.now());
      if (_now.difference(start).inDays >= 1) {
        _ticker?.cancel();
        _ticker = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      key: const Key('home-tether-duration'),
      decoration: BoxDecoration(
        color: isDark
            ? BubColors.white.withValues(alpha: 0.10)
            : BubColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? BubColors.white.withValues(alpha: 0.14)
              : BubColors.purple.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: BubColors.deepPurple.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded, color: BubColors.pink, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Tethered for ${_durationLabel(widget.tetheredSince, _now)}',
                key: const Key('home-tether-since-date'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? BubColors.white : BubColors.deepPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _durationLabel(DateTime? start, DateTime now) {
    if (start == null) {
      return '0 seconds';
    }
    final duration = now.difference(start);
    if (duration.isNegative || duration.inSeconds <= 0) {
      return '0 seconds';
    }
    if (duration.inDays >= 1) {
      final days = duration.inDays;
      return '$days ${days == 1 ? 'day' : 'days'}';
    }
    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }
    if (duration.inMinutes >= 1) {
      final minutes = duration.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }
    final seconds = duration.inSeconds;
    return '$seconds ${seconds == 1 ? 'second' : 'seconds'}';
  }
}

class _UntetheredPartnerHero extends StatelessWidget {
  const _UntetheredPartnerHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeroIllustration(
          asset: 'assets/illustrations/bears/bear1.png',
          assetKey: Key('home-tether-bear'),
          imageHeight: 168,
        ),
        const SizedBox(height: 8),
        const Text(
          'Find your Bub',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          "Once you're tethered, you'll see how long you've been paired here.",
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        SizedBox(
          key: const Key('home-tether-cta-button'),
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EnterTetherScreen(),
                ),
              );
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  key: Key('home-tether-cta-heart'),
                  size: 18,
                ),
                SizedBox(width: 8),
                Text('Start tethering'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration({
    required this.asset,
    required this.assetKey,
    this.imageHeight = 196,
  });

  final String asset;
  final Key assetKey;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final haloColor = isDark ? BubColors.heroHaloDark : BubColors.heroHalo;

    return SizedBox(
      height: imageHeight + 36,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            key: const Key('home-hero-halo'),
            width: imageHeight + 54,
            height: imageHeight + 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  haloColor,
                  haloColor.withValues(alpha: isDark ? 0.55 : 0.92),
                  haloColor.withValues(alpha: 0),
                ],
                stops: const [0.42, 0.72, 1],
              ),
            ),
          ),
          Image.asset(
            asset,
            key: assetKey,
            height: imageHeight,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
