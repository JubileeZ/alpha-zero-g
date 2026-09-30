#!/usr/bin/env bash
# tests/test-phase10.sh — Portable Core: tests/verify.sh gate
#
# Behaviors:
#   1. azg new scaffolds executable tests/verify.sh
#   2. verify.sh exits 0 on a fresh scaffold
#   3. verify.sh exits non-zero when a required harness file is removed
#   4. commit-gate invokes verify.sh (not only test-harness.sh)

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

TEMP_WORKSPACE="$(azg_mktemp_d "tmp_azg_phase10-workspace-XXXXXX")"
TEMP_HOME="$(azg_mktemp_d "tmp_azg_phase10-home-XXXXXX")"

export HOME="${TEMP_HOME}"
export AZG_ROOT="${REPO_ROOT}"
export GIT_TERMINAL_PROMPT=0
export GIT_AUTHOR_NAME="Test User"
export GIT_AUTHOR_EMAIL="test@example.com"
export GIT_COMMITTER_NAME="Test User"
export GIT_COMMITTER_EMAIL="test@example.com"

section "1. Scaffold includes tests/verify.sh"

cd "${TEMP_WORKSPACE}"
assert_exit "azg new my-app succeeds" 0 "${AZG}" new my-app --no-git
APP_DIR="${TEMP_WORKSPACE}/my-app"

assert_file_exists "tests/verify.sh exists" "${APP_DIR}/tests/verify.sh"
assert_executable "tests/verify.sh is executable" "${APP_DIR}/tests/verify.sh"

section "2. verify.sh passes on fresh scaffold"

cd "${APP_DIR}"
assert_exit "verify.sh exits 0 on scaffold" 0 bash tests/verify.sh

section "3. verify.sh fails when required file missing"

mv AGENTS.md AGENTS.md.bak
assert_exit "verify.sh exits non-zero without AGENTS.md" 1 bash tests/verify.sh
mv AGENTS.md.bak AGENTS.md

section "4. commit-gate runs verify.sh"

COMMIT_GATE="${APP_DIR}/.agents/hooks/commit-gate.sh"
commit_json='{"toolCall":{"name":"run_command","args":{"CommandLine":"git commit -m \"chore: check\""}},"session_id":"test-session"}'

mv AGENTS.md AGENTS.md.bak
out=$(echo "${commit_json}" | "${COMMIT_GATE}")
mv AGENTS.md.bak AGENTS.md

if echo "${out}" | grep -qE '"decision"[[:space:]]*:[[:space:]]*"deny"'; then
  pass "commit-gate denies via verify.sh when harness incomplete"
else
  fail "commit-gate should deny when verify.sh fails" "got: ${out}"
fi

section "5. Work Packet template fields"

assert_file_contains "work-packet tmpl has Acceptance" \
  "${APP_DIR}/.agents/work-packet.md.tmpl" "**Acceptance:**"
assert_file_contains "work-packet tmpl has SFDBN" \
  "${APP_DIR}/.agents/work-packet.md.tmpl" "## Work Packet (SFDBN)"
assert_file_contains "work-packet tmpl has Next" \
  "${APP_DIR}/.agents/work-packet.md.tmpl" "**Next:**"

mkdir -p .agents/work-packets
printf '# Broken packet\n' > .agents/work-packets/broken.md
assert_exit "verify.sh exits non-zero for incomplete Work Packet" 1 bash tests/verify.sh
rm -f .agents/work-packets/broken.md

section "6. setup preflight requires jq"

