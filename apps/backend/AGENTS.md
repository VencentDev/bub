# Backend Instructions

These rules apply to the Spring Boot backend in:

- `apps/backend/src/main/java/com/vencentdev/backend/**`
- `apps/backend/src/main/resources/**`
- `apps/backend/src/test/java/com/vencentdev/backend/**`

This app is a Java 21 Spring Boot MVC API backed by PostgreSQL, JPA, Flyway, MapStruct, Lombok, Spring Security, and Testcontainers. Keep backend changes aligned with the existing module package structure and avoid introducing alternate architectural styles unless the codebase is intentionally migrated.

## Package Structure

Use module-first packages under `com.vencentdev.backend.modules`.

Current module examples:

- `modules/auth/**`
- `modules/todo/**`
- `modules/user/**`

All business modules must live under:

- `src/main/java/com/vencentdev/backend/modules/<module>/**`
- `src/test/java/com/vencentdev/backend/modules/<module>/**`

For normal business modules, prefer this shape:

- `modules/<module>/controller/*Controller.java`
- `modules/<module>/service/*Service.java`
- `modules/<module>/service/*ServiceImpl.java`
- `modules/<module>/dto/*Request.java`
- `modules/<module>/dto/*Response.java`
- `modules/<module>/entity/*`
- `modules/<module>/enums/*`
- `modules/<module>/repository/*Repository.java`
- `modules/<module>/mapper/*Mapper.java`
- `modules/<module>/validation/*` when validation is module-specific

When a module has meaningful sub-features, group files one level deeper inside the normal technical folder. For example:

```text
modules/match/
  dto/
    lobby/
    setup/
    state/
    move/
  enums/
    rules/
    state/
    lobby/
  repository/
    lobby/
    state/
    move/
```

Apply the same pattern to other technical folders when it helps clarity, such as `controller/lobby`, `service/state`, `mapper/move`, or `entity/rules`. Do not create a parallel top-level sub-feature tree outside the module.

Keep cross-cutting code in the existing shared packages:

- `common/exception/**`: API error model, global exception handling, and domain HTTP exceptions.
- `common/persistence/**`: shared JPA persistence base classes.
- `common/web/**`: shared web filters and web infrastructure.
- `config/**`: Spring configuration only.

Do not create broad top-level packages such as `controllers`, `services`, `models`, `utils`, or `helpers`. Do not create new business packages directly under `com.vencentdev.backend`; put business code in `modules/<module>/**`, or in `common/**` only when it is truly shared by multiple modules.

## Controllers

Controllers are thin HTTP adapters.

- Annotate with `@RestController`.
- Use `/api/v1/<resource>` as the request mapping for business APIs.
- Accept the authenticated principal with `@CurrentUser AuthenticatedUser user` when endpoint behavior depends on the caller.
- Validate request bodies with `@Valid @RequestBody`.
- Use `@ResponseStatus(HttpStatus.CREATED)` for create endpoints and `@ResponseStatus(HttpStatus.NO_CONTENT)` for delete endpoints that return no body.
- Return DTOs, page DTOs, or `void`; do not return JPA entities.
- Delegate business rules to services. Do not put repository calls, ownership checks, mapping logic, or transaction boundaries in controllers.
- Keep route names resource-oriented and predictable, like `/api/v1/todos`, `/api/v1/todos/{id}`, and `/api/v1/users/me`.

For paginated list endpoints, use Spring `Pageable` and return the existing `PageResponse<T>` shape rather than exposing Spring's raw `Page` JSON.

## Services

Services own business logic, authorization-sensitive checks, and transactions.

- Define a service interface in `modules/<module>/service/*Service.java`.
- Implement it in `modules/<module>/service/*ServiceImpl.java`.
- Annotate implementations with `@Service`.
- Use constructor injection with `final` fields.
- Add `@Transactional` on service methods that read or write managed entities. Use `@Transactional(readOnly = true)` when a method only reads and does not provision or mutate state.
- Resolve the internal user id through `UserService.resolveInternalId(principal)` for user-owned resources.
- Enforce ownership in the service layer before returning, updating, or deleting user-owned data.
- Throw existing domain exceptions from `common.exception`, such as `ResourceNotFoundException`, `ForbiddenException`, `BadRequestException`, and `ConflictException`.

