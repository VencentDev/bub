# B02 Remove Tether Operation

## Goal

Add the backend operation that removes the authenticated user's active tether and deletes shared couple data required by Epic 2.

## Files To Create Or Modify

- `apps/backend/src/main/java/com/vencentdev/backend/modules/tether/controller/TetherController.java`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/tether/service/TetherService.java`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/tether/service/TetherServiceImpl.java`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/tether/repository/TetherConnectionRepository.java`
- Shared data repositories for moments, Bub history, Safe, and chat records
- `apps/backend/src/test/java/com/vencentdev/backend/modules/tether/controller/TetherControllerIntegrationTest.java`
- `apps/backend/src/test/java/com/vencentdev/backend/modules/tether/repository/TetherRepositoryTest.java`

## Requirements

- Add an authenticated endpoint for removing the current user's active tether.
- Return a successful empty response or updated tether status after removal.
- If the user has no active tether, return a clear client-safe error instead of deleting unrelated data.
- Delete or detach all shared couple data listed in Epic 2: Shared Moments, Bub History, Shared Safe, and Chat History.
- Ensure both former partners no longer report `hasActiveTether` from `GET /api/v1/tether/me`.
- The operation must be transactional.

## Implementation Notes

- Use the existing tether status lookup and active tether repository patterns.
- Prefer explicit repository delete methods scoped by tether connection or participant pair.
- Avoid deleting account-level data such as users, local settings preferences, or non-shared profile data.
- Keep the endpoint shape reflected in OpenAPI so the mobile generated client can call it.

## Tests Or Verification

- Add integration coverage for successful removal, no active tether, and shared data cleanup.
- Run `cd apps/backend && ./mvnw test`.

## Done Criteria

- Tether removal is exposed through the backend API.
- Shared couple data cleanup is verified by tests.
- Former partners are both untethered after the operation.
