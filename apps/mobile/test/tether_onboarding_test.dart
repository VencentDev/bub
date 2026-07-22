import 'dart:async';

import 'package:bub/src/api/generated/models/chat_thread_response.dart';
import 'package:bub/src/api/generated/models/tether_invitation_response.dart';
import 'package:bub/src/api/generated/models/tether_status_response.dart';
import 'package:bub/src/api/generated/models/user_response_kyc_status.dart';
import 'package:bub/src/api/generated/models/user_response_role.dart';
import 'package:bub/src/api/generated/models/user_response_user_type.dart';
import 'package:bub/src/api/generated/models/user_response.dart';
import 'package:bub/src/api/generated/models/home_dashboard_response.dart';
import 'package:bub/src/api/generated/models/home_latest_bub_response.dart';
import 'package:bub/src/api/generated/models/home_mood_summary_response.dart';
import 'package:bub/src/api/generated/models/home_tether_card_response.dart';
import 'package:bub/src/api/generated/models/home_today_moment_response.dart';
import 'package:bub/src/auth/auth_controller.dart';
import 'package:bub/src/auth/auth_state.dart';
import 'package:bub/src/features/bub/bub_send_controller.dart';
import 'package:bub/src/features/bub/first_bub_tutorial.dart';
import 'package:bub/src/features/chat/chat_controller.dart';
import 'package:bub/src/features/home/home_dashboard_controller.dart';
import 'package:bub/src/features/home/home_screen.dart';
import 'package:bub/src/features/home/widgets/home_latest_bub_card.dart';
import 'package:bub/src/features/home/widgets/home_today_moment_card.dart';
import 'package:bub/src/features/safe/safe_controller.dart';
import 'package:bub/src/features/tether_onboarding/tether_onboarding_screens.dart';
import 'package:bub/src/theme/bub_colors.dart';
import 'package:bub/src/theme/bub_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('first-time untethered user routes to tether onboarding', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: false),
          tetherOnboardingComplete: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Bub'), findsOneWidget);
    expect(find.text('Who are you tethering with?'), findsOneWidget);
  });

  testWidgets('tethered user routes to paired Bub home', (tester) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(
            hasActiveTether: true,
            partnerUserId: 'partner-id',
          ),
          tetherOnboardingComplete: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's Moment"), findsOneWidget);
  });

  testWidgets('completed untethered user routes to Bub home', (tester) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: false),
          tetherOnboardingComplete: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's Moment"), findsOneWidget);
  });

  testWidgets('authenticated Bub home uses themed logo in app bar', (
    tester,
  ) async {
    Future<void> pumpHome(ThemeData theme) async {
      await tester.pumpWidget(
        _appWithAuth(
          AuthState.authenticated(
            user: _user(),
            tetherStatus: const TetherStatusResponse(hasActiveTether: true),
            tetherOnboardingComplete: true,
          ),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpHome(BubTheme.light);

    var logo = tester.widget<Image>(
      find.byKey(const Key('bub-app-bar-logo-image')),
    );
    expect(
      (logo.image as AssetImage).assetName,
      'assets/branding/bub-logo-purple.png',
    );
    expect(
      tester.getSize(find.byKey(const Key('bub-app-bar-logo'))),
      const Size(120, 30),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('bub-app-bar-logo'))).dx,
      0.0,
    );
    expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Bub')),
      findsNothing,
    );

    await pumpHome(BubTheme.dark);

    logo = tester.widget<Image>(
      find.byKey(const Key('bub-app-bar-logo-image')),
    );
    expect(
      (logo.image as AssetImage).assetName,
      'assets/branding/bub-logo.png',
    );
    expect(
      tester.getSize(find.byKey(const Key('bub-app-bar-logo'))),
      const Size(120, 30),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('bub-app-bar-logo'))).dx,
      0.0,
    );
    expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
  });

  testWidgets('authenticated Bub home shows floating glass navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: true),
          tetherOnboardingComplete: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nav = find.byKey(const Key('bub-floating-nav'));
    expect(nav, findsOneWidget);
    expect(
      find.descendant(of: nav, matching: find.text('Home')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: nav, matching: find.text('Chat')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: nav, matching: find.text('Bub')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: nav, matching: find.text('Safe')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: nav, matching: find.text('Settings')),
      findsOneWidget,
    );

    final centerHeart = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('bub-nav-heart')),
        matching: find.byType(Image),
      ),
    );
    expect(
      (centerHeart.image as AssetImage).assetName,
      'assets/onboarding/heart.png',
    );
    expect(centerHeart.width, greaterThanOrEqualTo(50));
    expect(centerHeart.height, greaterThanOrEqualTo(50));
    expect(find.byKey(const Key('bub-nav-safe-lock')), findsOneWidget);
  });

  testWidgets('authenticated Bub home switches non-Bub nav sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: true),
          tetherOnboardingComplete: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's Moment"), findsOneWidget);
    expect(find.text('Latest Bub'), findsNothing);
    expect(find.text('No Bubs yet'), findsNothing);
    expect(
      find.text(
        "Once you're tethered, tiny Bubs from your person will land here.",
      ),
      findsNothing,
    );
    expect(
      tester.getSize(find.byKey(const Key('home-latest-bub-card'))).height,
      lessThan(135),
    );
    expect(find.text('Send your first Bub'), findsWidgets);
    expect(find.byKey(const Key('home-first-bub-button')), findsOneWidget);
    expect(find.byKey(const Key('home-first-bub-button')), findsOneWidget);
    expect(
      find.text(
        "Once you're tethered, your daily photo moments will sparkle here.",
      ),
      findsNothing,
    );
    expect(
      find.text("Your partner hasn't shared their moment today."),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home-today-moment-camera-tile')),
      findsOneWidget,
    );

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tether someone to start your conversation'),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Safe'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('safe-screen')), findsOneWidget);
    expect(find.byKey(const Key('safe-pin-entry')), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-screen')), findsOneWidget);
    expect(find.byKey(const Key('settings-theme-row')), findsOneWidget);
    expect(find.byKey(const Key('settings-language-row')), findsOneWidget);
    expect(find.byKey(const Key('settings-tether-section')), findsOneWidget);
    expect(find.byKey(const Key('settings-account-section')), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text("Today's Moment"), findsOneWidget);
  });

  testWidgets('first Bub CTA launches tutorial for the nav heart', (
    tester,
  ) async {
    var launchCount = 0;
    GlobalKey? launchedTargetKey;

    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: true),
          tetherOnboardingComplete: true,
        ),
        overrides: [
          firstBubTutorialLauncherProvider.overrideWithValue((
            context,
            targetKey,
          ) {
            launchCount += 1;
            launchedTargetKey = targetKey;
          }),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bub-nav-heart')), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-first-bub-button')));
    await tester.pump();

    expect(launchCount, 1);
    expect(launchedTargetKey?.currentContext, isNotNull);
  });

  testWidgets('Bub nav sends once while a send is in progress', (tester) async {
    final sendController = _FakeBubSendController();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: true),
          tetherOnboardingComplete: true,
        ),
        overrides: [
          bubSendControllerProvider.overrideWith(() => sendController),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bub-nav-heart')));
    await tester.pump();
    expect(find.byKey(const Key('bub-heart-burst-heart')), findsWidgets);

    await tester.tap(find.byKey(const Key('bub-nav-heart')));
    await tester.pump();

    expect(sendController.sendCount, 1);
    expect(
      find.descendant(
        of: find.byKey(const Key('bub-nav-heart')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );

    sendController.completeSend();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Bub sent'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Bub sent')).dy, lessThan(140));
    await tester.pump(const Duration(milliseconds: 2200));
  });

  testWidgets('Bub nav failure shows a non-blocking error', (tester) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: true),
          tetherOnboardingComplete: true,
        ),
        overrides: [
          bubSendControllerProvider.overrideWith(
            () => _FakeBubSendController(error: StateError('nope')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bub-nav-heart')));
    await tester.pumpAndSettle();

    expect(find.text("Bub couldn't send. Please try again."), findsOneWidget);
    expect(
      tester.getTopLeft(find.text("Bub couldn't send. Please try again.")).dy,
      lessThan(140),
    );
    expect(find.byKey(const Key('bub-floating-nav')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2200));
  });

  test('dashboard refresh can preserve current data while fetching', () async {
    final initialDashboard = _dashboard();
    final nextDashboard = _dashboard(
      latestBub: HomeLatestBubResponse(
        hasActivity: true,
        copy: 'You Bubbed them',
        viewerLastSentAt: DateTime(2026, 7, 17, 12),
        viewerLastSentCopy: 'You Bubbed them',
      ),
    );
    final controller = _DelayedHomeDashboardController(initialDashboard);
    final container = ProviderContainer(
      overrides: [homeDashboardProvider.overrideWith(() => controller)],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(homeDashboardProvider.future),
      initialDashboard,
    );

    controller.delayNextBuild();
    final refresh = container
        .read(homeDashboardProvider.notifier)
        .refresh(preserveCurrent: true);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(homeDashboardProvider).asData?.value,
      initialDashboard,
    );

    controller.completeNextBuild(nextDashboard);
    await refresh;

    expect(container.read(homeDashboardProvider).asData?.value, nextDashboard);
  });

  testWidgets('home section renders dashboard cards and mood quick access', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: true),
          tetherOnboardingComplete: true,
        ),
        homeDashboard: _dashboard(
          tether: HomeTetherCardResponse(
            hasActiveTether: true,
            partnerUserId: 'partner-id',
            partnerDisplayName: 'Bobby',
            tetheredSince: DateTime(2026, 7, 1),
            viewerMood: 'calm',
            partnerMood: 'cozy',
          ),
          todayMoment: HomeTodayMomentResponse(
            momentId: 'moment-id',
            photoUrl: 'https://cdn.example.com/moment.jpg',
            partnerCapturedAt: DateTime(2026, 7, 16, 10, 42),
            localDate: DateTime(2026, 7, 16),
            viewerHasPostedToday: false,
            partnerReaction: '❤️',
          ),
          latestBub: HomeLatestBubResponse(
            hasActivity: true,
            copy: 'Partner Bubbed you',
            occurredAt: DateTime(2026, 7, 16, 10, 0),
          ),
          mood: const HomeMoodSummaryResponse(
            copy: 'How are you feeling?',
            mood: 'calm',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bobby'), findsNothing);
    expect(find.textContaining('Tethered since'), findsOneWidget);
    expect(find.byKey(const Key('home-tether-string')), findsOneWidget);
    expect(find.byKey(const Key('home-tether-viewer-mood')), findsOneWidget);
    expect(find.byKey(const Key('home-tether-partner-mood')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('home-tether-viewer-mood')),
        matching: find.text('calm'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('home-tether-partner-mood')),
        matching: find.text('cozy'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home-tether-since-date')), findsOneWidget);
    expect(find.byKey(const Key('home-tether-duration')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('home-partner-card'))).height,
      lessThan(165),
    );
    expect(find.byType(RefreshIndicator), findsOneWidget);
    final refreshList = tester.widget<ListView>(
      find.byKey(const Key('home-dashboard-refresh-list')),
    );
    expect(refreshList.physics, isA<AlwaysScrollableScrollPhysics>());
    expect(
      tester
          .getSize(find.byKey(const Key('home-today-moment-photo')))
          .aspectRatio,
      closeTo(1, 0.01),
    );
    expect(
      tester.getCenter(find.byKey(const Key('home-today-moment-photo'))).dx,
      greaterThan(tester.getCenter(find.text("Today's Moment")).dx),
    );
    expect(
      tester.getSize(find.byKey(const Key('home-today-moment-card'))).height,
      lessThan(260),
    );
    expect(find.byKey(const Key('home-today-moment-photo')), findsOneWidget);
    expect(
      find.byKey(const Key('home-today-moment-partner-timestamp')),
      findsOneWidget,
    );
    expect(
      tester
          .getCenter(
            find.byKey(const Key('home-today-moment-partner-timestamp')),
          )
          .dx,
      lessThan(
        tester.getCenter(find.byKey(const Key('home-today-moment-photo'))).dx,
      ),
    );
    expect(find.text('07/16'), findsOneWidget);
    expect(find.text('10:42 AM'), findsOneWidget);
    expect(
      find.byKey(const Key('home-today-moment-reaction-badge')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home-today-moment-reacted-heart')),
      findsOneWidget,
    );
    expect(find.text('❤️'), findsNothing);
    expect(find.text('Partner Bubbed you'), findsOneWidget);
    final bubArt = tester.widget<Image>(
      find.byKey(const Key('home-latest-bub-art')),
    );
    expect((bubArt.image as AssetImage).assetName, 'assets/onboarding/bub.png');
    expect(
      tester.getSize(find.byKey(const Key('home-latest-bub-card'))).height,
      lessThan(155),
    );
    expect(find.byKey(const Key('home-today-moment-mood-pill')), findsNothing);
    expect(find.text('Mood: calm'), findsNothing);
    expect(
      find.byKey(const Key('home-today-moment-camera-tile')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('home-mood-card')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mood'), findsOneWidget);
    expect(find.text('How are you feeling?'), findsWidgets);
    expect(find.byKey(const Key('home-mood-card')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('home-mood-value')),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-mood-value')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-mood-dialog-glass')), findsOneWidget);
    expect(find.byKey(const Key('home-mood-dialog-field')), findsOneWidget);
    expect(find.text('How are you feeling?'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('home-mood-dialog-field')),
      'cozy',
    );
    await tester.tap(find.text('Save mood'));
    await tester.pumpAndSettle();
    expect(find.text('cozy'), findsOneWidget);
    expect(find.byKey(const Key('home-mood-card')), findsOneWidget);
  });

  testWidgets('latest Bub card separates untethered and first Bub states', (
    tester,
  ) async {
    var firstBubTapCount = 0;

    await tester.pumpWidget(
      _latestBubCardApp(
        latestBub: const HomeLatestBubResponse(
          hasActivity: false,
          copy: 'Tether to send bub',
        ),
        isTethered: false,
        onFirstBubPressed: () => firstBubTapCount += 1,
      ),
    );

    expect(find.text('Tether to send bub'), findsOneWidget);
    expect(find.byKey(const Key('home-first-bub-button')), findsNothing);

    await tester.pumpWidget(
      _latestBubCardApp(
        latestBub: const HomeLatestBubResponse(
          hasActivity: false,
          copy: 'Send your first Bub',
        ),
        isTethered: true,
        onFirstBubPressed: () => firstBubTapCount += 1,
      ),
    );

    expect(find.text('Tether to send bub'), findsNothing);
    expect(find.text('Send your first Bub'), findsWidgets);
    await tester.tap(find.byKey(const Key('home-first-bub-button')));
    expect(firstBubTapCount, 1);
  });

  testWidgets('latest Bub card renders directional activity rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _latestBubCardApp(
        latestBub: HomeLatestBubResponse(
          hasActivity: true,
          viewerLastSentAt: DateTime(2026, 7, 17, 8, 30),
          partnerLastSentAt: DateTime(2026, 7, 17, 7, 0),
          viewerLastSentCopy: 'You Bubbed them',
          partnerLastSentCopy: 'Your partner Bubbed you',
          streakDays: 45,
        ),
        isTethered: true,
        now: DateTime(2026, 7, 17, 9, 0),
      ),
    );

    expect(find.text('Latest Bub'), findsOneWidget);
    expect(
      find.byKey(const Key('home-latest-bub-partner-sent-row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home-latest-bub-viewer-sent-row')),
      findsOneWidget,
    );
    expect(find.text('Your partner Bubbed you'), findsOneWidget);
    expect(find.text('You Bubbed them'), findsOneWidget);
    expect(find.byKey(const Key('home-latest-bub-streak')), findsOneWidget);
    expect(find.text('45 days'), findsOneWidget);
    expect(find.text('2 hours ago'), findsOneWidget);
    expect(find.text('30 mins ago'), findsOneWidget);
  });

  testWidgets(
    'latest Bub card renders single directional rows without overflow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _latestBubCardApp(
          latestBub: HomeLatestBubResponse(
            hasActivity: true,
            viewerLastSentAt: DateTime(2026, 7, 17, 8, 59),
            viewerLastSentCopy: 'You Bubbed them',
          ),
          isTethered: true,
          now: DateTime(2026, 7, 17, 9, 0),
        ),
      );

      expect(
        find.byKey(const Key('home-latest-bub-viewer-sent-row')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('home-latest-bub-partner-sent-row')),
        findsNothing,
      );
      expect(find.text('1 mins ago'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _latestBubCardApp(
          latestBub: HomeLatestBubResponse(
            hasActivity: true,
            partnerLastSentAt: DateTime(2026, 7, 17, 9, 0),
            partnerLastSentCopy: 'Your partner Bubbed you',
          ),
          isTethered: true,
          now: DateTime(2026, 7, 17, 9, 0),
        ),
      );

      expect(
        find.byKey(const Key('home-latest-bub-partner-sent-row')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('home-latest-bub-viewer-sent-row')),
        findsNothing,
      );
      expect(find.text('Just now'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tethered home with no mood shows standalone mood card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: true),
          tetherOnboardingComplete: true,
        ),
        homeDashboard: _dashboard(
          todayMoment: HomeTodayMomentResponse(
            momentId: 'moment-id',
            photoUrl: 'https://cdn.example.com/moment.jpg',
            localDate: DateTime(2026, 7, 16),
            viewerHasPostedToday: false,
          ),
          mood: const HomeMoodSummaryResponse(copy: 'How are you feeling?'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-today-moment-mood-pill')), findsNothing);
    expect(
      find.byKey(const Key('home-today-moment-empty-heart')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('home-mood-card')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -140));
    await tester.pumpAndSettle();
    expect(find.text('Add'), findsOneWidget);
    expect(find.byKey(const Key('home-mood-card')), findsOneWidget);
  });

  testWidgets('today moment shows self polaroid when viewer has posted', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: true),
          tetherOnboardingComplete: true,
        ),
        homeDashboard: _dashboard(
          todayMoment: HomeTodayMomentResponse(
            momentId: 'moment-id',
            viewerPhotoUrl: 'https://cdn.example.com/moment.jpg',
            localDate: DateTime(2026, 7, 16),
            viewerHasPostedToday: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('home-today-moment-self-polaroid')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home-today-moment-photo')), findsNothing);
    expect(
      find.text("Your partner hasn't shared their moment today."),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home-today-moment-camera-tile')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('home-today-moment-self-polaroid')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('home-today-moment-self-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home-today-moment-retake-button')),
      findsOneWidget,
    );
  });

  testWidgets('untethered home keeps mood card and empty moment state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: false),
          tetherOnboardingComplete: true,
        ),
        homeDashboard: _dashboard(
          tether: const HomeTetherCardResponse(hasActiveTether: false),
          todayMoment: null,
          mood: const HomeMoodSummaryResponse(
            copy: 'How are you feeling?',
            mood: 'steady',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining("Once you're tethered"), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const Key('home-mood-card')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('home-mood-card')), findsOneWidget);
    expect(find.text('steady'), findsOneWidget);
  });

  testWidgets('today moment card uses theme-aware soft gradients', (
    tester,
  ) async {
    Future<BoxDecoration> pumpCard(ThemeData theme) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: BubTheme.light,
          home: Scaffold(
            body: Theme(
              data: theme,
              child: HomeTodayMomentCard(
                moment: null,
                onReact: () {},
                onCaptureMoment: () {},
              ),
            ),
          ),
        ),
      );

      return tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: find.byKey(const Key('home-today-moment-card')),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .first
              .decoration
          as BoxDecoration;
    }

    final lightDecoration = await pumpCard(BubTheme.light);
    expect(
      (lightDecoration.gradient! as LinearGradient).colors,
      contains(BubColors.partnerBubbleLight),
    );

    final darkDecoration = await pumpCard(BubTheme.dark);
    expect(
      (darkDecoration.gradient! as LinearGradient).colors,
      contains(BubColors.deepPurple.withValues(alpha: 0.96)),
    );
  });

  testWidgets('glass mood dialog validates and saves trimmed mood', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: true),
          tetherOnboardingComplete: true,
        ),
        homeDashboard: _dashboard(
          todayMoment: HomeTodayMomentResponse(
            momentId: 'moment-id',
            photoUrl: 'https://cdn.example.com/moment.jpg',
            localDate: DateTime(2026, 7, 16),
            viewerHasPostedToday: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('home-mood-empty-button')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -140));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-mood-empty-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save mood'));
    await tester.pumpAndSettle();
    expect(find.text('Mood is required'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('home-mood-dialog-field')),
      'this mood is too long today',
    );
    await tester.tap(find.text('Save mood'));
    await tester.pumpAndSettle();
    expect(find.text('Use 20 characters or fewer'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('home-mood-dialog-field')),
      '  bright  ',
    );
    await tester.tap(find.text('Save mood'));
    await tester.pumpAndSettle();
    expect(find.text('bright'), findsOneWidget);
  });

  testWidgets('home section renders untethered partner CTA', (tester) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: false),
          tetherOnboardingComplete: true,
        ),
        homeDashboard: _dashboard(
          tether: const HomeTetherCardResponse(
            hasActiveTether: false,
            ctaLabel: 'Tether with someone',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bear = tester.widget<Image>(
      find.byKey(const Key('home-tether-bear')),
    );
    expect(
      (bear.image as AssetImage).assetName,
      'assets/illustrations/bears/bear1.png',
    );
    expect(find.text('Find your Bub'), findsOneWidget);
    expect(
      find.text(
        "Once you're tethered, you'll see how long you've been paired here.",
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home-tether-cta-heart')), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Start tethering'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('home-tether-cta-button'))).width,
      greaterThan(180),
    );
    expect(
      tester.getSize(find.byKey(const Key('home-partner-card'))).height,
      lessThan(145),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Start tethering'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Bub'), findsOneWidget);
  });

  testWidgets('skip from home-started tethering returns to untethered home', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: false),
          tetherOnboardingComplete: true,
        ),
        homeDashboard: _dashboard(
          tether: const HomeTetherCardResponse(
            hasActiveTether: false,
            ctaLabel: 'Tether with someone',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Start tethering'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Skip for now'),
      80,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Bub'), findsNothing);
    expect(find.text('Find your Bub'), findsOneWidget);
  });

  testWidgets('enter tether screen renders required controls and bear', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: false),
          tetherOnboardingComplete: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bear = tester.widget<Image>(
      find.byKey(const Key('enter-tether-bear')),
    );
    expect(
      (bear.image as AssetImage).assetName,
      'assets/illustrations/bears/bear4.png',
    );
    final welcome = tester.widget<Text>(find.byKey(const Key('welcome-title')));
    final prompt = tester.widget<Text>(find.byKey(const Key('tether-prompt')));
    expect(welcome.style?.fontSize, greaterThan(prompt.style?.fontSize ?? 0));
    expect(bear.height, greaterThanOrEqualTo(280));
    expect(find.byKey(const Key('tether-code-field')), findsOneWidget);
    expect(find.byKey(const Key('qr-scanner-button')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('or'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('or'), findsOneWidget);
    expect(find.text('Generate new tether'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Skip for now'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Skip for now'), findsOneWidget);
  });

  testWidgets('onboarding background adapts to the active theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: false),
          tetherOnboardingComplete: false,
        ),
        theme: BubTheme.dark,
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, BubColors.darkScaffold);
  });

  testWidgets('scan QR opens scanner without completing onboarding', (
    tester,
  ) async {
    final controller = _FakeAuthController(
      AuthState.authenticated(
        user: _user(),
        tetherStatus: const TetherStatusResponse(hasActiveTether: false),
        tetherOnboardingComplete: false,
      ),
    );
    await tester.pumpWidget(_appWithAuthController(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('qr-scanner-button')));
    await tester.pumpAndSettle();

    expect(controller.completeCount, 0);
    expect(find.byKey(const Key('tether-scanner-guide')), findsOneWidget);
    expect(find.byKey(const Key('scanner-back-button')), findsOneWidget);
    expect(find.text('Place the QR inside the frame'), findsOneWidget);
  });

  test('tether QR payload parser extracts Bub codes only', () {
    expect(
      parseTetherCodeFromQrPayload('bub://tether/accept?code=BUB-7KQ2-XH19'),
      'BUB-7KQ2-XH19',
    );
    expect(parseTetherCodeFromQrPayload('BUB-7KQ2-XH19'), 'BUB-7KQ2-XH19');
    expect(parseTetherCodeFromQrPayload('https://example.com'), isNull);
    expect(parseTetherCodeFromQrPayload('BUB-NOPE'), isNull);
  });

  testWidgets('generate tether screen renders QR, code, and DONE action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tetherInvitationProvider.overrideWith(
            (ref) async => TetherInvitationResponse(
              id: 'invite-id',
              code: 'BUB-7KQ2-XH19',
              expiresAt: DateTime.utc(2026, 7, 17),
              qrPayload: 'bub://tether/accept?code=BUB-7KQ2-XH19',
            ),
          ),
        ],
        child: const MaterialApp(home: GenerateTetherScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Share your tether code'), findsOneWidget);
    expect(
      find.byKey(const Key('back-from-generate-tether-button')),
      findsOneWidget,
    );
    expect(
      find.text('Send this code to your person so they can Bub with you.'),
      findsOneWidget,
    );
    final qr = tester.widget<QrImageView>(
      find.byKey(const Key('tether-qr-code')),
    );
    expect(qr.embeddedImage, isNull);
    expect(qr.errorCorrectionLevel, QrErrorCorrectLevel.H);
    expect(qr.embeddedImageStyle, isNull);
    expect(find.byKey(const Key('tether-code-container')), findsOneWidget);
    expect(find.byKey(const Key('copy-tether-code-button')), findsOneWidget);
    expect(find.text('BUB-7KQ2-XH19'), findsOneWidget);
    expect(find.text('DONE'), findsOneWidget);
  });

  testWidgets('all set screen renders confirmation and routes to Bub', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: false),
          tetherOnboardingComplete: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    Navigator.of(
      tester.element(find.byType(EnterTetherScreen)),
    ).push(MaterialPageRoute<void>(builder: (_) => const AllSetScreen()));
    await tester.pumpAndSettle();

    final bear = tester.widget<Image>(find.byKey(const Key('all-set-bear')));
    expect(
      (bear.image as AssetImage).assetName,
      'assets/illustrations/bears/bear2.png',
    );
    expect(bear.height, greaterThanOrEqualTo(300));
    expect(find.text('All set'), findsOneWidget);
    expect(find.text("You're almost there"), findsOneWidget);

    await tester.tap(find.byKey(const Key('go-to-bub-button')));
    await tester.pumpAndSettle();

    expect(find.text("Today's Moment"), findsOneWidget);
  });
}