Do not silently leak whether another user's resource exists unless the current behavior intentionally does so. Follow existing endpoint behavior: read-by-id can return not found for cross-user access, while update and delete can return forbidden after loading the resource.

## DTOs

Requests and responses are explicit DTOs.

- Use Java records for request and response DTOs unless a class is clearly needed.
- Put validation annotations on request DTO fields.
- Keep response DTOs stable and client-facing; do not expose entity internals by accident.
- For partial update requests, preserve the current `JsonNullable<T>` pattern so the API can distinguish missing fields from explicit `null` values.
- When custom JSON parsing is needed for patch semantics, keep it inside the request DTO or a feature-local validator.

Do not accept trusted fields from clients when they are derived from authentication or server state. For example, owner ids must come from `@CurrentUser` resolution, not request bodies.

## Entities

Entities represent database tables and should stay persistence-focused.

- Put entities in `modules/<module>/entity/**`.
- Use JPA annotations from `jakarta.persistence`.
- Use `UUID` primary keys with `@GeneratedValue(strategy = GenerationType.UUID)` unless an existing table requires otherwise.
- Extend `AuditableEntity` for application tables that should track `createdAt`, `updatedAt`, `createdBy`, and `updatedBy`.
- Use Lombok consistently with the existing entities:
  - `@Getter`
  - `@Setter`
  - `@NoArgsConstructor(access = AccessLevel.PROTECTED)`
  - `@AllArgsConstructor`
  - `@Builder`
  - `@EqualsAndHashCode(callSuper = false, onlyExplicitlyIncluded = true)`
- Include only the id in entity equality with `@EqualsAndHashCode.Include`.
- Use `@Enumerated(EnumType.STRING)` for enums.
- Put enums in `modules/<module>/enums/**`, not in `entity/**`.
- Keep column names explicit when they differ from Java field names.

Avoid putting API serialization annotations or business workflow methods on entities unless the existing model makes that necessary.

## Repositories

Repositories are Spring Data JPA interfaces.

- Put them in `modules/<module>/repository/**`.
- Extend `JpaRepository<Entity, UUID>` for UUID-backed entities.
- Prefer explicit derived query methods that encode ownership, such as `findByIdAndOwnerId`, `findByOwnerId`, and `findByOwnerIdAndStatus`.
- Keep complex query logic out of controllers. If a query needs business context, call it from a service.

## Mappers

Use MapStruct for DTO/entity mapping.

- Put mappers in `modules/<module>/mapper/**`.
- Annotate with `@Mapper(componentModel = "spring")`.
- Use abstract classes when a mapper needs manual helper methods.
- Ignore server-owned fields when mapping create requests, such as `id`, `ownerId`, audit fields, or fields derived from authentication.
- Keep patch application methods explicit so `JsonNullable` semantics remain obvious.

Do not hand-map in controllers. Small service-level mapping is acceptable only when a full mapper would add no value and no local mapper exists yet.

## Validation

Use Jakarta Bean Validation for request contracts.

- Place simple constraints directly on DTO record components.
- Put module-specific annotations and validators in `modules/<module>/validation/**`.
- Use cross-field validators when request validity depends on more than one field.
- Return validation failures through `GlobalExceptionHandler`; do not build ad hoc validation responses in controllers.

## Errors

All API errors should flow through `GlobalExceptionHandler` and return `ApiError`.

- Use existing exception classes before adding new ones.
- Add a new exception class only when the HTTP status and code represent a reusable domain category.
- Keep error messages concise and safe for clients.
- Do not expose stack traces, SQL details, or third-party provider internals in API responses.
- Preserve trace id handling through MDC.

If adding a reusable exception, also add a handler branch in `GlobalExceptionHandler` with a stable error code.

## Authentication And Authorization

The API is stateless and authenticated by Spring Security.

- Keep public unauthenticated paths limited to health, info, OpenAPI, and Swagger unless the feature explicitly requires a public endpoint.
- Use `@CurrentUser AuthenticatedUser` instead of reading the `SecurityContextHolder` inside controllers.
- Let `CurrentUserArgumentResolver` translate security authentication into `AuthenticatedUser`.
- Use method security only for coarse-grained role checks. Keep resource ownership checks in services.
- Preserve OAuth provider and rate-limit filters in the security chain.

