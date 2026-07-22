# B01 Continuous Bub Streak

## Goal

Fix Bub streak calculation so the count does not reset to 0 during the second day before the day is complete.

## Files To Create Or Modify

- `apps/backend/src/main/java/com/vencentdev/backend/modules/home/service/HomeServiceImpl.java`
- `apps/backend/src/test/java/com/vencentdev/backend/modules/home/controller/HomeControllerIntegrationTest.java`
- `apps/backend/src/test/java/com/vencentdev/backend/modules/bub/controller/BubControllerIntegrationTest.java`

## Requirements

- A Bub streak day counts when at least one Bub was sent by either tethered user on that calendar day.
- The current day must be treated as still in progress until it has fully elapsed from 12:00 AM through 11:59 PM in `BUB_DAY_ZONE`.
- If yesterday had Bub activity and today has no Bub activity yet, return yesterday's streak count instead of `0`.
- If a full calendar day elapsed with no Bub from either user, reset the streak.
- Preserve the existing home dashboard response field `streakDays`.

## Implementation Notes

- Replace mutual-day logic with activity-day logic if the current code requires both users to send on the same day.
- When calculating the streak, start from today only if today has activity; otherwise start from yesterday because today is incomplete.
- Continue counting backward while each prior date has at least one Bub event.
- Use the existing `clock` and `BUB_DAY_ZONE` so tests can pin boundary times.
- Cover midnight boundary behavior explicitly: before midnight, an inactive current day must not break the streak; after a fully missed day, the streak must be `0`.

## Tests Or Verification

- Add backend tests for:
  - One Bub yesterday and no Bub today still returns `1`.
  - Consecutive activity days return the full count.
  - A fully missed day between activity days resets the count.
  - A single active day returns `1`.
- Run `cd apps/backend && ./mvnw test`.

## Done Criteria

- Streak count follows the 12:00 AM to 11:59 PM whole-day reset rule.
- Streak tests cover current-day inactivity and missed-day reset behavior.
- Backend tests pass or blocked verification is documented.
