# Settings Ticket Plan

## Feature Goal

Implement Epic 12 settings so authenticated users can manage dark mode, language, tether removal, and logout from the settings section.

## Architecture Summary

- The mobile app owns the settings experience under the existing authenticated home shell.
- Appearance and language choices should be represented by Riverpod state and persisted locally for immediate app startup behavior.
- Account-scoped preferences should also be persisted on the backend through the current user contract so settings can follow the account across devices.
- Tether removal must be implemented as a backend destructive operation before the mobile settings action calls it.
- Logout should reuse the existing auth controller logout flow and move the app-bar logout affordance into settings.

## Frontend Tickets

- `frontend/F01-settings-screen-shell-done.md`
- `frontend/F02-appearance-and-language-preferences-done.md`
- `frontend/F03-account-actions-done.md`

## Backend Tickets

- `backend/B01-user-settings-preferences-done.md`
- `backend/B02-remove-tether-operation-done.md`

## Implementation Order

1. `backend/B01-user-settings-preferences-done.md`
2. `frontend/F01-settings-screen-shell-done.md`
3. `frontend/F02-appearance-and-language-preferences-done.md`
4. `backend/B02-remove-tether-operation-done.md`
5. `frontend/F03-account-actions-done.md`

## Acceptance Criteria

- User can open a real settings section from the authenticated mobile shell.
- User can enable dark mode and the app applies it without requiring logout.
- User can change the language setting from supported language options.
- User can start tether removal from settings.
- Tether removal follows Epic 2 destructive confirmation rules and clears shared couple data server-side.
- User can logout from settings and return to the logged-out state.

## Verification Commands

- `cd apps/backend && ./mvnw test`
- `cd apps/mobile && flutter analyze`
- `cd apps/mobile && flutter test`
- `cd apps/mobile && dart run swagger_parser`

## Commit Policy

- Commit automatically after each coherent ticket or file-change batch.
- Stage only files changed for the completed ticket or batch.
- Use a focused commit message that names the implemented ticket, such as `feat: implement B01 matchmaking schema`.
- Do not include unrelated dirty work in the commit.
