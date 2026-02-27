# claudit

A Claude Code skill that audits, scores, and improves `CLAUDE.md` files — or generates a starter one from scratch when none exists.

Unlike Claude's built-in `/init` command, claudit runs deterministic scripts against your codebase, cross-references what your `CLAUDE.md` claims against what actually exists, scores each file on a 100-point rubric across 7 check categories, and produces an actionable findings report with concrete before/after examples.

## What it does

- **Audit mode**: Finds every `CLAUDE.md` in your project tree, runs security and structure scans, reconciles documented commands/directories against the real codebase, scores each file (A-F), and writes a consolidated findings report.
- **Generation mode**: When no `CLAUDE.md` exists, analyzes the codebase and writes a `CLAUDE.md.draft` populated with detected stack, build commands, directory structure, and security guardrails. Review it and rename when ready:

  ```bash
  mv CLAUDE.md.draft CLAUDE.md
  ```

The report is saved as `CLAUDE-AUDIT-YYYY-MM-DD-vN.md` in your project root. Claudit never writes to `CLAUDE.md` directly — existing files are never modified.

## Installation

1. Clone or download this repository into your Claude Code skills directory:

   ```bash
   # The default location for custom skills
   ~/.claude/skills/claudit/
   ```

2. Make the scripts executable:

   ```bash
   chmod +x scripts/scan_secrets.sh scripts/scan_structure.sh scripts/reconcile_codebase.sh
   ```

3. The skill is now available in Claude Code. Invoke it with `/claudit`. Claude may also invoke it automatically when your request matches the skill description (e.g., asking about CLAUDE.md auditing or best practices), but `/claudit` is the only guaranteed trigger.

## Project structure

```text
claudit/
  SKILL.md              — Skill definition and 7-step workflow
  scripts/              — Deterministic bash scripts (run before token-heavy analysis)
  references/           — Check criteria, scoring rubric, templates, and examples
  CHANGELOG.md          — Version history
```

## Scripts

The three scripts in `scripts/` run deterministic scans that would otherwise waste tokens if done inline by Claude. Each accepts a single argument and writes structured output to stdout.

| Script | Purpose | Usage |
| --- | --- | --- |
| `scan_secrets.sh` | Scans a CLAUDE.md file for exposed secrets, credentials, API keys, and tokens using regex patterns | `./scripts/scan_secrets.sh <path-to-claude-md>` |
| `scan_structure.sh` | Analyzes a CLAUDE.md file's structure: line/word/token counts, section headers, `@`-imports, and code blocks | `./scripts/scan_structure.sh <path-to-claude-md>` |
| `reconcile_codebase.sh` | Scans a project root to detect stack, monorepo layout, generated directories, env files, CI/CD config, build commands, and directory tree | `./scripts/reconcile_codebase.sh <project-root>` |

You can run any script standalone to inspect its output:

```bash
./scripts/reconcile_codebase.sh ~/Projects/my-app
./scripts/scan_secrets.sh ~/Projects/my-app/CLAUDE.md
./scripts/scan_structure.sh ~/Projects/my-app/CLAUDE.md
```

## References

The `references/` directory contains the detailed check criteria, scoring rubric, report templates, and examples that the skill reads during execution. These are separated from `SKILL.md` to keep the main skill file focused on workflow while allowing deep reference material to be loaded on demand.

| File | Contents |
| --- | --- |
| `security-checks.md` | Check 1: Secret exposure, credential patterns, guardrail validation |
| `structure-checks.md` | Check 2: File size, section organization, `@`-import hygiene |
| `architecture-checks.md` | Check 3: Codebase map, domain vocabulary, no-go zones, entry points |
| `knowledge-checks.md` | Check 4: Rationale, gotchas, deprecated patterns, definition of done |
| `clarity-checks.md` | Check 5: Vague directives, contradictions, untestable instructions |
| `environment-checks.md` | Check 6: Build/test commands, env vars, git conventions, IDE config |
| `verification-checks.md` | Check 7: Self-check hooks, verification commands |
| `cross-file-coherence.md` | Multi-file contradiction and redundancy detection |
| `scoring-rubric.md` | 100-point scoring rubric with category weights and grade thresholds |
| `templates.md` | Audit report template and Minimum Viable CLAUDE.md template |
| `examples.md` | Six canonical before/after examples for common anti-patterns |
| `advanced-patterns.md` | Advanced patterns for mature files (hooks, custom commands, rules) |
