# B02 Today's Moment Domain And API

## Goal

Implement storage and authenticated write APIs for one shared daily photo moment per tether, including partner heart reactions.

## Files To Create Or Modify

- `apps/backend/src/main/java/com/vencentdev/backend/modules/home/`
- backend migration files used by this repo
- `packages/api-types/openapi.json`
- `apps/mobile/lib/src/api/generated/`
- backend tests under `apps/backend/src/test/`

## Requirements

- Add a `home_daily_moments` table/entity with:
  - `id`
  - `tether_connection_id`
  - `created_by_user_id`
  - `local_date`
  - `photo_url`
  - `partner_reaction`
  - `created_at`
  - `updated_at`
- Enforce one moment per active tether per `local_date`.
- Add `PUT /api/v1/home/today-moment` with request fields:
  - `photoUrl`
  - `localDate`
- Add `POST /api/v1/home/today-moment/{momentId}/reaction` with request field:
  - `reaction`, initially only `❤️`
- Only users in the active tether can create, replace, or react to a moment.
- A user cannot react to their own moment.
- The first version stores `photoUrl`; binary upload/storage can be handled by a later media ticket.

## Implementation Notes

- Keep service methods transactional.
- Validate `localDate` as a date string, not a timestamp.
- Reuse the existing active tether lookup from the tether module where practical.
- Return the updated `HomeTodayMomentResponse` from both write endpoints.
- Use structured errors consistent with existing backend exception handling.

## Tests Or Verification

- Add repository/service/controller tests for:
  - creates today's moment for an active tether
  - replaces the same day's moment instead of inserting a duplicate
  - rejects untethered users
  - rejects users outside the tether
  - rejects self-reaction
  - accepts partner `❤️` reaction
- Run:

```bash
./mvnw test
```

## Done Criteria

- Daily moments persist with one row per tether per day.
- Moment create/replace and reaction endpoints are implemented.
- OpenAPI and generated mobile API types are updated.
- Backend tests pass.
- Changes are committed with a focused message for this ticket.
