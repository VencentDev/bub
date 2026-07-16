import 'package:app_mobile/src/core/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(Env.resetForTests);

  test('uses runtime environment values before dart defines', () {
    Env.setRuntimeValuesForTests(<String, String>{
      'API_BASE_URL': 'http://localhost:8080',
      'GOOGLE_CLIENT_ID': 'web-client.apps.googleusercontent.com',
    });

    expect(Env.apiBaseUrl, 'http://localhost:8080');
    expect(Env.googleClientId, 'web-client.apps.googleusercontent.com');
    expect(Env.isGoogleConfigured, isTrue);
  });
}
