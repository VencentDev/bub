# Home Mood Redesign Plan

## Feature Goal

Redesign the Home mood experience so it feels cute, modern, and lighter-weight. Today's Moment should stay the primary card when a user has a tether, while the user's own mood remains visible as a small editable control inside that card instead of taking over a full separate card.

This ticket set is a frontend refinement on top of the current Home dashboard work. It assumes the dashboard already provides `todayMoment` and the viewer's `mood`.

## Architecture Summary

Mobile keeps the existing Home dashboard data flow and API endpoints. The redesign changes presentation only:

- Add a reusable home card visual treatment for varied gradients by card type and theme.
- Update Today's Moment so the tethered card can include a compact mood pill/button.
- Replace the plain mood `AlertDialog` with a custom glassy dialog that still saves through the existing mood callback.

The first implementation shows the viewer's own mood only. Showing both the viewer's mood and the tether partner's mood requires a later backend contract that exposes partner mood data.

## Frontend Ticket List

- `frontend/F01-home-card-gradient-treatments.md`
- `frontend/F02-todays-moment-with-mood-pill.md`
- `frontend/F03-glass-mood-dialog.md`

## Backend Ticket List

- None for the first pass. Partner mood display should get its own backend ticket if the product decides to expose tether partner mood.

## Implementation Order

1. `frontend/F01-home-card-gradient-treatments.md`
2. `frontend/F02-todays-moment-with-mood-pill.md`
3. `frontend/F03-glass-mood-dialog.md`

## Acceptance Criteria

- Home cards have varied gradients and accents instead of every card sharing the same flat surface.
- Light mode uses soft purple-to-white style for the Today's Moment area.
- Dark mode uses dark purple-to-pink style for the Today's Moment area.
- Other cards use related but distinct treatments so the screen does not become one repeated gradient.
- When a user has a tether, Today's Moment is the primary place where mood appears.
- The standalone Mood card is not shown when mood is already available inside Today's Moment.
- Untethered Today's Moment empty state remains clear and acceptable.
- The mood control is small, tappable, and does not compete with the uploaded moment photo.
- The mood dialog feels glassy and cute while preserving validation, save, and cancel behavior.
- The layout works in both light and dark mode without clipped text or hidden actions.

## Verification Commands

Run these from `apps/mobile`:

```bash
flutter analyze
flutter test
```

Use targeted widget tests while implementing each ticket, then run the full command set before committing the ticket's work.

## Commit Policy

- Commit automatically after each coherent ticket or file-change batch.
- Stage only files changed for the completed ticket or batch.
- Use a focused commit message that names the implemented ticket, such as `feat: implement F01 home card gradient treatments`.
- Do not include unrelated dirty work in the commit.
