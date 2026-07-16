# Full-Stack Monorepo Template — Implementation Plan

Reusable template: **Next.js + Spring Boot + Keycloak (OAuth2)**. Locked after four rounds of iteration. Every ticket has clear scope and a "done when" line.

---

## Locked stack

- **Monorepo:** pnpm workspaces + Turborepo
- **Backend:** Spring Boot **4.0.6**, **Java 21**, **Maven**, package `com.backend.backend` (rename to `com.devmatch.backend` recommended but optional), Spring Security 7 (OAuth2 Resource Server), PostgreSQL, Flyway, MapStruct, **springdoc-openapi 3.0.x** (Boot 4 line — *not* 2.x), Testcontainers, Jackson 3, `jackson-databind-nullable`
- **Frontend:** Next.js 14 App Router, TypeScript, Tailwind + shadcn/ui, Auth.js v5, TanStack Query, Zustand (UI state only), openapi-typescript
- **IdP:** Keycloak in docker-compose, realm imported on startup. Google/GitHub addable later as Keycloak **identity brokers** via env vars — frontend and backend code don't change.
- **Shared:** `packages/api-types` generated from the backend's OpenAPI spec

## Conventions

- **Backend layout:** modular — `modules/{auth,user,todo}/{controller,service,repository,entity,dto,mapper}`. Not flat layered. Each feature owns its slice.
- **Entities → Lombok.** Mutable (JPA requires it), ID-based `equals/hashCode` via `@EqualsAndHashCode(onlyExplicitlyIncluded = true)`, `@NoArgsConstructor(access = AccessLevel.PROTECTED)`.
- **DTOs → Java records.** Immutable, native Jackson/Bean Validation/MapStruct support, zero annotation processing for the DTO class itself.
- **PATCH request DTOs → records with `JsonNullable<T>` fields** where "absent" and "null" must be distinguishable. Mappers apply only present values.
- **Frontend state layering:** server state → TanStack Query; session/auth → Auth.js; ephemeral UI state → Zustand. No overlap.

---

## Phase 0 — Repo foundations

### T0.1 — Initialize monorepo skeleton
Root `package.json` with pnpm workspaces. Folders: `apps/{backend,frontend}`, `packages/api-types`, `infra/`, `docs/adr/`. Add `.editorconfig`, `.gitignore`, `README.md`.

`turbo.json` tasks:
- `dev` — `persistent: true`, `cache: false`
- `build` — `dependsOn: ["^build", "generate:types"]`, declared `outputs`
- `lint` — no deps
- `typecheck` — `dependsOn: ["generate:types"]`
- `test` — `dependsOn: ["^build"]`
- `generate:types` — runs `openapi-typescript` in `packages/api-types`, outputs `dist/index.d.ts`

`apps/backend/package.json` wraps Maven so Turborepo can drive it:
```json
{
  "scripts": {
    "dev": "./mvnw spring-boot:run",
    "build": "./mvnw clean package -DskipTests",
    "test": "./mvnw test",
    "lint": "./mvnw spotless:check",
    "format": "./mvnw spotless:apply"
  }
}
```
**Done when:** `pnpm install` succeeds; `turbo run build` discovers both apps and respects the `generate:types` → frontend `typecheck` dependency.

### T0.2 — Shared tooling
Prettier + ESLint flat config at root, Husky + lint-staged, commitlint (Conventional Commits). On the backend, **spotless-maven-plugin** in `pom.xml` with Google Java Format. Wire `./mvnw spotless:check` into pre-commit via lint-staged.
**Done when:** a malformed commit is rejected; `pnpm format` rewrites both apps.

### T0.3 — Docker compose baseline
`infra/docker-compose.yml` services: `postgres` (init script creates `app` and `keycloak` DBs), `keycloak` (dev mode, importing `infra/keycloak/realm-export.json`). Realm pre-configured: `webapp` client (public, PKCE), `backend` client (bearer-only), one test user. Leave room for identity broker config — documented in T10.4.
**Done when:** `docker compose up` brings Keycloak up at `:8081` with realm loaded; you can log in as the test user.

---

## Phase 1 — Backend core (`apps/backend`)

