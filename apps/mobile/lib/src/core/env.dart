import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime configuration, loaded from the bundled `.env` asset at startup.
/// Dart defines are still supported as a fallback for CI or custom builds.
///
/// Auth mirrors the backend contract (ADR-006): the app obtains a **Google**
/// access token natively and sends it to the backend as a bearer token; the
/// backend resolves the user via the Google userinfo API.
///
/// `API_BASE_URL` defaults to the Android emulator's host alias (`10.0.2.2`).
/// Override per environment by editing `.env` before running the app.
class Env {
  const Env._();

  static Map<String, String>? _runtimeValuesForTests;

  static String _value(
    String key, {
    String defaultValue = '',
    String dartDefineValue = '',
  }) =>
      (_runtimeValuesForTests ??
          (dotenv.isInitialized
              ? dotenv.env
              : const <String, String>{}))[key] ??
      (dartDefineValue.isNotEmpty ? dartDefineValue : defaultValue);

  static String get apiBaseUrl => _value(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
    dartDefineValue: const String.fromEnvironment('API_BASE_URL'),
  );

  /// Web OAuth client ID from Google Cloud Console. On Android, this is passed
  /// as `serverClientId`; the Android package/SHA client must exist in the same
  /// Google Cloud project.
  static String get googleClientId => _value(
    'GOOGLE_CLIENT_ID',
    dartDefineValue: const String.fromEnvironment('GOOGLE_CLIENT_ID'),
  );

  /// Deprecated for Android; kept only for older local env files.
  static String get googleRedirectUrl => _value(
    'GOOGLE_REDIRECT_URL',
    dartDefineValue: const String.fromEnvironment('GOOGLE_REDIRECT_URL'),
  );

  /// `openid email profile` yields a token the backend can resolve via userinfo.
  static const List<String> googleScopes = <String>[
    'openid',
    'email',
    'profile',
  ];

  /// True when the Google client has been configured.
  static bool get isGoogleConfigured => googleClientId.isNotEmpty;

  static void setRuntimeValuesForTests(Map<String, String> values) {
    _runtimeValuesForTests = values;
  }

  static void resetForTests() {
    _runtimeValuesForTests = null;
  }
}
