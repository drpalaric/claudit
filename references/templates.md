# Claudit Templates

## Minimum Viable CLAUDE.md

If no CLAUDE.md files exist in the project and generation mode is active, use this template as the starting structure. Populate it with concrete information from the codebase reconciliation. Leave placeholder brackets for anything the reconciliation didn't detect.

```markdown
## Project overview
[One paragraph: what this project does, who it's for, and the primary language/stack.]

## Commands
Build:   [exact command]
Test:    [exact command]
Lint:    [exact command]

## Directory structure
[Tree of ALL directories from reconciliation output — every depth-1 and depth-2 directory must appear, with one-line purpose for each. For depth-3, include individually unless many siblings follow a pattern (use {pattern}/ placeholder)]

## Key constraints
- [Most important architectural rule — e.g., "services never call the database directly"]
- [Most important safety rule — e.g., "do not run destructive commands without confirmation"]
- [Most common mistake to avoid — e.g., "never edit files in generated/"]
```

If a team can fill out just this template, Claude's output quality improves dramatically. All other checks are refinements on top of this foundation.

For solo developers or new projects, this template is sufficient. The more advanced checks (Institutional Knowledge, Compliance, Definition of Done) become relevant as the team or codebase grows.

---

## Consolidated Audit Report Template

Use this exact structure for every audit report. The report covers all discovered CLAUDE.md files in a single document.

Save as `CLAUDE-AUDIT-YYYY-MM-DD-vN.md` in the project root. To determine the version number, check for existing `CLAUDE-AUDIT-YYYY-MM-DD-v*.md` files with today's date, find the highest version number, and increment by one. If none exist for today, start at v1.

```markdown
# CLAUDE.md Audit Report

| Field | Value |
|---|---|
| **Date** | YYYY-MM-DD |
| **Version** | vN |
| **Project root** | [path] |
| **Project type** | [code, infrastructure-as-code, documentation, data pipeline, research, or mixed] |
| **CLAUDE.md files found** | [N] (list paths below) |
| **Maturity** | [early-stage, developing, mature] |
| **Existing .claude/ config** | [rules files, commands, settings.json, subdirectory CLAUDE.md files — or "none"] |
| **Parallel config files** | [.cursorrules, AGENTS.md, etc. — or "none"] |

## Files Audited

| # | Path | Lines | Est. Tokens | Score | Grade |
|---|---|---|---|---|---|
| 1 | ./CLAUDE.md | [N] | ~[N] | [N]/100 | [A-F] |
| 2 | ./packages/api/CLAUDE.md | [N] | ~[N] | [N]/100 | [A-F] |
| ... | ... | ... | ... | ... | ... |

_In generation mode (no CLAUDE.md files found), this table shows a single row: "No CLAUDE.md files found" with a score reflecting the absent state._

## Findings Summary

| Severity | Count |
|---|---|
| CRITICAL | [N] |
| HIGH | [N] |
| MEDIUM | [N] |
| INFO | [N] |

---

## Findings

_CRITICAL findings always appear first, regardless of which file they came from._

### CRITICAL: [Short Title]

**File:** [path to the CLAUDE.md this finding applies to, or "Project-wide" for cross-file/codebase issues]
**Check:** [Which check found this — e.g., "Check 1: Secret Exposure"]
**Issue:** One sentence describing the problem.
**Current:**
> [Offending text from CLAUDE.md, verbatim, in a blockquote. For generation mode, state "Not present — no CLAUDE.md exists."]

**Recommended:**
```
[Replacement or addition text in a code block]
```

**Why it matters:** One sentence on impact if not addressed.

---

### HIGH: [Short Title]
[Same format — always include the **File:** field]

---

### MEDIUM: [Short Title]
[Same format]

---

### INFO: [Short Title — positive patterns or low-priority improvements]
[Same format, but frame as "Consider adding:" rather than a problem]

---

## Cross-File Coherence

_This section appears only when multiple CLAUDE.md files, rule files, or parallel config files were found._

### [Contradiction/Redundancy Title]

**Files involved:** [list the file paths that conflict]
**Issue:** [describe the contradiction or redundancy]
**Recommendation:** [which file should be authoritative, or how to resolve]

---

## Per-File Score Breakdown

### [path to first CLAUDE.md]

| Category | Score | Max | Notes |
|---|---|---|---|
| Security | [N] | 25 | [brief note] |
| Architecture | [N] | 20 | [brief note] |
| Structure | [N] | 15 | [brief note] |
| Institutional Knowledge | [N] | 15 | [brief note] |
| Clarity | [N] | 10 | [brief note] |
| Environment | [N] | 10 | [brief note] |
| Verification | [N] | 5 | [brief note] |
| **Total** | **[N]** | **100** | **Grade: [A-F]** |

### [path to second CLAUDE.md]
[Same table]

---

## Summary

[2-3 sentences. Overall assessment across all files. What is the single most important change the team should make first?]

_In generation mode, add: "A starter file has been written to `CLAUDE.md.draft`. Review it and rename to `CLAUDE.md` when ready: `mv CLAUDE.md.draft CLAUDE.md`"_
```

**Severity definitions:**
- **CRITICAL** — Security risk: exposed secrets, instruction injection surface, dangerous broad autonomy grants
- **HIGH** — Actively degrades performance: conflicting instructions, missing build/test commands, vague directives that Claude cannot act on
- **MEDIUM** — Missed opportunity: content that belongs in a rules file, missing verification hooks, `@`-mention misuse
- **INFO** — Positive patterns worth noting, or low-priority improvements