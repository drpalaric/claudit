# Before/After Examples

Use these canonical examples when presenting findings. Reference the relevant example number in your finding when it matches the anti-pattern you've detected.

---

## Example 1: Embedded Style Rules (Engineering)

A CLAUDE.md that embeds formatting rules duplicates the tool config and drifts the moment the config changes. The tool is always authoritative — reference it, don't restate it.

```
# BEFORE — Anti-pattern
Always use tabs for indentation. Exported functions must have doc comments.
Error returns must be the last return value. Max line length is 120 characters.
Package names must be lowercase. No underscores in identifiers.

# AFTER — Correct pattern
Code style is enforced by the project's linter (see config in repo root).
Run `[lint command]` to check. Do not reproduce style rules in this file.
Fix all lint errors before marking any task complete.
```

---

## Example 2: Hardcoded Database Credentials (Infosec — CRITICAL)

Credentials committed to a CLAUDE.md that lives in a git repo are exposed to everyone with repo access, in every git clone, forever.

```
# BEFORE — CRITICAL risk
The staging database is:
postgres://admin:hunter2@db.internal.corp:5432/staging

# AFTER — Correct pattern
Database credentials are managed via environment variables.
- Connection string: $DATABASE_URL
- If $DATABASE_URL is unset, stop and ask the user to configure it.
  Do not attempt to guess defaults or use hardcoded values.
- Never log the connection string or credentials.
```

---

## Example 3: Vague Security Guidance (Infosec/Engineering)

Telling Claude to "be careful with security" provides zero actionable direction and creates false assurance.

```
# BEFORE — Not actionable
Be careful with security. Make sure code is secure and doesn't introduce
vulnerabilities. Always use best practices.

# AFTER — Actionable guardrails
Security rules (do not override, do not disable):
- Never disable TLS certificate verification in any form. This is always a bug,
  including in test code.
- Never log or print values from fields named: password, token, secret, key,
  authorization, or credential.
- Every new API endpoint must require authentication. If you add one without auth,
  flag it explicitly before finishing.
- After adding any dependency, run the project's configured vulnerability
  audit tool and report HIGH/CRITICAL findings before marking the task complete.
```

---

## Example 4: Missing Architecture Context (Engineering/Infosec)

A CLAUDE.md that omits project structure causes Claude to make locally-correct changes that violate global invariants — the most expensive class of AI-assisted mistake.

```
# BEFORE — No architecture context (Go service)
This is a Go project that connects to PostgreSQL. Run tests with `go test ./...`.

# AFTER — Architecture-aware
## Project structure
cmd/
  server/     main.go — HTTP server entrypoint (chi router)
  migrate/    main.go — Run DB migrations manually, never in server startup
internal/
  api/        HTTP handlers. Validate input, call service layer, return JSON.
              Handlers never touch the database directly.
  service/    Business logic. Services call store interfaces — never sql.DB directly.
  store/      All SQL queries (pgx v5). One file per domain entity.
              Generated query boilerplate is in store/gen/ — do not edit by hand.
  model/      Shared domain types. No methods, no imports from service or store.
migrations/   SQL migration files (golang-migrate). Sequential, never edited after merge.

## Domain vocabulary
Core entities: Cluster (a managed Postgres instance), Node (a member of a Cluster),
Tenant (an isolated user namespace within a Cluster). Do not use "server", "db",
or "user" — these are ambiguous in this codebase and will be rejected in review.

## Key constraints
- Handlers never import store directly (enforced by depguard in .golangci.yml)
- store/ uses pgx v5, NOT database/sql — do not mix drivers
- migrations/ files are immutable once merged to main. Never edit an existing
  migration. Add a new one instead.

## Entry points
API server:   cmd/server/main.go
DB migration: cmd/migrate/main.go (run manually before deploying schema changes)
Build:        go build ./...
Test:         go test ./... -race -count=1
```

---

## Example 5: Undocumented Institutional Knowledge (Engineering)

Teams know their footguns. Claude doesn't. Undocumented gotchas cause Claude to confidently reintroduce patterns that were removed from the codebase for good reason.

```
# BEFORE — Rules without context (Python + C codebase)
Don't use threads in the agent. Be careful modifying src/wal/. The old
connection pool code in legacy/ shouldn't be used.

# AFTER — Rules with rationale and boundary

## Known constraints and why they exist

Threading (Python agent): Do not use threading.Thread. The agent uses asyncio
throughout — mixing threads and the event loop causes deadlocks that are
extremely hard to reproduce (see incident postmortem: docs/incidents/2024-07-deadlock.md).
Use asyncio.create_task() or run_in_executor() for blocking I/O only.

src/wal/: This is the WAL parsing subsystem. It is memory-mapped and has
alignment requirements — unaligned reads cause SIGBUS on non-x86 platforms.
Any change here requires review from the storage team and testing on ARM.
Do not refactor for "cleanliness" without a dedicated PR and sign-off.

legacy/pool/: The legacy connection pooler was replaced in 2023 (see pgbouncer
integration in src/pool/). The legacy code is preserved for reference during
the migration window. Do not add new callers. Do not delete it yet — it is
still referenced by the upgrade path for clusters running < v3.2.

## Deprecated patterns (do not introduce)
- psycopg2 — we migrated to psycopg3 (psycopg). Do not add psycopg2 imports.
- sprintf-style string formatting in C — use snprintf with explicit bounds.
  (Two buffer overflows traced to sprintf in 2022/2023.)
- Global mutable state in Go packages — use dependency injection. The pattern
  in internal/legacy/globals.go is the old approach; do not replicate it.
```

---

## Example 6: Verbose Narrative vs. Concise Directives (Engineering)

CLAUDE.md is working context for an AI agent, not documentation for humans. Every paragraph that could be a bullet point wastes tokens and dilutes the signal.

```
# BEFORE — Narrative style
When working on this project, it's important to remember that we have a
microservices architecture. The services communicate with each other through
a message queue, and you should be aware that the order of messages matters
in some cases. We've had issues in the past where developers accidentally
introduced direct HTTP calls between services, which caused coupling problems
and made it harder to deploy independently. Please try to avoid doing this
and instead use the message queue for all inter-service communication.

# AFTER — Directive style
## Architecture
Microservices communicating via message queue (RabbitMQ).

Rules:
- No direct HTTP calls between services. All inter-service communication
  goes through the queue. (Direct calls caused deployment coupling — see
  postmortem docs/incidents/2024-03-coupling.md)
- Message ordering matters in the payments and audit pipelines. Do not
  reorder or batch messages in those queues.
- Each service deploys independently. Do not introduce cross-service
  imports or shared mutable state.
```
