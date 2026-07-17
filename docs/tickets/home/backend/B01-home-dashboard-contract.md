# B01 Home Dashboard Contract

## Goal

Define the backend API contract and generated mobile types for the Home dashboard aggregate.

## Files To Create Or Modify

- `apps/backend/src/main/java/com/vencentdev/backend/modules/home/`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/tether/dto/`
- `packages/api-types/openapi.json`
- `apps/mobile/lib/src/api/generated/`
- backend tests under `apps/backend/src/test/`

## Requirements

- Add `GET /api/v1/home/dashboard` for authenticated users.
- Return a single `HomeDashboardResponse` with:
  - `tether` card data
  - `todayMoment` card data
  - `latestBub` card data
  - `safe` quick access data
- Define `HomeTetherCardResponse` with:
  - `hasActiveTether`
  - `partnerUserId`
  - `partnerDisplayName`
  - `partnerProfileImageUrl`
  - `viewerProfileImageUrl`
  - `tetheredSince`
  - `ctaLabel`
- Define `HomeTodayMomentResponse` with:
  - `momentId`
  - `photoUrl`
  - `localDate`
  - `viewerHasPostedToday`
  - `partnerReaction`
- Define `HomeLatestBubResponse` with:
  - `hasActivity`
  - `copy`
  - `occurredAt`
- Define `HomeSafeSummaryResponse` with:
  - `enabled`
  - `copy`
  - `ctaLabel`
- Untethered users must receive `hasActiveTether: false`, `ctaLabel: "Tether with someone"`, `todayMoment: null`, and `latestBub.hasActivity: false`.
- Timestamps should serialize as ISO-8601 strings.

## Implementation Notes

- Create DTO records first; service implementation is covered by `B03-home-dashboard-aggregation.md`.
- Keep this endpoint read-only.
- Keep the Safe summary intentionally generic: do not return document names or private metadata on Home.
- Regenerate API types after OpenAPI reflects the new endpoint.

## Tests Or Verification

- Add contract/controller tests for:
  - authenticated tethered dashboard response shape
  - authenticated untethered dashboard response shape
  - unauthenticated request is rejected
- Run:

```bash
./mvnw test
```

## Done Criteria

- `GET /api/v1/home/dashboard` exists in OpenAPI.
- Backend DTOs compile and serialize the required fields.
- Generated mobile API types include the Home dashboard models.
- Backend tests pass.
- Changes are committed with a focused message for this ticket.
