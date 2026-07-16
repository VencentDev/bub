# ADR-003: Spring Boot 4 and springdoc 3

- **Status:** Accepted
- **Date:** 2026-05-26

## Context

The backend needs a modern Spring stack with Java 21 support, current Spring Security APIs, and generated OpenAPI documentation that can feed frontend TypeScript types.

## Decision

Use Spring Boot 4.0.6, Spring Security 7, and the springdoc-openapi 3.0.x line.

## Consequences

Spring Boot 4 aligns with Jackson 3 and Java 21+ conventions. Spring Security 7 includes API changes from 6.x, so implementation should be checked against official documentation. springdoc 2.x does not support Boot 4, so the project must stay on the 3.0.x line.

The trade-off is a smaller community/blog ecosystem than Boot 3.x. Prefer official docs and primary sources for compatibility questions.

## Alternatives considered

- Stay on Spring Boot 3.x LTS. This would have a larger support ecosystem, but the project intentionally starts on the current major stack.
- Use Boot 4 with springdoc 2.x. This is incompatible with the chosen Spring Boot line.
