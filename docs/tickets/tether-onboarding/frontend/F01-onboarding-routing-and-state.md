# F01 Onboarding Routing And State

## Goal

Route newly provisioned mobile users without an active tether into the tether onboarding flow, while allowing existing tethered users and users who skipped pairing to reach the main Bub home.

## Files To Create Or Modify

- `apps/mobile/lib/src/auth/auth_controller.dart`
- `apps/mobile/lib/src/features/home/home_screen.dart`
- `apps/mobile/lib/src/features/tether_onboarding/`
- `apps/mobile/lib/src/core/dio_provider.dart`
- `apps/mobile/test/`

## Requirements

- Add a mobile state model that distinguishes:
  - authenticated with active tether
  - authenticated without active tether and onboarding not skipped
  - authenticated without active tether and onboarding skipped
  - logged out
- After Google login and `authMe`, fetch the user's current tether status.
- Route unauthenticated users to the sign-in page.
- Route authenticated users without tether and not skipped to the tether onboarding entry screen.
- Route authenticated users with an active tether to the main Bub home.
- Route authenticated users who choose `Skip for now` to the existing untethered home state.
- Store skip state locally so it survives app restarts for the current signed-in user.

## Implementation Notes

- Keep this ticket focused on flow state and routing. Use minimal route stubs only where needed to prove navigation; the final screen UI is covered by later frontend tickets.
- Use Riverpod providers consistent with the current `authControllerProvider` pattern.
- Prefer a small enum or sealed state object over boolean combinations.
- The backend contract should come from `B01-tether-domain-and-contract.md`.

## Tests Or Verification

- Add widget/provider tests for:
  - first-time untethered user routes to tether onboarding
  - tethered user routes to Bub home
  - skipped user routes to untethered Bub home
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Routing state is implemented without changing the final visual design.
- Tests cover each route branch.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
