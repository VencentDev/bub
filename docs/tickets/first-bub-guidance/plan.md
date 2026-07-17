# First Bub Guidance Plan

## Feature Goal

Make the Bub experience work end to end for tethered couples: a tethered user with no Bub activity should be prompted to send their first Bub, the prompt should launch a coach-mark tutorial pointing at the Bub nav button, and the Home Bub card should later show the last time each partner sent a Bub.

This plan implements the first usable slice of Epic 4: Bub Vibration, covering US-013 Send Bub, the Home-facing part of US-015 Bub History, and the first-send guidance needed after tether onboarding from `docs/product/epics/epic-04-bub-vibration.md`.

## Architecture Summary

Backend should introduce a real Bub event domain instead of returning the current hard-coded empty Home summary. Sending a Bub creates an immutable event for the active tether connection, stores sender and receiver, and returns enough data for mobile to update Home immediately. The Home dashboard should aggregate Bub events into a summary that distinguishes:

- untethered users who still need to tether before sending
- tethered users with no Bub activity who should send their first Bub
- tethered users with activity, including the viewer's latest sent Bub and the partner's latest sent Bub

Mobile should keep the first-send experience inside the authenticated Bub shell. The empty tethered Bub card becomes an actionable button labeled `Send your first Bub`. Tapping it launches a coach-mark tutorial using `tutorial_coach_mark` and highlights the existing Bub heart button in the floating nav. Tapping the Bub nav button sends a Bub through the backend, gives immediate haptic/visual feedback, refreshes the dashboard, and updates the card to show both latest directions.

## Frontend Ticket List

- `frontend/F01-bub-api-state-and-nav-action.md`
- `frontend/F02-first-bub-empty-card.md`
- `frontend/F03-first-bub-coach-mark.md`
- `frontend/F04-bub-activity-card.md`

## Backend Ticket List

- `backend/B01-bub-domain-and-contract.md`
- `backend/B02-bub-service-and-dashboard-summary.md`

## Implementation Order

1. `backend/B01-bub-domain-and-contract.md`
2. `backend/B02-bub-service-and-dashboard-summary.md`
3. `frontend/F01-bub-api-state-and-nav-action.md`
4. `frontend/F02-first-bub-empty-card.md`
5. `frontend/F03-first-bub-coach-mark.md`
6. `frontend/F04-bub-activity-card.md`

## Acceptance Criteria

- Untethered users still see a Home Bub card state explaining that they must tether before sending a Bub.
- Tethered users with no Bub activity do not see `Tether to send bub`.
- Tethered users with no Bub activity see `Send your first Bub` as an actionable button on the Bub card.
- Tapping `Send your first Bub` starts a coach-mark tutorial that highlights the Bub heart button in the floating nav and explains that the button sends a private Bub to the partner.
- Tapping the Bub heart button while tethered sends a Bub to the active partner and gives immediate mobile feedback.
- Sending a Bub persists an event with tether connection, sender, receiver, and timestamp.
- The Home dashboard returns the viewer's last sent Bub time and the partner's last sent Bub time.
- After either partner has sent at least one Bub, the Home card displays both directions when present: the last time your partner Bubbed you and the last time you Bubbed them.
- Backend and mobile generated API types are updated for the new Bub send endpoint and dashboard fields.

## Verification Commands

Run these from `apps/backend` for backend tickets:

```bash
./mvnw test
```

Run these from `apps/mobile` for frontend tickets:

```bash
flutter pub get
flutter analyze
flutter test
```

Run the relevant narrower test command first while implementing a single ticket, then run the full command set before committing that ticket's work.

## Commit Policy

- Commit automatically after each coherent ticket or file-change batch.
- Stage only files changed for the completed ticket or batch.
- Use a focused commit message that names the implemented ticket, such as `feat: implement B01 bub domain`.
- Do not include unrelated dirty work in the commit.
