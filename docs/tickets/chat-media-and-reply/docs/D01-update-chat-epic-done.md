# D01 Update Chat Epic

## Goal

Update `docs/product/epics/epic-05-chat.md` so Epic 5 reflects the current chat product direction before implementation continues.

## Files To Create Or Modify

- Modify: `docs/product/epics/epic-05-chat.md`

## Requirements

- Add media attachment coverage to Epic 5:
  - quick image messages
  - quick video messages
  - multiple image grouping
  - full-screen image viewer with swipe navigation
  - videos displayed as separate chat cards
- Add attachment mode coverage:
  - Safe vs Quick picker appears before file selection
  - Safe selection is a temporary placeholder that inserts a divider-style chat row until Epic 7 Safe is implemented
- Add swipe-to-reply coverage to US-020 Reply.
- Update read receipt acceptance criteria to match the current UI direction:
  - checks-only display
  - receipt appears only under the latest outgoing message when applicable
  - receipt disappears once the partner replies
- Add a product decision note for US-018 Edit Message:
  - either keep edit as required and restore it to the action sheet
  - or mark edit as deferred if the current Messenger-style action sheet intentionally excludes it
- Keep the existing untethered empty state acceptance criteria, correcting spelling if touched.

## Implementation Notes

- Do not remove existing user stories unless the product direction explicitly supersedes them.
- Use new story IDs after US-024, for example:
  - `US-025 Media Attachments`
  - `US-026 Attachment Mode Picker`
  - `US-027 Swipe To Reply`
- Cross-reference Epic 7 Safe for Safe persistence and note that this ticket set only adds a temporary chat placeholder.

## Tests Or Verification

- Run:

```bash
git diff -- docs/product/epics/epic-05-chat.md
```

- Verify the diff includes the new stories and does not remove unrelated Epic 5 content.

## Done Criteria

- Epic 5 includes the requested media, attachment picker, swipe-to-reply, and current receipt behavior.
- Edit-message status is explicitly documented.
- Changes are committed with a focused message for this ticket.
