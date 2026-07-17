# F03 First Bub Coach Mark

## Goal

Add a guided first-Bub tutorial that highlights the floating nav Bub button when the user taps the first-Bub CTA.

## Files To Create Or Modify

- `apps/mobile/pubspec.yaml`
- `apps/mobile/pubspec.lock`
- `apps/mobile/lib/src/features/home/home_screen.dart`
- `apps/mobile/lib/src/features/home/widgets/home_latest_bub_card.dart`
- `apps/mobile/lib/src/features/bub/`
- `apps/mobile/test/`

## Requirements

- Add `tutorial_coach_mark: ^1.3.3` as the Flutter coach-mark dependency.
- Tapping the `Send your first Bub` card button should start a coach mark that targets the floating nav Bub button.
- The tutorial content should explain:
  - the Bub button sends a private Bub to the partner
  - the partner should receive the Bub as a vibration/notification once delivery is fully wired
  - the user can tap the highlighted button to send now
- The highlighted target should use the existing Bub nav button key or a `GlobalKey` attached to the same widget.
- The overlay must be dismissible through the package skip/finish affordance.
- Respect reduced-motion/accessibility as much as the package allows:
  - do not require rapid animation to understand the tutorial
  - content text should be readable in light and dark themes
  - target padding should not hide the nav button

## Implementation Notes

- Pub.dev describes `tutorial_coach_mark` as a package for app guides and coach marks, and version `1.3.3` is current as of July 17, 2026.
- Build the coach-mark setup behind a small helper such as `FirstBubTutorial` so `home_screen.dart` does not become difficult to read.
- Ensure the tutorial is launched after the current frame so the nav button has a layout position.
- This ticket should only launch the tutorial from the explicit first-Bub CTA. Do not auto-show it on page load.

## Tests Or Verification

- Add widget tests for:
  - tapping `home-first-bub-button` attempts to start the tutorial
  - the Bub nav target key is present in the paired Home shell
  - the Home shell remains usable after tutorial completion or dismissal
- If direct overlay assertions are brittle, isolate target creation in a pure/helper function and test the target id/key mapping.
- Run:

```bash
flutter pub get
flutter test
flutter analyze
```

## Done Criteria

- `tutorial_coach_mark` is installed.
- First-Bub CTA highlights the Bub nav button.
- Tutorial copy explains what the Bub button does.
- Tests cover launch wiring and target stability.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
