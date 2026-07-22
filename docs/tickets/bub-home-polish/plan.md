# Bub Home Polish Ticket Plan

## Feature Goal

Fix Bub home presentation and streak behavior so the dashboard displays grammatically correct counts, accurate tether duration copy, continuous streaks, and clean Bub sent notifications.

## Architecture Summary

- The backend owns Bub streak calculation because streak counts are returned in the home dashboard response.
- The mobile app owns presentation copy for streak labels, tether duration, and the in-app Bub sent toast.
- Streak continuity should be based on complete local days in the Bub day zone: a streak only resets when both users forgot to send a Bub for a whole day from 12:00 AM through 11:59 PM.
- Mobile copy must handle singular and plural values explicitly instead of hard-coding plural labels.

## Frontend Tickets

- `frontend/F01-home-copy-and-toast-polish.md`

## Backend Tickets

- `backend/B01-continuous-bub-streak.md`

## Implementation Order

1. `backend/B01-continuous-bub-streak.md`
2. `frontend/F01-home-copy-and-toast-polish.md`

## Acceptance Criteria

- A 1-day streak displays as `1 day`, not `1 days`.
- Bub streak count remains continuous during the current day until the full day ends without either partner sending a Bub.
- Streak count resets only when both users forgot to Bub for a whole calendar day from 12:00 AM through 11:59 PM in the configured Bub day zone.
- Tether duration copy displays `Been tethered for {number} days` and no longer includes the word `since` or the tethered date.
- The Bub sent notification text has no underline.

## Verification Commands

- `cd apps/backend && ./mvnw test`
- `cd apps/mobile && flutter analyze`
- `cd apps/mobile && flutter test`

## Commit Policy

- Commit automatically after each coherent ticket or file-change batch.
- Stage only files changed for the completed ticket or batch.
- Use a focused commit message that names the implemented ticket, such as `feat: implement B01 matchmaking schema`.
- Do not include unrelated dirty work in the commit.