### T1.1 — Verify Initializr scaffold + add missing deps
Initializr gave you Spring Boot 4.0.6, Java 21, Maven, JAR packaging, package `com.backend.backend`. Finish the bootstrap:
- Verify Maven wrapper is committed (`mvnw`, `mvnw.cmd`, `.mvn/wrapper/`).
- Confirm `<java.version>21</java.version>` in `pom.xml` `<properties>`.
- Add dependencies to `pom.xml`:
  - `org.springframework.boot:spring-boot-starter-oauth2-resource-server`
  - `org.springdoc:springdoc-openapi-starter-webmvc-ui:3.0.x` (Boot 4 line — *not* 2.x)
  - `org.mapstruct:mapstruct`
  - `org.flywaydb:flyway-core` + `flyway-database-postgresql`
  - `org.openapitools:jackson-databind-nullable` (for PATCH DTOs)
  - `org.testcontainers:postgresql` + `testcontainers-junit-jupiter` (test scope)
  - Import `org.testcontainers:testcontainers-bom` in `<dependencyManagement>`.
- Configure annotation processors in `maven-compiler-plugin` — **ordering matters**:
  ```xml
  <annotationProcessorPaths>
    <path><groupId>org.projectlombok</groupId><artifactId>lombok</artifactId></path>
    <path><groupId>org.mapstruct</groupId><artifactId>mapstruct-processor</artifactId></path>
    <path><groupId>org.projectlombok</groupId><artifactId>lombok-mapstruct-binding</artifactId></path>
  </annotationProcessorPaths>
  ```
  Lombok before MapStruct; `lombok-mapstruct-binding` so MapStruct sees Lombok-generated getters on entities. DTO records need no Lombok — MapStruct reads record accessors directly.

**Done when:** `./mvnw spring-boot:run` starts and `/actuator/health` returns UP.

