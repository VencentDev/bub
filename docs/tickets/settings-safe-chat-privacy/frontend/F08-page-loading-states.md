# F08 Page Loading States

## Goal

Add consistent loading, empty, error, and retry states to pages touched by this feature set.

## Files To Create Or Modify

- Modify `apps/mobile/lib/src/features/home/home_screen.dart`
- Modify `apps/mobile/lib/src/features/chat/chat_section.dart`
- Modify `apps/mobile/lib/src/features/safe/safe_screen.dart`
- Modify `apps/mobile/lib/src/features/settings/settings_screen.dart`
- Modify notification files from F03.
- Modify legal policy files from F09.
- Create shared loading/error widgets under `apps/mobile/lib/src/core/` if repeated state UI becomes duplicated.
- Modify relevant widget tests under `apps/mobile/test/`.

## Requirements

- Every async page touched by this ticket set has loading, loaded, empty, error, and retry states where applicable.
- Loading states should keep layout stable and avoid large text jumps.
- Chat may show cached content during refresh instead of a full-screen spinner.
- Settings should show disabled rows or a compact loader while security status is loading.
- Safe should show tether-required, setup-required, unlock-required, empty vault, loading vault, and error states distinctly.
- Notifications should show empty inbox copy when there are no notifications.
- Legal pages should show loading and retry if backend policy content fails.

## Implementation Notes

- Prefer small shared widgets like `BubLoadingState`, `BubErrorState`, and `BubEmptyState` only if two or more screens need the same pattern.
- Do not use decorative full-page marketing layouts for operational loading states.
- Keep mobile text compact so it fits narrow screens.

## Tests Or Verification

- Widget tests cover at least one loading and one error state per touched feature.
- Run `cd apps/mobile && flutter analyze`.
- Run `cd apps/mobile && flutter test`.

## Done Criteria

- Users are never left with a blank page during load or failure on the touched flows.
