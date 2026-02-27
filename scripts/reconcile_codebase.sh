#!/usr/bin/env bash
# reconcile_codebase.sh — Verify CLAUDE.md claims against the actual project
# Usage: ./reconcile_codebase.sh <project-root>
# Checks: generated directories, env vars, build files, directory structure

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <project-root>" >&2
  exit 2
fi

ROOT="$1"

if [[ ! -d "$ROOT" ]]; then
  echo "ERROR: Directory not found: $ROOT" >&2
  exit 2
fi

echo "=== Claudit Codebase Reconciliation ==="
echo "Project root: $ROOT"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# --- Detect project type from build files ---
echo "=== Detected Stack ==="
declare -a STACK_FILES=(
  "package.json:Node.js"
  "Cargo.toml:Rust"
  "go.mod:Go"
  "pyproject.toml:Python (pyproject)"
  "setup.py:Python (setup.py)"
  "requirements.txt:Python (requirements)"
  "Gemfile:Ruby"
  "pom.xml:Java (Maven)"
  "build.gradle:Java/Kotlin (Gradle)"
  "meson.build:Meson"
  "CMakeLists.txt:CMake"
  "Makefile:Make"
  "Dockerfile:Docker"
  "docker-compose.yml:Docker Compose"
  "docker-compose.yaml:Docker Compose"
  "terraform.tf:Terraform"
  "main.tf:Terraform"
  "serverless.yml:Serverless Framework"
  "tsconfig.json:TypeScript"
  "hugo.toml:Hugo"
  "hugo.yaml:Hugo"
  "hugo.json:Hugo"
  "config.toml:Hugo (legacy config)"
)

for entry in "${STACK_FILES[@]}"; do
  FILE="${entry%%:*}"
  LABEL="${entry##*:}"
  if [[ -f "$ROOT/$FILE" ]]; then
    echo "  $LABEL ($FILE)"
  fi
done
echo ""

# --- Monorepo detection ---
echo "=== Monorepo Detection ==="
MONOREPO_TYPE=""

# JavaScript/TypeScript monorepo tools
if [[ -f "$ROOT/pnpm-workspace.yaml" ]]; then
  MONOREPO_TYPE="pnpm"
  echo "  Type: pnpm (pnpm-workspace.yaml)"
elif [[ -f "$ROOT/lerna.json" ]]; then
  MONOREPO_TYPE="lerna"
  echo "  Type: Lerna (lerna.json)"
elif [[ -f "$ROOT/nx.json" ]]; then
  MONOREPO_TYPE="nx"
  echo "  Type: Nx (nx.json)"
elif [[ -f "$ROOT/rush.json" ]]; then
  MONOREPO_TYPE="rush"
  echo "  Type: Rush (rush.json)"
elif [[ -f "$ROOT/turbo.json" ]]; then
  MONOREPO_TYPE="turborepo"
  echo "  Type: Turborepo (turbo.json)"
