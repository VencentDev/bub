# F01 Home Card Gradient Treatments

## Goal

Give Home cards a cute modern visual system with varied gradients and soft depth, while preserving readability and existing card content.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/home/widgets/home_today_moment_card.dart`
- `apps/mobile/lib/src/features/home/widgets/home_latest_bub_card.dart`
- `apps/mobile/lib/src/features/home/widgets/home_partner_card.dart`
- `apps/mobile/lib/src/theme/bub_colors.dart`
- `apps/mobile/test/`

## Requirements

- Add theme-aware card gradients for Home cards.
- Today's Moment card:
  - Light mode should read as soft purple to white.
  - Dark mode should read as dark purple to pink.
- Partner and Latest Bub cards should use distinct but related treatments so the screen does not look like repeated copies of the same card.
- Preserve existing card keys used by widget tests.
- Keep borders, shadows, and contrast readable in light and dark mode.
- Avoid making every card heavily saturated; use gradients as soft surfaces, not full-screen decoration.
- Keep card radius, padding, and minimum heights stable so hover/tap states or dynamic text do not shift layout.

## Implementation Notes

- Prefer a small local helper or shared private widget only if it reduces duplication across Home card widgets.
- Use existing `BubColors` tokens where possible, adding specific gradient helpers only when needed.
- Check dark mode text contrast carefully; pink accents should not sit behind long body copy at high saturation.
- Do not change Home dashboard data models in this ticket.

## Tests Or Verification

- Add or update widget tests for:
  - Today's Moment card renders in light mode.
  - Today's Moment card renders in dark mode.
  - Existing keys for Partner, Today's Moment, and Latest Bub cards still resolve.
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Home cards use varied theme-aware gradients.
- Existing Home card behavior is unchanged.
- Light and dark mode render without clipped text or illegible contrast.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
