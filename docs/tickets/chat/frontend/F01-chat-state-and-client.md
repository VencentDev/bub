# F01 Chat State And Client

## Goal

Connect the authenticated mobile Chat section to the generated backend chat API with loading, loaded, empty, and error states.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/home/home_screen.dart`
- `apps/mobile/lib/src/features/chat/`
- `apps/mobile/lib/src/api/generated/`
- `apps/mobile/test/`

## Requirements

- Add a `features/chat` module for chat controllers, state, and widgets.
- Add a Riverpod controller/provider that loads the authenticated user's chat thread.
- Use generated API models and endpoint methods from the backend chat tickets.
- Represent:
  - loading state
  - loaded tethered thread state
  - untethered state
  - error state with retry
- Wire the existing Chat bottom navigation item to the real Chat section instead of a placeholder.
- Keep Home, Bub, Safe, and Settings tab switching functional while Chat loads or errors.
- Do not build final message bubbles or composer controls in this ticket; render a minimal loaded placeholder with enough data to prove the state path works.

## Implementation Notes

- Follow the existing `homeDashboardProvider` pattern.
- Keep API calls in the controller and rendering in widgets.
- Keep provider overrides simple so widget tests can inject fake chat state.
- If backend generated types are not available yet, implement this ticket after the backend contract ticket and API generation are complete.

## Tests Or Verification

- Add widget/provider tests for:
  - selecting Chat displays loading state while the thread is loading
  - selecting Chat displays retry UI on load error
  - selecting Chat displays a loaded placeholder for a tethered thread
  - bottom navigation remains visible during Chat loading and error states
  - retry triggers provider refresh
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Chat navigation uses a real state-backed section.
- Loading, error, retry, loaded, and untethered state paths exist.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