Widget _appWithAuth(
  AuthState state, {
  Widget? home,
  ThemeData? theme,
  HomeDashboardResponse? homeDashboard,
  List<dynamic> overrides = const [],
}) {
  return _appWithAuthController(
    _FakeAuthController(state),
    home: home,
    theme: theme,
    homeDashboard: homeDashboard,
    overrides: overrides,
  );
}

Widget _appWithAuthController(
  _FakeAuthController controller, {
  Widget? home,
  ThemeData? theme,
  HomeDashboardResponse? homeDashboard,
  List<dynamic> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => controller),
      homeDashboardProvider.overrideWith(
        () => _FakeHomeDashboardController(homeDashboard ?? _dashboard()),
      ),
      chatThreadProvider.overrideWith(
        () => _FakeChatThreadController(
          const ChatThreadResponse(hasActiveTether: false, messages: []),
        ),
      ),
      safeControllerProvider.overrideWith(
        () => _FakeSafeController(
          const SafeStatus(tethered: true, pinConfigured: true),
        ),
      ),
      tetherScannerPreviewProvider.overrideWithValue(
        (context, scanWindow, onPayloadDetected) =>
            const ColoredBox(color: Colors.black),
      ),
      ...overrides,
    ],
    child: MaterialApp(theme: theme, home: home ?? const HomeScreen()),
  );
}

