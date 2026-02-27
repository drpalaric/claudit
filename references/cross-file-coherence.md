# Cross-File Coherence

When multiple CLAUDE.md files, rule files, settings.json, or parallel AI config files exist in the same project, check for coherence issues. These findings are tagged as "Project-wide" rather than attributed to a single file.

1. **Root vs. subdirectory contradictions**: If a root CLAUDE.md says "use npm" but a package-level CLAUDE.md says "use yarn", flag as MEDIUM. The more specific file takes precedence in Claude's merging behavior, but the contradiction creates confusion for humans reading the files.

2. **CLAUDE.md vs. rule file redundancy**: If a CLAUDE.md restates what a `.claude/rules/*.md` file already covers, flag as MEDIUM. The rule file is the authoritative location — the duplicate in CLAUDE.md will drift and create conflicting guidance.

3. **Prose vs. settings.json conflicts**: If the CLAUDE.md says "do not use bash to delete files" but `.claude/settings.json` does not include the relevant tool in `deniedTools`, flag as MEDIUM. The settings.json is the enforced boundary — the prose instruction can be overridden. Conversely, if `allowedTools` grants capabilities the CLAUDE.md doesn't discuss or that contradict its instructions, flag that too.

4. **Parallel config file contradictions**: If `.cursorrules`, `AGENTS.md`, or `copilot-instructions.md` exists alongside CLAUDE.md, check for contradictions in key constraints (build commands, style rules, architectural rules). Flag as INFO — different AI tools using contradictory config means inconsistent behavior across the team's tooling.

5. **Personal preferences in shared files**: If a shared CLAUDE.md contains developer names, local paths (`/Users/alice/`), personal editor preferences, or individual workflow customizations, flag as MEDIUM. These belong in `.claude.local.md` (which should be in `.gitignore`), not in the team-shared file.
