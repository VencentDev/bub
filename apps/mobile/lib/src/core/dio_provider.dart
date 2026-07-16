import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/generated/rest_client.dart';
import '../auth/auth_service.dart';
import '../auth/token_store.dart';
import 'env.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(ref.watch(secureStorageProvider)),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(GoogleSignIn.instance, ref.watch(tokenStoreProvider)),
);

/// Dio configured with the API base URL and an interceptor that attaches the
/// bearer token and transparently refreshes it on a 401.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl));
  dio.interceptors.add(_AuthInterceptor(ref.watch(authServiceProvider)));
  return dio;
});

/// Generated, type-safe API client bound to the authenticated Dio instance.
final restClientProvider = Provider<RestClient>(
  (ref) => RestClient(ref.watch(dioProvider)),
);

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._auth);

  final AuthService _auth;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _auth.validAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final token = await _auth.refresh();
      if (token != null) {
        final request = err.requestOptions
          ..headers['Authorization'] = 'Bearer $token';
        try {
          final response = await Dio().fetch<dynamic>(request);
          return handler.resolve(response);
        } catch (_) {
          // Fall through to propagate the original error.
        }
      }
    }
    handler.next(err);
  }
}
