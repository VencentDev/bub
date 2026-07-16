import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/generated/models/tether_status_response.dart';
import '../core/dio_provider.dart';
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
    final client = ref.read(restClientProvider).fallback;
    final user = await client.authMe();
    final tetherStatus = await client.tetherMe();
    final skipped = await ref.read(tetherSkipStoreProvider).isSkipped(user.id);
    return AuthState.authenticated(
      user: user,
      tetherStatus: tetherStatus,
      tetherOnboardingSkipped: skipped,
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
    state = const AsyncData(AuthState.loggedOut());
  }

  Future<void> skipTetherOnboarding() async {
    final current = state.asData?.value;
    final user = current?.user;
    final tetherStatus = current?.tetherStatus;
    if (user == null || tetherStatus == null) {
      return;
    }
    await ref.read(tetherSkipStoreProvider).setSkipped(user.id);
    state = AsyncData(
      AuthState.authenticated(
        user: user,
        tetherStatus: tetherStatus,
        tetherOnboardingSkipped: true,
      ),
    );
  }

  Future<void> refreshTetherStatus({bool markSkipped = false}) async {
    final current = state.asData?.value;
    final user = current?.user;
    if (user == null) {
      return;
    }
    state = await AsyncValue.guard(() async {
      final tetherStatus = await ref
          .read(restClientProvider)
          .fallback
          .tetherMe();
      if (markSkipped && !tetherStatus.hasActiveTether) {
        await ref.read(tetherSkipStoreProvider).setSkipped(user.id);
      }
      final skipped =
          markSkipped ||
          await ref.read(tetherSkipStoreProvider).isSkipped(user.id);
      return AuthState.authenticated(
        user: user,
        tetherStatus: tetherStatus,
        tetherOnboardingSkipped: skipped,
      );
    });
  }

  void applyAcceptedTether(TetherStatusResponse tetherStatus) {
    final user = state.asData?.value.user;
    if (user == null) {
      return;
    }
    state = AsyncData(
      AuthState.authenticated(
        user: user,
        tetherStatus: tetherStatus,
        tetherOnboardingSkipped: false,
      ),
    );
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
