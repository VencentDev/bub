# B02 Chat Media Upload API

## Goal

Expose a multipart backend API for quick image/video chat messages and include attachment data in chat thread responses.

## Files To Create Or Modify

- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/controller/ChatController.java`
- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/service/ChatService.java`
- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/service/ChatServiceImpl.java`
- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/dto/ChatMessageResponse.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/dto/ChatAttachmentResponse.java`
- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/live/ChatLiveEventType.java` if a new event type is needed.
- Modify: `apps/backend/src/test/java/com/vencentdev/backend/modules/chat/controller/ChatControllerIntegrationTest.java`

## Requirements

- Add a multipart endpoint:

```text
POST /api/v1/chat/messages/media
consumes multipart/form-data
operationId uploadChatMediaMessage
```

- Request parts:
  - `files`: one or more media files
  - `replyToMessageId`: optional UUID
- Response:
  - `List<ChatMessageResponse>` because multiple videos should create separate chat messages
- Validation:
  - require active tether
  - require at least one file
  - allow images with content types starting `image/`
  - allow videos with content types starting `video/`
  - reject unsupported content types with a `400`
  - keep a conservative per-file size limit documented in code, such as `25 MB`
- Grouping rules:
  - if every selected file is an image, create one `MEDIA` message containing all image attachments in order
  - if any selected file is a video, create one separate `MEDIA` message per video
  - if a mixed image/video request is submitted, create one grouped image message for the images and one separate message per video
- Reply rules:
  - apply `replyToMessageId` to every message created by the upload
- Response rules:
  - include `attachments` on media messages
  - use snippets `Photo`, `{count} photos`, and `Video` for media replies
  - hide attachments and reactions when `deletedForEveryone` is true
- Publish a live chat event after successful upload so the partner refreshes via WebSocket.

## Implementation Notes

- Keep existing `send(ChatSendMessageRequest)` unchanged for text, emoji, and GIF.
- Add a new service method:

```java
List<ChatMessageResponse> uploadMedia(
    AuthenticatedUser principal,
    List<MultipartFile> files,
    UUID replyToMessageId);
```

- Reuse existing helpers in `ChatServiceImpl`:
  - active connection lookup
  - `replyTarget`
  - response context building
  - live publisher
- Add `attachments` to `ChatMessageResponse` as the last constructor field to minimize generated-client churn.

## Tests Or Verification

- Add integration tests for:
  - uploading one image returns one media message with one image attachment
  - uploading multiple images returns one media message with ordered attachments
  - uploading one video returns one media message with one video attachment
  - uploading two videos returns two separate media messages
  - mixed image/video upload groups images and separates videos
  - unsupported content type returns `400`
  - media reply snippet is `Photo`, `{count} photos`, or `Video`
  - deleted-for-everyone media response hides attachments and reactions
- Run:

```bash
./mvnw -Dtest=ChatControllerIntegrationTest test
./mvnw spotless:check
```

## Done Criteria

- Multipart chat media upload endpoint is documented in OpenAPI.
- Thread responses include media attachment data.
- Upload behavior follows image grouping and video separation rules.
- Existing chat behavior remains green.
- Changes are committed with a focused message for this ticket.
