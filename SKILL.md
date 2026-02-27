---
name: claudit
description: Use when auditing, reviewing, improving, or checking CLAUDE.md files. Also trigger when the user says 'Claude is ignoring instructions', 'CLAUDE.md isn't working', 'onboarding to Claude Code', 'secret scanning config files', or 'CLAUDE.md best practices'. Traverses the full project tree, audits all CLAUDE.md files found, and produces a consolidated report. If no CLAUDE.md files exist, analyzes the codebase and generates a starter file based on audit findings.
---

# Claudit — CLAUDE.md Audit Skill

Traverse a project tree, audit every `CLAUDE.md` file found, and produce a single consolidated findings report. If no `CLAUDE.md` files exist anywhere in the project, analyze the codebase, produce the report, and generate a starter `CLAUDE.md` derived from the report's findings.

## Role

You are a senior engineering productivity and security consultant. Return structured findings that are direct, prioritized, and actionable.

---

## Skill Guardrails

These constraints apply to every claudit invocation regardless of context:

- **Write only two file types:** the audit report (`CLAUDE-AUDIT-YYYY-MM-DD-vN.md`) and, when no CLAUDE.md files exist anywhere in the project, a starter `CLAUDE.md`. No other files are created.
- **Never modify existing files.** Do not edit, overwrite, or append to any existing CLAUDE.md, rule file, settings.json, or any other project file. Findings go in the report only.
- **Never execute project commands without explicit user confirmation.** During codebase reconciliation, verify command existence (check package.json scripts, Makefile targets, etc.) but do not run build, test, or lint commands unless the user confirms.
- **Never read .env file values.** Only report that .env files exist and which variable names they define. Do not read, display, or log the values.
- **Never read or display secret values** found during scanning. Report the line number, the pattern type, and the remediation — not the secret itself.
- **Scope all filesystem operations to the project root and below.** Do not traverse above the project root or access unrelated directories.

---

## Workflow

### Step 1: Discover All CLAUDE.md Files

This step runs on every invocation before anything else.

Traverse the full project tree to find every `CLAUDE.md` file at any depth. Exclude `node_modules/`, `vendor/`, `.git/`, and other dependency/build directories.

Record the path of each discovered file. Also collect:
- All `.claude/` configuration: `rules/`, `commands/`, `settings.json`, `settings.local.json`
- Any `.claude.local.md` files
- Any parallel AI config files: `.cursorrules`, `AGENTS.md`, `copilot-instructions.md`

**The result of this step determines the mode:**
- **One or more CLAUDE.md files found → Audit mode** (Steps 2 through 6)
- **Zero CLAUDE.md files found anywhere → Generation mode** (Steps 2 through 5, then Step 7)

### Step 2: Establish Context

1. **Infer project type from detected stack files.** Run `scripts/reconcile_codebase.sh` against the project root. The detected build files (package.json, Cargo.toml, go.mod, main.tf, etc.) determine the project type: code, infrastructure-as-code, documentation, data pipeline, research, or mixed. Do not guess project type from CLAUDE.md content.

2. **Assess maturity level** (audit mode only). Maturity is a composite of file quality (score) and configuration breadth:
   - **Mature**: Any file scores 70+, OR a single file scores 85+ regardless of `.claude/` config
   - **Developing**: Highest file scores 40-69, or multiple files exist but none score 70+
   - **Early-stage**: All files score below 40, or a single sparse file with no `.claude/` config

   Note: Maturity requires scoring. Execute checks (Step 4) and score before assigning maturity. The label is applied retroactively in the report.

3. **Run deterministic scans against each discovered CLAUDE.md file:**
   - Execute `scripts/scan_secrets.sh <path>` for each file
   - Execute `scripts/scan_structure.sh <path>` for each file

**Fallback if script execution is denied:** If the user denies bash execution for any script, perform equivalent checks using Read, Glob, and Grep tools directly:
- Secret scanning: Use Grep with the same patterns from `scripts/scan_secrets.sh` against each CLAUDE.md file
- Structure analysis: Use Read to get file content, count lines/words/characters manually, and identify section headers and @-imports
- Codebase reconciliation: Use Glob to find build files, generated directories, and env files; use Read to extract package.json scripts and Makefile targets

### Step 3: Codebase Reconciliation

Verify what the CLAUDE.md files claim against what actually exists in the project. Use the output from `scripts/reconcile_codebase.sh` (already run in Step 2) to check:

1. **Directory map accuracy**: Compare documented directory structures against actual directories found. Flag directories that exist but aren't mentioned, especially generated/vendor/build output directories.
2. **Command existence**: Check that documented build/test/lint commands correspond to actual scripts in package.json, Makefile targets, or similar. Do not execute the commands — verify they exist.
3. **Environment variable coverage**: Compare env vars required by `.env.example` or similar against what the CLAUDE.md documents.
4. **Generated directory coverage**: Check that detected generated/vendor/build directories are identified as no-go zones.
5. **Settings.json coherence**: If `.claude/settings.json` exists, check for prose restrictions in CLAUDE.md not backed by `deniedTools`, and `allowedTools` granting capabilities the CLAUDE.md doesn't discuss.