elif [[ -f "$ROOT/package.json" ]] && command -v python3 &>/dev/null; then
  HAS_WORKSPACES=$(python3 -c "
import json
try:
    with open('$ROOT/package.json') as f:
        data = json.load(f)
    if 'workspaces' in data:
        print('yes')
except:
    pass
" 2>/dev/null)
  if [[ "$HAS_WORKSPACES" == "yes" ]]; then
    MONOREPO_TYPE="npm/yarn"
    echo "  Type: npm/yarn workspaces (package.json)"
  fi
fi

# Rust: Cargo workspace
if [[ -z "$MONOREPO_TYPE" && -f "$ROOT/Cargo.toml" ]]; then
  if grep -q '^\[workspace\]' "$ROOT/Cargo.toml" 2>/dev/null; then
    MONOREPO_TYPE="cargo"
    echo "  Type: Cargo workspace (Cargo.toml [workspace])"
    # List workspace members
    grep -A 20 '^\[workspace\]' "$ROOT/Cargo.toml" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p' | while read -r member; do
      if [[ -d "$ROOT/$member" ]]; then
        echo "    member: $member"
      fi
    done
  fi
fi

# Go: workspace mode
if [[ -z "$MONOREPO_TYPE" && -f "$ROOT/go.work" ]]; then
  MONOREPO_TYPE="go-workspace"
  echo "  Type: Go workspace (go.work)"
  grep '^[[:space:]]*./' "$ROOT/go.work" 2>/dev/null | sed 's/^[[:space:]]*/    module: /'
fi

# Java/Kotlin: Maven multi-module
if [[ -z "$MONOREPO_TYPE" && -f "$ROOT/pom.xml" ]]; then
  if grep -q '<modules>' "$ROOT/pom.xml" 2>/dev/null; then
    MONOREPO_TYPE="maven"
    echo "  Type: Maven multi-module (pom.xml <modules>)"
    sed -n 's/.*<module>\([^<]*\)<\/module>.*/\1/p' "$ROOT/pom.xml" 2>/dev/null | while read -r mod; do
      echo "    module: $mod"
    done
  fi
fi

# Java/Kotlin: Gradle multi-project
if [[ -z "$MONOREPO_TYPE" ]]; then
  SETTINGS_GRADLE=""
  if [[ -f "$ROOT/settings.gradle" ]]; then
    SETTINGS_GRADLE="$ROOT/settings.gradle"
  elif [[ -f "$ROOT/settings.gradle.kts" ]]; then
    SETTINGS_GRADLE="$ROOT/settings.gradle.kts"
  fi
  if [[ -n "$SETTINGS_GRADLE" ]] && grep -qE "include\s*['\(]" "$SETTINGS_GRADLE" 2>/dev/null; then
    MONOREPO_TYPE="gradle"
    echo "  Type: Gradle multi-project ($SETTINGS_GRADLE)"
    grep -E "include" "$SETTINGS_GRADLE" 2>/dev/null | sed "s/include//g;s/[\"'()]//g" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | while read -r proj; do
      [[ -n "$proj" ]] && echo "    project: $proj"
    done
  fi
fi

# Python: monorepo with multiple packages (multiple pyproject.toml in subdirs)
if [[ -z "$MONOREPO_TYPE" ]]; then
  PY_SUBPROJECTS=$(find "$ROOT" -maxdepth 2 -name "pyproject.toml" -not -path "$ROOT/pyproject.toml" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$PY_SUBPROJECTS" -ge 2 ]]; then
    MONOREPO_TYPE="python"
    echo "  Type: Python monorepo ($PY_SUBPROJECTS sub-packages with pyproject.toml)"
    find "$ROOT" -maxdepth 2 -name "pyproject.toml" -not -path "$ROOT/pyproject.toml" 2>/dev/null | sort | while read -r pf; do
      pkg_dir="${pf%/pyproject.toml}"
      pkg_name="${pkg_dir#$ROOT/}"
      echo "    package: $pkg_name"
    done
  fi
fi

# Bazel workspace
if [[ -z "$MONOREPO_TYPE" ]]; then
  if [[ -f "$ROOT/WORKSPACE" || -f "$ROOT/WORKSPACE.bazel" || -f "$ROOT/MODULE.bazel" ]]; then
    MONOREPO_TYPE="bazel"
    BAZEL_FILE="WORKSPACE"
    [[ -f "$ROOT/WORKSPACE.bazel" ]] && BAZEL_FILE="WORKSPACE.bazel"
    [[ -f "$ROOT/MODULE.bazel" ]] && BAZEL_FILE="MODULE.bazel"
    echo "  Type: Bazel workspace ($BAZEL_FILE)"
  fi
fi

# Pants build system
if [[ -z "$MONOREPO_TYPE" && -f "$ROOT/pants.toml" ]]; then
  MONOREPO_TYPE="pants"
  echo "  Type: Pants (pants.toml)"
fi

if [[ -n "$MONOREPO_TYPE" ]]; then
  # Scan common workspace directory patterns for build files
  echo "  Scanning workspace directories for build files..."
  for ws_dir in "$ROOT"/packages/*/ "$ROOT"/apps/*/ "$ROOT"/libs/*/ "$ROOT"/tools/*/ \
                "$ROOT"/services/*/ "$ROOT"/crates/*/ "$ROOT"/modules/*/ "$ROOT"/plugins/*/ \
                "$ROOT"/components/*/ "$ROOT"/internal/*/; do
    if [[ -d "$ws_dir" ]]; then
      ws_name="${ws_dir#$ROOT/}"
      ws_name="${ws_name%/}"
      for entry in "${STACK_FILES[@]}"; do
        FILE="${entry%%:*}"
        LABEL="${entry##*:}"
        if [[ -f "$ws_dir$FILE" ]]; then
          echo "    $ws_name: $LABEL ($FILE)"
        fi
      done
    fi
  done
else
  echo "  (not a monorepo)"
fi
echo ""

# --- Detect common generated / vendor / build directories ---
echo "=== Generated/Vendor/Build Directories ==="
declare -a GEN_DIRS=(
  "node_modules"
  "vendor"
  "dist"
  "build"
  ".next"
  "target"
  "__pycache__"
  ".tox"
  "coverage"
  ".nyc_output"
  "generated"
  "gen"
  "src/generated"
  "pkg/generated"
  ".terraform"
  ".serverless"
  "out"
  ".output"
  ".nuxt"
  ".cache"
  "egg-info"
)

GEN_FOUND=0
for d in "${GEN_DIRS[@]}"; do
  if [[ -d "$ROOT/$d" ]]; then
    echo "  FOUND: $d/"
    GEN_FOUND=$((GEN_FOUND + 1))
  fi
done
if [[ $GEN_FOUND -eq 0 ]]; then
  echo "  (none detected)"
fi
echo ""

# --- Detect environment variable files ---
echo "=== Environment Variable Files ==="
declare -a ENV_FILES=(
  ".env.example"
  ".env.template"
  ".env.sample"
  ".env.local.example"
  ".env.development"
  ".env.production"
)

for f in "${ENV_FILES[@]}"; do
  if [[ -f "$ROOT/$f" ]]; then
    echo "  FOUND: $f"
    echo "  Variables defined:"
    grep -E '^[A-Z_][A-Z0-9_]*=' "$ROOT/$f" 2>/dev/null | sed 's/=.*//' | sed 's/^/    /' || true
  fi
done
echo ""

# --- Directory structure ---
echo "=== Directory Structure ==="
# List directories up to depth 3, excluding hidden dirs and generated/vendor/build dirs
FIND_EXCLUDES=(
  -not -path '*/\.*'
  -not -path '*/node_modules*'
  -not -path '*/vendor*'
  -not -path '*/__pycache__*'
  -not -path '*/target*'
  -not -path '*/dist*'
  -not -path '*/build*'
  -not -path '*/.next*'
  -not -path '*/*egg-info*'
  -not -path '*/coverage'
  -not -path '*/coverage/*'
)
find "$ROOT" -maxdepth 3 -type d "${FIND_EXCLUDES[@]}" \
  2>/dev/null | sort | sed "s|$ROOT/||" | sed 's/^/  /' | head -100
echo ""

# --- Directory counts by depth (for CLAUDE.md verification) ---
echo "=== Directory Counts ==="
D1=$(find "$ROOT" -mindepth 1 -maxdepth 1 -type d "${FIND_EXCLUDES[@]}" 2>/dev/null | wc -l | tr -d ' ')
D2=$(find "$ROOT" -mindepth 2 -maxdepth 2 -type d "${FIND_EXCLUDES[@]}" 2>/dev/null | wc -l | tr -d ' ')
D3=$(find "$ROOT" -mindepth 3 -maxdepth 3 -type d "${FIND_EXCLUDES[@]}" 2>/dev/null | wc -l | tr -d ' ')
echo "  Depth 1: $D1 directories"
echo "  Depth 2: $D2 directories"
echo "  Depth 3: $D3 directories"
echo "  Total:   $((D1 + D2 + D3)) directories"
echo ""

# --- Check for CI/CD config (may contain build commands) ---
echo "=== CI/CD Configuration ==="
declare -a CI_FILES=(
  ".github/workflows"
  ".gitlab-ci.yml"
  "Jenkinsfile"
  ".circleci/config.yml"
  ".travis.yml"
  "bitbucket-pipelines.yml"
)

for f in "${CI_FILES[@]}"; do
  if [[ -e "$ROOT/$f" ]]; then
    echo "  FOUND: $f"
  fi
done
echo ""

# --- Extract likely build/test/lint commands from package.json ---
if [[ -f "$ROOT/package.json" ]]; then
  echo "=== package.json scripts ==="
  # Use python if available, otherwise grep
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
try:
    with open('$ROOT/package.json') as f:
        data = json.load(f)
    scripts = data.get('scripts', {})
    for k, v in scripts.items():
        print(f'  {k}: {v}')
except Exception as e:
    print(f'  Error reading package.json: {e}', file=sys.stderr)
" 2>/dev/null || echo "  (could not parse)"
  else
    echo "  (python3 not available for JSON parsing)"
  fi
  echo ""
fi

# --- Extract likely commands from Makefile ---
if [[ -f "$ROOT/Makefile" ]]; then
  echo "=== Makefile targets ==="
  grep -E '^[a-zA-Z0-9_-]+:' "$ROOT/Makefile" 2>/dev/null | sed 's/:.*$//' | sed 's/^/  /' | head -20
  echo ""
fi

echo "=== Reconciliation Complete ==="
echo ""
echo "Use this output to verify that the CLAUDE.md accurately reflects:"
echo "  1. The detected stack and project type"
echo "  2. All generated/vendor directories are listed as no-go zones"
echo "  3. Required environment variables are documented"
echo "  4. Build/test/lint commands match what the project actually uses"
echo "  5. The directory structure matches what the CLAUDE.md describes"
