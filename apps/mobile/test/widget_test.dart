import 'dart:io';

import 'package:bub/main.dart';
import 'package:bub/src/api/generated/models/chat_thread_response.dart';
import 'package:bub/src/api/generated/models/tether_status_response.dart';
import 'package:bub/src/api/generated/models/user_response.dart';
import 'package:bub/src/auth/auth_service.dart';
import 'package:bub/src/auth/auth_controller.dart';
import 'package:bub/src/auth/auth_state.dart';
import 'package:bub/src/auth/token_store.dart';
import 'package:bub/src/core/dio_provider.dart';
import 'package:bub/src/features/chat/chat_controller.dart';
import 'package:bub/src/features/notifications/notification_controller.dart';
import 'package:bub/src/features/settings/legal_policy_controller.dart';
import 'package:bub/src/features/settings/legal_policy_screen.dart';
import 'package:bub/src/features/settings/settings_controller.dart';
import 'package:bub/src/features/settings/settings_screen.dart';
import 'package:bub/src/features/settings/settings_store.dart';
import 'package:bub/src/theme/bub_colors.dart';
import 'package:bub/src/theme/bub_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Avoids touching platform channels (secure storage) during the test.
class _LoggedOutAuthService extends AuthService {
  _LoggedOutAuthService()
    : super(GoogleSignIn.instance, TokenStore(const FlutterSecureStorage()));

  @override
  Future<bool> get isLoggedIn async => false;
}

