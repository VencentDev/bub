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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('first-time untethered user routes to tether onboarding', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: false),
          tetherOnboardingSkipped: false,
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
          tetherOnboardingSkipped: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("You're tethered"), findsOneWidget);
  });

  testWidgets('skipped user routes to untethered Bub home', (tester) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: false),
          tetherOnboardingSkipped: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("You're not tethered yet ❤️"), findsOneWidget);
  });

  testWidgets('enter tether screen renders required controls and bear', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithAuth(
        AuthState.authenticated(
          user: _user(),
          tetherStatus: const TetherStatusResponse(hasActiveTether: false),
          tetherOnboardingSkipped: false,
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
    expect(find.byKey(const Key('tether-code-field')), findsOneWidget);
    expect(find.byKey(const Key('qr-scanner-button')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('or'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('or'), findsOneWidget);
    expect(find.text('Generate new tether'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
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

    expect(find.text('Share your tethered link'), findsOneWidget);
    expect(
      find.text('Send this link to your person so they can Bub with you.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('tether-qr-code')), findsOneWidget);
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
          tetherOnboardingSkipped: false,
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
    expect(find.text('All set'), findsOneWidget);
    expect(find.text("You're almost there"), findsOneWidget);

    await tester.tap(find.byKey(const Key('go-to-bub-button')));
    await tester.pumpAndSettle();

    expect(find.text("You're not tethered yet ❤️"), findsOneWidget);
  });
}

Widget _appWithAuth(AuthState state, {Widget? home}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(state)),
    ],
    child: MaterialApp(home: home ?? const HomeScreen()),
  );
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this.initial);

  final AuthState initial;

  @override
  Future<AuthState> build() async => initial;

  @override
  Future<void> refreshTetherStatus({bool markSkipped = false}) async {
    final user = state.asData?.value.user ?? initial.user!;
    final tetherStatus =
        state.asData?.value.tetherStatus ?? initial.tetherStatus!;
    state = AsyncData(
      AuthState.authenticated(
        user: user,
        tetherStatus: tetherStatus,
        tetherOnboardingSkipped: markSkipped || initial.tetherOnboardingSkipped,
      ),
    );
  }

  @override
  Future<void> skipTetherOnboarding() => refreshTetherStatus(markSkipped: true);
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
