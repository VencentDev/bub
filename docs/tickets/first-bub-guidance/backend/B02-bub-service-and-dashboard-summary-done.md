# B02 Bub Service And Dashboard Summary

## Goal

Aggregate Bub history into the Home dashboard so mobile can render the correct empty, sent, and received states.

## Files To Create Or Modify

- `apps/backend/src/main/java/com/vencentdev/backend/modules/bub/`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/home/dto/HomeLatestBubResponse.java`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/home/service/HomeServiceImpl.java`
- `packages/api-types/openapi.json`
- `apps/mobile/lib/src/api/generated/`
- backend tests under `apps/backend/src/test/`

## Requirements

- Extend the Home dashboard Bub summary to include directional activity:
  - `hasActivity`
  - `viewerLastSentAt`
  - `partnerLastSentAt`
  - `viewerLastSentCopy`
  - `partnerLastSentCopy`
  - keep or map existing `copy` and `occurredAt` fields if needed for backward compatibility during frontend migration
- For an untethered user:
  - `hasActivity: false`
  - no directional timestamps
  - copy should support the existing tether-required state
- For a tethered user with no Bub events:
  - `hasActivity: false`
  - no directional timestamps
  - copy should be `Send your first Bub`
- For a tethered user with events:
  - `viewerLastSentAt` is the latest Bub where the viewer is the sender
  - `partnerLastSentAt` is the latest Bub where the partner is the sender
  - `viewerLastSentCopy` should support UI copy like `You Bubbed them`
  - `partnerLastSentCopy` should support UI copy like `They Bubbed you`
- Dashboard aggregation must only include events from the active tether connection.
- Regenerate OpenAPI and mobile API types after the dashboard model changes.

## Implementation Notes

- Add repository methods such as `findFirstByTetherConnectionIdAndSenderUserIdOrderByCreatedAtDesc`.
- Consider a small `BubSummaryService` if Home aggregation would otherwise learn too much about Bub query details.
- Keep the response deterministic and let mobile format relative times locally.
- Do not remove existing Home dashboard fields until generated mobile code and widgets are migrated.

## Tests Or Verification

- Add backend tests for:
  - untethered dashboard returns tether-required empty Bub summary
  - tethered dashboard with no events returns `Send your first Bub`
  - dashboard includes latest viewer-sent timestamp
  - dashboard includes latest partner-sent timestamp
  - old events from inactive or unrelated tethers are not included
- Run:

```bash
./mvnw test
```

## Done Criteria

- Home dashboard returns directional Bub summary fields.
- Existing Home dashboard tests are updated without weakening coverage.
- Generated API types include the new fields.
- Backend tests pass.
- Changes are committed with a focused message for this ticket.
