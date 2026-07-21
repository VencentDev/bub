# B01 Safe Pin And Access Domain

## Goal

Add backend support for Safe PIN setup, PIN verification, and authorization checks that gate Safe operations by the active tether connection.

## Files To Create Or Modify

- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/controller/SafeController.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/dto/SafePinSetupRequest.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/dto/SafeUnlockRequest.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/dto/SafeUnlockResponse.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/dto/SafeStatusResponse.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/entity/SafeVaultAccess.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/repository/SafeVaultAccessRepository.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/service/SafeAccessService.java`
- Create: `apps/backend/src/main/java/com/vencentdev/backend/modules/safe/service/SafeAccessServiceImpl.java`
- Create or modify migration under `apps/backend/src/main/resources/db/migration/`.
- Create: `apps/backend/src/test/java/com/vencentdev/backend/modules/safe/controller/SafeControllerIntegrationTest.java`

## Requirements

- Add a `safe_vault_access` table with:
  - `id`
  - `tether_connection_id`
  - `user_id`
  - `pin_hash`
  - `created_at`
  - `updated_at`
- Enforce one Safe PIN record per user per tether connection.
- Use the current authenticated user from `@CurrentUser`; do not accept user IDs from clients.
- Resolve the active tether connection using `TetherConnectionRepository`.
- Return a safe status response that tells the mobile app whether the user is tethered and whether a PIN is configured.
- Add `POST /api/v1/safe/pin` for initial PIN setup.
- Add `POST /api/v1/safe/unlock` for PIN verification.
- Validate PIN input:
  - digits only
  - exactly 4 to 6 digits
  - required for setup and unlock
- Store a password-hashed PIN using the existing Spring security password encoder pattern or add a dedicated encoder bean if none exists.
- Never return the raw PIN or `pin_hash` in API responses.
- Return concise `400`, `401`, or `403` errors for invalid PINs, missing tether state, or unauthorized access.

## Implementation Notes

- Keep the unlock response stateless unless a broader session-token design is introduced in a later ticket. It can return fields such as:

```java
public record SafeUnlockResponse(boolean unlocked) {}
```

- Backend endpoints in B02 and B03 should require the PIN in request headers or request bodies until a server-side Safe session token is designed. Prefer a single convention such as:

```text
X-Bub-Safe-Pin: 1234
```

- Centralize PIN verification in `SafeAccessService` so media endpoints do not duplicate PIN checks.
- Treat an untethered user as having no available Safe vault.
- Do not implement biometric or password unlock in this ticket; document those as deferred if docs are touched.

## Tests Or Verification

- Add integration coverage for:
  - Safe status for untethered user
  - Safe status for tethered user with no PIN
  - successful PIN setup
  - duplicate PIN setup rejected or handled through a clearly named change-PIN path
  - successful unlock with correct PIN
  - failed unlock with incorrect PIN
  - malformed PIN rejected
- Run:

```bash
./mvnw -Dtest=SafeControllerIntegrationTest test
./mvnw spotless:check
```

## Done Criteria

- Safe PIN setup, status, and unlock endpoints exist.
- PIN values are validated and stored only as hashes.
- Safe access checks are centralized for later media endpoints.
- Integration tests pass.
- Changes are committed with a focused message for this ticket.
