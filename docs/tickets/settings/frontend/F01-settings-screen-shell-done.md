# F01 Settings Screen Shell

## Goal

Replace the settings placeholder in the mobile authenticated shell with a real settings screen.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/home/home_screen.dart`
- `apps/mobile/lib/src/features/settings/settings_screen.dart`
- `apps/mobile/test/widget_test.dart`
- `apps/mobile/test/tether_onboarding_test.dart`

## Requirements

- Selecting the settings tab must render a dedicated settings screen.
- The settings screen must include sections for Appearance, Language, Tether, and Account.
- The screen must be usable for both tethered and untethered users.
- The settings screen must respect the existing Bub visual system, spacing, app bar behavior, bottom navigation inset, and theme colors.
- Move settings-specific layout out of `home_screen.dart` into a feature file instead of expanding the home shell with large settings widgets.

## Implementation Notes

- Pass the current paired state and callbacks from `_BubHomeSectionBody` to `SettingsScreen`.
- Use stable widget keys for major rows and controls, such as `settings-screen`, `settings-theme-row`, and `settings-account-section`.
- Keep the current bottom navigation visible while settings is open.
- Do not implement preference persistence, tether removal, or logout behavior in this ticket beyond wiring disabled or callback-backed controls where needed.

## Tests Or Verification

- Add widget coverage that tapping the settings nav item shows the settings screen.
- Add widget coverage that all required sections are present in tethered and untethered states.
- Run `cd apps/mobile && flutter analyze`.
- Run `cd apps/mobile && flutter test`.

## Done Criteria

- The placeholder settings text is replaced by a real settings screen.
- The shell has clear extension points for preference controls and account actions.
- Mobile analysis and tests pass or blocked verification is documented.
