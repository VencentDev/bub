import 'package:flutter/material.dart';

import '../../../api/generated/models/home_today_moment_response.dart';
import '../../../theme/bub_colors.dart';
import 'home_card_shell.dart';

class HomeTodayMomentCard extends StatelessWidget {
  const HomeTodayMomentCard({
    super.key,
    required this.moment,
    required this.onReact,
    this.isTethered = false,
  });

  final HomeTodayMomentResponse? moment;
  final VoidCallback onReact;
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
                  _SelfMomentShortcut(moment: current),
                  const SizedBox(height: 10),
                ],
                if (!hasPartnerPhoto)
                  Text(
                    isTethered
                        ? "Your partner hasn't shared their moment today."
                        : "Once you're tethered, your daily photo moments will sparkle here.",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  )
                else ...[
                  Text(_dateLabel(current?.localDate)),
                  const SizedBox(height: 6),
                  if (current?.partnerReaction != null)
                    Text(
                      current!.partnerReaction!,
                      style: const TextStyle(fontSize: 22),
                    )
                  else
                    IconButton(
                      onPressed: onReact,
                      icon: const Icon(Icons.favorite_rounded),
                      color: BubColors.heart,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          _PartnerMomentVisual(
            photoUrl: partnerPhotoUrl,
            hasPartnerPhoto: hasPartnerPhoto,
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
  });

  final String? photoUrl;
  final bool hasPartnerPhoto;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 124,
      child: ClipRRect(
        key: hasPartnerPhoto ? const Key('home-today-moment-photo') : null,
        borderRadius: BorderRadius.circular(18),
        child: hasPartnerPhoto
            ? Image.network(
                photoUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
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
    );
  }
}

String _dateLabel(DateTime? date) {
  if (date == null) {
    return '';
  }
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class _SelfMomentShortcut extends StatelessWidget {
  const _SelfMomentShortcut({required this.moment});

  final HomeTodayMomentResponse? moment;

  @override
  Widget build(BuildContext context) {
    final photoUrl = moment?.photoUrl?.trim();
    final hasSelfMoment =
        moment?.viewerHasPostedToday == true &&
        photoUrl != null &&
        photoUrl.isNotEmpty;

    if (!hasSelfMoment) {
      return const _CameraSnapshotTile();
    }

    return Transform.rotate(
      angle: -0.08,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('home-today-moment-self-polaroid'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showSelfMomentPreview(context, photoUrl),
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
                  photoUrl,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
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

  void _showSelfMomentPreview(BuildContext context, String photoUrl) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              photoUrl,
              key: const Key('home-today-moment-self-preview'),
              fit: BoxFit.cover,
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
      ),
    );
  }
}

class _CameraSnapshotTile extends StatelessWidget {
  const _CameraSnapshotTile();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('home-today-moment-camera-tile'),
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
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
