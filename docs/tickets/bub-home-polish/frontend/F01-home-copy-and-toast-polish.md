# F01 Home Copy And Toast Polish

## Goal

Fix home dashboard copy for singular values, tether duration, and Bub sent notification styling.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/home/widgets/home_latest_bub_card.dart`
- `apps/mobile/lib/src/features/home/widgets/home_partner_card.dart`
- `apps/mobile/lib/src/features/home/home_screen.dart`
- `apps/mobile/test/tether_onboarding_test.dart`
- `apps/mobile/test/widget_test.dart`

## Requirements

- A streak value of `1` must display `1 day`.
- Streak values other than `1` must display `{count} days`.
- Tethered partner card must display `Been tethered for {number} days`.
- Remove the `Tethered since {date}` copy from the partner card.
- The tether duration copy must use `day` for `1` and `days` for all other values.
- The Bub sent notification text must not render with an underline.
- The toast style change must apply to the `Bub sent` notification and should not introduce underlines for error toasts.

## Implementation Notes

- Add a small label helper for day pluralization instead of interpolating `days` directly.
- If the current tether duration helper returns seconds, minutes, months, or years, adjust it or add a dedicated day-count helper so this card consistently uses day count copy.
- Consider whether same-day tether duration should display `0 days` or `1 day`; follow the product copy exactly if product clarifies this before implementation.
- Check inherited text styles in `_BubToast` and set `decoration: TextDecoration.none` if underline is coming from ambient text styling.
- Keep existing widget keys stable where possible.

## Tests Or Verification

- Add widget coverage that `streakDays: 1` renders `1 day`.
- Add widget coverage that `streakDays: 2` renders `2 days`.
- Add widget coverage for tether copy without `since` and with `Been tethered for`.
- Add widget coverage or a focused style assertion that the Bub sent toast text has no underline.
- Run `cd apps/mobile && flutter analyze`.
- Run `cd apps/mobile && flutter test`.

## Done Criteria

- Singular and plural streak labels are correct.
- Tether duration copy matches the requested format.
- Bub sent notification has no underline.
- Mobile analysis and tests pass or blocked verification is documented.
