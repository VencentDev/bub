import 'package:bub/src/api/generated/models/kyc_status.dart';
import 'package:bub/src/api/generated/models/role.dart';
import 'package:bub/src/api/generated/models/tether_invitation_response.dart';
import 'package:bub/src/api/generated/models/tether_status_response.dart';
import 'package:bub/src/api/generated/models/user_response.dart';
import 'package:bub/src/auth/auth_controller.dart';
import 'package:bub/src/auth/auth_state.dart';
import 'package:bub/src/features/home/home_screen.dart';
import 'package:bub/src/features/tether_onboarding/tether_onboarding_screens.dart';
import 'package:bub/src/api/generated/models/user_type.dart';
import 'package:bub/src/theme/bub_colors.dart';
import 'package:bub/src/theme/bub_theme.dart';
import 'package:flutter/material.dart';
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

    expect(find.text("You're tethered"), findsOneWidget);
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

    expect(find.text("You're not tethered yet ❤️"), findsOneWidget);
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
      find.byKey(const Key('bub-nav-heart')),
    );
    expect(
      (centerHeart.image as AssetImage).assetName,
      'assets/onboarding/heart.png',
    );
    expect(centerHeart.width, greaterThanOrEqualTo(40));
    expect(centerHeart.height, greaterThanOrEqualTo(40));
    expect(find.byKey(const Key('bub-nav-safe-lock')), findsOneWidget);
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

    expect(find.text("You're not tethered yet ❤️"), findsOneWidget);
  });
}

Widget _appWithAuth(AuthState state, {Widget? home, ThemeData? theme}) {
  return _appWithAuthController(
    _FakeAuthController(state),
    home: home,
    theme: theme,
  );
}

Widget _appWithAuthController(
  _FakeAuthController controller, {
  Widget? home,
  ThemeData? theme,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => controller),
      tetherScannerPreviewProvider.overrideWithValue(
        (context, scanWindow, onPayloadDetected) =>
            const ColoredBox(color: Colors.black),
      ),
    ],
    child: MaterialApp(theme: theme, home: home ?? const HomeScreen()),
  );
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
  role: Role.user,
  userType: UserType.individual,
  kycStatus: KycStatus.none,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
