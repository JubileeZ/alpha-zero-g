#!/usr/bin/env bash
set -e

source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

run_test() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd"; then
    pass "$name"
  else
    fail "$name"
  fi
}

cd "$TEST_DIR"
mkdir test-repo
cd test-repo
git init -q
git commit --allow-empty -m "Init" -q

# Pre-populate hooks.json and skills
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
echo "dummy hook" > .agents/hooks/block-destructive-ops.sh
chmod +x .agents/hooks/block-destructive-ops.sh

# Apply
"$REPO_ROOT/azg" apply .

run_test ".agents/hooks/quality-gate.sh copied" "[ -f \".agents/hooks/quality-gate.sh\" ]"
run_test "Existing hook not overwritten" "[ \"\$(cat .agents/hooks/block-destructive-ops.sh)\" = \"dummy hook\" ]"
run_test "hooks.json existing key preserved" "[ \"\$(jq -r '.\"existing-gate\".enabled' .agents/hooks.json)\" = \"true\" ]"
run_test "hooks.json default safety-gate added as false" "[ \"\$(jq -r '.\"safety-gate\".enabled' .agents/hooks.json)\" = \"false\" ]"
run_test "hooks.json default quality-gate added as false" "[ \"\$(jq -r '.\"quality-gate\".enabled' .agents/hooks.json)\" = \"false\" ]"

run_test "GEMINI.md created from template" "[ -f \"GEMINI.md\" ]"
run_test "AGENTS.md created from template" "[ -f \"AGENTS.md\" ]"

# Add custom content to GEMINI.md, run apply again to verify managed block update
cat << 'EOF' > GEMINI.md
# Custom Header
Custom Content
<!-- AZG:MANAGED:START -->
Old Managed Content
<!-- AZG:MANAGED:END -->
Footer
EOF

"$REPO_ROOT/azg" apply .

run_test "Custom content preserved" "grep -q 'Custom Content' GEMINI.md"
run_test "Old Managed Content replaced" "! grep -q 'Old Managed Content' GEMINI.md"
run_test "New Managed Content inserted" "grep -q '## Build and Test Commands' GEMINI.md"
run_test "Footer preserved" "grep -q 'Footer' GEMINI.md"

test_summary
