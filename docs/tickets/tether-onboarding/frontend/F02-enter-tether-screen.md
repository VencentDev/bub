# F02 Enter Tether Screen

## Goal

Build the first tether onboarding screen where a new user can enter a partner's tether code, scan a QR code, generate their own tether, or skip pairing.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/tether_onboarding/`
- `apps/mobile/lib/src/theme/`
- `apps/mobile/pubspec.yaml`
- `apps/mobile/test/`

## Requirements

- Use a white background.
- At the top, display `Welcome to Bub` with a purple heart accent.
- Display the prompt `Who are you tethering with?` below the welcome text.
- Center `assets/illustrations/bears/bear4.png` in the main content area.
- Include tether code entry fields for codes in the format `BUB-7KQ2-XH19`.
- Include a QR scanner button adjacent to or directly below the code entry area.
- Include an `or` divider before the alternative actions.
- Include a primary `Generate new tether` button.
- Include a secondary `Skip for now` action.
- Submitting a complete code calls the accept tether endpoint.
- Tapping QR scanner opens scanner UI. If camera integration is split into a later task, this ticket must still define the scanner route, disabled state, and user-facing message explicitly.
- Tapping `Generate new tether` navigates to the generate tether screen.
- Tapping `Skip for now` routes to the untethered home state from F01.

## Implementation Notes

- Use `bear4.png` from `assets/illustrations/bears/`.
- Keep all text readable on small screens; the code entry, scanner button, and actions must not overlap.
- Prefer stable dimensions for the bear image and code fields so validation messages do not shift the layout abruptly.
- If a scanner package is needed, choose it in this ticket and document any platform permission changes in the commit.

## Tests Or Verification

- Add widget tests for:
  - welcome text and prompt render
  - `bear4.png` is used
  - code entry and scanner action render
  - generate and skip actions route correctly
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- The enter tether screen matches the requested layout.
- Code entry, scanner, generate, and skip actions are wired.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