### T1.2 — Config & profiles
Rename `application.properties` → `application.yml`. Add `application-{dev,test,prod}.yml`. Externalize via env: `SPRING_DATASOURCE_*`, `SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI`, `APP_CORS_ALLOWED_ORIGINS`.
Create `com.backend.backend.config` package: `CorsConfig`, `JpaAuditingConfig`, `OpenApiConfig` (registers the bearer auth scheme so Swagger UI's "Authorize" button works), `WebMvcConfig`.
**Done when:** app reads config from env; `/v3/api-docs` is reachable.

### T1.3 — Common exception handling
`com.backend.backend.common.exception`: `ApiError` record (RFC 7807-style), `ResourceNotFoundException`, `BadRequestException`, `ForbiddenException`, `ConflictException`, `GlobalExceptionHandler` (`@RestControllerAdvice`) handling bean validation, Spring Security, custom exceptions, fallback `Exception`.
**Done when:** missing resource returns structured JSON with status, code, message, traceId.

### T1.4 — Database migrations & auditing
Flyway baseline. `V1__init.sql` with `pgcrypto` extension, `users` table, audit columns. Base class `AuditableEntity` with `@EntityListeners(AuditingEntityListener.class)` (Lombok-based — it's an entity).
**Done when:** migrations run cleanly; inserting a row populates audit fields.

### T1.5 — Request ID + structured logging
`common/web/RequestIdFilter` setting `traceId` into MDC. Logback config with JSON encoder for non-dev profiles.
**Done when:** every log line carries a `traceId`; same id returned in error responses.

---

## Phase 2 — Backend auth module (`modules/auth`)

### T2.1 — Resource Server security config
Verify APIs against **Spring Security 7** docs (Boot 4 line), not 6.x posts — `SecurityFilterChain` builder has minor renames. Stateless, CSRF off, CORS on. JWT decoder via `issuer-uri`. `JwtAuthenticationConverter` mapping `realm_access.roles` → `ROLE_*`. Public endpoints: `/actuator/health`, `/v3/api-docs/**`, `/swagger-ui/**`. Everything else authenticated.
**Done when:** unauth → 401; Keycloak token → 200.

### T2.2 — Current-user plumbing
`@CurrentUser` annotation, `CurrentUserArgumentResolver` resolving to an `AuthenticatedUser` **record** (subject, email, roles) from JWT. Register in `WebMvcConfig`.
**Done when:** `me(@CurrentUser AuthenticatedUser u)` returns the JWT subject.

### T2.3 — Method security
`@EnableMethodSecurity`. `@PreAuthorize` example on an admin endpoint.
**Done when:** non-admin token → 403 on admin route.

### T2.4 — Auth controller + tests
`AuthController` with `GET /api/v1/auth/me`. Tests via `@SpringBootTest` + `MockMvc` with `jwt()` post-processor and Testcontainers Postgres.
**Done when:** tests green; real Keycloak token returns the user.

---

## Phase 3 — Backend user module (`modules/user`)

### T3.1 — Entities + enums
**Lombok-based entities:** `User`, `ContactInfo`. `User` carries `externalId` (Keycloak `sub`), `email`, `displayName`, `role`, `userType`, audit fields. Enums: `Role`, `UserType`, `KycStatus`.

### T3.2 — Repositories
`UserRepository` with `findByExternalId(String)`, `existsByEmail(String)`.

### T3.3 — Mappers + DTOs
**DTOs as Java records.** `UserResponse` (record), `UserUpdateRequest` (record, fields wrapped in `JsonNullable<T>` for true PATCH semantics). Bean validation annotations on record components: `public record UserUpdateRequest(@Email JsonNullable<String> email, @Size(max=120) JsonNullable<String> displayName) {}`. MapStruct mappers (`UserMapper`, `ContactInfoMapper`) target records natively; PATCH mappers apply only `isPresent()` values.

### T3.4 — Service: JIT provisioning
`UserService` / `UserServiceImpl`: on first authenticated request, if no `User` matches JWT `sub`, create one from claims. Wire via filter after JWT filter, or lazily in `AuthController.me()`.
**Done when:** new Keycloak user calling `/auth/me` → one row inserted; subsequent calls don't.

### T3.5 — Controller + validation
`UserController`: `GET /api/v1/users/me`, `PATCH /api/v1/users/me` (accepts `UserUpdateRequest` record with `JsonNullable` fields — mapper applies only present values to the entity). Custom validators in `validation/{phone,url,notFutureYear,user}`.

### T3.6 — Tests
`@DataJpaTest` repo slices with Testcontainers; service unit tests; controller integration tests (incl. PATCH cases for "field absent" vs "field set to null").

---

## Phase 4 — Backend todo module (the smoke test)

### T4.1 — Module scaffold
`modules/todo/{controller,service,repository,entity,dto,mapper}`. Lombok-based `Todo` entity: `id`, `ownerId` (FK to `users.id`), `title`, `description`, `status` enum (TODO/IN_PROGRESS/DONE), `dueDate`, audit. Flyway `V2__todo.sql`.

### T4.2 — Repository + service
Every query scoped by `ownerId` (from `@CurrentUser`). Server-side only — never trust `ownerId` from request body. `TodoService` enforces ownership on update/delete (`ForbiddenException` on mismatch).

### T4.3 — Controller + DTOs
DTO records: `TodoResponse`, `TodoCreateRequest`, `TodoUpdateRequest` (uses `JsonNullable<T>` for PATCH). Endpoints: `GET /api/v1/todos` (paginated), `POST`, `GET /{id}`, `PATCH /{id}`, `DELETE /{id}`. Spring `Pageable`; wrap responses in `PageResponse<T>` record.

### T4.4 — Integration tests
MockMvc with two JWT subjects: assert user A cannot read/modify user B's todos. PATCH tests cover the `JsonNullable` semantics (clearing `dueDate` to null vs leaving it untouched).

---

## Phase 5 — Shared types package

### T5.1 — `packages/api-types`
Runs `openapi-typescript` against `http://localhost:8080/v3/api-docs`, emits `index.d.ts`. Turborepo `generate:types` task drives it. Fallback if springdoc 3.0.x has Boot 4 hiccups: commit `openapi.json` and generate from the file.
**Done when:** `import type { paths } from '@app/api-types'` works in the frontend.

---

## Phase 6 — Frontend init (`apps/frontend`)

### T6.1 — Next.js bootstrap
`create-next-app` (App Router, TS, Tailwind, ESLint, src/). Folders: `src/{app,components,lib,hooks,store,types}`. `components/ui` for shadcn primitives; initialize `shadcn-ui`.

### T6.2 — Base layout + theming
Root layout, font setup, dark mode via `next-themes`, minimal navbar.

---

## Phase 7 — Frontend auth (Auth.js v5)

### T7.1 — Auth.js setup with Keycloak provider
`src/lib/auth.ts` with Keycloak provider, PKCE, env vars (`AUTH_KEYCLOAK_*`). `jwt` and `session` callbacks persist `access_token` and `refresh_token`.

### T7.2 — Token refresh
In `jwt` callback, refresh via Keycloak's token endpoint near expiry. On failure, mark session `error: 'RefreshAccessTokenError'`.

### T7.3 — Middleware + protected routes
`middleware.ts` protecting `/app/**`. Public: `/`, `/login`. `app/(auth)/login/page.tsx` + callback page.

### T7.4 — Server actions vs client fetch
Convention: RSC reads `auth()` and forwards bearer; mutations via server actions or client mutations with bearer.

---

## Phase 8 — Frontend API client

### T8.1 — Typed fetch wrapper
`src/lib/api.ts` exporting `apiFetch<T>(path, init)`. Reads session, attaches `Authorization: Bearer ...`, throws typed errors. Two flavors: `serverApi` (uses `auth()` server-side) and `clientApi` (uses `useSession()` or session prop).

### T8.2 — TanStack Query setup
`QueryClientProvider` in a `Providers` client component, devtools dev-only. `src/lib/queryKeys.ts` factory.

### T8.3 — Generated hooks
Per-resource hook files: `hooks/useTodos.ts`, `hooks/useMe.ts`, typed against `packages/api-types`.

### T8.4 — Zustand UI state store
`src/store/` with one example store (`useTodoFiltersStore` for status filter + sort, or `useUiStore` for modal state). Document the layering convention in the README.
**Done when:** todo page filter state lives in Zustand and survives client-side navigation but not full refresh.

---

## Phase 9 — Frontend todo UI (smoke test)

### T9.1 — `/app/todos` page
List with status filter (driven by T8.4 store), sorted by due date. Empty state. Skeletons.

### T9.2 — Create/edit/delete
Modal or side sheet. Optimistic updates via TanStack Query. Toast on success/error.

### T9.3 — Error + unauth handling
401 → trigger Auth.js `signIn()`. 403/404 → friendly inline error.

---

## Phase 10 — Integration & DX

### T10.1 — Top-level docker-compose
Compose adds `backend` and `frontend` services built from each Dockerfile, plus Postgres/Keycloak from T0.3. Backend Dockerfile is a Maven multi-stage build:
```dockerfile
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY .mvn/ .mvn/
COPY mvnw .
RUN ./mvnw dependency:go-offline -B
COPY src ./src
RUN ./mvnw clean package -DskipTests -B

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
ENTRYPOINT ["java","-jar","/app/app.jar"]
```
Backend `depends_on` Postgres + Keycloak health.

### T10.2 — Makefile / scripts
`make dev` → start infra in compose, then `turbo run dev`. `make seed` → `./mvnw flyway:migrate` against seed config. `make reset` → nuke volumes. `make backend-test` → `./mvnw test`. `make backend-build` → `./mvnw clean package`.

### T10.3 — GitHub Actions CI
Three jobs:
- `backend-test`: `setup-java@v4` Temurin 21, cache `~/.m2/repository` keyed on `pom.xml`, `./mvnw verify` (Testcontainers gets Docker from `ubuntu-latest`).
- `frontend-test`: `setup-node@v4`, `setup-pnpm`, cache pnpm store, `pnpm lint && pnpm typecheck && pnpm test`.
- `build-images`: on `main`, push backend + frontend to GHCR.

### T10.4 — README + ADRs
README sections: prereqs, one-command start, architecture diagram, "how to add a backend module," "how to add a frontend feature," **"how to add Google/GitHub as Keycloak identity brokers"** (config in Keycloak admin or realm export JSON + env vars for client IDs/secrets — frontend and backend code don't change).

Starter ADRs:
- ADR-001: Why Keycloak as default IdP
- ADR-002: Why modular backend layout
- ADR-003: Why Spring Boot 4.0 (and springdoc 3.x line)
- ADR-004: Why Maven (capture the actual reason — Initializr default, team familiarity, whatever it is)
- ADR-005: Lombok for entities, records for DTOs (the rule + the `JsonNullable` PATCH convention)

---

## Phase 11 — Optional polish (post-MVP)

Bucket4j rate limiting, Sentry both sides, Playwright E2E (login → create todo → see it), Storybook, `packages/ui` extraction, Redis cache for user lookups, identity broker config (Google/GitHub) wired in.

---

## Acceptance — "auth works"

1. `docker compose up` brings Postgres + Keycloak up with realm imported.
2. `pnpm dev` starts backend (`:8080`) and frontend (`:3000`).
3. Visiting `localhost:3000/app/todos` redirects to Keycloak login.
4. After login, frontend has a valid session; `GET /api/v1/auth/me` returns the user.
5. One row in `users` after first login; no duplicates on repeat logins.
6. Access token refresh works silently across Keycloak's default expiry.

## Acceptance — "todo smoke test"

1. Authenticated user CRUDs their own todos via the UI.
2. Two Keycloak users see disjoint todo lists.
3. Forging another user's todo id in PATCH returns 403.
4. Backend integration test asserts cross-user isolation.
5. PATCH with `dueDate` absent leaves the value untouched; PATCH with `dueDate: null` clears it.
6. Frontend optimistic update rolls back on a forced 500.

---

## Recommended execution order

`T0.1 → T0.3 → T1.1 → T1.2 → T2.1` — gets you a Spring Boot 4 app validating Keycloak JWTs, which is the highest-risk part of the template. Everything after is mechanical.
