# F05 Safe Untethered And New Tether States

## Goal

Fix Safe UI state after untethering and for newly tethered users so the app shows PIN setup instead of an impossible unlock prompt.

## Files To Create Or Modify

- Modify `apps/mobile/lib/src/features/safe/safe_controller.dart`
- Modify `apps/mobile/lib/src/features/safe/safe_screen.dart`
- Modify `apps/mobile/lib/src/features/chat/chat_section.dart`
- Modify `apps/mobile/test/chat_screen_test.dart`
- Modify `apps/mobile/test/tether_onboarding_test.dart`

## Requirements

- Untethered Safe page must not show unlock.
- Untethered Safe page should show the existing tether-required empty state.
- New tether with `pinConfigured: false` shows `Set your PIN`.
- Chat Safe image dialog for a new tether with no PIN configured shows setup form, not unlock form.
- After untether action completes, invalidate Safe status, Safe session, Safe media, chat thread, home dashboard, and tether status providers.
- Old local Safe session PIN must be cleared immediately after untether.
- Safe upload from chat must require active tether and either a configured/unlocked Safe or successful PIN setup.

## Implementation Notes

- Trust backend `SafeStatusResponse.tethered` and `pinConfigured` over local cached state.
- Ensure fake Safe controller tests can return `SafeStatus(tethered: false, pinConfigured: false)`.
- In chat, branch setup vs unlock from current Safe status at the time the user taps Safe mode.

## Tests Or Verification

- Widget test untethered Safe page has no `safe-pin-entry` unlock prompt.
- Widget test new tether no PIN shows setup dialog in chat Safe image flow.
- Widget test configured Safe still shows unlock dialog when session is locked.
- Widget test untether completion clears local Safe session.
- Run `cd apps/mobile && flutter test`.

## Done Criteria

- Users cannot get stuck on Safe unlock after untethering.
- New tethered partners start with a clean PIN setup flow.
