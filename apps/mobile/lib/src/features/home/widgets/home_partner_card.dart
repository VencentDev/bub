import 'package:flutter/material.dart';

import '../../../api/generated/models/home_tether_card_response.dart';
import '../../../features/tether_onboarding/tether_onboarding_screens.dart';
import '../../../theme/bub_colors.dart';
import 'home_card_shell.dart';

class HomePartnerCard extends StatelessWidget {
  const HomePartnerCard({super.key, required this.tether});

  final HomeTetherCardResponse tether;

  @override
  Widget build(BuildContext context) {
    return HomeCardShell(
      key: const Key('home-partner-card'),
      treatment: HomeCardTreatment.partner,
      padding: const EdgeInsets.all(14),
      child: tether.hasActiveTether == true
          ? _TetheredPartnerCard(tether: tether)
          : const _UntetheredPartnerCard(),
    );
  }
}

class _TetheredPartnerCard extends StatelessWidget {
  const _TetheredPartnerCard({required this.tether});

  final HomeTetherCardResponse tether;

  @override
  Widget build(BuildContext context) {
    final partnerName = tether.partnerDisplayName ?? 'Your Bub';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(
                key: Key('home-tether-string'),
                child: CustomPaint(painter: _TetherStringPainter()),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: _ProfileNode(label: 'You'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _ProfileNode(label: _initials(partnerName)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const SizedBox(height: 2),
        DecoratedBox(
          key: const Key('home-tether-duration'),
          decoration: BoxDecoration(
            color: isDark
                ? BubColors.white.withValues(alpha: 0.08)
                : BubColors.white.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark
                  ? BubColors.white.withValues(alpha: 0.12)
                  : BubColors.deepPurple.withValues(alpha: 0.10),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              'Tethered since ${_dateLabel(tether.tetheredSince)} • ${_durationLabel(tether.tetheredSince, DateTime.now())}',
              key: const Key('home-tether-since-date'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? BubColors.white : BubColors.deepPurple,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _initials(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'B' : trimmed.characters.first.toUpperCase();
  }

  static String _durationLabel(DateTime? start, DateTime now) {
    if (start == null) {
      return '0 seconds';
    }
    final duration = now.difference(start);
    if (duration.isNegative) {
      return '0 seconds';
    }
    if (duration.inSeconds < 60) {
      final seconds = duration.inSeconds;
      return '$seconds ${seconds == 1 ? 'second' : 'seconds'}';
    }
    if (duration.inMinutes < 60) {
      final minutes = duration.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }
    if (duration.inHours < 24) {
      final hours = duration.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }
    final days = duration.inDays;
    if (days < 30) {
      return '$days ${days == 1 ? 'day' : 'days'}';
    }
    if (days < 365) {
      final months = days ~/ 30;
      return '$months ${months == 1 ? 'month' : 'months'}';
    }
    final years = days ~/ 365;
    return '$years ${years == 1 ? 'year' : 'years'}';
  }

  static String _dateLabel(DateTime? date) {
    if (date == null) {
      return 'today';
    }
    final local = date.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }
}

class _TetherStringPainter extends CustomPainter {
  const _TetherStringPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final left = 48.0;
    final right = size.width - 48.0;
    final midY = size.height / 2;
    final path = Path()
      ..moveTo(left, midY + 2)
      ..cubicTo(
        size.width * 0.30,
        midY - 18,
        size.width * 0.40,
        midY + 16,
        size.width * 0.50,
        midY - 2,
      )
      ..cubicTo(
        size.width * 0.60,
        midY - 18,
        size.width * 0.70,
        midY + 16,
        right,
        midY - 1,
      );

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);

    final stringPaint = Paint()
      ..color = BubColors.heart
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stringPaint);

    final highlightPaint = Paint()
      ..color = BubColors.white.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path.shift(const Offset(0, -1.4)), highlightPaint);

    _drawKnot(canvas, Offset(size.width * 0.36, midY + 2), -0.35);
    _drawKnot(canvas, Offset(size.width * 0.64, midY - 2), 0.35);
  }

  void _drawKnot(Canvas canvas, Offset center, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final knotPaint = Paint()
      ..color = BubColors.heart
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final knotPath = Path()..addOval(const Rect.fromLTWH(-8, -5, 16, 10));
    canvas.drawPath(knotPath, knotPaint);
    canvas.drawLine(const Offset(-11, 0), const Offset(-6, 0), knotPaint);
    canvas.drawLine(const Offset(6, 0), const Offset(11, 0), knotPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TetherStringPainter oldDelegate) => false;
}

class _UntetheredPartnerCard extends StatelessWidget {
  const _UntetheredPartnerCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/illustrations/bears/bear1.png',
          key: const Key('home-tether-bear'),
          width: 78,
          height: 78,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find your Bub',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                "Once you're tethered, you'll see how long you've been paired here.",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
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
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                      fontSize: 12,
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
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text('Start tethering'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileNode extends StatelessWidget {
  const _ProfileNode({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: BubColors.partnerBubbleLight,
        shape: BoxShape.circle,
        border: Border.all(color: BubColors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: BubColors.deepPurple.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: BubColors.deepPurple,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
