# ADR-002: Modular Backend Layout

- **Status:** Accepted
- **Date:** 2026-05-26

## Context

The backend needs to remain understandable as features are added. A purely flat package layout can make feature ownership harder once controllers, services, repositories, DTOs, entities, and mappers grow.

## Decision

Use vertical feature slices for backend modules. Each feature groups its own controller, service, repository, entity, DTO, and mapper types.

## Consequences

Feature code stays cohesive as the project grows, and a module can be lifted into a separate service more easily later. The drawback is that cross-module references can be longer and must be treated intentionally.

## Alternatives considered

- Flat layered packages such as top-level `controller/`, `service/`, and `repository/`. This is simple early on but scatters feature behavior across the project.
- Hexagonal or clean architecture with adapters and ports. This is powerful for complex domains, but it adds ceremony before this app needs it.
