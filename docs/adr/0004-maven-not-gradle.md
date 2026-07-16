# ADR-004: Maven Not Gradle

- **Status:** Accepted
- **Date:** 2026-05-26

## Context

The backend needs a repeatable Java build that is easy to run in CI and clear about annotation processor ordering for Lombok and MapStruct.

## Decision

Use Maven with `pom.xml` and the Maven wrapper.

## Consequences

Maven is the Spring Initializr default and has fewer moving parts than Groovy or Kotlin build scripts. Frontend-focused contributors can use pnpm wrapper scripts without needing to learn Maven details immediately. Annotation processor ordering is explicit in `pom.xml`, which matters for Lombok, MapStruct, and `lombok-mapstruct-binding`.

The drawback is Maven verbosity for advanced build customization.

## Alternatives considered

- Gradle with Groovy DSL. This can be concise, but it adds another DSL and more moving parts.
- Gradle with Kotlin DSL. This gives type-safe build scripts, but it is still extra build-system complexity for this project.
