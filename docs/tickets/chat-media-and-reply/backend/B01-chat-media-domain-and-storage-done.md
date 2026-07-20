# B01 Chat Media Domain And Storage

## Goal

Add backend domain support for chat image/video attachments and storage metadata.

## Files To Create Or Modify

- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/entity/ChatMessageType.java`
- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/entity/ChatMessage.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/entity/ChatMessageAttachment.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/entity/ChatAttachmentType.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/repository/ChatMessageAttachmentRepository.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/service/ChatMediaStorageService.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/service/StoredChatMedia.java`
- Create or modify migration under backend migration folder used by this repo.
- Modify: `apps/backend/src/test/java/com/vencentdev/backend/modules/chat/controller/ChatControllerIntegrationTest.java`

## Requirements

- Add a media-capable message type. Prefer `MEDIA` if one chat message can contain multiple attachments.
- Add attachment rows with:
  - `id`
  - `message_id`
  - `type` with values `IMAGE` and `VIDEO`
  - `url`
  - `storage_object_path`
  - `content_type`
  - `size_bytes`
  - `position`
  - `created_at`
- One chat message may have multiple image attachments.
- Video attachments should be saved in separate messages by the upload service in B02.
- Preserve existing text, emoji, GIF, reply, delete, reaction, read, and presence behavior.
- Deleted-for-everyone media messages should keep the message row but hide attachment URLs and reactions in responses.
- Add a storage abstraction instead of calling Supabase directly from `ChatServiceImpl`.

## Implementation Notes

- Model the storage interface after `MomentStorageService` and `StoredMomentPhoto`.
- Suggested interface:

```java
public interface ChatMediaStorageService {
  StoredChatMedia uploadChatMedia(UUID connectionId, UUID senderUserId, MultipartFile file);
}
```

- Suggested storage record:

```java
public record StoredChatMedia(
    String publicUrl,
    String storageObjectPath,
    String contentType,
    long sizeBytes) {}
```

- Use a chat storage path shape that scopes objects by connection and user, for example:

```text
chat/{connectionId}/{senderUserId}/{messageOrUploadId}/{filename}
```

- Keep service-level validation in B02 so this ticket stays focused on domain shape and persistence.

## Tests Or Verification

- Add persistence/integration coverage that creates a media message with two image attachments and verifies:
  - attachment order is preserved
  - attachment rows are associated with the chat message
  - deleted-for-everyone response hides attachment URLs and reactions
- Run:

```bash
./mvnw -Dtest=ChatControllerIntegrationTest test
./mvnw spotless:check
```

## Done Criteria

- Chat media entities, repository, migration, and storage interface exist.
- Existing chat tests still pass.
- New media persistence tests pass.
- Changes are committed with a focused message for this ticket.
