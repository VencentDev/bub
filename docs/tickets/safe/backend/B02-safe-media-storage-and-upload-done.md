# B02 Safe Media Storage And Upload

## Goal

Add Safe media persistence and upload support so photos and videos can be stored privately in the Safe vault after PIN verification.

## Files To Create Or Modify

- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/dto/SafeMediaItemResponse.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/dto/SafeMediaUploadResponse.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/entity/SafeMediaItem.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/entity/SafeMediaType.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/repository/SafeMediaItemRepository.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/service/SafeMediaService.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/service/SafeMediaServiceImpl.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/service/SafeMediaStorageService.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/service/StoredSafeMedia.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/service/SupabaseSafeMediaStorageService.java`
- Modify: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/controller/SafeController.java`
- Create or modify migration under `apps/backend/src/main/resources/db/migration/`.
- Modify: `apps/backend/src/test/java/com/vencentdev/backend/modules/safe/controller/SafeControllerIntegrationTest.java`

## Requirements

- Add a `safe_media_items` table with:
  - `id`
  - `tether_connection_id`
  - `uploaded_by_user_id`
  - `type` with values `IMAGE` and `VIDEO`
  - `url`
  - `storage_object_path`
  - `content_type`
  - `size_bytes`
  - `original_filename`
  - `created_at`
  - `deleted_at`
- Add `POST /api/v1/safe/media` as a multipart endpoint.
- Require a verified Safe PIN for upload.
- Accept multiple files in one request.
- Support image and video content types already allowed by chat media where practical.
- Reject empty uploads, unsupported content types, and oversized files with concise errors.
- Scope uploads to the active tether connection.
- Store files under a Safe-specific object path, for example:

```text
safe/{tetherConnectionId}/{uploadingUserId}/{safeMediaId}/{filename}
```

- Return the uploaded item IDs, media types, URLs, and created timestamps.
- Preserve media URL privacy at the application layer by returning Safe media only from Safe endpoints after PIN verification.

## Implementation Notes

- Model storage abstractions after `MomentStorageService` and `ChatMediaStorageService`.
- Keep the storage service responsible only for storage operations; media validation and ownership checks belong in `SafeMediaService`.
- Use soft delete support from the initial schema even though deletion is implemented in B03.
- If the chat media upload limit constants are reusable, share them through a small package-private helper only if it reduces duplication without widening the ticket unnecessarily.
- Add OpenAPI-friendly request and response DTOs so the generated Flutter client can call the endpoint.

## Tests Or Verification

- Add integration coverage for:
  - upload requires authentication
  - upload requires active tether connection
  - upload requires configured and correct Safe PIN
  - uploading one image succeeds
  - uploading multiple files succeeds and returns the expected count
  - unsupported content type is rejected
  - stored rows include tether connection, uploader, type, URL, storage path, content type, and size
- Run:

```bash
./mvnw -Dtest=SafeControllerIntegrationTest test
./mvnw spotless:check
```

## Done Criteria

- Safe media table, entity, repository, storage service, and upload endpoint exist.
- Uploads are PIN-gated and tether-scoped.
- Response models are ready for mobile API generation.
- Integration tests pass.
- Changes are committed with a focused message for this ticket.
