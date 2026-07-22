# B01 Tether Destruction Cleanup

## Goal

Make untethering permanently delete all shared couple data, Safe media, and Safe PIN state so a future tether starts with a clean Safe setup.

## Files To Create Or Modify

- Modify `apps/backend/src/main/java/com/vencentdev/backend/modules/tether/service/TetherServiceImpl.java`
- Modify `apps/backend/src/main/java/com/vencentdev/backend/modules/tether/repository/TetherConnectionRepository.java`
- Modify chat repositories under `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/repository/`
- Modify Safe repositories under `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/repository/`
- Modify `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/service/SafeMediaStorageService.java`
- Modify `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/service/SupabaseSafeMediaStorageService.java`
- Modify `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/service/ChatMediaStorageService.java`
- Modify `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/service/SupabaseChatMediaStorageService.java`
- Modify home and Bub repositories used by tether-scoped data.
- Modify `apps/backend/src/test/java/com/vencentdev/backend/modules/tether/controller/TetherControllerIntegrationTest.java`
- Modify `apps/backend/src/test/java/com/vencentdev/backend/modules/safe/controller/SafeControllerIntegrationTest.java`
- Modify `apps/backend/src/test/java/com/vencentdev/backend/modules/chat/controller/ChatControllerIntegrationTest.java`

## Requirements

- Untethering must delete chat messages, reactions, reads, deletions, typing/presence state, and chat attachments for the old tether.
- Untethering must delete chat image/video objects from object storage before or during database cleanup.
- Untethering must delete Safe media rows, Safe vault access/PIN rows, and Safe object storage files for the old tether.
- Untethering must delete shared moments, moment photos, moods tied to the tether, Bub event history, and streak state for the old tether.
- Untethering must delete notification records tied to the old tether once B02 exists.
- Cleanup must run in a transaction for database rows.
- Object storage deletion should be best-effort with retry/logging, but database rows must not leave users stuck with stale Safe access.
- After removal, `GET /api/v1/safe/status` for both users returns `tethered: false` and `pinConfigured: false`.
- If either user later creates a new tether, Safe status returns `tethered: true` and `pinConfigured: false` until each user sets a new PIN.

## Implementation Notes

- Prefer service-level cleanup methods such as `safeMediaService.deleteAllForTether(connectionId)` and `chatService.deleteAllForTether(connectionId)` instead of putting cross-module delete details directly in `TetherServiceImpl`.
- Delete child rows before parent rows when database constraints require it.
- If the `TetherConnection` row must be retained for audit, mark it inactive only after all dependent rows are removed and ensure no Safe/chat query includes inactive tethers. If no audit requirement exists, deleting the connection is acceptable after dependent cleanup.
- Add repository delete methods using `@Modifying` queries where bulk deletion is needed.

## Tests Or Verification

- Integration test removing tether deletes old chat messages and attachments from database.
- Integration test removing tether deletes old Safe media and Safe PIN access rows.
- Integration test removing tether resets Safe status for both users.
- Integration test new tether starts with no PIN configured and cannot unlock with old PIN.
- Integration test home dashboard no longer shows old "Been tethered" duration or streak after untether.
- Run `cd apps/backend && ./mvnw -Dtest=TetherControllerIntegrationTest,SafeControllerIntegrationTest,ChatControllerIntegrationTest test`.

## Done Criteria

- No old tether data can be reached through chat, Safe, home, Bub, notification, or generated API responses after untether.
- The stuck unlock bug is fixed because no untethered user can retain a configured Safe PIN state.
