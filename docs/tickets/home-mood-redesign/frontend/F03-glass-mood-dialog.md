# F03 Glass Mood Dialog

## Goal

Replace the plain mood `AlertDialog` with a cute, modern glass-style dialog that feels custom to Bub while preserving the existing mood form behavior.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/home/widgets/home_mood_card.dart`
- `apps/mobile/lib/src/features/home/widgets/home_today_moment_card.dart`
- `apps/mobile/test/`

## Requirements

- Build a custom mood dialog surface instead of the default-looking `AlertDialog`.
- The dialog should include:
  - A frosted or glassy translucent panel effect.
  - A soft irregular/blob-like backing shape or layered rounded shape.
  - Purple/pink accents that adapt to light and dark mode.
  - A rounded mood text field.
  - Clear cancel and save actions.
- Preserve existing validation:
  - Mood is required.
  - Mood must be 20 characters or fewer.
- Preserve existing test keys where practical, especially `home-mood-dialog-field`.
- Autofocus the input as the current dialog does.
- Return the trimmed mood string to the caller on save.
- Avoid decorative elements that make text hard to read or cause overlap on small screens.

## Implementation Notes

- Consider extracting the dialog into a small reusable function or widget if both `HomeMoodCard` and `HomeTodayMomentCard` need to open it.
- Use `showDialog` with a transparent background and a custom centered widget for the glass effect.
- Flutter blur effects may require `BackdropFilter`; keep the implementation simple enough to remain performant.
- The irregular cute shape can be achieved with layered rounded containers or a lightweight custom clipper. Do not introduce heavy dependencies.
- Keep all visible text concise.

## Tests Or Verification

- Add or update widget tests for:
  - Dialog opens from the mood control.
  - Initial mood populates the field.
  - Empty save shows `Mood is required`.
  - More than 20 characters shows `Use 20 characters or fewer`.
  - Valid save returns the trimmed mood.
  - Dialog renders under dark theme.
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Mood dialog no longer uses the default plain alert styling.
- Validation and save/cancel behavior still work.
- Dialog is readable and polished in light and dark mode.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
