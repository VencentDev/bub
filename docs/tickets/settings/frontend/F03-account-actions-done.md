# F03 Account Actions

## Goal

Expose logout and tether removal actions from the settings screen.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/home/home_screen.dart`
- `apps/mobile/lib/src/features/settings/settings_screen.dart`
- `apps/mobile/lib/src/features/settings/settings_controller.dart`
- `apps/mobile/lib/src/api/generated/clients/tether_controller_api.dart`
- `apps/mobile/lib/src/auth/auth_controller.dart`
- `apps/mobile/test/widget_test.dart`
- `apps/mobile/test/tether_onboarding_test.dart`

## Requirements

- User can logout from the Account section in settings.
- Logout must reuse the existing auth controller logout flow and return the app to logged-out state.
- Remove the app-bar logout button once logout exists in settings.
- Tethered users can start tether removal from the Tether section.
- Untethered users must not see an enabled destructive remove tether action.
- Tether removal must require explicit destructive confirmation before calling the backend.
- After successful removal, authenticated route state must refresh so the user becomes untethered.
- Tether removal failure must show a recoverable error and keep the user tethered in UI state.

## Implementation Notes

- Generate the mobile API client after B02 adds the backend operation.
- Use confirmation copy that names the data being removed: Shared Moments, Bub History, Shared Safe, and Chat History.
- Require a deliberate confirmation action, such as typing a confirmation phrase or using a destructive confirmation dialog with a clearly labeled destructive button.
- Invalidate or refresh providers that depend on tether state, home dashboard data, chat, safe, and moments after successful removal.
- Keep logout confirmation separate from tether removal confirmation.

## Tests Or Verification

- Add widget tests for logout confirmation and callback execution.
- Add widget tests for tether removal visibility in tethered and untethered states.
- Add controller tests for successful and failed tether removal when practical.
- Run `cd apps/mobile && dart run swagger_parser`.
- Run `cd apps/mobile && flutter analyze`.
- Run `cd apps/mobile && flutter test`.

## Done Criteria

- Logout is available from settings and the app-bar logout control is removed.
- Tether removal starts from settings, requires destructive confirmation, and refreshes route state after success.
- Mobile tests and analysis pass or blocked verification is documented.
