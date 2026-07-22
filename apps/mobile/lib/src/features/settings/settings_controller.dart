import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/generated/models/user_response.dart';
import '../../api/generated/models/user_update_request.dart';
import '../../api/generated/models/user_update_request_language.dart';
import '../../api/generated/models/user_update_request_theme_mode.dart';
import '../../core/dio_provider.dart';
import 'settings_store.dart';

abstract interface class SettingsRemoteSync {
  Future<void> sync(BubSettings settings);
}

class ApiSettingsRemoteSync implements SettingsRemoteSync {
  ApiSettingsRemoteSync(this._ref);

  final Ref _ref;

  @override
  Future<void> sync(BubSettings settings) async {
    await _ref
        .read(restClientProvider)
        .userController
        .updateCurrentUser(
          body: UserUpdateRequest(
            themeMode: settings.themeMode.toUserUpdateThemeMode(),
            language: UserUpdateRequestLanguage.fromJson(settings.language),
          ),
        );
  }
}

final settingsRemoteSyncProvider = Provider<SettingsRemoteSync>(
  (ref) => ApiSettingsRemoteSync(ref),
);

class SettingsController extends AsyncNotifier<BubSettings> {
  @override
  Future<BubSettings> build() async {
    final store = ref.read(settingsStoreProvider);
    return BubSettings(
      themeMode: await store.readThemeMode() ?? BubSettingsThemeMode.system,
      language: await store.readLanguage() ?? 'en',
    );
  }

  Future<void> setThemeMode(BubSettingsThemeMode themeMode) async {
    final previous = await future;
    final next = previous.copyWith(themeMode: themeMode, clearSyncError: true);
    state = AsyncData(next);
    await ref.read(settingsStoreProvider).writeThemeMode(themeMode);
    await _sync(next);
  }

  Future<void> setLanguage(String language) async {
    final previous = await future;
    final next = previous.copyWith(language: language, clearSyncError: true);
    state = AsyncData(next);
    await ref.read(settingsStoreProvider).writeLanguage(language);
    await _sync(next);
  }

  Future<void> applyUserPreferences(UserResponse user) async {
    final themeMode = BubSettingsThemeMode.fromUserResponse(user.themeMode);
    final language = user.language?.json ?? 'en';
    final next = BubSettings(themeMode: themeMode, language: language);
    state = AsyncData(next);
    await ref.read(settingsStoreProvider).writeThemeMode(themeMode);
    await ref.read(settingsStoreProvider).writeLanguage(language);
  }

  Future<void> _sync(BubSettings settings) async {
    try {
      await ref.read(settingsRemoteSyncProvider).sync(settings);
    } catch (error) {
      state = AsyncData(settings.copyWith(syncError: error));
    }
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, BubSettings>(
      SettingsController.new,
    );

extension BubSettingsThemeModeApi on BubSettingsThemeMode {
  UserUpdateRequestThemeMode toUserUpdateThemeMode() {
    return switch (this) {
      BubSettingsThemeMode.system => UserUpdateRequestThemeMode.system,
      BubSettingsThemeMode.light => UserUpdateRequestThemeMode.light,
      BubSettingsThemeMode.dark => UserUpdateRequestThemeMode.dark,
    };
  }
}
