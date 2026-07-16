# F04 Latest Bub And Safe Card

## Goal

Render the latest Bub activity card and the suggested Safe Quick Access card on Home.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/home/widgets/home_latest_bub_card.dart`
- `apps/mobile/lib/src/features/home/widgets/home_safe_quick_access_card.dart`
- `apps/mobile/lib/src/features/home/home_screen.dart`
- `apps/mobile/test/`

## Requirements

- Latest Bub card:
  - Shows copy similar to `Partner Bubbed you` when activity exists.
  - Shows relative time such as `5 mins ago`.
  - Shows `No Bubs yet` or equivalent empty state when no activity exists.
- Safe Quick Access card:
  - Shows generic safe access copy from the dashboard response.
  - Shows an `Open Safe` action.
  - Tapping `Open Safe` switches the bottom nav to the Safe section.
  - Does not show document names, account numbers, or private values.
- Home should render Partner, Today's Moment, Latest Bub, and Safe cards in a vertically scrollable layout above the floating nav.

## Implementation Notes

- Keep relative time formatting local and deterministic in tests by injecting or wrapping the current clock where practical.
- The Safe card should use the existing nav section state rather than creating a separate route.
- Keep cards small enough that the bottom floating nav does not cover final content; add bottom padding to the scroll view.

## Tests Or Verification

- Add widget tests for:
  - latest Bub card shows activity copy and relative time
  - latest Bub empty state renders when no activity exists
  - Safe card shows `Open Safe`
  - tapping `Open Safe` switches to `Safe section`
  - Home scroll view includes bottom padding so the last card is not hidden by the nav
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Latest Bub and Safe cards render from dashboard data.
- Safe card action switches to Safe section.
- Home dashboard layout scrolls cleanly above the floating nav.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
