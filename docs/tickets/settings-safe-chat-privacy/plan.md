# Settings, Safe, Chat, Notifications, And Privacy Ticket Plan

## Feature Goal

Add Filipino language support, top-nav notifications, safer untether behavior, Safe state fixes, recent chat and image caching, loading states, legal policy pages, and a clear deferred state for forgotten Safe PIN recovery until secure email is configured.

## Architecture Summary

- The backend owns destructive tether cleanup, unread notification state, chat pagination contracts, and legal policy versioning.
- The mobile app owns the settings flows, Filipino localization, Safe setup/unlock presentation, deferred Safe PIN recovery copy, top navigation notification entry point, recent local caches, image cache usage, page loading states, and legal policy screens.
- Safe must be scoped to the active tether. When a tether is removed, shared chat, Safe media, Safe PIN access, moments, Bub history, streak state, and related notifications must be permanently removed for that tether before both users return to an untethered state.

## Deferred Email Scope

- Do not implement Resend, Brevo, SMTP, or any email-provider integration in this ticket set.
- Do not implement forgotten Safe PIN reset endpoints in this ticket set.
- Forgotten Safe PIN recovery should appear only as a disabled/deferred settings state until the app has a verified sending domain.
- The current Safe recovery path is tether removal with a clear permanent-deletion warning, because untethering deletes the old tether's Safe media and PIN state.

## Frontend Tickets

- `frontend/F01-filipino-localization.md`
- `frontend/F02-safe-pin-recovery-deferred-state-done.md`
- `frontend/F03-top-nav-notifications.md`
- `frontend/F04-chat-presence-last-seen.md`
- `frontend/F05-safe-untethered-and-new-tether-states-done.md`
- `frontend/F06-untether-warning-copy-done.md`
- `frontend/F07-chat-and-image-caching.md`
- `frontend/F08-page-loading-states.md`
- `frontend/F09-legal-policy-settings-pages.md`

## Backend Tickets

- `backend/B01-tether-destruction-cleanup-done.md`
- `backend/B02-notification-center-contract.md`
- `backend/B03-chat-pagination-and-cache-contract.md`
- `backend/B04-legal-policy-versioning.md`

## Implementation Order

1. `backend/B01-tether-destruction-cleanup-done.md`
2. `frontend/F05-safe-untethered-and-new-tether-states-done.md`
3. `frontend/F02-safe-pin-recovery-deferred-state-done.md`
4. `frontend/F06-untether-warning-copy-done.md`
5. `backend/B02-notification-center-contract.md`
6. `frontend/F03-top-nav-notifications.md`
7. `backend/B03-chat-pagination-and-cache-contract.md`
8. `frontend/F07-chat-and-image-caching.md`
9. `frontend/F04-chat-presence-last-seen.md`
10. `frontend/F08-page-loading-states.md`
11. `frontend/F01-filipino-localization.md`
12. `backend/B04-legal-policy-versioning.md`
13. `frontend/F09-legal-policy-settings-pages.md`

## Acceptance Criteria

- Forgotten Safe PIN recovery is not implemented in this scope and no email provider/domain is required.
- Settings either hides forgotten Safe PIN recovery or shows it disabled with copy that secure email must be configured first.
- Safe status for an untethered user returns `tethered: false` and `pinConfigured: false`.
- After untethering, Safe media, Safe PIN rows, chat messages, chat images, moments, Bub history, streak state, and notification records tied to the old tether are permanently deleted from the database and object storage.
- The untether confirmation dialog warns that chat, images, Safe, moments, "Been tethered" duration, Bub streak, and other couple history will be permanently gone.
- A newly tethered user sees "Set your PIN" in the Safe page and in the chat Safe image dialog until they configure a new PIN.
- Filipino is selectable from settings and app-owned user-facing copy has Filipino translations for the touched screens.
- The top nav includes a notification icon with an unread badge and a notifications panel/list.
- Chat hides "last seen" once the partner has been offline for more than 1 full day.
- Chat loads recent messages quickly, supports loading older messages by scrolling/back-reading to a date, and does not refetch the full thread on every entry.
- Images use local caching so media does not reload from the network every login when cache entries are still valid.
- Pages touched by these tickets have explicit loading, empty, error, and retry states.
- Settings includes Terms of Service, Privacy Policy, and Cookies Policy pages and exposes current policy versions.

## Verification Commands

- `cd apps/backend && ./mvnw test`
- `cd apps/mobile && flutter analyze`
- `cd apps/mobile && flutter test`
- `cd apps/mobile && dart run swagger_parser`

## Commit Policy

- Commit automatically after each coherent ticket or file-change batch.
- Stage only files changed for the completed ticket or batch.
- Use a focused commit message that names the implemented ticket, such as `feat: implement B01 tether cleanup`.
- Do not include unrelated dirty work in the commit.
