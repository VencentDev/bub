# Safe Plan

## Feature Goal

Implement Safe as Bub's private vault for intimate memories, with PIN-gated access, recent-first browsing, confirmed deletion, and chat notifications when media is added to the vault.

## Architecture Summary

Safe should be a first-class backend module instead of a chat-only placeholder. The backend owns vault membership through the active tether connection, stores Safe media metadata and storage object paths, validates that only tethered partners can add or view vault items, and exposes PIN setup/unlock, upload, list, and delete endpoints under `/api/v1/safe`.

Safe access is separate from account authentication. Users stay signed in through normal auth, but the mobile Safe tab remains locked until the user verifies their Safe PIN for the current app session. Store only a password-hashed PIN on the backend, never the raw PIN. Keep biometric/password methods deferred unless Epic 6 is updated to bring them into this feature batch.

Safe media upload should reuse the existing Supabase storage style used by Moments and chat media, but write to Safe-specific paths scoped by tether connection. Chat should call the Safe upload path when the user chooses Safe from the attachment picker, then render a safe-box notice rather than exposing media thumbnails in the thread.

## Frontend Ticket List

- `frontend/F01-safe-api-client-and-session-lock.md`
- `frontend/F02-safe-unlock-and-pin-flow.md`
- `frontend/F03-safe-gallery-and-delete.md`
- `frontend/F04-chat-safe-upload-notice.md`

## Backend Ticket List

- `backend/B01-safe-pin-and-access-domain.md`
- `backend/B02-safe-media-storage-and-upload.md`
- `backend/B03-safe-gallery-delete-and-chat-events.md`

## Docs Ticket List

- `docs/D01-align-safe-product-epics.md`

## Implementation Order

1. `docs/D01-align-safe-product-epics.md`
2. `backend/B01-safe-pin-and-access-domain.md`
3. `frontend/F01-safe-api-client-and-session-lock.md`
4. `frontend/F02-safe-unlock-and-pin-flow.md`
5. `backend/B02-safe-media-storage-and-upload.md`
6. Regenerate the mobile API client from backend OpenAPI.
7. `frontend/F03-safe-gallery-and-delete.md`
8. `backend/B03-safe-gallery-delete-and-chat-events.md`
9. Regenerate the mobile API client again if B03 changes response contracts.
10. `frontend/F04-chat-safe-upload-notice.md`

## Acceptance Criteria

- Safe tab opens to a locked state until the user enters a valid PIN.
- A user with no Safe PIN can create one before accessing Safe.
- PIN verification is required before listing, uploading, or deleting Safe media.
- Backend stores only a hashed PIN and never returns the PIN or hash in API responses.
- Safe media is scoped to the active tether connection and inaccessible to untethered users or unrelated users.
- Safe gallery lists media sorted newest first.
- Safe delete requires explicit confirmation in the mobile UI.
- Deleted Safe media no longer appears in the gallery.
- Safe upload from chat stores the selected file in Safe instead of quick chat media.
- Chat renders `safe-box.png` for Safe upload notices rather than media thumbnails or a pill placeholder.
- Chat Safe notices indicate how many files were added to Safe.
- Existing chat quick-media, Moments, home, and tether behavior still pass tests.

## Verification Commands

Run these from `apps/backend` for backend tickets:

```bash
./mvnw -Dtest=SafeControllerIntegrationTest test
./mvnw -Dtest=ChatControllerIntegrationTest,HomeControllerIntegrationTest test
./mvnw spotless:check
```

Run these from `apps/mobile` for frontend tickets:

```bash
flutter pub get
flutter test test/safe_screen_test.dart
flutter test test/chat_screen_test.dart
flutter test test/tether_onboarding_test.dart
flutter analyze
```

Run API generation after backend OpenAPI changes:

```bash
dart run swagger_parser
```

## Commit Policy

- Commit automatically after each coherent ticket or file-change batch.
- Stage only files changed for the completed ticket or batch.
- Use a focused commit message that names the implemented ticket, such as `feat: implement B01 safe pin domain`.
- Do not include unrelated dirty work in the commit.
