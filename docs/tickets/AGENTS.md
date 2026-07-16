# Ticket Documentation Instructions

These rules apply to all ticket sets created under `docs/tickets/**`.

## Folder Structure

Every feature ticket set must live under:

```text
docs/tickets/{feature-name}/
```

Use kebab-case for `{feature-name}`, for example:

```text
docs/tickets/automatic-matchmaking/
docs/tickets/player-profiles/
```

Each feature folder must include:

```text
docs/tickets/{feature-name}/plan.md
docs/tickets/{feature-name}/frontend/
docs/tickets/{feature-name}/backend/
```

Create only the folders that are relevant to the feature if the feature is truly frontend-only or backend-only, but still include `plan.md`.

## Ticket Naming

Frontend ticket files must be named:

```text
F01-{task-name}.md
F02-{task-name}.md
F03-{task-name}.md
```

Backend ticket files must be named:

```text
B01-{task-name}.md
B02-{task-name}.md
B03-{task-name}.md
```

Use kebab-case for `{task-name}`. Number tickets in the intended implementation order within each discipline. Do not use bare numeric names such as `01-api-hooks.md`.

Examples:

```text
docs/tickets/automatic-matchmaking/frontend/F01-api-hooks.md
docs/tickets/automatic-matchmaking/frontend/F02-find-match-page.md
docs/tickets/automatic-matchmaking/backend/B01-schema-and-contract.md
docs/tickets/automatic-matchmaking/backend/B02-service-and-controller.md
```

## Plan Requirements

Every `plan.md` must include:

- Feature goal.
- Architecture summary.
- Frontend ticket list with filenames.
- Backend ticket list with filenames.
- Implementation order.
- Acceptance criteria.
- Verification commands.
- Commit policy.

The commit policy section must state that implementation work should be committed automatically after each coherent ticket or file-change batch. Each commit must include only the files changed for that completed ticket or batch, and the commit message must describe the implemented ticket.

Use this section text unless the user gives a more specific commit policy:

```markdown
## Commit Policy

- Commit automatically after each coherent ticket or file-change batch.
- Stage only files changed for the completed ticket or batch.
- Use a focused commit message that names the implemented ticket, such as `feat: implement B01 matchmaking schema`.
- Do not include unrelated dirty work in the commit.
```

## Implemented Ticket Renaming

When a ticket has been fully implemented and verified, rename that ticket file by appending `-done` before `.md`.

Examples:

```text
F01-api-hooks.md -> F01-api-hooks-done.md
B02-service-and-controller.md -> B02-service-and-controller-done.md
```

Only rename a ticket to `-done` after:

- The implementation described by the ticket is complete.
- Relevant tests or verification commands have been run, or any blocked verification is documented.
- The implementation has been committed according to the feature plan's commit policy.

Do not rename `plan.md`.

## Ticket Contents

Each ticket should include:

- Goal.
- Files to create or modify.
- Requirements.
- Implementation notes.
- Tests or verification.
- Done criteria.

Keep tickets implementation-ready. Avoid placeholders such as `TBD`, `TODO`, `fill in later`, or vague instructions like `add proper error handling`.