Widget _latestBubCardApp({
  required HomeLatestBubResponse latestBub,
  required bool isTethered,
  VoidCallback? onFirstBubPressed,
  DateTime? now,
}) {
  return MaterialApp(
    theme: BubTheme.light,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: HomeLatestBubCard(
            latestBub: latestBub,
            isTethered: isTethered,
            onFirstBubPressed: onFirstBubPressed ?? () {},
            now: now,
          ),
        ),
      ),
    ),
  );
}

HomeDashboardResponse _dashboard({
  HomeTetherCardResponse? tether,
  HomeTodayMomentResponse? todayMoment,
  HomeLatestBubResponse latestBub = const HomeLatestBubResponse(
    hasActivity: false,
    copy: 'Send your first Bub',
  ),
  HomeMoodSummaryResponse mood = const HomeMoodSummaryResponse(
    copy: 'How are you feeling?',
  ),
}) {
  return HomeDashboardResponse(
    tether:
        tether ??
        HomeTetherCardResponse(
          hasActiveTether: true,
          partnerUserId: 'partner-id',
          partnerDisplayName: 'Partner',
          tetheredSince: DateTime(2026, 7, 1),
        ),
    todayMoment: todayMoment,
    latestBub: latestBub,
    mood: mood,
  );
}

class _FakeHomeDashboardController extends HomeDashboardController {
  _FakeHomeDashboardController(this.dashboard);

