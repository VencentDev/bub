# B03 Home Dashboard Aggregation

## Goal

Implement the Home dashboard service that combines tether, today moment, latest Bub activity, and Safe summary data into `GET /api/v1/home/dashboard`.

## Files To Create Or Modify

- `apps/backend/src/main/java/com/vencentdev/backend/modules/home/`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/tether/`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/user/`
- backend tests under `apps/backend/src/test/`

## Requirements

- For tethered users, populate partner card data from the active tether connection and user records.
- Use the active tether connection creation timestamp as `tetheredSince`.
- For untethered users, return the `Tether with someone` CTA and omit partner-only data.
- For today's moment, return the active tether's moment for the request user's current local date when present.
- For latest Bub, return:
  - `hasActivity: false`, `copy: "No Bubs yet"`, and `occurredAt: null` if no source data exists yet
  - later-compatible fields so Epic 4 can wire real Bub events without changing mobile
- For Safe summary, return:
  - `enabled: true`
  - `copy: "Keep important details ready when you need them."`
  - `ctaLabel: "Open Safe"`
- Do not include sensitive Safe document names or values.

## Implementation Notes

- Keep aggregation read-only and fast; avoid N+1 user lookups.
- If profile image URL fields do not exist yet, return `null` and let mobile use initials/fallback art.
- Keep latest Bub as a neutral placeholder until the Bub activity domain exists.
- Add mapper/helper methods only if they reduce duplication across tests and controller code.

## Tests Or Verification

- Add service/controller tests for:
  - tethered dashboard includes partner and tethered-since date
  - untethered dashboard includes CTA and omits partner-only fields
  - dashboard includes today's moment when one exists
  - dashboard returns no-Bub placeholder when no Bub activity exists
  - dashboard safe summary never returns document names
- Run:

```bash
./mvnw test
```

## Done Criteria

- Home dashboard endpoint returns complete aggregate data for tethered and untethered users.
- Existing tether onboarding behavior still passes.
- Backend tests pass.
- Changes are committed with a focused message for this ticket.
