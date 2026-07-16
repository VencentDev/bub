import 'dart:io';

import 'package:bub/main.dart';
import 'package:bub/src/auth/auth_service.dart';
import 'package:bub/src/auth/token_store.dart';
import 'package:bub/src/core/dio_provider.dart';
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

  test('auth controller provisions the user after login', () {
    final source = File('lib/src/auth/auth_controller.dart').readAsStringSync();

    expect(source, contains('.authMe()'));
    expect(source, isNot(contains('.getCurrentUser()')));
  });

  test('native splash uses purple background behind the white logo', () {
    final source = File('pubspec.yaml').readAsStringSync();

    expect(source, contains("color: '#8A5CF6'"));
    expect(source, contains('image: assets/branding/bub-logo.png'));
    expect(
      source,
      isNot(contains('background_image: assets/branding/splash.png')),
    );
  });
}