  HomeDashboardResponse dashboard;

  @override
  Future<HomeDashboardResponse> build() async => dashboard;

  @override
  Future<void> putMood(String mood) async {
    dashboard = HomeDashboardResponse(
      tether: dashboard.tether,
      todayMoment: dashboard.todayMoment,
      latestBub: dashboard.latestBub,
      mood: HomeMoodSummaryResponse(copy: dashboard.mood?.copy, mood: mood),
    );
    state = AsyncData(dashboard);
  }
}

class _DelayedHomeDashboardController extends HomeDashboardController {
  _DelayedHomeDashboardController(this.dashboard);

  HomeDashboardResponse dashboard;
  Completer<HomeDashboardResponse>? _nextBuild;

  @override
  Future<HomeDashboardResponse> build() {
    final nextBuild = _nextBuild;
    if (nextBuild != null) {
      return nextBuild.future;
    }
    return Future.value(dashboard);
  }

  void delayNextBuild() {
    _nextBuild = Completer<HomeDashboardResponse>();
  }

  void completeNextBuild(HomeDashboardResponse nextDashboard) {
    dashboard = nextDashboard;
    _nextBuild?.complete(nextDashboard);
    _nextBuild = null;
  }
}

class _FakeBubSendController extends BubSendController {
  _FakeBubSendController({this.error});

