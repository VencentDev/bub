# F01 Home Dashboard State And Client

## Goal

Connect the authenticated mobile Home section to the backend Home dashboard API with loading, error, and loaded states.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/home/home_screen.dart`
- `apps/mobile/lib/src/features/home/home_dashboard_controller.dart`
- `apps/mobile/lib/src/features/home/home_dashboard_state.dart`
- `apps/mobile/lib/src/api/generated/`
- `apps/mobile/test/`

## Requirements

- Add a Riverpod controller/provider that calls `GET /api/v1/home/dashboard`.
- Represent loading, loaded, and error states without blocking the bottom navbar.
- Show a centered loading indicator while the Home section loads.
- Show a retry action when the dashboard request fails.
- Keep Chat, Bub, Safe, and Settings tab switching functional while Home data loads or errors.
- Keep Bub center button non-routing for this ticket set.

## Implementation Notes

- Follow the existing `authControllerProvider` and generated API client patterns.
- Keep API-specific model parsing in the controller; keep widgets focused on rendering.
- Avoid adding mock production data. Tests may use fake providers.
- This ticket should not build final cards; it only creates state and a simple loaded placeholder.

## Tests Or Verification

- Add widget/provider tests for:
  - Home section shows loading state
  - Home section shows retry on error
  - Home section renders loaded placeholder when dashboard data arrives
  - bottom navbar remains visible during loading and error states
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Home has a real dashboard data provider.
- Loading and error states are covered by tests.
- Existing nav section switching tests still pass.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
