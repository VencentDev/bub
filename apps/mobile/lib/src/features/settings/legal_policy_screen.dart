import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/async_state_widgets.dart';
import 'legal_policy_controller.dart';

class LegalPolicyScreen extends ConsumerWidget {
  const LegalPolicyScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(legalPolicyProvider(slug));
    return Scaffold(
      key: Key('legal-policy-screen-$slug'),
      appBar: AppBar(title: Text(_titleForSlug(slug))),
      body: policy.when(
        loading: () => const BubLoadingState(
          key: Key('legal-policy-loading'),
          label: 'Loading policy',
        ),
        error: (_, _) => BubErrorState(
          key: const Key('legal-policy-error'),
          title: 'Policy could not load',
          onRetry: () => ref.invalidate(legalPolicyProvider(slug)),
          retryKey: const Key('legal-policy-retry-button'),
        ),
        data: (value) => _LegalPolicyBody(policy: value),
      ),
    );
  }

  String _titleForSlug(String slug) {
    return switch (slug) {
      'terms-of-service' => 'Terms of Service',
      'cookies-policy' => 'Cookies Policy',
      _ => 'Privacy Policy',
    };
  }
}

class _LegalPolicyBody extends StatelessWidget {
  const _LegalPolicyBody({required this.policy});

  final LegalPolicy policy;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
      children: [
        Text(
          policy.title,
          key: Key('legal-policy-title-${policy.slug}'),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PolicyBadge(label: 'Version ${policy.version}'),
            _PolicyBadge(label: 'Effective ${policy.effectiveDate}'),
            if (policy.stale)
              const _PolicyBadge(
                key: Key('legal-policy-offline'),
                label: 'Offline copy',
              ),
          ],
        ),
        const SizedBox(height: 18),
        SelectableText(
          policy.body,
          key: Key('legal-policy-body-${policy.slug}'),
          style: const TextStyle(
            fontSize: 15,
            height: 1.42,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PolicyBadge extends StatelessWidget {
  const _PolicyBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
