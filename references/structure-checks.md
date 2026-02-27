# Check 2: Structure and File Hygiene

1. **Length and focus**: If the file exceeds 100 lines, evaluate whether every line is actively directing Claude. Flag anything that is background reading, policy documentation, or content duplicated from another file. A focused 150-line file is better than a bloated 60-line one — length is a proxy for focus, not quality.

2. **Linter and formatter instructions**: If the file instructs Claude on indentation, naming conventions, import ordering, or similar style rules, flag as MEDIUM. Deterministic tools (eslint, ruff, gofmt, prettier) enforce these better than prose. Remove and point to the tool config instead.

3. **Specialized topic bleed**: If code style, testing strategy, or security policy is present inline, suggest splitting into `.claude/rules/CODE-STYLE.md`, `.claude/rules/TESTING.md`, and `.claude/rules/SECURITY.md`. The main `CLAUDE.md` should reference these with a one-line description of when to consult each.

4. **Embedded file content**: If the file copy-pastes content from other source files (e.g., inlining a config file or pasting an entire API schema), flag it. Suggest replacing with `@path/to/file` dynamic imports so the content stays in sync with the source of truth. This is appropriate for small, authoritative files that Claude needs on every invocation (e.g., a shared types file or a project config).

5. **Large or conditional `@`-mentions**: The `@path/to/file` syntax causes Claude to read the referenced file on *every* invocation regardless of relevance. For documentation, READMEs, or large reference files, this wastes context. Flag as MEDIUM if large docs are `@`-imported. Instead, write a conditional reference: *"If you encounter a FooBarError or need advanced configuration, see `docs/troubleshooting.md`."* This lets Claude judge when to read. Reserve `@`-imports for small files that are always relevant.

6. **Configuration coherence with `.claude/`**: If the Pre-Scan found existing `.claude/rules/`, `.claude/commands/`, or `.claude/settings.json`, check that the `CLAUDE.md` is coherent with them. Common problems:
   - Prose tool restrictions in CLAUDE.md that duplicate `allowedTools`/`deniedTools` in settings.json — flag as MEDIUM; the setting is authoritative, the prose will drift.
   - Style rules in CLAUDE.md that restate what a rule file already covers — flag as MEDIUM; remove the duplicate.
   - Multi-step workflows described in prose that would be better as a custom command in `.claude/commands/` — flag as INFO.

7. **Token budget awareness**: CLAUDE.md competes for context window space with the system prompt, conversation history, tool results, and file contents. If the `scripts/scan_structure.sh` output shows the file exceeds ~2,000 tokens, note the approximate token count and what percentage of a typical context window it occupies before any work begins. Files above ~4,000 tokens should be actively trimmed or split.


