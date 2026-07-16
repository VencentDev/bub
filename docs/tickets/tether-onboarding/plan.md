# Tether Onboarding Plan

## Feature Goal

After a new Google account is provisioned, guide the user through tether setup before they enter the main Bub experience. The flow should let them enter a partner's tether code, scan a QR code, generate their own tether invitation, or skip pairing for now.

This plan implements the onboarding portion of Epic 2: Tether Pairing, covering US-004 Receive Tether Code, US-005 Generate Tether Code, and US-006 Skip Pairing from `docs/product/epics/epic-02-tether-pairing.md`.

## Architecture Summary

Mobile should treat tether setup as a post-auth onboarding flow. After `GET /api/v1/auth/me` returns a user without an active tether, the app routes to a white-background stepper-style flow instead of the main Bub home.

The frontend flow has three screens:

- Enter tether: welcome header, purple heart accent, `bear4.png`, tether code entry, QR scanner action, `or` divider, generate tether button, and skip for now button.
- Generate tether: invitation copy, QR code, tether code below the QR, and a bottom `DONE` button.
- All set: confirmation copy, `bear2.png`, and a `Go to Bub` button.

The backend should expose the minimum pairing API needed by mobile: read current tether status, generate one-time tether invitations, accept codes, and skip/defer onboarding locally on the client.

## Frontend Ticket List

- `frontend/F01-onboarding-routing-and-state.md`
- `frontend/F02-enter-tether-screen.md`
- `frontend/F03-generate-tether-screen.md`
- `frontend/F04-all-set-screen.md`

## Backend Ticket List

- `backend/B01-tether-domain-and-contract.md`
- `backend/B02-tether-service-and-controller.md`

## Implementation Order

1. `backend/B01-tether-domain-and-contract.md`
2. `backend/B02-tether-service-and-controller.md`
3. `frontend/F01-onboarding-routing-and-state.md`
4. `frontend/F02-enter-tether-screen.md`
5. `frontend/F03-generate-tether-screen.md`
6. `frontend/F04-all-set-screen.md`

## Acceptance Criteria

- First-time users without an active tether land on the tether onboarding flow after Google sign-in.
- The enter tether screen uses a white background, top text `Welcome to Bub` with a purple heart accent, the prompt `Who are you tethering with?`, and `assets/illustrations/bears/bear4.png` centered in the screen.
- The enter tether screen includes tether code fields, a QR scanner button, an `or` divider, a `Generate new tether` button, and a `Skip for now` action.
- Generating a tether opens a page with bold text `Share your tethered link`, supporting copy `Send this link to your person so they can Bub with you.`, a QR code, the tether code below the QR, and a bottom `DONE` button.
- Completing generation or successful pairing opens an all-set page with bold text `All set`, supporting copy `You're almost there`, `assets/illustrations/bears/bear2.png`, and a `Go to Bub` button.
- Existing users who already have an active tether bypass onboarding and go directly to Bub.
- Users who skip pairing can reach the current untethered home state.
- Tether codes are one-time use, expire, and cannot pair a user to themselves.

## Verification Commands

Run these from `apps/mobile` for frontend work:

```bash
flutter analyze
flutter test
```

Run these from `apps/backend` for backend work:

```bash
./mvnw test
```

Run the relevant narrower test command first while implementing a single ticket, then run the full command set before committing that ticket's work.

## Commit Policy

- Commit automatically after each coherent ticket or file-change batch.
- Stage only files changed for the completed ticket or batch.
- Use a focused commit message that names the implemented ticket, such as `feat: implement B01 matchmaking schema`.
- Do not include unrelated dirty work in the commit.
