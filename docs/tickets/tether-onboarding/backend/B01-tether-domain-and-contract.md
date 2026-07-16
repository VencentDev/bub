# B01 Tether Domain And Contract

## Goal

Define the backend data model and API contract for tether status, invitation generation, and code acceptance.

## Files To Create Or Modify

- `apps/backend/src/main/java/com/vencentdev/backend/modules/tether/`
- `packages/api-types/openapi.json`
- backend migration files used by this repo
- backend tests under `apps/backend/src/test/`

## Requirements

- Model one active tether per user.
- Model tether invitations with:
  - generated code in the format `BUB-7KQ2-XH19`
  - creator user ID
  - expiration timestamp
  - consumed timestamp
  - optional accepted user ID
- Define response DTOs for:
  - current tether status
  - generated tether invitation
  - accepted tether result
- Define request DTOs for accepting a tether code.
- Ensure the contract supports QR payloads for invite sharing.
- Ensure constraints prevent duplicate active tethers and self-tethering.

## Implementation Notes

- Align rules with `docs/product/epics/epic-02-tether-pairing.md`.
- Prefer database constraints for one-active-tether invariants where practical.
- Keep invitation codes one-time use and expiring.
- Update OpenAPI generation or API type artifacts according to the repo's established workflow.

## Tests Or Verification

- Add repository/domain tests for:
  - one active tether per user
  - unique invitation code
  - expired invitation cannot be accepted
  - consumed invitation cannot be accepted twice
- Run:

```bash
./mvnw test
```

## Done Criteria

- Tether domain schema and DTO contract are implemented.
- API types are updated.
- Backend tests pass.
- Changes are committed with a focused message for this ticket.
