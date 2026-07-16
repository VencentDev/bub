# Direct Google and GitHub OAuth Setup

This guide configures direct Google and GitHub login through Auth.js in the Next.js frontend. The Spring backend accepts the provider access token as a bearer token and resolves the current user through the provider userinfo APIs.

## Local URLs

Use these while developing locally:

- Frontend: `http://localhost:3000`
- Backend: `http://localhost:8080`
- Google callback: `http://localhost:3000/api/auth/callback/google`
- GitHub callback: `http://localhost:3000/api/auth/callback/github`

No custom domain is required for local development.

## Frontend Environment

Copy `apps/frontend/.env.example` to `apps/frontend/.env.local` and fill in:

```env
AUTH_SECRET=replace-me
AUTH_URL=http://localhost:3000
AUTH_GOOGLE_ID=
AUTH_GOOGLE_SECRET=
AUTH_GITHUB_ID=
AUTH_GITHUB_SECRET=
NEXT_PUBLIC_API_BASE=http://localhost:8080
NEXT_PUBLIC_API_BASE_URL=http://localhost:8080
```

Generate `AUTH_SECRET` with:

```bash
openssl rand -base64 32
```

## Google Keys

1. Open Google Cloud Console: `https://console.cloud.google.com/`
2. Create or select a project.
3. Go to `APIs & Services` > `OAuth consent screen`.
4. Choose the appropriate user type, then complete the required app information.
5. Go to `APIs & Services` > `Credentials`.
6. Click `Create Credentials` > `OAuth client ID`.
7. Choose `Web application`.
8. Add this Authorized JavaScript origin:

```text
http://localhost:3000
```

9. Add this Authorized redirect URI:

```text
http://localhost:3000/api/auth/callback/google
```

10. Copy the generated client ID and client secret into:

```env
AUTH_GOOGLE_ID=
AUTH_GOOGLE_SECRET=
```

## GitHub Keys

1. Open GitHub Developer Settings: `https://github.com/settings/developers`
2. Go to `OAuth Apps`.
3. Click `New OAuth App`.
4. Set `Application name` to your app name.
5. Set `Homepage URL`:

```text
http://localhost:3000
```

6. Set `Authorization callback URL`:

```text
http://localhost:3000/api/auth/callback/github
```

7. Register the app.
8. Copy the client ID and generate a client secret.
9. Add them to:

```env
AUTH_GITHUB_ID=
AUTH_GITHUB_SECRET=
```

## Backend Behavior

The backend expects the frontend to send the Auth.js provider access token as:

```text
Authorization: Bearer <provider-access-token>
```

For Google tokens, the backend calls Google userinfo. For GitHub tokens, it calls GitHub `/user` and `/user/emails`. GitHub email lookup requires the `user:email` scope configured in the frontend provider.

This is simpler than running Keycloak locally, but it means the backend depends on provider API calls during authentication. A later production hardening pass can exchange provider identity for an app-owned backend session or JWT.
