# Check 4: Institutional Knowledge and Project Nuance

Documents the "why" behind constraints, the gotchas that cause incidents, and deprecated-but-present patterns.

## Criteria

1. **Rationale for non-obvious constraints**: Every rule in CLAUDE.md that isn't self-evident should include a one-line "why." A rule without a reason gets treated as optional. Compare:
   - Weak: *"Do not use `eval()`."*
   - Strong: *"Do not use `eval()` — two separate XSS incidents traced to this in 2023/2024."*
   - Weak: *"Don't modify the auth middleware."*
   - Strong: *"The auth middleware has a known race condition in session refresh (see issue #1847). Changes require review from @security-team."*

2. **Known footguns and gotchas**: Are there non-obvious dangerous spots in the codebase documented? These are the things that only surface in postmortems. If the team knows about them, Claude should too. Look for signals of undocumented tribal knowledge: patterns that are *unusual or unconventional*, *opinionated*, or *consistent across multiple files but never explained*. If the CLAUDE.md contains rules but no footguns, that's a gap — every mature codebase has them. Flag as MEDIUM if absent. Example: *"`UserPreferences.save()` is not idempotent — calling it twice in the same request will duplicate entries. Always check existence before calling."*

3. **Deprecated patterns and migration state**: If parts of the codebase use old patterns that are being phased out, document the boundary clearly. Without this, Claude will either replicate the old pattern (following existing code) or attempt to refactor everything at once (over-helping). Flag as HIGH if deprecated patterns exist without documentation. Example: *"The `legacy/` directory uses callback-style async. All new code uses `async/await`. Do not add new callback-style code anywhere. Do not refactor `legacy/` without a migration ticket."*

4. **Performance-sensitive and high-risk paths**: Are there components where Claude should apply extra scrutiny or always ask before modifying? High-traffic endpoints, payment flows, auth paths, and data migration scripts all warrant explicit flagging. Example: *"The `payments/` service processes live transactions. Any change here requires a manual review step — do not ship a change to this directory without flagging it to the user first."*

5. **Compliance and regulatory context**: For teams in regulated industries, does the file state the compliance frame? Without it, Claude cannot make appropriate trade-offs. Example: *"This product is SOC 2 Type II certified. All new data fields that store user information must be reviewed before shipping. Do not add logging of request payloads — that would create a PII audit issue."*

6. **Definition of done by task type**: Different tasks require different completion criteria, and CLAUDE.md rarely defines them. Flag as MEDIUM if absent. Suggest:
   ```
   Bug fix:       Tests pass, root cause explained, no unrelated changes
   New feature:   Tests pass, docs updated if user-facing, lint clean
   Refactor:      Behavior unchanged (verified by tests), no new abstractions
   Security fix:  Reported to user before fixing, tests added for the vuln
   Dependency:    Vulnerability audit clean, changelog reviewed for breaking changes
   ```