In generation mode (no CLAUDE.md files), this step still runs — the reconciliation output becomes the primary input for the audit findings.

### Step 4: Execute Checks

Run each check against every discovered CLAUDE.md file. In generation mode, run the checks against the codebase state itself — evaluating what's absent.

Each check has detailed criteria in the references. Read the relevant reference file when executing each check.

| # | Check | Reference | Severity range |
|---|---|---|---|
| 1 | **Security & Secret Hygiene** | `references/security-checks.md` | CRITICAL / HIGH |
| 2 | **Structure & File Hygiene** | `references/structure-checks.md` | MEDIUM |
| 3 | **Architecture & Domain Context** | `references/architecture-checks.md` | HIGH / MEDIUM |
| 4 | **Institutional Knowledge** | `references/knowledge-checks.md` | HIGH / MEDIUM |
| 5 | **Instruction Clarity** | `references/clarity-checks.md` | HIGH / MEDIUM |
| 6 | **Environment & Workflow** | `references/environment-checks.md` | MEDIUM / INFO |
| 7 | **Verification & Validation Hooks** | `references/verification-checks.md` | HIGH / MEDIUM |

**Check 1 (Security) is always first.** Any CRITICAL finding must appear first in the report.

Not every check applies to every project type. When a check genuinely doesn't apply, skip it — do not flag the absence as a finding. Tag every finding with the file path it came from.

**Cross-file coherence** (runs after individual file checks):
When multiple CLAUDE.md files, rule files, settings.json, or parallel config files were discovered in Step 1, check for contradictions, redundancies, and precedence issues. Read `references/cross-file-coherence.md` for detailed criteria.

### Step 5: Score and Report

Calculate a score for each audited CLAUDE.md file using the rubric in `references/scoring-rubric.md`. In generation mode, score the absent state (which will be low — that's expected and useful).

Produce a single consolidated report using the template in `references/templates.md`. The report covers all discovered files with per-file scores and a unified findings list.

Save the report as `CLAUDE-AUDIT-YYYY-MM-DD-vN.md` in the project root. To determine the version number, check for existing `CLAUDE-AUDIT-YYYY-MM-DD-v*.md` files with today's date, find the highest version number, and increment by one. If none exist for today, start at v1.

Display a brief summary in the conversation: total files audited, finding counts by severity, per-file scores and grades, and the single most important change.

**In audit mode, the workflow proceeds to Step 6 if any file qualifies. Otherwise it ends here.** The report is the deliverable. The user decides what to act on.

### Step 6: Advanced Patterns (Audit Mode, Mature Files Only)

If any file scores 70+ and covers the basics, check for advanced opportunities. Read `references/advanced-patterns.md` for details. Flag as INFO. These findings are appended to the report produced in Step 5.

### Step 7: Generate Starter CLAUDE.md (Generation Mode Only)

This step runs only when Step 1 found zero CLAUDE.md files anywhere in the project.

The audit report from Step 5 is the source of truth. The generated CLAUDE.md is derived from it.

1. Start with the Minimum Viable template from `references/templates.md`
2. Populate it with concrete information discovered during reconciliation: detected stack, command names found in package.json/Makefile, environment variable names from .env.example
3. For the directory structure section, apply the completeness criteria from `references/architecture-checks.md` criterion 1 (Codebase map): every depth-1 and depth-2 directory from reconciliation must appear, depth-3 uses `{pattern}/` grouping where siblings repeat. Annotate each entry with its purpose
4. Address the HIGH and CRITICAL findings from the report — if the report says "missing build commands" and the reconciliation found them in package.json, include them
5. Do not include speculative content. If the reconciliation didn't detect it, don't invent it. Leave placeholder brackets for anything the user needs to fill in
6. Write the file to `CLAUDE.md` in the project root
7. **Verify directory completeness**: Compare the directory structure you wrote against the reconciliation output's "Directory Counts" section. Count the depth-1 and depth-2 entries in your generated tree. If your count is lower, find the missing directories and add them

The user reads the report to understand what matters, then modifies the generated file based on their own knowledge of the project.

---

## Before/After Examples

When presenting findings, use concrete before/after examples to illustrate the fix. See `references/examples.md` for six canonical examples covering the most common anti-patterns. Reference the relevant example in your finding when it matches.

---

## When to Apply This Skill

- Reviewing or improving existing CLAUDE.md files
- Onboarding a codebase to Claude Code (or Claude is ignoring instructions)
- Security review of AI tooling configuration before open-sourcing
- Periodic audit of CLAUDE.md drift as a codebase evolves