# F03 Generate Tether Screen

## Goal

Build the screen that displays a generated tether invitation as a QR code and code string so the user can share it with their person.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/tether_onboarding/`
- `apps/mobile/lib/src/core/dio_provider.dart`
- `apps/mobile/pubspec.yaml`
- `apps/mobile/test/`

## Requirements

- Use a white background.
- Display bold text `Share your tethered link` above the QR code.
- Display supporting copy: `Send this link to your person so they can Bub with you.`
- Generate or fetch a tether invitation when the screen opens.
- Display a QR code for the tether invite link or invite payload.
- Display the tether code below the QR code.
- Include a bottom `DONE` button.
- Tapping `DONE` navigates to the all-set screen.
- Show loading and error states for invitation generation.
- Allow retry if invitation generation fails.

## Implementation Notes

- Use a proven Flutter QR rendering package rather than hand-drawing a QR code.
- The QR payload should be compatible with the accept invitation flow from Epic 2. If deep links are not available yet, encode a stable URL or payload shape documented in the backend contract.
- Keep the QR visually centered and sized with responsive constraints.
- Use the backend endpoint from `B02-tether-service-and-controller.md`.

## Tests Or Verification

- Add widget/provider tests for:
  - copy text renders
  - generated code renders below the QR
  - loading, success, and error states
  - `DONE` routes to all-set
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- The generate tether screen displays the invitation QR and code.
- The bottom `DONE` action routes to all-set.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
