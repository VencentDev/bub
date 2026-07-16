# F04 All Set Screen

## Goal

Build the final tether onboarding confirmation screen that sends the user into Bub.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/tether_onboarding/`
- `apps/mobile/test/`

## Requirements

- Use a white background.
- Display bold text `All set`.
- Display supporting copy `You're almost there`.
- Display `assets/illustrations/bears/bear2.png` in the middle of the screen.
- Include a bottom `Go to Bub` button.
- Tapping `Go to Bub` routes to the appropriate Bub home state.
- If the user is already tethered, route to the paired home state.
- If the user generated an invite but has not been paired yet, route to the untethered home state.

## Implementation Notes

- Use the same layout language as the enter and generate tether screens.
- Keep the confirmation screen lightweight; do not add onboarding copy beyond the requested text.
- The button should use existing Bub button styling from the mobile theme.

## Tests Or Verification

- Add widget tests for:
  - `All set` and `You're almost there` render
  - `bear2.png` is used
  - `Go to Bub` routes correctly
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- The all-set screen matches the requested layout.
- `Go to Bub` navigation is implemented.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
