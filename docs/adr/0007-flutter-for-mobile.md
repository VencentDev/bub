# ADR-007: Flutter for the Mobile App

- **Status:** Accepted
- **Date:** 2026-06-22
- **Relates to:** ADR-006 (provider OAuth) for the authentication model

## Context

The product needs a mobile app sharing the existing Spring Boot backend and its OpenAPI contract. The mobile app lives in this monorepo as `apps/mobile`, a sibling to `apps/frontend` and `apps/backend`. Because it is a Dart project with no `package.json`, pnpm and Turbo ignore it; it is built with the Flutter toolchain.

## Decision

- **Framework:** Flutter (Dart). One codebase for Android and iOS, mature tooling.
- **API client:** Generated from the backend OpenAPI spec with `swagger_parser` (Dio + json_serializable), reading the same committed `packages/api-types/openapi.json` that drives the web `@app/api-types`. Single source of truth, regenerated in CI; generated code is git-ignored.
- **State & networking:** Riverpod (no codegen) + Dio, with an interceptor that attaches the bearer token and refreshes on 401.
- **Authentication:** Native **Google OAuth** (Authorization Code + PKCE via `flutter_appauth`, no client secret). The Google access token is sent as `Authorization: Bearer`, which the backend resolves via the Google userinfo API — the same contract the web frontend uses (ADR-006). Tokens are stored in `flutter_secure_storage`.

## Consequences

- Mobile and web share one backend and one API contract; backend changes regenerate both clients.
- Auth deliberately follows ADR-006 (provider tokens), **not** Keycloak (ADR-001, superseded). The unused `*_JWT_ISSUER_URI` env var and the Keycloak realm are not involved.
- **GitHub sign-in is not yet implemented on mobile.** GitHub OAuth Apps require a client secret at the token-exchange step and do not support PKCE, so a secret cannot be shipped safely in the app. Adding GitHub requires a backend authorization-code exchange endpoint (future work); the backend already accepts GitHub access tokens once obtained.

## Alternatives considered

- **React Native.** Would let mobile import the TypeScript `@app/api-types` directly and reuse JS tooling. Rejected: Flutter was preferred for UI consistency and a single typed Dart client generated from the same spec keeps the contract guarantee without coupling to the JS build.
- **Keycloak OIDC on mobile.** Clean PKCE story, but the backend no longer validates Keycloak JWTs (ADR-006); tokens would be rejected. Rejected to avoid reversing ADR-006 and adding a resource-server path.
- **Hand-written Dart models/client.** Less tooling, but drifts from the backend. Rejected in favor of generation.
