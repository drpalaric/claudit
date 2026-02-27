#!/usr/bin/env bash
# scan_secrets.sh — Deterministic secret and credential pattern scanner for CLAUDE.md files
# Usage: ./scan_secrets.sh <path-to-claude-md>
# Exit code: 0 = clean, 1 = findings detected, 2 = usage error

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

FOUND=0

echo "=== Claudit Secret Scan ==="
echo "File: $TARGET"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# --- AWS Access Key IDs ---
if grep -nP 'AKIA[A-Z0-9]{16}' "$TARGET" 2>/dev/null; then
  echo "CRITICAL: AWS Access Key ID detected (lines above)"
  FOUND=1
fi

# --- Private key material ---
if grep -n 'BEGIN.*PRIVATE KEY' "$TARGET" 2>/dev/null; then
  echo "CRITICAL: Private key material detected (lines above)"
  FOUND=1
fi

# --- Generic API keys/tokens/bearer tokens ---
# Looks for common patterns: key=, token=, bearer, api_key, apikey, secret=
if grep -niP '(api[_-]?key|api[_-]?secret|access[_-]?token|bearer\s+[A-Za-z0-9\-._~+/]+=*|auth[_-]?token)\s*[=:]\s*["\x27]?[A-Za-z0-9\-._~+/]{20,}' "$TARGET" 2>/dev/null; then
  echo "CRITICAL: API key or token pattern detected (lines above)"
  FOUND=1
fi

# --- Database connection strings with credentials ---
if grep -nP '(postgres|mysql|mongodb|redis|amqp)://[^:]+:[^@]+@' "$TARGET" 2>/dev/null; then
  echo "CRITICAL: Database connection string with embedded credentials (lines above)"
  FOUND=1
fi

# --- RFC-1918 private IP addresses ---
if grep -nP '\b(10\.\d{1,3}\.\d{1,3}\.\d{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3})\b' "$TARGET" 2>/dev/null; then
  echo "HIGH: RFC-1918 private IP address detected (lines above)"
  FOUND=1
fi

# --- Internal hostnames (common patterns) ---
if grep -niP '\b[a-z0-9-]+\.(internal|corp|local|lan|private|intranet)\b' "$TARGET" 2>/dev/null; then
  echo "HIGH: Internal hostname pattern detected (lines above)"
  FOUND=1
fi

# --- Hardcoded user home directories ---
if grep -nP '/(Users|home)/[a-zA-Z][a-zA-Z0-9._-]+/' "$TARGET" 2>/dev/null; then
  echo "MEDIUM: Hardcoded user home directory path detected (lines above)"
  FOUND=1
fi

# --- GitHub personal access tokens ---
if grep -nP 'ghp_[A-Za-z0-9]{36}' "$TARGET" 2>/dev/null; then
  echo "CRITICAL: GitHub personal access token detected (lines above)"
  FOUND=1
fi

# --- Slack tokens ---
if grep -nP 'xox[baprs]-[A-Za-z0-9\-]+' "$TARGET" 2>/dev/null; then
  echo "CRITICAL: Slack token detected (lines above)"
  FOUND=1
fi

# --- Generic high-entropy strings that look like secrets (base64, 40+ chars) ---
# Intentionally conservative — only flags in key/secret/token context
if grep -nP '(secret|password|credential|token)\s*[=:]\s*["\x27]?[A-Za-z0-9+/]{40,}=*' "$TARGET" 2>/dev/null; then
  echo "HIGH: High-entropy string in secret/password/token context (lines above)"
  FOUND=1
fi

echo ""
if [[ $FOUND -eq 0 ]]; then
  echo "RESULT: No secret patterns detected."
  exit 0
else
  echo "RESULT: One or more secret patterns detected. Review findings above."
  exit 1
fi
