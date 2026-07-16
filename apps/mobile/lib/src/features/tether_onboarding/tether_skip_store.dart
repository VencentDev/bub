import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_provider.dart';

class TetherSkipStore {
  TetherSkipStore(this._storage);

  final FlutterSecureStorage _storage;

  String _key(String userId) => 'tether_onboarding_skipped:$userId';

  Future<bool> isSkipped(String userId) async =>
      await _storage.read(key: _key(userId)) == 'true';

  Future<void> setSkipped(String userId) =>
      _storage.write(key: _key(userId), value: 'true');
}

final tetherSkipStoreProvider = Provider<TetherSkipStore>(
  (ref) => TetherSkipStore(ref.watch(secureStorageProvider)),
);
