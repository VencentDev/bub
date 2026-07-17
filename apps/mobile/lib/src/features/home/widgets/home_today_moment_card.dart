import 'package:flutter/material.dart';

import '../../../api/generated/models/home_today_moment_response.dart';
import '../../../theme/bub_colors.dart';
import 'home_card_shell.dart';

class HomeTodayMomentCard extends StatelessWidget {
  const HomeTodayMomentCard({
    super.key,
    required this.moment,
    required this.onReact,
    required this.onCaptureMoment,
    this.isTethered = false,
  });

  final HomeTodayMomentResponse? moment;
  final VoidCallback onReact;
  final VoidCallback onCaptureMoment;
  final bool isTethered;

  @override
  Widget build(BuildContext context) {
    final current = moment;
    final partnerPhotoUrl = current?.photoUrl?.trim();
    final hasPartnerPhoto =
        partnerPhotoUrl != null && partnerPhotoUrl.isNotEmpty;
    return HomeCardShell(
      key: const Key('home-today-moment-card'),
      treatment: HomeCardTreatment.todayMoment,
      minHeight: 208,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Moment",
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                if (isTethered) ...[
                  _SelfMomentShortcut(
                    moment: current,
                    onCaptureMoment: onCaptureMoment,
                  ),
                  const SizedBox(height: 10),
                ],
                if (!hasPartnerPhoto)
                  Text(
                    isTethered
                        ? "Your partner hasn't shared their moment today."
                        : "Once you're tethered, your daily photo moments will sparkle here.",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          if (hasPartnerPhoto) ...[
            const SizedBox(width: 10),
            _PartnerMomentTimestamp(
              capturedAt: current?.partnerCapturedAt,
              localDate: current?.localDate,
            ),
          ],
          const SizedBox(width: 12),
          _PartnerMomentVisual(
            photoUrl: partnerPhotoUrl,
            hasPartnerPhoto: hasPartnerPhoto,
            hasReaction: current?.partnerReaction != null,
            onReact: onReact,
          ),
        ],
      ),
    );
  }
}

class _PartnerMomentVisual extends StatelessWidget {
  const _PartnerMomentVisual({
    required this.photoUrl,
    required this.hasPartnerPhoto,
    required this.hasReaction,
    required this.onReact,
  });

  final String? photoUrl;
  final bool hasPartnerPhoto;
  final bool hasReaction;
  final VoidCallback onReact;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 124,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              key: hasPartnerPhoto
                  ? const Key('home-today-moment-photo')
                  : null,
              borderRadius: BorderRadius.circular(18),
              child: hasPartnerPhoto
                  ? Image.network(
                      photoUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: _momentImageLoadingBuilder,
                      errorBuilder: (context, error, stackTrace) => Container(
                        alignment: Alignment.center,
                        color: BubColors.partnerBubbleLight,
                        child: const Icon(
                          Icons.photo_rounded,
                          color: BubColors.deepPurple,
                          size: 30,
                        ),
                      ),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: BubColors.white.withValues(alpha: 0.48),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/illustrations/bears/bear3.png',
                          key: const Key('home-today-moment-bear'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
            ),
          ),
          if (hasPartnerPhoto)
            Positioned(
              right: -5,
              bottom: -5,
              child: _PartnerReactionBadge(
                hasReaction: hasReaction,
                onReact: onReact,
              ),
            ),
        ],
      ),
    );
  }
}

class _PartnerReactionBadge extends StatelessWidget {
  const _PartnerReactionBadge({
    required this.hasReaction,
    required this.onReact,
  });

