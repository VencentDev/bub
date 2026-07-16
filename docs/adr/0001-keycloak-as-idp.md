# ADR-001: Keycloak as Default IdP

- **Status:** Accepted
- **Date:** 2026-05-26

## Context

The application needs local authentication, token issuance, and a path to add external identity providers such as Google, GitHub, or SAML without repeatedly changing application code.

## Decision

Use Keycloak in Docker Compose with realm import as the default identity provider.

## Consequences

Future identity brokers can be added in Keycloak with zero frontend or backend code changes. The backend validates one JWT issuer through Spring Security Resource Server configuration, and the same self-hosted setup works locally, in staging, and in production.

The trade-off is operating an extra container and maintaining the realm export as part of infrastructure.

## Alternatives considered

- Auth.js handling OAuth directly against Google/GitHub. This would reduce local infrastructure, but every new provider would couple auth configuration more tightly to frontend code and backend token validation assumptions.
- Spring Authorization Server. This keeps auth in the Java stack, but it is heavier to own for this app and would still require additional work for identity brokering.