void main() {
  testWidgets('logged-out home shows the Google sign-in action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(_LoggedOutAuthService()),
        ],
        child: const MobileApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('logged-out home uses branded background and gradient button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(_LoggedOutAuthService()),
        ],
        child: const MobileApp(),
      ),
    );
    await tester.pumpAndSettle();

    final background = tester.widget<Image>(
      find.byKey(const Key('login-background')),
    );
    expect(
      (background.image as AssetImage).assetName,
      'assets/branding/signin.png',
    );
    expect(find.byKey(const Key('google-sign-in-gradient')), findsOneWidget);
    final googleIcon = tester.widget<Image>(
      find.byKey(const Key('google-icon')),
    );
    expect(
      (googleIcon.image as AssetImage).assetName,
      'assets/icons/google.png',
    );
    final buttonSafeArea = tester
        .widgetList<SafeArea>(find.byType(SafeArea))
        .singleWhere((safeArea) => safeArea.minimum.bottom > 0);
    expect(buttonSafeArea.minimum.bottom, 48);
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('mobile app applies stored dark mode preference', (tester) async {
    final store = _MemorySettingsStore()
      ..themeMode = BubSettingsThemeMode.dark
      ..language = 'en';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(_LoggedOutAuthService()),
          settingsStoreProvider.overrideWithValue(store),
          settingsRemoteSyncProvider.overrideWithValue(
            _NoopSettingsRemoteSync(),
          ),
        ],
        child: const MobileApp(),
      ),
    );
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('chat opens as a full-screen page without the Bub shell chrome', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _TetheredAuthController()),
          chatThreadProvider.overrideWith(
            () => _ReadyChatController(
              const ChatThreadResponse(
                hasActiveTether: true,
                partnerDisplayName: 'Bob',
                messages: [],
              ),
            ),
          ),
        ],
        child: const MobileApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const Key('bub-floating-nav')), findsNothing);
    expect(find.byKey(const Key('chat-fullscreen-header')), findsOneWidget);
    expect(find.byKey(const Key('chat-composer-field')), findsOneWidget);
  });

  testWidgets('mobile back from chat returns to the home section', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _TetheredAuthController()),
          chatThreadProvider.overrideWith(
            () => _ReadyChatController(
              const ChatThreadResponse(
                hasActiveTether: true,
                partnerDisplayName: 'Bob',
                messages: [],
              ),
            ),
          ),
        ],
        child: const MobileApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('chat-fullscreen-header')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('chat-fullscreen-header')), findsNothing);
    expect(find.byKey(const Key('bub-floating-nav')), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('top nav notification bell shows unread badge', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _TetheredAuthController()),
          notificationSummaryProvider.overrideWith(
            () => _ReadyNotificationSummaryController(
              const NotificationSummary(unreadCount: 3),
            ),
          ),
        ],
        child: const MobileApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('notifications-button')), findsOneWidget);
    expect(find.byKey(const Key('notifications-badge')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('top nav notification badge caps at 99 plus', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _TetheredAuthController()),
          notificationSummaryProvider.overrideWith(
            () => _ReadyNotificationSummaryController(
              const NotificationSummary(unreadCount: 120),
            ),
          ),
        ],
        child: const MobileApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('notifications-badge')), findsOneWidget);
    expect(find.text('99+'), findsOneWidget);
  });

  test('auth controller provisions the user after login', () {
    final source = File('lib/src/auth/auth_controller.dart').readAsStringSync();

    expect(source, contains('.authMe()'));
    expect(source, isNot(contains('.getCurrentUser()')));
  });

  test('auth service restores a saved Google account silently', () {
    final source = File('lib/src/auth/auth_service.dart').readAsStringSync();

    expect(source, contains('attemptLightweightAuthentication'));
    expect(source, contains('validAccessToken() != null'));
  });

  test('auth service revokes Google authorization on logout', () {
    final source = File('lib/src/auth/auth_service.dart').readAsStringSync();

    expect(source, contains('_googleSignIn.disconnect()'));
    expect(source, isNot(contains('_googleSignIn.signOut()')));
  });

  test('auth controller clears authenticated provider caches on logout', () {
    final source = File('lib/src/auth/auth_controller.dart').readAsStringSync();

    expect(source, contains('ref.invalidate(homeDashboardProvider)'));
    expect(source, contains('ref.invalidate(chatThreadProvider)'));
    expect(source, contains('ref.invalidate(restClientProvider)'));
    expect(source, contains('ref.invalidate(dioProvider)'));
  });

  test('auth controller clears home data after tether status changes', () {
    final source = File('lib/src/auth/auth_controller.dart').readAsStringSync();

    expect(source, contains('_invalidateAuthenticatedData()'));
    expect(source, contains('Future<void> applyAcceptedTether'));
    expect(
      source,
      contains('completeTetherOnboarding(tetherStatus: tetherStatus)'),
    );
  });

  test('auth controller hydrates settings from the authenticated user', () {
    final source = File('lib/src/auth/auth_controller.dart').readAsStringSync();

    expect(source, contains('settingsControllerProvider'));
    expect(source, contains('applyUserPreferences(user)'));
  });

  test('all set action awaits tether refresh before returning home', () {
    final source = File(
      'lib/src/features/tether_onboarding/tether_onboarding_screens.dart',
    ).readAsStringSync();

    expect(source, contains('onPressed: () async'));
    expect(source, contains('await ref'));
    expect(source, contains('.refreshTetherStatus(markComplete: true)'));
  });

  test(
    'home controller captures and sends today moment through backend upload',
    () {
      final source = File(
        'lib/src/features/home/home_dashboard_controller.dart',
      ).readAsStringSync();

      expect(source, contains('pickImage'));
      expect(source, contains('ImageSource.camera'));
      expect(source, isNot(contains('cropImage')));
      expect(source, contains('/api/v1/home/today-moment/photo'));
      expect(source, contains('FormData.fromMap'));
      expect(source, isNot(contains('SUPABASE_SECRET_KEY')));
      expect(source, isNot(contains('/storage/v1/object/')));
      expect(source, isNot(contains('putTodayMoment(publicUrl')));
    },
  );

  test('API client uses finite network timeouts', () {
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(_LoggedOutAuthService()),
      ],
    );
    addTearDown(container.dispose);

    final dio = container.read(dioProvider);

    expect(dio.options.connectTimeout, const Duration(seconds: 8));
    expect(dio.options.receiveTimeout, const Duration(seconds: 12));
    expect(dio.options.sendTimeout, const Duration(seconds: 8));
  });

  test('native splash uses purple background behind the white logo', () {
    final source = File('pubspec.yaml').readAsStringSync();

    expect(source, contains("color: '#7C3AED'"));
    expect(source, contains('image: assets/branding/bub-logo.png'));
    expect(
      source,
      isNot(contains('background_image: assets/branding/splash.png')),
    );
  });

  test('Bub theme uses purple as the dominant brand color', () {
    final theme = BubTheme.light;

    expect(theme.scaffoldBackgroundColor, BubColors.white);
    expect(theme.colorScheme.primary, BubColors.purple);
    expect(theme.colorScheme.secondary, BubColors.pink);
    expect(theme.bottomNavigationBarTheme.selectedItemColor, BubColors.purple);
    expect(
      theme.filledButtonTheme.style?.backgroundColor?.resolve({}),
      BubColors.purple,
    );
    expect(BubColors.bubButtonGradient.colors.first, BubColors.purple);
    expect(
      BubColors.bubButtonGradient.colors,
      isNot(contains(BubColors.coral)),
    );
    expect(BubColors.loginButtonGradient.colors.first, BubColors.purple);
    expect(
      BubColors.loginButtonGradient.colors,
      isNot(contains(BubColors.coral)),
    );
  });

  test('settings controller loads default local preferences', () async {
    final container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        settingsRemoteSyncProvider.overrideWithValue(_NoopSettingsRemoteSync()),
      ],
    );
    addTearDown(container.dispose);

    final settings = await container.read(settingsControllerProvider.future);

    expect(settings.themeMode, BubSettingsThemeMode.system);
    expect(settings.language, 'en');
  });

  test(
    'settings controller persists theme and language changes locally',
    () async {
      final store = _MemorySettingsStore();
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          settingsRemoteSyncProvider.overrideWithValue(
            _NoopSettingsRemoteSync(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(settingsControllerProvider.future);
      await container
          .read(settingsControllerProvider.notifier)
          .setThemeMode(BubSettingsThemeMode.dark);
      await container
          .read(settingsControllerProvider.notifier)
          .setLanguage('en');

      expect(store.themeMode, BubSettingsThemeMode.dark);
      expect(store.language, 'en');
      expect(
        container.read(settingsControllerProvider).value?.themeMode,
        BubSettingsThemeMode.dark,
      );
    },
  );

  testWidgets('settings language menu includes English and Filipino', (
    tester,
  ) async {
    final store = _MemorySettingsStore()..language = 'en';
    await tester.pumpWidget(
      _settingsApp(
        SettingsScreen(
          paired: true,
          onLogout: () {},
          onRemoveTether: () async {},
        ),
        store: store,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsWidgets);
    expect(find.text('Filipino'), findsOneWidget);
  });

  testWidgets('selecting Filipino persists fil and updates settings labels', (
    tester,
  ) async {
    final store = _MemorySettingsStore()..language = 'en';
    await tester.pumpWidget(
      _settingsApp(
        SettingsScreen(
          paired: true,
          onLogout: () {},
          onRemoveTether: () async {},
        ),
        store: store,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filipino').last);
    await tester.pumpAndSettle();

    expect(store.language, 'fil');
    expect(find.text('Mga Setting'), findsOneWidget);
    expect(find.text('Wika'), findsWidgets);
    expect(find.text('Nakalimutan ang PIN'), findsOneWidget);
  });

  testWidgets('settings logout confirms before running logout action', (
    tester,
  ) async {
    var logoutCount = 0;
    await tester.pumpWidget(
      _settingsApp(
        SettingsScreen(
          paired: true,
          onLogout: () => logoutCount += 1,
          onRemoveTether: () async {},
        ),
      ),
    );

    await tester.drag(
      find.byKey(const Key('settings-screen')),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-logout-button')));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(logoutCount, 1);
  });

  testWidgets('settings remove tether requires destructive confirmation', (
    tester,
  ) async {
    var removeCount = 0;
    await tester.pumpWidget(
      _settingsApp(
        SettingsScreen(
          paired: true,
          onLogout: () {},
          onRemoveTether: () async => removeCount += 1,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-remove-tether-button')));
    await tester.pumpAndSettle();
    expect(find.text('Remove tether?'), findsOneWidget);
    expect(find.textContaining('permanently deletes'), findsOneWidget);
    expect(find.textContaining('chat conversation'), findsOneWidget);
    expect(find.textContaining('Bub streak'), findsOneWidget);
    expect(find.textContaining('Been tethered'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Remove tether'));
    await tester.pumpAndSettle();

    expect(removeCount, 1);
  });

  testWidgets('settings disables remove tether when untethered', (
    tester,
  ) async {
    var removeCount = 0;
    await tester.pumpWidget(
      _settingsApp(
        SettingsScreen(
          paired: false,
          onLogout: () {},
          onRemoveTether: () async => removeCount += 1,
        ),
      ),
    );

    final action = tester.widget<InkWell>(
      find.byKey(const Key('settings-remove-tether-button')),
    );

    expect(action.onTap, isNull);
    expect(removeCount, 0);
  });

  testWidgets('settings shows safe pin recovery as deferred', (tester) async {
    await tester.pumpWidget(
      _settingsApp(
        SettingsScreen(
          paired: true,
          onLogout: () {},
          onRemoveTether: () async {},
        ),
      ),
    );

    final action = tester.widget<InkWell>(
      find.byKey(const Key('settings-safe-pin-recovery-button')),
    );

    expect(find.text('Forgot Safe PIN'), findsOneWidget);
    expect(
      find.text(
        'PIN recovery will be available after secure email is configured.',
      ),
      findsOneWidget,
    );
    expect(action.onTap, isNull);
  });

  testWidgets('settings renders all legal policy rows', (tester) async {
    await tester.pumpWidget(
      _settingsApp(
        SettingsScreen(
          paired: true,
          onLogout: () {},
          onRemoveTether: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('settings-privacy-legal-section')),
      findsOneWidget,
    );
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Cookies Policy'), findsOneWidget);
  });

  testWidgets('tapping each legal row opens matching policy screen', (
    tester,
  ) async {
    final repository = _FakeLegalPolicyRepository();
    await tester.pumpWidget(
      _settingsApp(
        SettingsScreen(
          paired: true,
          onLogout: () {},
          onRemoveTether: () async {},
        ),
        legalPolicyRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    for (final entry in const [
      ('settings-privacy-policy-button', 'privacy-policy', 'Privacy Policy'),
      ('settings-terms-button', 'terms-of-service', 'Terms of Service'),
      ('settings-cookies-button', 'cookies-policy', 'Cookies Policy'),
    ]) {
      await tester.ensureVisible(find.byKey(Key(entry.$1)));
      await tester.tap(find.byKey(Key(entry.$1)));
      await tester.pumpAndSettle();

      expect(
        find.byKey(Key('legal-policy-screen-${entry.$2}')),
        findsOneWidget,
      );
      expect(find.text(entry.$3), findsWidgets);
      expect(find.text('Version 2026-07-22'), findsOneWidget);
      expect(find.text('Effective 2026-07-22'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('policy fallback shows offline indicator', (tester) async {
    await tester.pumpWidget(
      _settingsApp(
        const LegalPolicyScreenHarness(slug: 'privacy-policy'),
        legalPolicyRepository: _FakeLegalPolicyRepository(stale: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('legal-policy-offline')), findsOneWidget);
    expect(find.text('Offline copy'), findsOneWidget);
  });
}

Widget _settingsApp(
  Widget child, {
  _MemorySettingsStore? store,
  LegalPolicyRepository? legalPolicyRepository,
}) {
  return ProviderScope(
    overrides: [
      settingsStoreProvider.overrideWithValue(store ?? _MemorySettingsStore()),
      settingsRemoteSyncProvider.overrideWithValue(_NoopSettingsRemoteSync()),
      if (legalPolicyRepository != null)
        legalPolicyRepositoryProvider.overrideWithValue(legalPolicyRepository),
    ],
    child: MaterialApp(
      theme: BubTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

class LegalPolicyScreenHarness extends StatelessWidget {
  const LegalPolicyScreenHarness({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return LegalPolicyScreen(slug: slug);
  }
}

class _FakeLegalPolicyRepository implements LegalPolicyRepository {
  _FakeLegalPolicyRepository({this.stale = false});

  final bool stale;

  @override
  Future<LegalPolicy> fetchPolicy(String slug) async {
    return LegalPolicy(
      slug: slug,
      title: switch (slug) {
        'terms-of-service' => 'Terms of Service',
        'cookies-policy' => 'Cookies Policy',
        _ => 'Privacy Policy',
      },
      version: '2026-07-22',
      effectiveDate: '2026-07-22',
      body: 'Policy body for $slug.',
      stale: stale,
    );
  }
}

class _NoopSettingsRemoteSync implements SettingsRemoteSync {
  @override
  Future<void> sync(BubSettings settings) async {}
}

class _MemorySettingsStore implements SettingsStore {
  BubSettingsThemeMode? themeMode;
  String? language;

  @override
  Future<BubSettingsThemeMode?> readThemeMode() async => themeMode;

  @override
  Future<String?> readLanguage() async => language;

  @override
  Future<void> writeThemeMode(BubSettingsThemeMode value) async {
    themeMode = value;
  }

  @override
  Future<void> writeLanguage(String value) async {
    language = value;
  }
}

class _TetheredAuthController extends AuthController {
  @override
  Future<AuthState> build() async {
    return AuthState.authenticated(
      user: const UserResponse(id: 'user-1', displayName: 'Alice'),
      tetherStatus: const TetherStatusResponse(
        hasActiveTether: true,
        partnerUserId: 'user-2',
      ),
      tetherOnboardingComplete: true,
    );
  }
}

class _ReadyChatController extends ChatThreadController {
  _ReadyChatController(this.thread);

  final ChatThreadResponse thread;

  @override
  Future<ChatThreadResponse> build() async => thread;
}

class _ReadyNotificationSummaryController
    extends NotificationSummaryController {
  _ReadyNotificationSummaryController(this.summary);

  final NotificationSummary summary;

  @override
  Future<NotificationSummary> build() async => summary;
}