  final bool hasReaction;
  final VoidCallback onReact;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.18,
      child: Material(
        key: const Key('home-today-moment-reaction-badge'),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: hasReaction ? null : onReact,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: BubColors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: hasReaction
                    ? BubColors.pink.withValues(alpha: 0.48)
                    : BubColors.deepPurple.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SizedBox.square(
              dimension: 34,
              child: hasReaction
                  ? const Icon(
                      Icons.favorite_rounded,
                      key: Key('home-today-moment-reacted-heart'),
                      color: BubColors.heart,
                      size: 20,
                    )
                  : CustomPaint(
                      key: const Key('home-today-moment-empty-heart'),
                      painter: _DashedHeartPainter(color: BubColors.deepPurple),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedHeartPainter extends CustomPainter {
  const _DashedHeartPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(width * 0.50, height * 0.72);
    path.cubicTo(
      width * 0.18,
      height * 0.50,
      width * 0.16,
      height * 0.28,
      width * 0.34,
      height * 0.28,
    );
    path.cubicTo(
      width * 0.44,
      height * 0.28,
      width * 0.49,
      height * 0.36,
      width * 0.50,
      height * 0.42,
    );
    path.cubicTo(
      width * 0.51,
      height * 0.36,
      width * 0.56,
      height * 0.28,
      width * 0.66,
      height * 0.28,
    );
    path.cubicTo(
      width * 0.84,
      height * 0.28,
      width * 0.82,
      height * 0.50,
      width * 0.50,
      height * 0.72,
    );

    final paint = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 3.2;
      const gap = 2.7;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedHeartPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _PartnerMomentTimestamp extends StatelessWidget {
  const _PartnerMomentTimestamp({
    required this.capturedAt,
    required this.localDate,
  });

  final DateTime? capturedAt;
  final DateTime? localDate;

  @override
  Widget build(BuildContext context) {
    final time = capturedAt?.toLocal();
    final date = time ?? localDate;
    return Column(
      key: const Key('home-today-moment-partner-timestamp'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _dateLabel(date),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: BubColors.deepPurple.withValues(alpha: 0.68),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _timeLabel(time),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: BubColors.deepPurple.withValues(alpha: 0.56),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

String _dateLabel(DateTime? date) {
  if (date == null) return '';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day';
}

String _timeLabel(DateTime? date) {
  if (date == null) return '--:--';
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

class _SelfMomentShortcut extends StatelessWidget {
  const _SelfMomentShortcut({
    required this.moment,
    required this.onCaptureMoment,
  });

  final HomeTodayMomentResponse? moment;
  final VoidCallback onCaptureMoment;

  @override
  Widget build(BuildContext context) {
    final viewerPhotoUrl = moment?.viewerPhotoUrl?.trim();
    final hasSelfMoment =
        moment?.viewerHasPostedToday == true &&
        viewerPhotoUrl != null &&
        viewerPhotoUrl.isNotEmpty;

    if (!hasSelfMoment) {
      return _CameraSnapshotTile(onCaptureMoment: onCaptureMoment);
    }

    return Transform.rotate(
      angle: -0.08,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('home-today-moment-self-polaroid'),
          borderRadius: BorderRadius.circular(12),
          onTap: () =>
              _showSelfMomentPreview(context, viewerPhotoUrl, onCaptureMoment),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: BubColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 13),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  viewerPhotoUrl,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  loadingBuilder: _momentImageLoadingBuilder,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    color: BubColors.partnerBubbleLight,
                    child: const Icon(
                      Icons.photo_rounded,
                      color: BubColors.deepPurple,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSelfMomentPreview(
    BuildContext context,
    String photoUrl,
    VoidCallback onCaptureMoment,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    photoUrl,
                    key: const Key('home-today-moment-self-preview'),
                    fit: BoxFit.cover,
                    loadingBuilder: _momentImageLoadingBuilder,
                    errorBuilder: (context, error, stackTrace) => Container(
                      alignment: Alignment.center,
                      color: BubColors.partnerBubbleLight,
                      child: const Icon(
                        Icons.photo_rounded,
                        color: BubColors.deepPurple,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('home-today-moment-retake-button'),
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.of(context).pop();
                      onCaptureMoment();
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: BubColors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const SizedBox.square(
                        dimension: 38,
                        child: Icon(
                          Icons.photo_camera_back_rounded,
                          color: BubColors.deepPurple,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _momentImageLoadingBuilder(
  BuildContext context,
  Widget child,
  ImageChunkEvent? loadingProgress,
) {
  if (loadingProgress == null) {
    return child;
  }
  return Stack(
    fit: StackFit.expand,
    children: [
      const _MomentImageSkeleton(),
      Center(
        child: SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: BubColors.deepPurple.withValues(alpha: 0.42),
          ),
        ),
      ),
    ],
  );
}

class _MomentImageSkeleton extends StatelessWidget {
  const _MomentImageSkeleton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('home-today-moment-image-skeleton'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BubColors.white.withValues(alpha: 0.62),
            BubColors.partnerBubbleLight.withValues(alpha: 0.82),
            BubColors.pink.withValues(alpha: 0.20),
          ],
        ),
      ),
    );
  }
}

class _CameraSnapshotTile extends StatelessWidget {
  const _CameraSnapshotTile({required this.onCaptureMoment});

  final VoidCallback onCaptureMoment;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('home-today-moment-camera-tile'),
        borderRadius: BorderRadius.circular(16),
        onTap: onCaptureMoment,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: BubColors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BubColors.pink.withValues(alpha: 0.34)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const SizedBox.square(
            dimension: 64,
            child: Icon(
              Icons.camera_alt_rounded,
              color: BubColors.deepPurple,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
