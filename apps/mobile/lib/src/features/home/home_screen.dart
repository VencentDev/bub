import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_state.dart';
import '../../core/env.dart';
import '../../features/tether_onboarding/tether_onboarding_screens.dart';
import '../../theme/bub_colors.dart';

/// Starter screen: switches between Google sign-in and the authenticated Bub shell.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    if (auth case AsyncData(
      value: final state,
    ) when state.route == AuthRouteState.tethered) {
      return _BubHome(onLogout: controller.logout, paired: true);
    }

    if (auth case AsyncData(
      value: final state,
    ) when state.route == AuthRouteState.untethered) {
      return _BubHome(onLogout: controller.logout, paired: false);
    }

    if (auth case AsyncData(
      value: final state,
    ) when state.route == AuthRouteState.needsTetherOnboarding) {
      return const EnterTetherScreen();
    }

    return _LoginScaffold(
      child: switch (auth) {
        AsyncLoading() => const Center(
          child: CircularProgressIndicator(color: BubColors.white),
        ),
        AsyncError(:final error) => _LoginBottomPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sign-in failed:\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: BubColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _GoogleSignInButton(
                label: 'Try again',
                onPressed: controller.login,
              ),
            ],
          ),
        ),
        _ => _LoginBottomPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GoogleSignInButton(
                onPressed: Env.isGoogleConfigured ? controller.login : null,
              ),
              if (!Env.isGoogleConfigured)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Set GOOGLE_CLIENT_ID in .env and restart the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: BubColors.white),
                  ),
                ),
            ],
          ),
        ),
      },
    );
  }
}

class _LoginScaffold extends StatelessWidget {
  const _LoginScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/branding/signin.png',
            key: const Key('login-background'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          child,
        ],
      ),
    );
  }
}

class _LoginBottomPanel extends StatelessWidget {
  const _LoginBottomPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.34),
              Colors.black.withValues(alpha: 0.62),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(24, 96, 24, 48),
          child: child,
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    this.label = 'Sign in with Google',
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.56,
      child: DecoratedBox(
        key: const Key('google-sign-in-gradient'),
        decoration: BoxDecoration(
          gradient: BubColors.loginButtonGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: BubColors.purple.withValues(alpha: 0.34),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 58,
                minWidth: double.infinity,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _GoogleMark(),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: BubColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: BubColors.white,
        shape: BoxShape.circle,
      ),
      child: Image.asset(
        'assets/icons/google.png',
        key: const Key('google-icon'),
        width: 20,
        height: 20,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _BubHome extends StatelessWidget {
  const _BubHome({required this.onLogout, required this.paired});

  final VoidCallback onLogout;
  final bool paired;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bub'),
        actions: [TextButton(onPressed: onLogout, child: const Text('Logout'))],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                paired ? "You're tethered" : "You're not tethered yet ❤️",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                paired
                    ? 'Your paired Bub home is ready for the next product stories.'
                    : 'Pairing, chat, Bubs, moments, and Safe will build from the product stories.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
