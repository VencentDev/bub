import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../api/generated/models/tether_accept_request.dart';
import '../../api/generated/models/tether_invitation_response.dart';
import '../../auth/auth_controller.dart';
import '../../core/dio_provider.dart';
import '../../theme/bub_colors.dart';

class EnterTetherScreen extends ConsumerStatefulWidget {
  const EnterTetherScreen({super.key});

  @override
  ConsumerState<EnterTetherScreen> createState() => _EnterTetherScreenState();
}

class _EnterTetherScreenState extends ConsumerState<EnterTetherScreen> {
  final _controller = TextEditingController();
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GradientButton(
            label: 'Generate new tether',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GenerateTetherScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          TextButton(
            key: const Key('skip-tether-button'),
            onPressed: () => ref
                .read(authControllerProvider.notifier)
                .skipTetherOnboarding(),
            child: const Text('Skip for now'),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        children: [
          const _WelcomeHeader(),
          const SizedBox(height: 18),
          const Text(
            'Who are you tethering with?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: BubColors.textPrimaryLight,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Image.asset(
              'assets/illustrations/bears/bear4.png',
              key: const Key('enter-tether-bear'),
              height: 190,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            key: const Key('tether-code-field'),
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'BUB-7KQ2-XH19',
              errorText: _error,
              suffixIcon: IconButton(
                tooltip: 'Submit tether code',
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                onPressed: _submitting ? null : _acceptCode,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('qr-scanner-button'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TetherScannerUnavailableScreen(),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Scan QR code'),
          ),
          const SizedBox(height: 22),
          const _OrDivider(),
        ],
      ),
    );
  }

  Future<void> _acceptCode() async {
    final code = _controller.text.trim().toUpperCase();
    if (!RegExp(r'^BUB-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(code)) {
      setState(() => _error = 'Enter a code like BUB-7KQ2-XH19');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final status = await ref
          .read(restClientProvider)
          .fallback
          .acceptTether(body: TetherAcceptRequest(code: code));
      ref.read(authControllerProvider.notifier).applyAcceptedTether(status);
      if (mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const AllSetScreen()));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'That tether code could not be used');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class GenerateTetherScreen extends ConsumerWidget {
  const GenerateTetherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitation = ref.watch(tetherInvitationProvider);

    return _OnboardingScaffold(
      bottom: _GradientButton(
        key: const Key('done-generate-tether-button'),
        label: 'DONE',
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const AllSetScreen()),
          );
        },
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Share your tethered link',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: BubColors.textPrimaryLight,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Send this link to your person so they can Bub with you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: BubColors.textSecondaryLight,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            invitation.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Could not generate a tether code.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('retry-generate-tether-button'),
                    onPressed: () => ref.invalidate(tetherInvitationProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
              data: (invite) => _InviteQr(invite: invite),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class AllSetScreen extends ConsumerWidget {
  const AllSetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _OnboardingScaffold(
      bottom: _GradientButton(
        key: const Key('go-to-bub-button'),
        label: 'Go to Bub',
        onPressed: () {
          ref
              .read(authControllerProvider.notifier)
              .refreshTetherStatus(markSkipped: true);
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 42, 24, 24),
        child: Column(
          children: [
            const Text(
              'All set',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: BubColors.textPrimaryLight,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You're almost there",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: BubColors.textSecondaryLight,
                fontSize: 17,
              ),
            ),
            const Spacer(),
            Image.asset(
              'assets/illustrations/bears/bear2.png',
              key: const Key('all-set-bear'),
              height: 230,
              fit: BoxFit.contain,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class TetherScannerUnavailableScreen extends StatelessWidget {
  const TetherScannerUnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OnboardingScaffold(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'QR scanning will be available once camera permissions are enabled.',
            key: Key('scanner-unavailable-message'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

final tetherInvitationProvider =
    FutureProvider.autoDispose<TetherInvitationResponse>(
      (ref) => ref.read(restClientProvider).fallback.createTetherInvitation(),
    );

class _InviteQr extends StatelessWidget {
  const _InviteQr({required this.invite});

  final TetherInvitationResponse invite;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: BubColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BubColors.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: QrImageView(
              key: const Key('tether-qr-code'),
              data: invite.qrPayload,
              size: 220,
              backgroundColor: BubColors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SelectableText(
          invite.code,
          key: const Key('generated-tether-code'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: BubColors.textPrimaryLight,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Welcome to Bub',
          style: TextStyle(
            color: BubColors.textPrimaryLight,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        SizedBox(width: 6),
        Icon(Icons.favorite_rounded, color: BubColors.purple, size: 20),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: BubColors.textHintLight)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}

class _OnboardingScaffold extends StatelessWidget {
  const _OnboardingScaffold({required this.child, this.bottom});

  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BubColors.white,
      body: SafeArea(child: child),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: bottom!,
            ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: BubColors.bubButtonGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