# Hide real jq by constructing PATH without jq
_no_jq_dir="$(mktemp -d)"
for p in /bin/* /usr/bin/* /usr/local/bin/* /opt/homebrew/bin/*; do
  n="$(basename "$p")"
  if [ "$n" != "jq" ] && [ -x "$p" ] && [ ! -e "${_no_jq_dir}/$n" ]; then
    ln -s "$p" "${_no_jq_dir}/$n" 2>/dev/null || true
  fi
done
_setup_out="$(cd "${TEMP_WORKSPACE}" && env -u PATH PATH="${_no_jq_dir}" "${AZG}" setup 2>&1)" || _setup_rc=$?
_setup_rc="${_setup_rc:-0}"
find "${_no_jq_dir}" -type l -delete 2>/dev/null || true
rmdir "${_no_jq_dir}" 2>/dev/null || true

if [ "${_setup_rc}" -ne 0 ] && echo "${_setup_out}" | grep -qi 'jq'; then
  pass "azg setup fails fast when jq missing"
else
  fail "azg setup should fail with jq hint when jq unavailable" "rc=${_setup_rc} out=${_setup_out}"
fi

section "7. Cursor adapters scaffolded"

cd "${TEMP_WORKSPACE}"
# Fresh app for cursor checks (prior APP_DIR task.md may be corrupted)
assert_exit "azg new cursor-app succeeds" 0 "${AZG}" new cursor-app --no-git
CUR_DIR="${TEMP_WORKSPACE}/cursor-app"
assert_file_exists "Cursor .mdc rule exists" "${CUR_DIR}/.cursor/rules/read-agents-md.mdc"
assert_file_exists "Cursor hooks.json exists" "${CUR_DIR}/.cursor/hooks.json"
assert_file_exists "Cursor run-hook.cmd exists" "${CUR_DIR}/.cursor/hooks/run-hook.cmd"
assert_executable "commit-verify.sh executable" "${CUR_DIR}/.cursor/hooks/commit-verify.sh"

# Adapter denies when verify would fail
cd "${CUR_DIR}"
mv AGENTS.md AGENTS.md.bak
_cv_out=$(echo '{"command":"git commit -m test"}' | bash .cursor/hooks/commit-verify.sh)
mv AGENTS.md.bak AGENTS.md
if echo "${_cv_out}" | grep -qE '"permission"[[:space:]]*:[[:space:]]*"deny"'; then
  pass "Cursor commit-verify denies when verify fails"
else
  fail "Cursor commit-verify should deny" "got: ${_cv_out}"
fi

section "8. azg apply does not seed task.md"

cd "${TEMP_WORKSPACE}"
mkdir -p brownfield && cd brownfield
git init -q
git commit --allow-empty -m "init" -q
# apply requires jq — skip clearly if missing
if ! command -v jq >/dev/null 2>&1; then
  skip "azg apply packet test requires jq"
else
  assert_exit "azg apply succeeds" 0 "${AZG}" apply .
  assert_file_not_exists "apply does not seed task.md" "${TEMP_WORKSPACE}/brownfield/task.md"
  assert_file_exists "apply copies work-packet.md.tmpl" \
    "${TEMP_WORKSPACE}/brownfield/.agents/work-packet.md.tmpl"
fi

section "9. Checkpoint freshness requires Work Packet with code"

cd "${TEMP_WORKSPACE}"
assert_exit "azg new cp-app succeeds" 0 "${AZG}" new cp-app
CP_DIR="${TEMP_WORKSPACE}/cp-app"
cd "${CP_DIR}"
git config user.email "test@azg"
git config user.name "AZG Test"

# Stage code without Work Packet
mkdir -p src
echo "print(1)" > src/app.py
git add src/app.py
commit_json='{"toolCall":{"name":"run_command","args":{"CommandLine":"git commit -m \"feat: code without packet\""}}}'
_cp_out=$(echo "${commit_json}" | bash .agents/hooks/commit-gate.sh)
if echo "${_cp_out}" | grep -qE '"decision"[[:space:]]*:[[:space:]]*"deny"' && echo "${_cp_out}" | grep -qi 'Work Packet\|work-packets\|Checkpoint'; then
  pass "commit-gate denies code commit without staged Work Packet"
else
  fail "commit-gate should deny Checkpoint without work-packets path" "got: ${_cp_out}"
fi

# Stage updated Work Packet too → allow (verify still passes)
mkdir -p .agents/work-packets
cp "${AZG_ROOT}/templates/project/.agents/work-packet.md.tmpl" .agents/work-packets/checkpoint-test.md
# tmpl has {{TASK_NAME}} — still has SFDBN markers; add an unchecked todo (already in tmpl)
git add .agents/work-packets/checkpoint-test.md src/app.py
_cp_ok=$(echo "${commit_json}" | bash .agents/hooks/commit-gate.sh)
if echo "${_cp_ok}" | grep -qE '"decision"[[:space:]]*:[[:space:]]*"allow"'; then
  pass "commit-gate allows Checkpoint when Work Packet staged with code"
else
  fail "commit-gate should allow when work-packets path staged" "got: ${_cp_ok}"
fi

# Packet with no checkboxes is not finished (abandoned stay)
{
  echo "# Active Task: no-boxes"
  echo ""
  echo "- **Objective:** abandoned import"
  echo "- **Acceptance:** stay until user deletes"
  echo ""
  echo "## Work Packet (SFDBN)"
  echo ""
  echo "- **Status:** parked"
  echo "- **Files:** src/app.py"
  echo "- **Decisions:** none"
  echo "- **Blocked:** none"
  echo "- **Next:** user says done"
} > .agents/work-packets/no-boxes.md
git add .agents/work-packets/no-boxes.md src/app.py
_cp_nb=$(echo "${commit_json}" | bash .agents/hooks/commit-gate.sh)
if echo "${_cp_nb}" | grep -qE '"decision"[[:space:]]*:[[:space:]]*"allow"'; then
  pass "commit-gate allows packet with no checkboxes"
else
  fail "abandoned packet without checkboxes must not count as finished" "got: ${_cp_nb}"
fi

# Non-markdown file in .agents/work-packets/ is rejected by commit-gate
touch .agents/work-packets/sneak.py
git add .agents/work-packets/sneak.py
_cp_sneak=$(echo "${commit_json}" | bash .agents/hooks/commit-gate.sh)
if echo "${_cp_sneak}" | grep -qE '"decision"[[:space:]]*:[[:space:]]*"deny"' && echo "${_cp_sneak}" | grep -qi 'non-markdown'; then
  pass "commit-gate rejects non-markdown file in work-packets"
else
  fail "commit-gate must reject non-markdown file in work-packets" "got: ${_cp_sneak}"
fi
rm -f .agents/work-packets/sneak.py
git rm -f --cached .agents/work-packets/sneak.py 2>/dev/null || true

# commit-scan classifies non-markdown as code
source .agents/hooks/commit-scan.sh
azg_commit_classify_paths <<EOF
.agents/work-packets/sneak.py
EOF
if [ "${AZG_COMMIT_HAS_CODE}" = true ] && [ "${AZG_COMMIT_HAS_PACKET}" = false ]; then
  pass "commit-scan classifies non-markdown in work-packets as code"
else
  fail "commit-scan must classify non-markdown in work-packets as code" "has_code=${AZG_COMMIT_HAS_CODE} has_packet=${AZG_COMMIT_HAS_PACKET}"
fi

# Cursor commit-verify rejects non-markdown file
touch .agents/work-packets/sneak.py
_cursor_cv_out=$(echo '{"command":"git commit -m \"test\""}' | bash .cursor/hooks/commit-verify.sh)
if echo "${_cursor_cv_out}" | grep -qE '"permission"[[:space:]]*:[[:space:]]*"deny"' && echo "${_cursor_cv_out}" | grep -qi 'non-markdown'; then
  pass "Cursor commit-verify rejects non-markdown file in work-packets"
else
  fail "Cursor commit-verify must reject non-markdown file in work-packets" "got: ${_cursor_cv_out}"
fi
rm -f .agents/work-packets/sneak.py

section "10. azg apply refreshes AZG-owned hooks"

cd "${TEMP_WORKSPACE}"
mkdir -p upgrade-app/.agents/hooks
cd upgrade-app
git init -q
git commit --allow-empty -m "init" -q
printf 'STALE_OWNED_HOOK\n' > .agents/hooks/commit-gate.sh
chmod +x .agents/hooks/commit-gate.sh
printf 'KEEP_CUSTOM\n' > .agents/hooks/my-custom.sh
chmod +x .agents/hooks/my-custom.sh
cat > .agents/hooks.json <<'EOF'
{
  "existing-gate": {
    "enabled": true,
    "PreToolUse": []
  },
  "safety-gate": {
    "enabled": true,
    "SubagentStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "./hooks/spawn-budget.sh"
          }
        ]
      }
    ]
  }
}
EOF

assert_exit "azg apply upgrades owned hooks" 0 "${AZG}" apply .
if grep -q 'STALE_OWNED_HOOK' .agents/hooks/commit-gate.sh; then
  fail "apply should refresh AZG-owned commit-gate.sh"
else
  pass "apply refreshed AZG-owned commit-gate.sh"
fi
if grep -q 'KEEP_CUSTOM' .agents/hooks/my-custom.sh; then
  pass "apply preserved custom hook"
else
  fail "apply should not touch custom hooks"
fi
if [ "$(jq -r '."existing-gate".enabled' .agents/hooks.json)" = "true" ]; then
  pass "apply preserved existing hooks.json gate"
else
  fail "apply lost existing-gate"
fi
if [ "$(jq -r '."safety-gate".enabled' .agents/hooks.json)" = "true" ]; then
  pass "apply enables template safety-gate"
else
  fail "apply should enable safety-gate from template" "got: $(cat .agents/hooks.json)"
fi
if [ "$(jq -r '."safety-gate" | has("SubagentStart")' .agents/hooks.json)" = "false" ]; then
  pass "apply strips retired safety-gate.SubagentStart"
else
  fail "apply must delete SubagentStart (ADR 0006 double-count)" "got: $(jq -c '."safety-gate" | keys' .agents/hooks.json)"
fi
if ! grep -q 'spawn-budget' .agents/hooks.json; then
  pass "apply strips spawn-budget wires from hooks.json (ADR 0011)"
else
  fail "apply must remove spawn-budget from hooks.json" "got: $(cat .agents/hooks.json)"
fi

section "11. verify rejects repo-root tmp_azg leaks"

mkdir tmp_azg_leak
assert_exit "verify fails when tmp_azg* present" 1 bash tests/verify.sh
azg_rmtree tmp_azg_leak
assert_exit "verify passes after leak removed" 0 bash tests/verify.sh

section "12. harness scrub clears repo-root tmp_azg*"

mkdir -p "${REPO_ROOT}/tmp_azg_scrub_probe"
azg_scrub_root_leaks
assert_dir_not_exists "repo-root tmp_azg* scrubbed" "${REPO_ROOT}/tmp_azg_scrub_probe"

test_summary
