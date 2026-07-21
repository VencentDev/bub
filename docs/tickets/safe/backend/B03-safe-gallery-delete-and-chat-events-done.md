# B03 Safe Gallery Delete And Chat Events

## Goal

Add recent-first Safe gallery listing, confirmed deletion support, and a chat-safe event contract for notifying partners when files are added to Safe.

## Files To Create Or Modify

- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/dto/SafeMediaListResponse.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/dto/SafeMediaDeleteResponse.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/dto/SafeChatNoticeResponse.java`
- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/controller/SafeController.java`
- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/service/SafeMediaService.java`
- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/service/SafeMediaServiceImpl.java`
- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/service/SafeMediaStorageService.java`
- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/entity/ChatMessageType.java`
- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/entity/ChatMessage.java`
- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/dto/ChatMessageResponse.java`
- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/service/ChatServiceImpl.java`
- Modify: `apps/backend/src/test/java/com/vencentdev/backend/modules/safe/controller/SafeControllerIntegrationTest.java`
- Modify: `apps/backend/src/test/java/com/vencentdev/backend/modules/chat/controller/ChatControllerIntegrationTest.java`

## Requirements

- Add `GET /api/v1/safe/media` for recent-first gallery listing.
- Require verified Safe PIN for gallery listing.
- Exclude soft-deleted items from the gallery.
- Add `DELETE /api/v1/safe/media/{id}` for deletion.
- Require verified Safe PIN for deletion.
- Enforce ownership through the active tether connection; either partner may delete vault items if product docs allow shared-vault deletion.
- Delete the storage object when deleting the Safe item. If object deletion fails after the database row is soft-deleted, log the storage failure without leaking storage internals to the client.
- Return a deletion response that is easy for the mobile app to reconcile locally.
- Add a chat notice contract for Safe uploads:
  - displays `safe-box.png` in the mobile app
  - does not expose Safe media URLs in chat payloads
  - includes the count of files added to Safe
  - identifies the uploading user
- Prefer a dedicated chat message type such as `SAFE_NOTICE` if the existing chat media model cannot represent Safe notices without exposing thumbnails.

## Implementation Notes

- A Safe upload in B02 may already return uploaded media details. In this ticket, make sure the upload flow also creates or returns enough data for chat to render one notice per upload batch.
- Suggested chat response fields for Safe notices:

```java
UUID id;
String type; // SAFE_NOTICE
Integer safeItemCount;
UUID senderUserId;
Instant createdAt;
```

- Keep Safe media URLs available only from Safe endpoints.
- If chat live events already publish message changes, reuse that path so the partner sees Safe notices without refreshing.
- Use `safe-box.png` only as a mobile asset reference; backend should not hard-code an asset path unless the existing chat API already carries asset identifiers.

## Tests Or Verification

- Add integration coverage for:
  - gallery list requires correct Safe PIN
  - gallery is sorted by `created_at` descending
  - deletion requires correct Safe PIN
  - deleted item disappears from gallery
  - unrelated users cannot list or delete a vault item
  - Safe upload creates or returns a chat notice with file count
  - chat thread response hides Safe media URLs and exposes only Safe notice metadata
- Run:

```bash
./mvnw -Dtest=SafeControllerIntegrationTest test
./mvnw -Dtest=ChatControllerIntegrationTest test
./mvnw spotless:check
```

## Done Criteria

- Safe gallery listing and deletion endpoints exist.
- Gallery is recent-first and excludes deleted items.
- Safe upload notices are represented in chat without exposing private media URLs.
- Integration tests pass.
- Changes are committed with a focused message for this ticket.
