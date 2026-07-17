import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_state.dart';
import '../../core/env.dart';
import '../../features/chat/chat_section.dart';
import '../../features/home/home_dashboard_controller.dart';
import '../../features/home/widgets/home_latest_bub_card.dart';
import '../../features/home/widgets/home_mood_card.dart';
import '../../features/home/widgets/home_partner_card.dart';
import '../../features/home/widgets/home_today_moment_card.dart';
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

enum _BubHomeSection {
  home('Home section'),
  chat('Chat section'),
  safe('Safe section'),
  settings('Settings section');

  const _BubHomeSection(this.label);

  final String label;
}

class _BubHome extends ConsumerStatefulWidget {
  const _BubHome({required this.onLogout, required this.paired});

  final VoidCallback onLogout;
  final bool paired;

  @override
  ConsumerState<_BubHome> createState() => _BubHomeState();
}

class _BubHomeState extends ConsumerState<_BubHome> {
  var _section = _BubHomeSection.home;

  void _selectSection(_BubHomeSection section) {
    setState(() {
      _section = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const _BubAppBarLogo(),
        actions: [
          TextButton(onPressed: widget.onLogout, child: const Text('Logout')),
        ],
      ),
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _BubHomeSectionBody(
              section: _section,
              onOpenSafe: () => _selectSection(_BubHomeSection.safe),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BubFloatingNav(
              selectedSection: _section,
              onSelected: _selectSection,
            ),
          ),
        ],
      ),
    );
  }
}

class _BubAppBarLogo extends StatelessWidget {
  const _BubAppBarLogo();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/branding/bub-logo.png'
        : 'assets/branding/bub-logo-purple.png';

    return SizedBox(
      key: const Key('bub-app-bar-logo'),
      height: 30,
      width: 120,
      child: ClipRect(
        child: Align(
          alignment: Alignment.center,
          child: SizedBox(
            height: 30,
            width: 120,
            child: FittedBox(
              alignment: Alignment.center,
              fit: BoxFit.none,
              clipBehavior: Clip.hardEdge,
              child: Image.asset(
                asset,
                key: const Key('bub-app-bar-logo-image'),
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                semanticLabel: 'Bub',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubHomeSectionBody extends ConsumerWidget {
  const _BubHomeSectionBody({required this.section, required this.onOpenSafe});

  final _BubHomeSection section;
  final VoidCallback onOpenSafe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (section == _BubHomeSection.chat) {
      return const ChatSection();
    }

    if (section != _BubHomeSection.home) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 132),
          child: Text(
            section.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    final dashboard = ref.watch(homeDashboardProvider);
    return dashboard.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: 132),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 132),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Home could not load',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.read(homeDashboardProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        final tether = data.tether;
        final latestBub = data.latestBub;
        final mood = data.mood;
        if (tether == null || latestBub == null || mood == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 132),
              child: Text(
                'Home could not load',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          );
        }
        final showMoodInTodayMoment = tether.hasActiveTether == true;
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 140),
          children: [
            HomePartnerCard(tether: tether),
            const SizedBox(height: 16),
            HomeTodayMomentCard(
              moment: data.todayMoment,
              mood: showMoodInTodayMoment ? mood : null,
              showMoodPill: showMoodInTodayMoment,
              onSaveMood: (mood) =>
                  ref.read(homeDashboardProvider.notifier).putMood(mood),
              onReact: data.todayMoment == null
                  ? () {}
                  : () => ref
                        .read(homeDashboardProvider.notifier)
                        .reactToTodayMoment(data.todayMoment!.momentId ?? ''),
            ),
            const SizedBox(height: 16),
            HomeLatestBubCard(latestBub: latestBub),
            if (!showMoodInTodayMoment) ...[
              const SizedBox(height: 16),
              HomeMoodCard(
                mood: mood,
                onSaveMood: (mood) =>
                    ref.read(homeDashboardProvider.notifier).putMood(mood),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BubFloatingNav extends StatelessWidget {
  const _BubFloatingNav({
    required this.selectedSection,
    required this.onSelected,
  });

  final _BubHomeSection selectedSection;
  final ValueChanged<_BubHomeSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor =
        (isDark ? const Color(0xFF2A2633) : const Color(0xFFECEAF1)).withValues(
          alpha: 0.82,
        );
    final borderColor = (isDark ? BubColors.white : BubColors.deepPurple)
        .withValues(alpha: 0.12);
    final shadowColor = BubColors.deepPurple.withValues(alpha: 0.18);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: SizedBox(
        key: const Key('bub-floating-nav'),
        height: 92,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: glassColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: borderColor),
                    ),
                    child: SizedBox(
                      height: 68,
                      child: Row(
                        children: [
                          Expanded(
                            child: _BubNavItem(
                              icon: Icons.home_rounded,
                              label: 'Home',
                              selected: selectedSection == _BubHomeSection.home,
                              onTap: () => onSelected(_BubHomeSection.home),
                            ),
                          ),
                          Expanded(
                            child: _BubNavItem(
                              icon: Icons.chat_bubble_rounded,
                              label: 'Chat',
                              selected: selectedSection == _BubHomeSection.chat,
                              onTap: () => onSelected(_BubHomeSection.chat),
                            ),
                          ),
                          const Expanded(child: SizedBox.shrink()),
                          Expanded(
                            child: _BubNavItem(
                              key: Key('bub-nav-safe-lock'),
                              icon: Icons.lock_rounded,
                              label: 'Safe',
                              selected: selectedSection == _BubHomeSection.safe,
                              onTap: () => onSelected(_BubHomeSection.safe),
                            ),
                          ),
                          Expanded(
                            child: _BubNavItem(
                              icon: Icons.settings_rounded,
                              label: 'Settings',
                              selected:
                                  selectedSection == _BubHomeSection.settings,
                              onTap: () => onSelected(_BubHomeSection.settings),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(top: 0, child: _BubNavHeartItem()),
          ],
        ),
      ),
    );
  }
}

class _BubNavItem extends StatelessWidget {
  const _BubNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = Theme.of(context).hintColor;
    final color = selected ? selectedColor : inactiveColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubNavHeartItem extends StatelessWidget {
  const _BubNavHeartItem();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: BubColors.bubGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: BubColors.pink.withValues(alpha: 0.34),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Image.asset(
              'assets/onboarding/heart.png',
              key: const Key('bub-nav-heart'),
              width: 52,
              height: 52,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Bub',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
