# B01 User Settings Preferences

## Goal

Persist account-level settings for dark mode and language on the current user record.

## Files To Create Or Modify

- `apps/backend/src/main/resources/db/migration/V*_user_settings_preferences.sql`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/user/entity/User.java`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/user/dto/UserResponse.java`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/user/dto/UserUpdateRequest.java`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/user/mapper/UserMapper.java`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/user/service/UserServiceImpl.java`
- `apps/backend/src/test/java/com/vencentdev/backend/modules/user/controller/UserControllerIntegrationTest.java`
- `apps/backend/src/test/java/com/vencentdev/backend/modules/user/service/UserServiceTest.java`

## Requirements

- Add nullable or defaulted user preference fields for theme mode and language.
- Supported theme values must include `system`, `light`, and `dark`.
- Supported language values must include at least `en`.
- `GET /api/v1/users/me` must return the current persisted preference values.
- `PATCH /api/v1/users/me` must allow updating preferences without requiring profile fields to be changed.
- Invalid theme or language values must fail validation with a 400 response.
- Existing users must receive defaults through the migration or service mapping.

## Implementation Notes

- Prefer enum types in Java for theme mode and language when they fit existing mapper and DTO patterns.
- Use database defaults that keep existing rows valid after migration.
- Keep response field names stable and mobile-friendly, for example `themeMode` and `language`.
- Update generated OpenAPI output only if the project workflow requires it from backend changes.

## Tests Or Verification

- Add or update backend tests covering read defaults, preference update, partial profile update, and invalid preference values.
- Run `cd apps/backend && ./mvnw test`.

## Done Criteria

- Current user preferences are persisted and returned by the user API.
- Preference validation is covered by tests.
- The backend test suite passes or any blocked verification is documented in the commit notes.
