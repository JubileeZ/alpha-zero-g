#!/usr/bin/env bash
# tests/test-phase7.sh — brownfield apply: preserve customs, refresh AZG-owned

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

TEMP_DIR="$(azg_mktemp_d "tmp_azg_phase7-XXXXXX")"

cd "${TEMP_DIR}"
mkdir test-repo
cd test-repo
git init -q
git commit --allow-empty -m "Init" -q

mkdir -p .agents/hooks .agents/skills/dummy-skill
cat << 'EOF' > .agents/hooks.json
{
  "existing-gate": {
    "enabled": true,
    "PreToolUse": []
  }
}
EOF
echo "dummy" > .agents/skills/dummy-skill/SKILL.md
echo "STALE_OWNED" > .agents/hooks/block-destructive-ops.sh
chmod +x .agents/hooks/block-destructive-ops.sh
echo "KEEP_CUSTOM" > .agents/hooks/my-custom.sh
chmod +x .agents/hooks/my-custom.sh

assert_exit "azg apply exits 0" 0 "${AZG}" apply .

if grep -q 'STALE_OWNED' .agents/hooks/block-destructive-ops.sh; then
  fail "AZG-owned hook should be refreshed from template"
else
  pass "AZG-owned block-destructive-ops.sh refreshed"
fi

assert_file_contains "Custom hook preserved" ".agents/hooks/my-custom.sh" "KEEP_CUSTOM"
assert_file_contains "Custom skill preserved" ".agents/skills/dummy-skill/SKILL.md" "dummy"

if [ "$(jq -r '."existing-gate".enabled' .agents/hooks.json)" = "true" ]; then
  pass "hooks.json existing key preserved"
else
  fail "hooks.json existing key lost"
fi

if [ "$(jq -r '."safety-gate".enabled' .agents/hooks.json)" = "true" ]; then
  pass "hooks.json safety-gate enabled from template"
else
  fail "hooks.json safety-gate should be enabled"
fi

assert_file_exists "AGENTS.md created from template" "AGENTS.md"

cat << 'EOF' > AGENTS.md
# Custom Header
Custom Content
<!-- AZG:MANAGED:START -->
Old Managed Content
<!-- AZG:MANAGED:END -->
Footer
EOF

assert_exit "azg apply again exits 0" 0 "${AZG}" apply .

assert_file_contains "Custom content preserved" "AGENTS.md" "Custom Content"
assert_file_not_contains "Old Managed Content replaced" "AGENTS.md" "Old Managed Content"
assert_file_contains "New Managed Content inserted" "AGENTS.md" "## Session start"
assert_file_contains "Footer preserved" "AGENTS.md" "Footer"

test_summary
