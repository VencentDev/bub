import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/settings_controller.dart';

final appStringsProvider = Provider<AppStrings>((ref) {
  final language =
      ref.watch(settingsControllerProvider).value?.language ?? 'en';
  return AppStrings.forLanguage(language);
});

abstract class AppStrings {
  const AppStrings();

  factory AppStrings.forLanguage(String language) {
    return switch (language) {
      'fil' => const FilipinoAppStrings(),
      _ => const EnglishAppStrings(),
    };
  }

  String get settingsTitle;
  String get settingsSubtitle;
  String get appearance;
  String get theme;
  String get language;
  String get safe;
  String get forgotSafePin;
  String get forgotSafePinDeferred;
  String get tether;
  String get removeTether;
  String get available;
  String get notTethered;
  String get account;
  String get logout;
  String get endSession;
  String get setUpSafe;
  String get createSafePinSubtitle;
  String get setPin;
  String get unlockSafe;
  String get createSafePin;
  String get safeUnlockSubtitle;
  String get safeCreatePinSubtitle;
  String languageName(String value);
}

class EnglishAppStrings extends AppStrings {
  const EnglishAppStrings();

  @override
  String get settingsTitle => 'Settings';
  @override
  String get settingsSubtitle => 'Personalize Bub and manage your account.';
  @override
  String get appearance => 'Appearance';
  @override
  String get theme => 'Theme';
  @override
  String get language => 'Language';
  @override
  String get safe => 'Safe';
  @override
  String get forgotSafePin => 'Forgot Safe PIN';
  @override
  String get forgotSafePinDeferred =>
      'PIN recovery will be available after secure email is configured.';
  @override
  String get tether => 'Tether';
  @override
  String get removeTether => 'Remove tether';
  @override
  String get available => 'Available';
  @override
  String get notTethered => 'Not tethered';
  @override
  String get account => 'Account';
  @override
  String get logout => 'Logout';
  @override
  String get endSession => 'End session';
  @override
  String get setUpSafe => 'Set up your Safe';
  @override
  String get createSafePinSubtitle =>
      'Create your private PIN before opening shared memories.';
  @override
  String get setPin => 'Set a PIN';
  @override
  String get unlockSafe => 'Unlock Safe';
  @override
  String get createSafePin => 'Create Safe PIN';
  @override
  String get safeUnlockSubtitle =>
      'Enter your Safe PIN to view private memories.';
  @override
  String get safeCreatePinSubtitle =>
      'Choose a 4 to 6 digit PIN for this shared vault.';

  @override
  String languageName(String value) {
    return switch (value) {
      'fil' => 'Filipino',
      'en' => 'English',
      _ => value,
    };
  }
}

class FilipinoAppStrings extends AppStrings {
  const FilipinoAppStrings();

  @override
  String get settingsTitle => 'Mga Setting';
  @override
  String get settingsSubtitle =>
      'I-personalize ang Bub at pamahalaan ang account mo.';
  @override
  String get appearance => 'Itsura';
  @override
  String get theme => 'Tema';
  @override
  String get language => 'Wika';
  @override
  String get safe => 'Safe';
  @override
  String get forgotSafePin => 'Nakalimutan ang PIN';
  @override
  String get forgotSafePinDeferred =>
      'Magiging available ang PIN recovery kapag naka-configure na ang secure email.';
  @override
  String get tether => 'Tether';
  @override
  String get removeTether => 'Alisin ang tether';
  @override
  String get available => 'Available';
  @override
  String get notTethered => 'Hindi naka-tether';
  @override
  String get account => 'Account';
  @override
  String get logout => 'Mag-log out';
  @override
  String get endSession => 'Tapusin ang session';
  @override
  String get setUpSafe => 'I-set up ang Safe';
  @override
  String get createSafePinSubtitle =>
      'Gumawa ng pribadong PIN bago buksan ang shared memories.';
  @override
  String get setPin => 'Itakda ang PIN';
  @override
  String get unlockSafe => 'I-unlock ang Safe';
  @override
  String get createSafePin => 'Gumawa ng Safe PIN';
  @override
  String get safeUnlockSubtitle =>
      'Ilagay ang Safe PIN para makita ang private memories.';
  @override
  String get safeCreatePinSubtitle =>
      'Pumili ng 4 hanggang 6 na digit na PIN para sa shared vault na ito.';

  @override
  String languageName(String value) {
    return switch (value) {
      'fil' => 'Filipino',
      'en' => 'English',
      _ => value,
    };
  }
}
