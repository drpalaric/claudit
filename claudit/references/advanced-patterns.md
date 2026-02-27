# Advanced CLAUDE.md Patterns

For teams already past the basics (score 70+), check whether the `CLAUDE.md` leverages these advanced Claude Code features. Flag as INFO if absent — these are opportunities, not problems.

1. **CLAUDE.md hierarchy**: Claude Code reads `CLAUDE.md` files at multiple levels — user-level (`~/.claude/CLAUDE.md`), project root, and subdirectories. If the project has components with different conventions (e.g., a `frontend/` and a `backend/`), suggest placing a `CLAUDE.md` in each subdirectory rather than overloading the root file. Claude merges them automatically, with more specific files taking precedence.

2. **`.claude.local.md` for personal preferences**: Personal preferences (editor settings, name, timezone, local paths) should live in `.claude.local.md` (added to `.gitignore`), not in the shared `CLAUDE.md`. This keeps the team file focused on project concerns.

3. **Rule files in `.claude/rules/`**: For projects with substantial style, testing, or security policies, does the team use `.claude/rules/*.md` to organize these by topic? Each rule file is automatically loaded as context. This keeps the root `CLAUDE.md` focused on project overview and key commands while letting specialized policies live in dedicated files.

4. **Custom slash commands**: Custom commands defined in `.claude/commands/` can encode team-specific workflows (e.g., `/review`, `/deploy-check`, `/onboard`). If the team has recurring multi-step workflows that they repeatedly explain to Claude, suggest packaging them as commands.

5. **Hooks**: Claude Code supports pre- and post-execution hooks in `.claude/settings.json` that can automate quality gates (e.g., auto-running linters after file edits). If the team relies on manual "remember to run X after Y" instructions in CLAUDE.md, suggest migrating deterministic checks to hooks instead — they're more reliable than prose instructions.

6. **Settings and permissions in `.claude/settings.json`**: If the CLAUDE.md contains instructions about which tools Claude should or shouldn't use, suggest encoding these as `allowedTools` or `deniedTools` in settings instead. Declarative permissions are harder to accidentally override than prose instructions.

7. **Cross-tool coherence**: If the project also has `.cursorrules`, `AGENTS.md`, or `copilot-instructions.md`, suggest aligning key constraints across all AI configuration files. Contradictions between these files mean different AI tools will behave inconsistently on the same codebase.
