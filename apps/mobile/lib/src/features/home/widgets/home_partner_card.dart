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
      child: tether.hasActiveTether
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          partnerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                key: const Key('home-tether-string'),
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 48),
                decoration: BoxDecoration(
                  color: BubColors.heart,
                  borderRadius: BorderRadius.circular(999),
                ),
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
        const SizedBox(height: 12),
        Text(
          'Tethered since ${_dateLabel(tether.tetheredSince)}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
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
