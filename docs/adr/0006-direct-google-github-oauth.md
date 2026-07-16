# ADR-006: Direct Google and GitHub OAuth

- **Status:** Accepted
- **Date:** 2026-05-28
- **Supersedes:** ADR-001 for the default local identity provider

## Context

The application no longer needs a self-hosted Keycloak container for local authentication. The desired developer flow is direct Google and GitHub sign-in through Auth.js.

## Decision

Use Auth.js Google and GitHub providers in the frontend. The frontend stores the provider access token in the Auth.js JWT session and sends it to the Spring backend as a bearer token for API requests.

The backend resolves that bearer token through provider userinfo APIs and maps the result into the existing `AuthenticatedUser` application principal.

## Consequences

Local development has fewer moving pieces because Keycloak and its database are no longer required.

GitHub access tokens are opaque, so the backend cannot validate them with Spring Resource Server JWT issuer configuration. Authentication now depends on external provider API calls. For higher-volume production use, consider exchanging provider identity for an app-owned session or backend JWT.
