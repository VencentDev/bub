# D01 Align Safe Product Epics

## Goal

Clarify Safe behavior across product epics before implementation so Epic 6 Photos, Epic 7 Safe, Epic 11 Notifications, and Epic 14 Security do not describe conflicting unlock or notification behavior.

## Files To Create Or Modify

- Modify: `docs/product/epics/epic-06-photos.md`
- Modify: `docs/product/epics/epic-07-safe.md`
- Modify: `docs/product/epics/epic-11-notifications.md`
- Modify: `docs/product/epics/epic-14-security.md` if biometric or password unlock remains deferred.

## Requirements

- Expand Epic 7 acceptance criteria for:
  - PIN setup when no PIN exists
  - PIN unlock for viewing Safe
  - recent-first gallery organization
  - confirmed delete
  - Safe upload notification in chat
- Resolve the current unlock-method mismatch:
  - Epic 6 says Safe photos require password and Safe password method can be PIN, biometric, or password.
  - Epic 7 says Safe requires PIN.
  - This ticket set should define PIN as the implemented method and mark biometric/password methods as deferred unless product decides otherwise.
- Clarify that Safe media is private in chat:
  - chat shows `safe-box.png`
  - chat shows file count
  - chat does not show Safe thumbnails or Safe media URLs
- Clarify whether either partner can delete any Safe item in the shared vault or only the uploader can delete their own uploads.
- Clarify whether videos are included in Safe for this implementation, since the current chat picker supports image/video attachments.
- Keep story numbering stable unless adding explicit new stories is clearer.
- Do not remove unrelated stories from adjacent epics.

## Implementation Notes

- Keep the docs concise and product-facing.
- Prefer concrete acceptance criteria over implementation details.
- Cross-reference Epic 7 from Epic 6 where Photos mentions Safe behavior.
- Cross-reference Epic 11 only for external/push notifications if chat Safe notices remain in Epic 7.

## Tests Or Verification

- Run:

```bash
git diff -- docs/product/epics/epic-06-photos.md docs/product/epics/epic-07-safe.md docs/product/epics/epic-11-notifications.md docs/product/epics/epic-14-security.md
```

- Verify the diff:
  - defines PIN as the implemented Safe unlock method
  - documents deferred unlock methods if any
  - keeps Safe chat notices private
  - does not remove unrelated acceptance criteria

## Done Criteria

- Safe-related epics describe one coherent implementation scope.
- Unlock method, delete permissions, supported media types, and chat notice behavior are explicit.
- Changes are committed with a focused message for this ticket.
