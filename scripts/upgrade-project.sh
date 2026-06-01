#!/bin/bash
set -e

[ -d .git ] || [ -f AGENTS.md ] || { echo "Error: Not inside a valid project" >&2; exit 1; }

DRY_RUN=false; AUTO_CONFIRM=false
for arg in "$@"; do
  [ "$arg" = "--dry-run" ] && DRY_RUN=true
  [ "$arg" = "-y" ] || [ "$arg" = "--yes" ] && AUTO_CONFIRM=true
done

T_DIR="$(cd "$(dirname "$0")/../templates/project" 2>/dev/null && pwd || true)"
[ -d "$T_DIR" ] || { echo "Error: Templates directory not found at $T_DIR" >&2; exit 1; }

DIRS=(".agents" ".agents/rules" ".agents/skills" "docs" "docs/adr" "docs/research" "data" "data/raw" "data/interim" "data/processed" "src" "tests" "notebooks" "scripts")
FILES=("AGENTS.md" "GEMINI.md" "CLAUDE.md" ".agents/rules/code-style.md" ".agents/rules/safety.md" ".gitignore" ".skillsrc" "README.md")

echo "--- Alpha-Zero-G Project Upgrade Audit ---"
ADD=0; SKIP=0
for d in "${DIRS[@]}"; do
  if [ -d "$d" ]; then echo "[EXISTS]  Directory: $d"; ((SKIP++))
  else echo "[MISSING] Directory: $d"; ((ADD++)); fi
done
for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then echo "[EXISTS]  File: $f"; ((SKIP++))
  else echo "[MISSING] File: $f"; ((ADD++)); fi
done

$DRY_RUN && { echo "Dry-run mode. Stopping."; exit 0; }
if [ "$AUTO_CONFIRM" = "false" ] && [ -t 0 ]; then
  read -p "Proceed with upgrade? (y/N): " -r resp
  [[ ! "$resp" =~ ^[Yy]$ ]] && { echo "Upgrade cancelled."; exit 0; }
fi

PROJ_NAME=$(basename "$PWD")
for d in "${DIRS[@]}"; do [ -d "$d" ] || mkdir -p "$d"; done

write_file() {
  local f="$1"
  [ -f "$f" ] && return
  case "$f" in
    AGENTS.md) sed "s/{{PROJECT_NAME}}/$PROJ_NAME/g" "$T_DIR/AGENTS.md" > "$f" ;;
    GEMINI.md) cp "$T_DIR/GEMINI.md" "$f" ;;
    CLAUDE.md) cp "$T_DIR/CLAUDE.md" "$f" ;;
    .agents/rules/code-style.md) cp "$T_DIR/.agents/rules/code-style.md" "$f" ;;
    .agents/rules/safety.md) cp "$T_DIR/.agents/rules/safety.md" "$f" ;;
    .gitignore) cp "$T_DIR/gitignore.template" "$f" ;;
    .skillsrc) cp "$T_DIR/skillsrc.template" "$f" ;;
    README.md) sed -e "s/{{PROJECT_NAME}}/$PROJ_NAME/g" -e "s/{{PROJECT_DESCRIPTION}}//g" "$T_DIR/README.md" > "$f" ;;
  esac
}

for f in "${FILES[@]}"; do
  if [ "$f" = "AGENTS.md" ] && [ -f "AGENTS.md" ]; then
    if ! grep -q "## Alpha-Zero-G" AGENTS.md; then
      cat <<EOF >> AGENTS.md

## Alpha-Zero-G
- **Deterministic Python**: Always execute via \`uv run\` (\`uv run pytest\`, \`uv run python\`).
- **No Symlink Portability**: All project rules are physical copies and use relative links.
- **Explicit Typings**: Require strict type hints in Python.
EOF
    fi
  else
    write_file "$f"
  fi
done

MAX=0
if [ -d docs/adr ]; then
  for file in docs/adr/ADR-*.md; do
    if [ -e "$file" ]; then
      base=$(basename "$file")
      num=$(echo "$base" | sed -E 's/ADR-([0-9]+)-.*/\1/')
      clean=$(echo "$num" | sed 's/^0*//')
      [ -z "$clean" ] && clean=0
      (( clean > MAX )) && MAX=$clean
    fi
  done
fi
NEXT=$((MAX + 1))
NEXT_PAD=$(printf "%03d" $NEXT)
DATE_STR=$(date +%Y-%m-%d)
ADR_FILE="docs/adr/ADR-${NEXT_PAD}-alpha-zero-g-upgrade.md"

cat <<EOF > "$ADR_FILE"
# ADR-${NEXT_PAD}: Alpha-Zero-G Upgrade
**Status:** Accepted
**Date:** $DATE_STR

## Context
We need to upgrade the existing project to the latest Alpha-Zero-G canonical structure.

## Decision
Upgrade the project structure, append missing instructions to AGENTS.md, and ensure all canonical files/directories are present.

## Alternatives Considered
- Manual upgrade: Rejected because it is error-prone and time-consuming.

## Consequences
- Good: Project aligns with the latest Alpha-Zero-G standards.
- Bad: None.
EOF
((ADD++))

echo "Upgrade complete. $ADD items added, $SKIP items skipped (already present)."
