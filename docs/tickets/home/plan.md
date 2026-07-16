# Home Dashboard Plan

## Feature Goal

Build the authenticated Bub home dashboard after tether onboarding. Home should show the couple's tether card, today's shared moment, latest Bub activity, and a suggested Safe Quick Access card.

This plan implements Epic 3: Home, covering US-009 View Partner Card, US-010 Today's Moment, US-011 View Last Bub, and the suggested US-012 Safe Quick Access Card based on the epic summary in `docs/product/epics/epic-03-home.md`.

## Architecture Summary

Backend exposes one aggregate home dashboard endpoint for fast mobile rendering and separate write endpoints for today's moment and reactions. The aggregate should work for both tethered and untethered users so mobile can render either a partner card or a `Tether with someone` CTA.

Mobile replaces the current authenticated placeholder sections with a real Home section backed by Riverpod state. Cards should be independently testable widgets so later chat, Bub, Safe, and settings work can evolve without bloating `home_screen.dart`.

## Suggested Extra Card

Add a Safe Quick Access card. The epic says Home should immediately reflect safe access, but no explicit user story exists yet. The first version should show whether Safe is ready, provide a direct action to open the Safe tab/section, and avoid exposing private document names on the home dashboard.

## Frontend Ticket List

- `frontend/F01-home-dashboard-state-and-client.md`
- `frontend/F02-partner-card.md`
- `frontend/F03-todays-moment-card.md`
- `frontend/F04-latest-bub-and-safe-card.md`

## Backend Ticket List

- `backend/B01-home-dashboard-contract.md`
- `backend/B02-todays-moment-domain-and-api.md`
- `backend/B03-home-dashboard-aggregation.md`

## Implementation Order

1. `backend/B01-home-dashboard-contract.md`
2. `backend/B02-todays-moment-domain-and-api.md`
3. `backend/B03-home-dashboard-aggregation.md`
4. `frontend/F01-home-dashboard-state-and-client.md`
5. `frontend/F02-partner-card.md`
6. `frontend/F03-todays-moment-card.md`
7. `frontend/F04-latest-bub-and-safe-card.md`

## Acceptance Criteria

- Tethered users see a partner card with both profile pictures connected by a red string and a tethered-since date.
- Untethered users see a partner card fallback with `assets/illustrations/bears/bear1.png`, copy to tether with someone, and a button that routes to the tether onboarding entry screen.
- Users can add or replace today's shared moment once per tether per local day.
- The partner can react to today's moment with `❤️`.
- Home shows latest Bub activity copy similar to `Partner Bubbed you` plus a relative time such as `5 mins ago`.
- Home shows a Safe Quick Access card with a clear action into the Safe section/tab and no sensitive document names.
- Home has loading, empty, and error states that do not block the bottom navbar.
- Mobile and backend contract changes are reflected in generated API types.

## Verification Commands

Run these from `apps/backend` for backend tickets:

```bash
./mvnw test
```

Run these from `apps/mobile` for frontend tickets:

```bash
flutter analyze
flutter test
```

Run the relevant narrower test command first while implementing a single ticket, then run the full command set before committing that ticket's work.

## Commit Policy

- Commit automatically after each coherent ticket or file-change batch.
- Stage only files changed for the completed ticket or batch.
- Use a focused commit message that names the implemented ticket, such as `feat: implement B01 home dashboard contract`.
- Do not include unrelated dirty work in the commit.
