# F01 Bub API State And Nav Action

## Goal

Wire the mobile floating Bub nav button to the backend send-Bub endpoint with loading, error, success, and dashboard refresh behavior.

## Files To Create Or Modify

- `apps/mobile/pubspec.yaml`
- `apps/mobile/pubspec.lock`
- `apps/mobile/lib/src/api/generated/`
- `apps/mobile/lib/src/features/home/home_screen.dart`
- `apps/mobile/lib/src/features/home/home_dashboard_controller.dart`
- `apps/mobile/lib/src/features/bub/`
- `apps/mobile/test/`

## Requirements

- Use the generated API client for `POST /api/v1/bubs`.
- Add a small Riverpod controller or notifier for sending a Bub.
- The floating Bub heart button should:
  - be disabled or show an in-progress state while a send is running
  - send a Bub when the authenticated user is tethered
  - show a clear non-blocking error if the backend rejects the send
  - refresh the Home dashboard after success
  - keep the user in the Home shell
- Add immediate mobile feedback on success:
  - light haptic feedback
  - a small visual pulse, toast, or snackbar that does not cover the bottom nav
- Preserve existing behavior for switching to non-Bub nav sections.

## Implementation Notes

- The current floating nav already exposes `Key('bub-nav-heart')`; keep that key stable because the coach-mark ticket depends on it.
- Avoid making the Bub button navigate away from Home. The button is an action.
- If the generated client names the operation differently than expected, use the generated operation name rather than handwritten Dio calls.
- Keep send state isolated from dashboard loading so a send does not blank the Home screen.

## Tests Or Verification

- Add widget/controller tests for:
  - tapping the Bub nav button calls the send endpoint when tethered
  - a successful send refreshes the dashboard
  - while sending, duplicate taps do not create duplicate requests
  - backend failure surfaces an error and leaves the shell usable
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Bub nav button sends a Bub through the backend.
- Success and failure states are visible and do not break nav layout.
- Dashboard refreshes after success.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
