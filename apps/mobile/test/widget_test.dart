import 'package:app_mobile/main.dart';
import 'package:app_mobile/src/auth/auth_service.dart';
import 'package:app_mobile/src/auth/token_store.dart';
import 'package:app_mobile/src/core/dio_provider.dart';
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
}
