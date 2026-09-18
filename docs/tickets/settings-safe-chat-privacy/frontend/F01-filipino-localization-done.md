# F01 Filipino Localization

Status: Done

## Goal

Add Filipino as a supported app language and localize the settings, Safe, chat, notifications, loading, and legal policy entry points touched by this ticket set.

## Files To Create Or Modify

- Modify `apps/mobile/lib/src/features/settings/settings_screen.dart`
- Modify `apps/mobile/lib/src/features/settings/settings_controller.dart`
- Modify `apps/mobile/lib/src/features/settings/settings_store.dart`
- Create or modify localization files under `apps/mobile/lib/src/l10n/` if localization scaffolding does not already exist.
- Modify touched screens in `apps/mobile/lib/src/features/chat/`, `apps/mobile/lib/src/features/safe/`, and `apps/mobile/lib/src/features/home/`.
- Modify `apps/mobile/test/widget_test.dart`
- Modify `apps/mobile/test/chat_screen_test.dart`

## Requirements

- Add language option `fil` with display label `Filipino`.
- Keep existing `en` option with display label `English`.
- Persist the selected language locally and, if existing user settings support backend persistence, sync it to the backend preference contract.
- Use Filipino for user-facing copy on touched screens when `fil` is selected.
- Keep developer keys, route names, analytics names, and API fields in English.
- Do not translate legal policy slugs.

## Implementation Notes

- Prefer Flutter's `gen_l10n` if the app already uses it. If not, introduce a small typed app strings provider before replacing strings broadly.
- Use natural Filipino phrasing instead of word-for-word Tagalog translations. Recommended labels:
  - Settings: `Mga Setting`
  - Language: `Wika`
  - Forgot PIN: `Nakalimutan ang PIN`
  - Set your PIN: `Itakda ang PIN`
  - Unlock Safe: `I-unlock ang Safe`
  - Notifications: `Mga Notification`
  - Terms of Service: `Mga Tuntunin ng Serbisyo`
  - Privacy Policy: `Patakaran sa Privacy`
  - Cookies Policy: `Patakaran sa Cookies`

## Tests Or Verification

- Widget test settings language menu includes English and Filipino.
- Widget test selecting Filipino persists `fil`.
- Widget test at least one settings label and one Safe label render in Filipino after switching.
- Run `cd apps/mobile && flutter analyze`.
- Run `cd apps/mobile && flutter test`.

## Done Criteria

- Filipino can be selected and remains selected after app restart.
- Touched screens no longer hard-code English where app strings are available.

## Implementation Summary

- Added a lightweight typed strings provider under `apps/mobile/lib/src/l10n/`.
- Added language option `fil` with display label `Filipino`, keeping `en` as `English`.
- Settings persists `fil` locally and renders Filipino labels after selection.
- Updated generated mobile user language enums so `fil` can serialize for settings sync.
- Safe setup/unlock entry labels use app strings and render Filipino when selected.

## Verification

- `cd apps/mobile && flutter analyze`
- `cd apps/mobile && flutter test test/widget_test.dart test/safe_screen_test.dart`
