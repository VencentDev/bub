import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/generated/models/user_response.dart';
import '../core/dio_provider.dart';

/// Holds the authenticated user. `null` data means logged out.
class AuthController extends AsyncNotifier<UserResponse?> {
  @override
  Future<UserResponse?> build() async {
    final loggedIn = await ref.read(authServiceProvider).isLoggedIn;
    return loggedIn ? _fetchUser() : null;
  }

  Future<UserResponse?> _fetchUser() =>
      ref.read(restClientProvider).fallback.getCurrentUser();

  Future<void> login() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).login();
      return _fetchUser();
    });
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserResponse?>(AuthController.new);
