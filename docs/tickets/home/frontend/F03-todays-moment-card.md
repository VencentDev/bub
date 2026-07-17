# F03 Today's Moment Card

## Goal

Render and update today's shared moment card on Home.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/home/widgets/home_today_moment_card.dart`
- `apps/mobile/lib/src/features/home/home_dashboard_controller.dart`
- `apps/mobile/lib/src/api/generated/`
- `apps/mobile/test/`

## Requirements

- If no moment exists today, show an empty state with a clear action to add today's photo.
- If a moment exists, show the shared photo and local date.
- Allow the viewer to submit or replace today's photo by sending `photoUrl` and `localDate` to `PUT /api/v1/home/today-moment`.
- Allow the partner to react with `❤️` by calling `POST /api/v1/home/today-moment/{momentId}/reaction`.
- Refresh the dashboard state after create/replace/reaction succeeds.
- Show an inline error if the write request fails.

## Implementation Notes

- First implementation may use a URL text field or existing picker abstraction if present; binary upload is outside this ticket.
- Use the device local date in `YYYY-MM-DD` format.
- Hide the reaction action for the user who created the moment if the backend rejects self-reactions.
- Keep this widget independent from Partner Card layout.

## Tests Or Verification

- Add widget/controller tests for:
  - empty state renders add-photo action
  - existing moment renders photo URL as an image
  - submitting a photo calls the generated API client with today's local date
  - successful submit refreshes dashboard provider
  - tapping heart reaction calls reaction endpoint
  - failed submit shows inline error
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Today's Moment card supports read, create/replace, and heart reaction flows.
- Dashboard state refreshes after successful writes.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