Tests should use Spring Security test support, especially `.with(jwt())`, for authenticated requests.

## Configuration

Use Spring configuration classes only for framework wiring.

- Put framework beans in `config/**`.
- Put module runtime properties near the module when they are module-specific, as `modules/auth/ratelimit/AuthRateLimitProperties` currently does.
- Bind configuration from `application*.yml` using environment-backed defaults.
- Keep secrets out of source. Use `.env` locally and update `.env.example` when adding required environment variables.

Do not commit local `.env` changes or generated `target/**` output.

## Database And Migrations

Database schema is managed by Flyway.

- Add migrations under `src/main/resources/db/migration`.
- Name migrations as `V<N>__description.sql`.
- Never edit an already-applied migration to change behavior; add a new migration.
- Keep JPA mappings and Flyway schema changes in sync.
- Add indexes for owner filters, status filters, foreign keys, and list endpoints that will be queried frequently.
- Use PostgreSQL-compatible SQL.
- Remember that JPA is configured with `ddl-auto: validate`; the app should validate against migrations, not generate schema at runtime.

When adding a table for user-owned data, include an `owner_id` or equivalent foreign key and make ownership part of repository queries and service checks.

## Tests

Match the current test style.

- Unit tests live beside the matching package under `src/test/java/com/vencentdev/backend/**`.
- Integration tests that boot the app should extend `IntegrationTestBase`.
- Use `MockMvc` for controller integration tests.
- Use Testcontainers PostgreSQL through `IntegrationTestBase` for persistence-backed integration tests.
- Reset repositories in `@BeforeEach` when tests create data.
- Cover authentication, validation, ownership isolation, patch semantics, pagination shape, and important error cases for API changes.
- Prefer testing externally visible API behavior over implementation details.

For new endpoints, add at least one happy-path test and at least one authorization or validation failure test when applicable.

## Commands

Run commands from `apps/backend` unless using the workspace package scripts.

Useful local commands:

```bash
./mvnw test
./mvnw spotless:check
./mvnw spotless:apply
./mvnw clean package -DskipTests
./mvnw spring-boot:run
```

Workspace package scripts mirror these:

```bash
pnpm --filter @app/backend test
pnpm --filter @app/backend lint
pnpm --filter @app/backend format
pnpm --filter @app/backend build
pnpm --filter @app/backend dev
```

Before finishing backend code changes, run the most relevant tests and `spotless:check`. If tests require Docker for Testcontainers and Docker is unavailable, say that explicitly in the handoff.

## Formatting And Style

- Java is formatted by Spotless with Google Java Format.
- Use Java 21 language features conservatively and consistently with existing code.
- Prefer constructor injection over field injection in production code.
- Keep imports organized by the formatter.
- Do not add comments that restate obvious code. Add comments only for non-obvious business rules, security decisions, or tricky framework behavior.
- Keep class names specific and conventional: `ThingController`, `ThingService`, `ThingServiceImpl`, `ThingRepository`, `ThingMapper`, `ThingCreateRequest`, `ThingUpdateRequest`, `ThingResponse`.

Avoid generic file names like `Utils`, `Helper`, `Manager`, `CommonService`, or `Data`.

## Dependency Boundaries

- Do not add dependencies for simple code that Spring, Java, MapStruct, or existing project dependencies can already handle.
- If adding a dependency is necessary, add it to `pom.xml` with a clear reason and ensure it works with Spring Boot 4 and Java 21.
- Keep frontend-specific code out of the backend. The frontend should call Spring Boot APIs; the backend should not depend on frontend app-router conventions.

## Change Checklist

When implementing backend changes:

- Keep files in the feature-first package structure.
- Add or update DTOs instead of exposing entities.
- Put business logic and transactions in services.
- Add repository queries that enforce ownership when needed.
- Add Flyway migrations for schema changes.
- Update validation and error handling through the shared mechanisms.
- Add focused tests for the changed behavior.
- Run formatting and relevant tests before handoff.
