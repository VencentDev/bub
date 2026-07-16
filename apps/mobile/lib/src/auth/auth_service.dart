import 'package:google_sign_in/google_sign_in.dart';

import '../core/env.dart';
import 'token_store.dart';

/// Drives native Google Sign-In and stores the Google access token that the
/// backend accepts as a bearer credential (ADR-006), resolved server-side via
/// the userinfo API.
class AuthService {
  AuthService(this._googleSignIn, this._store);

  final GoogleSignIn _googleSignIn;
  final TokenStore _store;
  Future<void>? _initializeFuture;

  Future<void> _initialize() => _initializeFuture ??= _googleSignIn.initialize(
    serverClientId: Env.googleClientId,
  );

  Future<bool> get isLoggedIn async => (await _store.refreshToken) != null;

  Future<void> login() async {
    await _initialize();
    final account = await _googleSignIn.authenticate(
      scopeHint: Env.googleScopes,
    );
    final authorization =
        await account.authorizationClient.authorizationForScopes(
          Env.googleScopes,
        ) ??
        await account.authorizationClient.authorizeScopes(Env.googleScopes);
    await _persist(
      authorization.accessToken,
      account.email,
      account.authentication.idToken,
      DateTime.now().add(const Duration(minutes: 50)),
    );
  }

  /// Returns a non-expired access token, refreshing if needed. Null if logged out.
  Future<String?> validAccessToken() async {
    final token = await _store.accessToken;
    final expiry = await _store.expiry;
    final stillValid =
        token != null &&
        expiry != null &&
        expiry.isAfter(DateTime.now().add(const Duration(seconds: 30)));
    return stillValid ? token : refresh();
  }

  Future<String?> refresh() async {
    final refreshToken = await _store.refreshToken;
    if (refreshToken == null) return null;
    await _initialize();
    final authorization = await _googleSignIn.authorizationClient
        .authorizationForScopes(Env.googleScopes);
    if (authorization == null) return null;
    await _persist(
      authorization.accessToken,
      refreshToken,
      await _store.idToken,
      DateTime.now().add(const Duration(minutes: 50)),
    );
    return authorization.accessToken;
  }

  Future<void> logout() async {
    await _initialize();
    await _googleSignIn.signOut();
    await _store.clear();
  }

  Future<void> _persist(
    String? access,
    String? refresh,
    String? id,
    DateTime? expiry,
  ) => _store.save(
    accessToken: access,
    refreshToken: refresh,
    idToken: id,
    expiry: expiry,
  );
}
