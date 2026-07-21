# F02 Safe Unlock And Pin Flow

## Goal

Replace the Safe placeholder with a polished PIN setup and unlock flow that gates Safe content until the user verifies their PIN.

## Files To Create Or Modify

- Create: `apps/mobile/lib/src/features/safe/safe_screen.dart`
- Create: `apps/mobile/lib/src/features/safe/widgets/safe_pin_entry.dart`
- Create: `apps/mobile/lib/src/features/safe/widgets/safe_locked_state.dart`
- Modify: `apps/mobile/lib/src/features/tether_onboarding/tether_onboarding_screens.dart`
- Modify: `apps/mobile/test/safe_screen_test.dart`
- Modify: `apps/mobile/test/tether_onboarding_test.dart`

## Requirements

- Tapping the Safe tab should show the Safe screen, not the existing `Safe section` placeholder.
- If the user is untethered, show an empty locked-state view that explains Safe becomes available after tethering.
- If no PIN is configured, show a PIN setup flow.
- PIN setup requires:
  - 4 to 6 digits
  - confirmation entry
  - mismatch error state
  - successful setup transitions to unlocked state
- If a PIN is configured, show the locked-state unlock flow.
- Unlock requires:
  - digit-only input
  - disabled submit until valid length
  - incorrect PIN error state
  - successful unlock transitions to unlocked state
- Do not display entered digits as plain text after entry; use masked PIN cells.
- Keep text, buttons, and inputs sized so they do not overflow on small mobile screens.
- Keep the visual design consistent with the existing Bub mobile style and use `safe-box.png` as the main Safe visual.

## Implementation Notes

- Reuse `apps/mobile/assets/illustrations/bears/safe-box.png`.
- Use familiar mobile controls:
  - masked PIN cells for digits
  - icon button for back/close actions
  - primary button for setup or unlock submit
- Avoid adding biometric UI in this ticket unless backend support exists.
- Use stable keys:
  - `safe-screen`
  - `safe-locked-state`
  - `safe-pin-entry`
  - `safe-pin-submit`
  - `safe-pin-error`
  - `safe-box-image`

## Tests Or Verification

- Add widget tests for:
  - Safe tab opens `safe-screen`
  - configured PIN status shows locked state
  - entering invalid PIN length keeps submit disabled
  - wrong PIN shows `safe-pin-error`
  - correct PIN unlocks
  - no-PIN status shows setup flow
  - mismatched setup confirmation shows error
- Run:

```bash
flutter test test/safe_screen_test.dart
flutter test test/tether_onboarding_test.dart
flutter analyze
```

## Done Criteria

- Safe screen has real PIN setup and unlock flows.
- Locked content remains hidden until unlock succeeds.
- Tests cover locked, setup, error, and unlocked transitions.
- Changes are committed with a focused message for this ticket.
