# F02 Today's Moment With Mood Pill

## Goal

Make Today's Moment the main tethered Home card and show the viewer's mood as a tiny editable pill/button inside that card.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/home/home_screen.dart`
- `apps/mobile/lib/src/features/home/widgets/home_today_moment_card.dart`
- `apps/mobile/lib/src/features/home/widgets/home_mood_card.dart`
- `apps/mobile/test/`

## Requirements

- Pass the dashboard mood data and save callback into `HomeTodayMomentCard`.
- When the user has a tether, show a compact mood pill/button inside the Today's Moment card.
- The mood pill should:
  - Show the current mood when one exists.
  - Show a short add-state label when no mood exists.
  - Open the mood dialog when tapped.
  - Stay visually secondary to the moment photo and title.
- Hide the standalone `HomeMoodCard` when mood is represented inside Today's Moment.
- Preserve the untethered Today's Moment empty state as an acceptable fallback.
- If no tether exists, do not make the empty moment state feel broken or blocked by the mood feature.
- Continue saving mood through the existing `putMood` dashboard controller method.

## Implementation Notes

- The first pass shows only the viewer's own mood because the current dashboard mood summary is viewer-scoped.
- If future product requirements call for both people’s moods, add a backend ticket to expose partner mood in the dashboard response before changing this UI.
- Keep tap targets at least 44 by 44 logical pixels even if the visible pill is small.
- Use concise labels so the pill does not crowd the moment photo row on small screens.

## Tests Or Verification

- Add or update widget tests for:
  - Tethered Home renders Today's Moment with the mood pill.
  - Existing mood text appears in the pill.
  - Empty mood state shows an add-style pill.
  - Tapping the pill opens the mood dialog.
  - Saving mood calls the existing save callback.
  - Standalone Mood card is not duplicated when Today's Moment owns mood display.
  - Untethered empty Today's Moment state still renders.
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Mood is visible and editable from Today's Moment for tethered users.
- The standalone Mood card is no longer duplicated in the tethered Home layout.
- Untethered empty state remains clear.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
