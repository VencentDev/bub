import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists OIDC tokens in the platform secure store (Keychain / Keystore).
class TokenStore {
  TokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kId = 'id_token';
  static const _kExpiry = 'access_token_expiry';

  Future<void> save({
    String? accessToken,
    String? refreshToken,
    String? idToken,
    DateTime? expiry,
  }) async {
    await Future.wait([
      if (accessToken != null)
        _storage.write(key: _kAccess, value: accessToken),
      if (refreshToken != null)
        _storage.write(key: _kRefresh, value: refreshToken),
      if (idToken != null) _storage.write(key: _kId, value: idToken),
      if (expiry != null)
        _storage.write(key: _kExpiry, value: expiry.toIso8601String()),
    ]);
  }

  Future<String?> get accessToken => _storage.read(key: _kAccess);
  Future<String?> get refreshToken => _storage.read(key: _kRefresh);
  Future<String?> get idToken => _storage.read(key: _kId);

  Future<DateTime?> get expiry async {
    final raw = await _storage.read(key: _kExpiry);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> clear() => _storage.deleteAll();
}
