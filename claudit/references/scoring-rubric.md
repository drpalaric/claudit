# Claudit Scoring Rubric

## Overview

After executing all checks, calculate an overall score. This makes audits comparable across projects and trackable over time.

## Scoring Categories

| Category | Max Points | Source Check | What it measures |
|---|---|---|---|
| Security | 25 | Check 1 | Secret hygiene, injection risk, guardrails |
| Architecture | 20 | Check 3 | Codebase map, domain vocab, entry points, patterns, no-go zones |
| Structure | 15 | Check 2 | Length, focus, separation of concerns, config coherence |
| Institutional Knowledge | 15 | Check 4 | Rationale, gotchas, deprecated patterns, compliance |
| Clarity | 10 | Check 5 | Actionable directives, no contradictions, no vague verbs |
| Environment | 10 | Check 6 | Build/test commands, env vars, workflow setup |
| Verification | 5 | Check 7 | Self-check hooks, escalation, scope guardrails |
| **Total** | **100** | | |

## Scoring Rules

### Security (0-25)
- **0**: Any CRITICAL finding (exposed secrets, key material)
- **10**: No CRITICAL but HIGH findings present (injection risk, broad autonomy)
- **18**: No CRITICAL or HIGH; missing recommended guardrails (INFO only)
- **25**: Clean — no secrets, trust boundaries defined, tool restrictions in place

### Architecture (0-20)
- **0**: No architecture context at all
- **5**: Project type mentioned but no directory map or domain vocabulary
- **10**: Directory map present but missing domain vocab, entry points, or patterns
- **15**: Directory map + domain vocab + entry points; minor gaps (e.g., no reference implementations)
- **20**: Complete — map, vocab, entry points, patterns, no-go zones, reference implementations

### Structure (0-15)
- **0**: Severely bloated (>300 lines with significant non-directive content) or content entirely misplaced
- **5**: Over 150 lines with embedded style rules, inlined configs, or policy docs that belong in rules files
- **10**: Reasonable length, minor issues (a few large @-imports, some duplication with settings.json)
- **15**: Focused, well-organized, proper separation into rules files, no duplication

### Institutional Knowledge (0-15)
- **0**: Rules with no rationale, no documented gotchas or constraints
- **5**: Some rules have rationale; no gotchas, deprecated patterns, or compliance context
- **10**: Rules have rationale and some gotchas documented; missing deprecated patterns or definition of done
- **15**: Complete — rationale on all non-obvious rules, gotchas, deprecated patterns with migration boundary, compliance context if applicable, definition of done

### Clarity (0-10)
- **0**: Dominated by vague verbs, contradictions, or audience mismatch
- **3**: Mix of actionable and vague instructions; some contradictions
- **7**: Mostly actionable; minor vagueness or one contradiction
- **10**: All instructions are specific, observable directives with no contradictions

### Environment (0-10)
- **0**: No build/test/lint commands
- **3**: Partial commands (e.g., test but no lint, no env vars)
- **7**: All key commands present; minor gaps (missing format or audit command, no working directory stated)
- **10**: Complete — build, test, lint, format, audit commands; env vars documented; git conventions stated

### Verification (0-5)
- **0**: No self-check instructions
- **2**: Some verification (e.g., "run tests") but no escalation or scope guardrails
- **4**: Self-check commands + escalation rules; minor gap in scope guardrails
- **5**: Complete — self-check, expected output anchors, escalation, scope guardrails

## Grade Mapping

| Score | Grade | Interpretation |
|---|---|---|
| 90-100 | A | Excellent — minor refinements only |
| 75-89 | B | Good — a few meaningful improvements available |
| 60-74 | C | Adequate — several gaps affecting Claude's effectiveness |
| 40-59 | D | Needs work — significant gaps causing Claude to underperform |
| 0-39 | F | Critical — security risks or fundamental gaps; start with the Minimum Viable template |

## Application Notes

- If a check genuinely doesn't apply to the project type (e.g., no build commands for a documentation-only repo), award full points for that category and note "N/A — project type" in the report.
- The score is a communication tool, not a precise measurement. Use judgment — a file with a score of 62 that has excellent security but no architecture context is in a very different position than one with a score of 62 that has good architecture but exposed credentials.
- Always pair the score with the "single most important change" recommendation. The score tells the team where they are; the recommendation tells them where to start.
