#!/usr/bin/env bash
# scan_structure.sh — Deterministic structure analysis for CLAUDE.md files
# Usage: ./scan_structure.sh <path-to-claude-md>
# Outputs: line count, word count, estimated token count, @-import count, section headers

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path-to-claude-md>" >&2
  exit 2
fi

TARGET="$1"

if [[ ! -f "$TARGET" ]]; then
  echo "ERROR: File not found: $TARGET" >&2
  exit 2
fi

echo "=== Claudit Structure Scan ==="
echo "File: $TARGET"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# --- Basic metrics ---
LINES=$(wc -l < "$TARGET")
WORDS=$(wc -w < "$TARGET")
CHARS=$(wc -c < "$TARGET")
# Rough token estimate: ~4 chars per token for English prose/code mix
TOKENS_EST=$(( CHARS / 4 ))

echo "Lines:            $LINES"
echo "Words:            $WORDS"
echo "Characters:       $CHARS"
echo "Estimated tokens: ~$TOKENS_EST"
echo ""

# --- Context budget warning ---
# Claude Code system prompt is ~50 instructions. Typical context is 128k-200k tokens.
# CLAUDE.md should ideally be <2000 tokens; >4000 is a concern.
if [[ $TOKENS_EST -gt 4000 ]]; then
  echo "WARNING: Estimated tokens ($TOKENS_EST) exceed 4,000. This file consumes significant context before any work begins. Consider trimming or splitting."
elif [[ $TOKENS_EST -gt 2000 ]]; then
  echo "NOTE: Estimated tokens ($TOKENS_EST) exceed 2,000. Review for content that could be moved to .claude/rules/ or conditional references."
else
  echo "Token budget: OK ($TOKENS_EST estimated tokens)"
fi
echo ""

# --- @-import detection ---
AT_IMPORTS=$(grep -cE '(^|[[:space:]])@([a-zA-Z0-9_./-]*/[a-zA-Z0-9_.-]+|[a-zA-Z0-9_./-]+\.(md|ts|tsx|js|jsx|json|py|go|rs|rb|sh|ya?ml|toml|css|html|sql|cfg|ini|txt))([[:space:]]|$)' "$TARGET" 2>/dev/null || echo "0")
echo "@-imports detected: $AT_IMPORTS"
if [[ "$AT_IMPORTS" -gt 0 ]]; then
  echo "  Files referenced via @-import (loaded on every invocation):"
  grep -nE '(^|[[:space:]])@([a-zA-Z0-9_./-]*/[a-zA-Z0-9_.-]+|[a-zA-Z0-9_./-]+\.(md|ts|tsx|js|jsx|json|py|go|rs|rb|sh|ya?ml|toml|css|html|sql|cfg|ini|txt))([[:space:]]|$)' "$TARGET" 2>/dev/null | sed 's/^/    /'
fi
echo ""

# --- Section headers ---
echo "Section headers found:"
grep -nE '^#{1,4}[[:space:]]' "$TARGET" 2>/dev/null | sed 's/^/  /' || echo "  (none)"
echo ""

# --- Embedded code blocks (potential inlined configs) ---
CODE_BLOCKS=$(grep -c '```' "$TARGET" 2>/dev/null) || CODE_BLOCKS=0
CODE_BLOCKS_PAIRS=$(( CODE_BLOCKS / 2 ))
echo "Code blocks: $CODE_BLOCKS_PAIRS"
echo ""

# --- Check for .claude/ sibling config ---
CLAUDE_DIR=$(dirname "$TARGET")
PROJECT_ROOT="$CLAUDE_DIR"
# If the CLAUDE.md is inside .claude/, go up one level
if [[ "$(basename "$CLAUDE_DIR")" == ".claude" ]]; then
  PROJECT_ROOT=$(dirname "$CLAUDE_DIR")
fi

echo "=== .claude/ Configuration ==="
if [[ -d "$PROJECT_ROOT/.claude" ]]; then
  # Rules
  if [[ -d "$PROJECT_ROOT/.claude/rules" ]]; then
    RULES_COUNT=$(find "$PROJECT_ROOT/.claude/rules" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')
    echo "  rules/:     $RULES_COUNT .md files"
  else
    echo "  rules/:     (not found)"
  fi

  # Commands
  if [[ -d "$PROJECT_ROOT/.claude/commands" ]]; then
    CMD_COUNT=$(find "$PROJECT_ROOT/.claude/commands" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')
    echo "  commands/:  $CMD_COUNT .md files"
  else
    echo "  commands/:  (not found)"
  fi

  # Settings
  if [[ -f "$PROJECT_ROOT/.claude/settings.json" ]]; then
    echo "  settings.json: found"
    # Check for allowedTools / deniedTools
    if grep -q 'allowedTools' "$PROJECT_ROOT/.claude/settings.json" 2>/dev/null; then
      echo "    - allowedTools configured"
    fi
    if grep -q 'deniedTools' "$PROJECT_ROOT/.claude/settings.json" 2>/dev/null; then
      echo "    - deniedTools configured"
    fi
  else
    echo "  settings.json: (not found)"
  fi

  # Local settings
  if [[ -f "$PROJECT_ROOT/.claude/settings.local.json" ]]; then
    echo "  settings.local.json: found"
  fi
else
  echo "  .claude/ directory not found"
fi

# --- .claude.local.md ---
if [[ -f "$PROJECT_ROOT/.claude.local.md" ]]; then
  echo "  .claude.local.md: found"
else
  echo "  .claude.local.md: (not found)"
fi
echo ""

# --- Parallel config files ---
echo "=== Parallel AI Config Files ==="
for f in ".cursorrules" "AGENTS.md" ".github/copilot-instructions.md" "copilot-instructions.md"; do
  if [[ -f "$PROJECT_ROOT/$f" ]]; then
    echo "  $f: found"
  fi
done
echo ""

# --- Subdirectory CLAUDE.md files ---
echo "=== Subdirectory CLAUDE.md Files ==="
find "$PROJECT_ROOT" -maxdepth 3 -name 'CLAUDE.md' -not -path "$TARGET" -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | sed 's/^/  /' || echo "  (none found)"
echo ""

echo "=== Scan Complete ==="
