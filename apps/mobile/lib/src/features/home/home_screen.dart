import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_state.dart';
import '../../core/env.dart';
import '../../features/bub/bub_heart_burst.dart';
import '../../features/bub/bub_send_controller.dart';
import '../../features/bub/first_bub_tutorial.dart';
import '../../features/chat/chat_section.dart';
import '../../features/home/home_dashboard_controller.dart';
import '../../features/home/widgets/home_latest_bub_card.dart';
import '../../features/home/widgets/home_mood_card.dart';
import '../../features/home/widgets/home_partner_card.dart';
import '../../features/home/widgets/home_today_moment_card.dart';
import '../../features/safe/safe_screen.dart';
import '../../features/settings/settings_screen.dart';
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
  var _bubJellyTrigger = 0;
  var _heartBurstTrigger = 0;
  DateTime? _lastSeenPartnerBubAt;
  var _hasSeenPartnerBubSnapshot = false;
  final _bubNavTargetKey = GlobalKey(debugLabel: 'bub-nav-heart-target');

  void _selectSection(_BubHomeSection section) {
    setState(() {
      _section = section;
    });
  }

  void _startFirstBubTutorial() {
    setState(() {
      _section = _BubHomeSection.home;
    });
    ref.read(firstBubTutorialLauncherProvider)(context, _bubNavTargetKey);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to get back to Bub.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) {
      return;
    }
    widget.onLogout();
  }

  Future<void> _sendBub() async {
    if (!widget.paired) {
      _showBubToast(
        context,
        message: 'Tether with someone to send a Bub.',
        icon: Icons.favorite_border_rounded,
      );
      return;
    }

    setState(() {
      _bubJellyTrigger += 1;
      _heartBurstTrigger += 1;
    });
    try {
      await ref.read(bubSendControllerProvider.notifier).sendBub();
      await HapticFeedback.lightImpact();
      if (!mounted) {
        return;
      }
      _showBubToast(context, message: 'Bub sent', icon: Icons.favorite_rounded);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showBubToast(
        context,
        message: _bubSendMessage(error),
        icon: Icons.favorite_border_rounded,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bubSendState = ref.watch(bubSendControllerProvider);
    ref.listen(homeDashboardProvider, (_, next) {
      final partnerLastSentAt = next.asData?.value.latestBub?.partnerLastSentAt;
      if (!_hasSeenPartnerBubSnapshot) {
        _hasSeenPartnerBubSnapshot = true;
        _lastSeenPartnerBubAt = partnerLastSentAt;
        return;
      }
      if (partnerLastSentAt == null) {
        return;
      }
      final previousPartnerBub = _lastSeenPartnerBubAt;
      if (previousPartnerBub != null &&
          !partnerLastSentAt.isAfter(previousPartnerBub)) {
        return;
      }
      _lastSeenPartnerBubAt = partnerLastSentAt;
      HapticFeedback.heavyImpact();
      if (!mounted) {
        return;
      }
      setState(() {
        _heartBurstTrigger += 1;
      });
      _showBubToast(
        context,
        message: 'They Bubbed you',
        icon: Icons.favorite_rounded,
      );
    });
    if (_section == _BubHomeSection.chat) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: ChatSection(onBack: () => _selectSection(_BubHomeSection.home)),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        titleSpacing: 0,
        title: const _BubAppBarLogo(),
        actions: [
          TextButton(onPressed: _confirmLogout, child: const Text('Logout')),
        ],
      ),
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _BubHomeSectionBody(
              section: _section,
              paired: widget.paired,
              onOpenSafe: () => _selectSection(_BubHomeSection.safe),
              onStartFirstBub: _startFirstBubTutorial,
            ),
          ),
          Positioned.fill(child: BubHeartBurst(trigger: _heartBurstTrigger)),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BubFloatingNav(
              selectedSection: _section,
              onSelected: _selectSection,
              bubTargetKey: _bubNavTargetKey,
              onBubPressed: _sendBub,
              sendingBub: bubSendState.isLoading,
              bubJellyTrigger: _bubJellyTrigger,
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
  const _BubHomeSectionBody({
    required this.section,
    required this.paired,
    required this.onOpenSafe,
    required this.onStartFirstBub,
  });

  final _BubHomeSection section;
  final bool paired;
  final VoidCallback onOpenSafe;
  final VoidCallback onStartFirstBub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (section == _BubHomeSection.chat) {
      return const ChatSection();
    }

    if (section != _BubHomeSection.home) {
      if (section == _BubHomeSection.safe) {
        return const SafeScreen();
      }
      return SettingsScreen(paired: paired);
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
        final isTethered = paired && tether.hasActiveTether == true;
        return RefreshIndicator(
          onRefresh: () => ref.read(homeDashboardProvider.notifier).refresh(),
          child: ListView(
            key: const Key('home-dashboard-refresh-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            cacheExtent: 1200,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 140),
            children: [
              HomePartnerCard(tether: tether),
              const SizedBox(height: 16),
              HomeTodayMomentCard(
                moment: data.todayMoment,
                isTethered: isTethered,
                onCaptureMoment: () async {
                  try {
                    await ref
                        .read(homeDashboardProvider.notifier)
                        .captureTodayMoment();
                  } catch (error) {
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_momentUploadMessage(error))),
                    );
                  }
                },
                onReact: data.todayMoment == null
                    ? () {}
                    : () => ref
                          .read(homeDashboardProvider.notifier)
                          .reactToTodayMoment(data.todayMoment!.momentId ?? ''),
              ),
              const SizedBox(height: 16),
              HomeLatestBubCard(
                latestBub: latestBub,
                isTethered: isTethered,
                onFirstBubPressed: onStartFirstBub,
              ),
              const SizedBox(height: 16),
              HomeMoodCard(
                mood: mood,
                onSaveMood: (mood) =>
                    ref.read(homeDashboardProvider.notifier).putMood(mood),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _momentUploadMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
  }
  return "Moment couldn't upload. Please try again.";
}

String _bubSendMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
  }
  return "Bub couldn't send. Please try again.";
}

class _BubFloatingNav extends StatelessWidget {
  const _BubFloatingNav({
    required this.selectedSection,
    required this.onSelected,
    required this.bubTargetKey,
    required this.onBubPressed,
    required this.sendingBub,
    required this.bubJellyTrigger,
  });

  final _BubHomeSection selectedSection;
  final ValueChanged<_BubHomeSection> onSelected;
  final GlobalKey bubTargetKey;
  final VoidCallback onBubPressed;
  final bool sendingBub;
  final int bubJellyTrigger;

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
            Positioned(
              top: 0,
              child: _BubNavHeartItem(
                targetKey: bubTargetKey,
                onTap: sendingBub ? null : onBubPressed,
                sending: sendingBub,
                jellyTrigger: bubJellyTrigger,
              ),
            ),
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

class _BubNavHeartItem extends StatefulWidget {
  const _BubNavHeartItem({
    required this.targetKey,
    required this.onTap,
    required this.sending,
    required this.jellyTrigger,
  });

  final GlobalKey targetKey;
  final VoidCallback? onTap;
  final bool sending;
  final int jellyTrigger;

  @override
  State<_BubNavHeartItem> createState() => _BubNavHeartItemState();
}

class _BubNavHeartItemState extends State<_BubNavHeartItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _squish;
  late final Animation<double> _stretch;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _squish = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.18), weight: 18),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.88), weight: 22),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.08), weight: 24),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1), weight: 36),
    ]).animate(curve);
    _stretch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.82), weight: 18),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.16), weight: 22),
      TweenSequenceItem(tween: Tween(begin: 1.16, end: 0.94), weight: 24),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1), weight: 36),
    ]).animate(curve);
  }

  @override
  void didUpdateWidget(covariant _BubNavHeartItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.jellyTrigger != oldWidget.jellyTrigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('bub-nav-heart'),
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scaleX: _squish.value,
                scaleY: _stretch.value,
                child: child,
              );
            },
            child: Opacity(
              opacity: widget.sending ? 0.82 : 1,
              child: Container(
                key: widget.targetKey,
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
                  width: 85,
                  height: 85,
                  fit: BoxFit.contain,
                ),
              ),
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

