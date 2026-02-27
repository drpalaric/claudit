# Changelog

## 2026-02-27

### Fixed

- **All three scripts**: Converted all `grep -P` (PCRE) to `grep -E` (ERE) for macOS compatibility. BSD grep on macOS doesn't support `-P`, causing all pattern matches to silently fail — the `2>/dev/null` suppressed errors, so scans reported "clean" when they couldn't actually run. PCRE-specific features were translated: `\d` → `[0-9]`, `\w` → `[a-zA-Z0-9_]`, `\s` → `[[:space:]]`, `(?:...)` → `(...)`, `\b` dropped (patterns specific enough without word boundaries), `\x27` → shell quote-break for literal single quote. (Gotcha 1)

- **All three scripts**: Set execute permissions (`chmod +x`). Previously `-rw-r--r--`, now `-rwxr-xr-x`. (Gotcha 2)

- **scripts/scan_structure.sh**: Fixed pre-existing bug on line 65 where `grep -c` returning exit code 1 on zero matches combined with `|| echo "0"` produced `"0\n0"` instead of `"0"`, causing arithmetic error. Changed to `|| CODE_BLOCKS=0`.

- **scripts/scan_structure.sh** (lines 51, 55): Tightened @-import detection regex to require either a `/` path separator or a recognized file extension (20+ common types). Eliminates false positives from email addresses (`user@domain.com`), social mentions (`@security-team`), and Python decorators (`@dataclass`). (Gotcha 3)

### Added

- **scripts/reconcile_codebase.sh**: Monorepo detection section inserted after stack detection. Recognizes pnpm (`pnpm-workspace.yaml`), Lerna (`lerna.json`), Nx (`nx.json`), Rush (`rush.json`), Turborepo (`turbo.json`), and npm/yarn workspaces (`workspaces` key in `package.json`). Scans `packages/`, `apps/`, `libs/`, `tools/`, `services/` directories for per-workspace build files using the existing `STACK_FILES` array. (Gotcha 7)

- **SKILL.md** (Step 2): Fallback clause for when bash script execution is denied. Describes equivalent checks via Read, Glob, and Grep tools for secret scanning, structure analysis, and codebase reconciliation. (Gotcha 4)

### Changed

- **SKILL.md** (Step 2): Maturity assessment now uses score-based composite instead of configuration-breadth heuristic. Thresholds: 70+ or single file 85+ = Mature, 40-69 = Developing, <40 = Early-stage. Note added that maturity is finalized after Step 4 scoring and applied retroactively in the report. (Gotcha 6)

- **SKILL.md**: Trimmed Role section (removed prompt engineering/infosec mindset elaboration). Condensed "When to Apply" from 7 bullets to 4 by merging related items. (Gotcha 5)

- **references/examples.md**: Removed explanatory paragraphs before each of the 6 examples. Condensed BEFORE blocks to 1-2 representative lines each. All AFTER blocks preserved intact. Saved ~1,550 chars. (Gotcha 5)

- **references/architecture-checks.md**: Replaced 4-line intro with 1 line. Removed "Without this, Claude..." explanations from criteria 1-6. Criteria names, severity flags, and examples preserved. Saved ~910 chars. (Gotcha 5)

- **references/clarity-checks.md**: Removed intro sentence. Condensed verbose-writing criterion preamble and bullet point elaborations. Saved ~320 chars. (Gotcha 5)

- **references/knowledge-checks.md**: Replaced 9-line intro (including "Without institutional knowledge, Claude will:" list) with 2-line summary. Saved ~460 chars. (Gotcha 5)

### Files Changed

| File | Change Type |
|---|---|
| `scripts/scan_secrets.sh` | Modified (grep -P → grep -E, chmod +x) |
| `scripts/scan_structure.sh` | Modified (grep -P → grep -E, regex fix, code blocks bug, chmod +x) |
| `scripts/reconcile_codebase.sh` | Modified (grep -P → grep -E, monorepo detection, chmod +x) |
| `SKILL.md` | Modified (fallback clause, maturity, trimming) |
| `references/examples.md` | Modified (trimmed) |
| `references/architecture-checks.md` | Modified (trimmed) |
| `references/clarity-checks.md` | Modified (trimmed) |
| `references/knowledge-checks.md` | Modified (trimmed) |
| `CHANGELOG.md` | Created |

### Token Impact

Total skill character count: 51,478 → 48,604 (~2,874 chars net reduction / ~720 tokens saved). Trimming alone saved ~3,244 chars from reference files; SKILL.md grew by ~370 chars from new fallback clause and maturity note.
