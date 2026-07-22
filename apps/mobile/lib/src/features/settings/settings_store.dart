import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../api/generated/models/user_response_theme_mode.dart';
import '../../core/dio_provider.dart';

enum BubSettingsThemeMode {
  system('system'),
  light('light'),
  dark('dark');

  const BubSettingsThemeMode(this.value);

  final String value;

  static BubSettingsThemeMode fromValue(String? value) {
    return values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => BubSettingsThemeMode.system,
    );
  }

  static BubSettingsThemeMode fromUserResponse(UserResponseThemeMode? value) {
    return switch (value) {
      UserResponseThemeMode.light => BubSettingsThemeMode.light,
      UserResponseThemeMode.dark => BubSettingsThemeMode.dark,
      _ => BubSettingsThemeMode.system,
    };
  }
}

class BubSettings {
  const BubSettings({
    this.themeMode = BubSettingsThemeMode.system,
    this.language = 'en',
    this.syncError,
  });

  final BubSettingsThemeMode themeMode;
  final String language;
  final Object? syncError;

  BubSettings copyWith({
    BubSettingsThemeMode? themeMode,
    String? language,
    Object? syncError,
    bool clearSyncError = false,
  }) {
    return BubSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      syncError: clearSyncError ? null : syncError ?? this.syncError,
    );
  }
}

abstract interface class SettingsStore {
  Future<BubSettingsThemeMode?> readThemeMode();

  Future<String?> readLanguage();

  Future<void> writeThemeMode(BubSettingsThemeMode value);

  Future<void> writeLanguage(String value);
}

class SecureSettingsStore implements SettingsStore {
  SecureSettingsStore(this._storage);

  static const _themeModeKey = 'settings_theme_mode';
  static const _languageKey = 'settings_language';

  final FlutterSecureStorage _storage;

  @override
  Future<BubSettingsThemeMode?> readThemeMode() async {
    final value = await _storage.read(key: _themeModeKey);
    return value == null ? null : BubSettingsThemeMode.fromValue(value);
  }

  @override
  Future<String?> readLanguage() => _storage.read(key: _languageKey);

  @override
  Future<void> writeThemeMode(BubSettingsThemeMode value) {
    return _storage.write(key: _themeModeKey, value: value.value);
  }

  @override
  Future<void> writeLanguage(String value) {
    return _storage.write(key: _languageKey, value: value);
  }
}

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => SecureSettingsStore(ref.watch(secureStorageProvider)),
);