void _showBubToast(
  BuildContext context, {
  required String message,
  required IconData icon,
  bool isError = false,
}) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) =>
        _BubToastOverlay(message: message, icon: icon, isError: isError),
  );
  overlay.insert(entry);
  Future<void>.delayed(const Duration(milliseconds: 2100), () {
    if (entry.mounted) {
      entry.remove();
    }
  });
}

class _BubToastOverlay extends StatefulWidget {
  const _BubToastOverlay({
    required this.message,
    required this.icon,
    required this.isError,
  });

  final String message;
  final IconData icon;
  final bool isError;

  @override
  State<_BubToastOverlay> createState() => _BubToastOverlayState();
}

class _BubToastOverlayState extends State<_BubToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, -0.28),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 18,
      right: 18,
      child: SafeArea(
        bottom: false,
        child: IgnorePointer(
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _offset,
              child: _BubToast(
                message: widget.message,
                icon: widget.icon,
                isError: widget.isError,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubToast extends StatelessWidget {
  const _BubToast({
    required this.message,
    required this.icon,
    required this.isError,
  });

  final String message;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = brightness == Brightness.dark
        ? BubColors.darkDialog.withValues(alpha: 0.96)
        : BubColors.white.withValues(alpha: 0.98);
    final borderColor = isError
        ? BubColors.coral.withValues(alpha: 0.42)
        : BubColors.pink.withValues(alpha: 0.32);
    final textColor = brightness == Brightness.dark
        ? BubColors.textPrimaryDark
        : BubColors.textPrimaryLight;
    final iconColor = isError ? BubColors.coral : BubColors.pink;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: BubColors.deepPurple.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
