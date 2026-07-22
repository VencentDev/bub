# B04 Legal Policy Versioning

Status: Done

## Goal

Expose current Terms of Service, Privacy Policy, and Cookies Policy versions so settings can show policy content and future acceptance tracking can be added safely.

## Files To Create Or Modify

- Create `apps/backend/src/main/java/com/vencentdev/backend/modules/legal/controller/LegalPolicyController.java`
- Create `apps/backend/src/main/java/com/vencentdev/backend/modules/legal/dto/LegalPolicyResponse.java`
- Create policy markdown resources under `apps/backend/src/main/resources/legal/`
- Test `apps/backend/src/test/java/com/vencentdev/backend/modules/legal/LegalPolicyControllerIntegrationTest.java`

## Requirements

- Add `GET /api/v1/legal/policies` returning all current policy summaries.
- Add `GET /api/v1/legal/policies/{slug}` for `terms-of-service`, `privacy-policy`, and `cookies-policy`.
- Each policy response includes `slug`, `title`, `version`, `effectiveDate`, and markdown `body`.
- Policy content must be general app policy copy, not legal advice or jurisdiction-specific promises the team cannot honor.
- No acceptance gating is required in this ticket.

## Implementation Notes

- Store policy bodies as markdown resources so mobile can render the same content without shipping a new app build for backend-hosted updates.
- Version format should be ISO date based, for example `2026-07-22`.
- If the team wants offline policy viewing, F09 can also ship local fallback markdown with the same version.

## Tests Or Verification

- Integration test all three policies are listed.
- Integration test each policy detail endpoint returns title, version, effective date, and non-empty body.
- Run `cd apps/backend && ./mvnw -Dtest=LegalPolicyControllerIntegrationTest test`.

## Done Criteria

- Settings can load all three policy pages through generated API clients.
- Policy version metadata is available for future acceptance tracking.

## Implementation Summary

- Added `GET /api/v1/legal/policies` to return the current policy set.
- Added `GET /api/v1/legal/policies/{slug}` for `terms-of-service`, `privacy-policy`, and `cookies-policy`.
- Added policy responses with `slug`, `title`, `version`, `effectiveDate`, and markdown `body`.
- Stored current policy markdown under `apps/backend/src/main/resources/legal/`.

## Verification

- `cd apps/backend && ./mvnw spotless:apply`
- `cd apps/backend && ./mvnw -Dtest=LegalPolicyControllerIntegrationTest test`
