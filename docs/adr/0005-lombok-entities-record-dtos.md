# ADR-005: Lombok Entities, Record DTOs, and JsonNullable PATCH

- **Status:** Accepted
- **Date:** 2026-05-26

## Context

The backend needs clear conventions for persistence models, API DTOs, and partial update semantics. PATCH requests must distinguish between absent fields, explicit nulls, and concrete values.

## Decision

Use Lombok-based mutable JPA entities with ID-only equality, Java records for DTOs, and `JsonNullable<T>` fields for PATCH DTOs.

## Consequences

Lombok keeps JPA entities compact while preserving the mutable no-arg-constructor model that Hibernate expects. ID-only `equals` and `hashCode` avoid Hibernate proxy pitfalls. Java records work well for API DTOs with Jackson, Bean Validation, and MapStruct. `JsonNullable<T>` correctly represents PATCH semantics:

- Absent field means unchanged.
- Field set to `null` means clear it.
- Field set to a value means update it.

Developers must remember the PATCH convention, and `JsonNullable` adds some verbosity. Annotation processor ordering must remain Lombok -> MapStruct -> `lombok-mapstruct-binding`.

## Alternatives considered

- Records for entities. JPA needs mutable entities with a no-arg constructor, so records are a poor fit.
- Lombok DTOs. They work, but records give the same value-object behavior with fewer annotations.
- Plain nullable PATCH fields. They cannot distinguish absent from explicitly null fields.
