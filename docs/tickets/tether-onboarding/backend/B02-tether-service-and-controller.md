# B02 Tether Service And Controller

## Goal

Implement authenticated API endpoints for checking tether status, generating tether invitations, and accepting tether codes.

## Files To Create Or Modify

- `apps/backend/src/main/java/com/vencentdev/backend/modules/tether/`
- `apps/backend/src/test/`
- `packages/api-types/openapi.json`

## Requirements

- Add authenticated endpoints for:
  - `GET /api/v1/tether/me` to return current tether status
  - `POST /api/v1/tether/invitations` to generate a tether invitation
  - `POST /api/v1/tether/accept` to accept a tether code
- Generate codes in the format `BUB-7KQ2-XH19`.
- Reject self-tether attempts.
- Reject attempts when either user already has an active tether.
- Reject expired or already consumed codes.
- Mark accepted invitations as consumed.
- Return enough data for mobile to decide whether to show onboarding, untethered home, or paired home.
- Keep endpoints protected by the existing Google bearer-token auth flow.

## Implementation Notes

- Use `@CurrentUser AuthenticatedUser` to resolve the authenticated principal.
- Reuse or extend the user service to resolve internal user IDs.
- Keep service methods transactional.
- Return structured error responses consistent with existing backend exception handling.
- Regenerate API types for mobile after endpoints are present.

## Tests Or Verification

- Add controller/service integration tests for:
  - status without tether
  - invitation generation
  - successful code accept
  - self-tether rejection
  - already tethered rejection
  - expired code rejection
  - consumed code rejection
- Run:

```bash
./mvnw test
```

## Done Criteria

- Tether status, generate, and accept endpoints are implemented.
- Mobile-consumable API types are updated.
- Backend tests pass.
- Changes are committed with a focused message for this ticket.
