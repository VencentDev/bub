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
      padding: const EdgeInsets.all(18),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Tethered since ${_dateLabel(tether.tetheredSince)}',
          key: const Key('home-tether-since-date'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: BubColors.deepPurple.withValues(alpha: 0.72),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 86,
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
        const SizedBox(height: 10),
        Text(
          _durationLabel(tether.tetheredSince, DateTime.now()),
          key: const Key('home-tether-duration'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: BubColors.deepPurple,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  static String _initials(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'B' : trimmed.characters.first.toUpperCase();
  }

  static String _dateLabel(DateTime? date) {
    if (date == null) {
      return 'today';
    }
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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
      return '$minutes mins';
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
      final remainingDays = days % 30;
      if (remainingDays == 0) {
        return '${months}m';
      }
      return '${months}m ${remainingDays}d';
    }

    final years = days ~/ 365;
    final months = (days % 365) ~/ 30;
    if (months == 0) {
      return '${years}y';
    }
    return '${years}y ${months}m';
  }
}

class _TetherStringPainter extends CustomPainter {
  const _TetherStringPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final left = 58.0;
    final right = size.width - 58.0;
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
          width: 96,
          height: 96,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find your Bub',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                "Once you're tethered, you'll see how long you've been paired here.",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
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
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: BubColors.partnerBubbleLight,
        shape: BoxShape.circle,
        border: Border.all(color: BubColors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: BubColors.deepPurple.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
