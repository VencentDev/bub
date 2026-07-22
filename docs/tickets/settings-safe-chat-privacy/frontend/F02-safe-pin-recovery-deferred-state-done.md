# F02 Safe PIN Recovery Deferred State

## Goal

Remove email-dependent forgotten Safe PIN recovery from the current implementation scope and show a clear deferred state until the app has a verified sending domain.

## Files To Create Or Modify

- Modify `apps/mobile/lib/src/features/settings/settings_screen.dart`
- Modify `apps/mobile/lib/src/features/safe/safe_screen.dart` only if Safe currently exposes forgotten PIN copy.
- Modify `apps/mobile/test/widget_test.dart`

## Requirements

- Do not add Resend, Brevo, SMTP, or any email-provider integration in this ticket set.
- Do not add backend PIN reset request or confirmation endpoints in this ticket set.
- If a `Forgot Safe PIN` row is shown, keep it disabled and label it as unavailable until account email recovery is configured.
- Recommended disabled copy: `PIN recovery will be available after secure email is configured.`
- Do not block normal Safe setup, unlock, upload, or delete flows.
- Untether behavior from B01 must still reset the Safe state by deleting old Safe PIN rows for the removed tether.

## Implementation Notes

- The safest current recovery path is destructive tether removal with clear warnings, because the old Safe belongs to the old tether and will be deleted.
- Keep this as a disabled UI and documentation state only. Adding an insecure local reset flow would weaken the Safe.
- When the team buys and verifies a domain later, create a separate ticket set for email confirmation and Safe PIN reset.

## Tests Or Verification

- Widget test settings either does not render a forgot-PIN action or renders it disabled.
- Widget test disabled recovery copy is visible when the user opens Safe/security settings.
- Widget test existing Safe setup and unlock tests still pass.
- Run `cd apps/mobile && flutter test`.

## Done Criteria

- Current tickets no longer require a sending domain or email provider.
- Users are not offered a broken or insecure forgotten PIN flow.
