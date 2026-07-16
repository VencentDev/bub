# Frontend Instructions

These rules apply to the Next.js frontend in:

- `apps/frontend/src/app/**`
- `apps/frontend/src/features/**`

Spring Boot owns backend domain APIs. Do not add application API handlers under the Next.js app router for business features. Keep frontend route files thin, keep feature code predictable, and colocate feature UI, API hooks, state, and helpers under `src/features/**`.

## App Router Rule

Folders under `apps/frontend/src/app/**` should contain route entry files only:

- `page.tsx`
- `layout.tsx`

Required framework files are allowed only when Next.js/Auth.js needs them, such as `src/app/api/auth/[...nextauth]/route.ts` for the current Auth.js login flow.

For any `apps/frontend/src/app/**/page.tsx`:

- Keep the file as a thin route entry only.
- Import exactly one page-content component from `@/features/**/components/**-page-content`.
- Export exactly one default page function.
- Have that function directly return the imported page-content component.
- Forward route props such as `params` and `searchParams` directly to the page-content component when needed.
- Do not place UI markup, hooks, constants, validation, queries, or business logic in route files.
- Do not perform server-side data fetching in route files; keep feature fetching in the imported page-content component or in that feature's API layer.
- You may export standard Next.js page config such as `metadata`, `viewport`, `revalidate`, `dynamic`, `generateMetadata`, and `generateViewport`.

Example:

```tsx
import { TodosPageContent } from '@/features/todos/list/components/todos-page-content';

export default function Page() {
  return <TodosPageContent />;
}
```

## Feature Folder Structure

Prefer a feature and subfeature folder before concern folders:

- `features/<feature>/<subfeature>/components/*`
- `features/<feature>/<subfeature>/api/*`
- `features/<feature>/<subfeature>/lib/*`
- `features/<feature>/<subfeature>/hooks/*`
- `features/<feature>/<subfeature>/types/*`
- `features/<feature>/<subfeature>/context/*`

Current examples:

- `features/home/landing/components/*`
- `features/auth/login/components/*`
- `features/auth/session/api/*`
- `features/todos/list/components/*`
- `features/todos/list/api/*`
- `features/todos/list/hooks/*`

Avoid broad top-level folders like `features/<feature>/components/*` unless the feature is tiny and has no meaningful subfeature split yet.

Inside each subfeature:

- `components/`: UI and composition only.
- `api/`: TanStack Query hooks, query keys, API adapters, and transport-facing code for Spring Boot endpoints.
- `lib/`: Pure helpers, schemas, constants, defaults, formatters, mappers, and other non-React logic.
- `hooks/`: Reusable stateful client behavior that is too substantial to live inside one small component.
- `types/`: Feature-specific shared types.
- `context/`: Shared provider state only when multiple descendants truly need it.

Shared design-system primitives may remain in `src/components/ui/**`. Feature-specific components should not live in `src/app/**` or generic shared component folders.

## Page-Content Rule

For `**-page-content.tsx` files:

- Compose child components and feature hooks.
- Keep them readable at a glance.
- Move display-only sections into neighboring component files within the same subfeature.
- Move pure formatting and derived labels into that subfeature's `lib/`.
- Move reusable stateful behavior into that subfeature's `hooks/`.

Good names:

- `todos-page-content.tsx`
- `todo-filters.tsx`
- `todo-form-sheet.tsx`
- `login-page-content.tsx`

## Component Decomposition

For files under `apps/frontend/src/features/**/components/`:

- Prefer small, focused components over large multi-purpose files.
- Treat page-content files as orchestration layers, not the final home for every UI region.
- Prefer one primary exported component per file.
- Extract summary cards, forms, filters, dialogs, sheets, banners, tabs, empty states, skeletons, cards, row items, and action bars into separate files when they grow.
- Split files that mix data fetching, dialog state, helper formatting, schemas, long form markup, and submission logic.

Refactor triggers:

- A component file grows over roughly 200 to 300 lines.
- A file contains multiple clearly separate UI regions.
- A file has multiple inline helper components.
- A file mixes React rendering with significant pure helper logic.
- A file mixes form schemas/default values with UI markup and submit behavior.

## API And Backend Boundaries

The frontend talks to the Spring Boot backend through typed client helpers and feature API hooks.

- Keep TanStack Query hooks in `features/**/api/*.hooks.ts`.
- Keep raw API helpers near the feature API layer when they are feature-specific.
- Components should consume feature hooks rather than assemble remote calls inline.
- Do not create Next.js route handlers for Spring Boot domain resources such as todos, users, bookings, or reports.

Examples:

- `features/todos/list/api/todos.hooks.ts`
- `features/auth/session/api/me.hooks.ts`

## Form And Lib Separation

Forms should be split when they grow beyond a small single-section form:

- `<subfeature>/components/<thing>-form.tsx`: high-level form orchestration.
- `<subfeature>/components/<thing>-fields.tsx`: main field group markup.
- `<subfeature>/components/<thing>-step.tsx`: per-step orchestration for multi-step flows.
- `<subfeature>/components/<thing>-summary-card.tsx`: read-only sidecards or summaries.
- `<subfeature>/lib/<thing>-form.ts`: schemas, defaults, step definitions, constants, and pure validation helpers.
- `<subfeature>/api/<thing>.hooks.ts`: submission/query hooks and query keys.

Keep JSX, React hooks, mutation calls, router navigation, and toast calls out of `lib/`.

## Naming

Use descriptive, feature-local file names.

Prefer:

- `todos-page-content.tsx`
- `todo-form-sheet.tsx`
- `todo-filters.tsx`
- `me.hooks.ts`

Avoid vague names:

- `utils.ts`
- `helpers.ts`
- `form2.tsx`
- `section.tsx`
- `data.ts`

If a name is too generic, it is usually a sign the file is too broad or in the wrong place.