  final Object? error;
  var sendCount = 0;
  Completer<void>? _sendCompleter;

  @override
  Future<void> build() async {}

  @override
  Future<void> sendBub() async {
    if (state.isLoading) {
      return;
    }
    sendCount += 1;
    if (error != null) {
      state = AsyncError(error!, StackTrace.current);
      throw error!;
    }
    _sendCompleter = Completer<void>();
    state = const AsyncLoading();
    await _sendCompleter!.future;
    state = const AsyncData(null);
  }

  void completeSend() {
    _sendCompleter?.complete();
  }
}

class _FakeChatThreadController extends ChatThreadController {
  _FakeChatThreadController(this.thread);

  final ChatThreadResponse thread;

  @override
  Future<ChatThreadResponse> build() async => thread;
}

class _FakeSafeController extends SafeController {
  _FakeSafeController(this.status);

  final SafeStatus status;

  @override
  Future<SafeStatus> build() async => status;
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this.initial);

  final AuthState initial;
  var completeCount = 0;

  @override
  Future<AuthState> build() async => initial;

  @override
  Future<void> refreshTetherStatus({
    bool markComplete = false,
    bool markSkipped = false,
  }) async {
    final user = state.asData?.value.user ?? initial.user!;
    final tetherStatus =
        state.asData?.value.tetherStatus ?? initial.tetherStatus!;
    state = AsyncData(
      AuthState.authenticated(
        user: user,
        tetherStatus: tetherStatus,
        tetherOnboardingComplete:
            markComplete || markSkipped || initial.tetherOnboardingComplete,
      ),
    );
  }

  @override
  Future<void> completeTetherOnboarding({
    TetherStatusResponse? tetherStatus,
  }) async {
    completeCount += 1;
    await refreshTetherStatus(markComplete: true);
  }

  @override
  Future<void> skipTetherOnboarding() =>
      refreshTetherStatus(markComplete: true);
}

UserResponse _user() => UserResponse(
  id: 'user-id',
  email: 'user@example.com',
  role: UserResponseRole.user,
  userType: UserResponseUserType.individual,
  kycStatus: UserResponseKycStatus.none,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
