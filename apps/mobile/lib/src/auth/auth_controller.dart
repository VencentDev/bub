import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/generated/models/tether_status_response.dart';
import '../core/dio_provider.dart';
import '../features/chat/chat_controller.dart';
import '../features/home/home_dashboard_controller.dart';
import '../features/settings/settings_controller.dart';
import '../features/tether_onboarding/tether_skip_store.dart';
import 'auth_state.dart';

/// Holds the authenticated app route state after auth and tether status checks.
class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final loggedIn = await ref.read(authServiceProvider).isLoggedIn;
    return loggedIn ? _fetchSession() : const AuthState.loggedOut();
  }

  Future<AuthState> _fetchSession() async {
    final client = ref.read(restClientProvider);
    final user = await client.authController.authMe();
    await ref
        .read(settingsControllerProvider.notifier)
        .applyUserPreferences(user);
    final tetherStatus = await client.tetherController.tetherMe();
    final onboardingComplete = await ref
        .read(tetherSkipStoreProvider)
        .isComplete(user.id ?? '');
    return AuthState.authenticated(
      user: user,
      tetherStatus: tetherStatus,
      tetherOnboardingComplete: onboardingComplete,
    );
  }

  Future<void> login() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).login();
      return _fetchSession();
    });
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    _invalidateAuthenticatedData();
    state = const AsyncData(AuthState.loggedOut());
  }

  Future<void> skipTetherOnboarding() async {
    await completeTetherOnboarding();
  }

  Future<void> completeTetherOnboarding({
    TetherStatusResponse? tetherStatus,
  }) async {
    final current = state.asData?.value;
    final user = current?.user;
    final nextTetherStatus = tetherStatus ?? current?.tetherStatus;
    if (user == null || nextTetherStatus == null) {
      return;
    }
    await ref.read(tetherSkipStoreProvider).setComplete(user.id ?? '');
    _invalidateAuthenticatedData();
    state = AsyncData(
      AuthState.authenticated(
        user: user,
        tetherStatus: nextTetherStatus,
        tetherOnboardingComplete: true,
      ),
    );
  }

  Future<void> refreshTetherStatus({
    bool markComplete = false,
    bool markSkipped = false,
  }) async {
    final current = state.asData?.value;
    final user = current?.user;
    if (user == null) {
      return;
    }
    state = await AsyncValue.guard(() async {
      final tetherStatus = await ref
          .read(restClientProvider)
          .tetherController
          .tetherMe();
      final shouldComplete = markComplete || markSkipped;
      if (shouldComplete && tetherStatus.hasActiveTether != true) {
        await ref.read(tetherSkipStoreProvider).setComplete(user.id ?? '');
      }
      final onboardingComplete =
          shouldComplete ||
          await ref.read(tetherSkipStoreProvider).isComplete(user.id ?? '');
      _invalidateAuthenticatedData();
      return AuthState.authenticated(
        user: user,
        tetherStatus: tetherStatus,
        tetherOnboardingComplete: onboardingComplete,
      );
    });
  }

  Future<void> applyAcceptedTether(TetherStatusResponse tetherStatus) =>
      completeTetherOnboarding(tetherStatus: tetherStatus);

  void _invalidateAuthenticatedData() {
    ref.invalidate(homeDashboardProvider);
    ref.invalidate(chatThreadProvider);
    ref.invalidate(restClientProvider);
    ref.invalidate(dioProvider);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
