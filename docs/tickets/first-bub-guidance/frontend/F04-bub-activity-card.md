# F04 Bub Activity Card

## Goal

Render directional Bub activity on Home: the last time the partner Bubbed the viewer and the last time the viewer Bubbed the partner.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/home/widgets/home_latest_bub_card.dart`
- `apps/mobile/lib/src/features/home/home_dashboard_controller.dart`
- `apps/mobile/lib/src/features/home/home_screen.dart`
- `apps/mobile/test/`

## Requirements

- When there is Bub activity, the card should show both available directions:
  - `Your partner Bubbed you` with relative time from `partnerLastSentAt`
  - `You Bubbed them` with relative time from `viewerLastSentAt`
- If only one direction exists, show only that row.
- If neither direction exists and the user is tethered, keep the first-Bub CTA from `F02`.
- If neither direction exists and the user is untethered, keep the tether-required state.
- Use the generated dashboard fields from the backend ticket; do not infer direction from display copy.
- Relative time formatting should be deterministic in tests.
- The card should avoid text overflow on narrow mobile screens.

## Implementation Notes

- Consider replacing the single `copy`/`occurredAt` rendering path with small row widgets for directional activity.
- Keep the card title concise, such as `Latest Bub`.
- Prefer local relative-time formatting until the app has a shared time-format utility.
- Use stable keys:
  - `home-latest-bub-viewer-sent-row`
  - `home-latest-bub-partner-sent-row`

## Tests Or Verification

- Add widget tests for:
  - both directional rows render when both timestamps are present
  - only viewer-sent row renders when only `viewerLastSentAt` is present
  - only partner-sent row renders when only `partnerLastSentAt` is present
  - relative time output is stable with an injected clock or helper
  - no text overflow errors are thrown in a constrained width test
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Home card shows latest Bub activity by direction.
- First-Bub and tether-required empty states still work.
- Widget tests cover activity and empty states.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
