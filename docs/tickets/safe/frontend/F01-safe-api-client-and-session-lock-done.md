# F01 Safe Api Client And Session Lock

## Goal

Add mobile Safe API client wiring and local unlocked-state management so Safe screens can distinguish locked, unlocked, untethered, and missing-PIN states.

## Files To Create Or Modify

- Modify: `apps/mobile/lib/src/api/generated/**` after backend OpenAPI generation.
- Create: `apps/mobile/lib/src/features/safe/safe_controller.dart`
- Create: `apps/mobile/lib/src/features/safe/safe_session.dart`
- Create: `apps/mobile/test/safe_screen_test.dart`
- Modify: `apps/mobile/lib/src/features/tether_onboarding/tether_onboarding_screens.dart`
- Modify: `apps/mobile/test/tether_onboarding_test.dart`

## Requirements

- Regenerate the mobile API client after B01 is implemented.
- Add a Safe controller that wraps generated API calls for:
  - status
  - PIN setup
  - unlock
  - media upload
  - gallery listing
  - deletion
- Add a local Safe session model that stores whether Safe is unlocked for the current app session.
- Do not persist the raw PIN in shared preferences, secure storage, logs, provider state that outlives the session, or analytics.
- Clear local unlocked state on logout, app restart, tether removal, and user change.
- Represent these UI states:
  - untethered
  - PIN not configured
  - locked
  - unlocked
  - loading
  - error
- Keep the existing bottom navigation Safe item and lock icon behavior stable until F02 replaces the placeholder screen.

## Implementation Notes

- Keep controller methods small and typed around generated models.
- If no Safe generated API exists yet, scaffold the controller against interfaces or method names from B01 and finish generation after backend endpoints are merged.
- Use existing app state patterns in `chat_controller.dart` and `home_dashboard_controller.dart` rather than adding a new state management library.
- Prefer test fixture responses over network calls in widget tests.

## Tests Or Verification

- Add tests for:
  - Safe tab starts locked when status says PIN is configured
  - Safe tab prompts for PIN setup when status says no PIN is configured
  - Safe tab remains unavailable when untethered
  - unlocked state clears when the user changes or logs out
- Run:

```bash
flutter test test/safe_screen_test.dart
flutter test test/tether_onboarding_test.dart
flutter analyze
```

## Done Criteria

- Safe controller and local session state exist.
- Raw PIN is not persisted.
- Existing navigation tests pass with Safe state handling.
- Changes are committed with a focused message for this ticket.
