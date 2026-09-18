# F09 Legal Policy Settings Pages

Status: Done

## Goal

Add Terms of Service, Privacy Policy, and Cookies Policy pages under settings.

## Files To Create Or Modify

- Modify `apps/mobile/lib/src/features/settings/settings_screen.dart`
- Create `apps/mobile/lib/src/features/settings/legal_policy_screen.dart`
- Create `apps/mobile/lib/src/features/settings/legal_policy_controller.dart`
- Modify generated API files after backend OpenAPI generation.
- Modify `apps/mobile/test/widget_test.dart`

## Requirements

- Settings includes a Privacy and Legal section.
- The section contains rows for `Terms of Service`, `Privacy Policy`, and `Cookies Policy`.
- Each row opens a readable policy page with title, effective date, version, and body.
- Policy pages should use backend content from `backend/B04-legal-policy-versioning.md` when available.
- If backend content fails and local fallback copy exists, show fallback with a small stale/offline indicator.
- Privacy Policy page should be reachable from the existing settings privacy policy area.
- Cookies Policy should explain app/session cookies and similar local storage in plain language.

## Implementation Notes

- Render markdown policy bodies with an existing markdown package if present. If no markdown package exists, use simple section rendering from plain strings for the first version.
- Keep the policy content general and product-specific. Final legal review remains a business responsibility before public launch.
- Suggested first-page order in settings: Privacy Policy, Terms of Service, Cookies Policy.

## Tests Or Verification

- Widget test settings renders all three legal rows.
- Widget test tapping each row opens the matching policy screen.
- Widget test policy loading failure shows retry or fallback state.
- Run `cd apps/mobile && flutter test test/widget_test.dart`.

## Done Criteria

- Users can read all three policy pages from settings.
- Policy pages expose version and effective date.

## Implementation Summary

- Added a Privacy and Legal settings section with Privacy Policy, Terms of Service, and Cookies Policy rows.
- Added `LegalPolicyScreen` with loading, error/retry, version, effective date, body, and offline-copy indicator states.
- Added `LegalPolicyRepository` backed by direct Dio calls to the B04 backend endpoints.
- Added local fallback policy copy for all three policy slugs when backend content cannot load.
- Added widget tests for settings rows, navigation to each policy page, and fallback/offline display.

## Verification

- `cd apps/mobile && flutter analyze`
- `cd apps/mobile && flutter test test/widget_test.dart`
