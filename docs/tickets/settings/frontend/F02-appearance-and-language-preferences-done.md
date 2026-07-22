# F02 Appearance And Language Preferences

## Goal

Let users change dark mode and language settings from the mobile settings screen.

## Files To Create Or Modify

- `apps/mobile/lib/main.dart`
- `apps/mobile/lib/src/features/settings/settings_screen.dart`
- `apps/mobile/lib/src/features/settings/settings_controller.dart`
- `apps/mobile/lib/src/features/settings/settings_store.dart`
- `apps/mobile/lib/src/api/generated/models/user_response.dart`
- `apps/mobile/lib/src/api/generated/models/user_update_request.dart`
- `apps/mobile/lib/src/api/generated/clients/user_controller_api.dart`
- `apps/mobile/test/widget_test.dart`
- `apps/mobile/test/tether_onboarding_test.dart`

## Requirements

- User can select theme mode values for system, light, and dark.
- Selecting dark mode must apply dark theme immediately.
- User can select a language value from supported options.
- Settings must persist locally so app restart uses the last known choice before network hydration finishes.
- When authenticated, settings must sync to the backend user preferences from B01.
- Failed backend sync must keep the local app usable and surface a non-blocking error state.

## Implementation Notes

- Use Riverpod state for current settings and a store backed by existing secure storage or another local persistence mechanism already used by the mobile app.
- Wire `MaterialApp.themeMode` to the settings provider instead of hard-coding `ThemeMode.system`.
- Keep `BubTheme.light` and `BubTheme.dark` as the theme definitions.
- Run `dart run swagger_parser` after backend preference fields are available and commit generated API client changes with this ticket.
- Language selection can update the stored preference before full localization exists; visible app copy may remain English until localization resources are introduced.

## Tests Or Verification

- Add controller or widget tests for theme selection, language selection, local persistence, and failed sync handling.
- Run `cd apps/mobile && dart run swagger_parser`.
- Run `cd apps/mobile && flutter analyze`.
- Run `cd apps/mobile && flutter test`.

## Done Criteria

- Dark mode can be enabled from settings and applies immediately.
- Language preference can be changed and persisted.
- Generated API models include the backend preference fields.
- Relevant mobile tests pass or blocked verification is documented.
