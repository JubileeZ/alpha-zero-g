#!/usr/bin/env bash
# tests/test-phase3.sh — TDD suite for Phase 3: apply-overlay.sh
#
# Run from repo root:  bash tests/test-phase3.sh
#
# What is tested:
#   1.  apply-overlay.sh shebang is #!/usr/bin/env bash
#   2.  No sed -i in apply-overlay.sh
#   3.  No ((VAR++)) in apply-overlay.sh
#   4.  apply-overlay.sh is sourceable and defines apply_overlay()
#   5.  apply_overlay: rm -rf old dest, cp -R from vendor, apply tool-map remap
#   6.  apply_overlay: SKILL.md frontmatter tool tokens are remapped correctly
#       (Read→read_file, Write→write_file, Edit→edit_file, Bash→run_command,
#        Grep→grep, Glob→glob)
#   7.  apply_overlay: unmapped tokens pass through unchanged
#   8.  apply_overlay: ANTIGRAVITY-NOTE.md is rendered from template with
#       {{SKILL_NAME}} substituted
#   9.  apply_overlay: per-skill overlay/ contents are copied additively
#  10.  apply_overlay: existing dest is replaced on each call (rm -rf + cp -R)
#  11.  apply_overlay: skills outside frontmatter are NOT rewritten
#  12.  apply_overlay: allowed-tools: line is also remapped (not just tools:)
#  13.  apply_overlay: works for all vendor skills (round-trip)
#  14.  azg setup now calls apply_overlay (post-Phase 3 regression)
#  15.  Installed skill SKILL.md has remapped tools in global dir
#  16.  Installed skill has ANTIGRAVITY-NOTE.md in global dir
#  17.  apply_overlay: body text tool names are NOT rewritten (frontmatter only)
#  18.  apply_overlay: multiple tools on one tools: line are all remapped
#  19.  apply-overlay.sh does not use sed -i (repeated guard, belt-and-suspenders)
#  20.  azg setup idempotency still holds after Phase 3 (run twice, no diff)
#
# Exit code: 0 if all tests pass, 1 if any fail.

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

# ---------------------------------------------------------------------------
# Skills vendored from mattpocock/skills (engineering/ + productivity/)
# Source of truth: templates/global/skills/vendor/VENDOR.lock
# These must exactly match what vendor-sync.sh fetches from upstream.
# DO NOT add custom/non-Matt skills here.
# ---------------------------------------------------------------------------
ENGINEERING_SKILLS=(
  "ask-matt"
  "code-review"
  "codebase-design"
  "diagnosing-bugs"
  "domain-modeling"
  "grill-with-docs"
  "implement"
  "improve-codebase-architecture"
  "prototype"
  "research"
  "resolving-merge-conflicts"
  "setup-matt-pocock-skills"
  "tdd"
  "to-spec"
  "to-tickets"
  "triage"
  "wayfinder"
)
PRODUCTIVITY_SKILLS=(
  "grill-me"
  "grilling"
  "handoff"
  "teach"
  "writing-great-skills"
)

# ---------------------------------------------------------------------------
# Build a mock vendor tree with realistic SKILL.md frontmatter for testing
# apply_overlay in isolation.
# ---------------------------------------------------------------------------
TEMP_DIR="$(mktemp -d "${PWD}/tmp_azg_phase3-test-XXXXXX")"
trap 'rm -rf "${TEMP_DIR}" "${TEMP_HOME:-}" "${TEMP_REPO:-}"' EXIT

# We create a mock vendor with realistic frontmatter (tools: + allowed-tools:)
MOCK_VENDOR="${TEMP_DIR}/vendor/mattpocock-skills"

_make_skill_md() {
  local skill="$1"
  # Realistic frontmatter with Claude-style tool names.
  # Both `tools:` and `allowed-tools:` lines should be remapped.
  # Body text should NOT be remapped (it contains names like "Read" in prose).
  cat <<'SKILLEOF'
---
name: SKILL_PLACEHOLDER
tools: [Read, Write, Edit, Bash, Grep, Glob, CustomTool]
allowed-tools: [Read, Write, Bash]
---
# Skill: SKILL_PLACEHOLDER

Use Read to read files. Use Write to write files. Use Bash to run commands.
This is body text that should NOT be tool-remapped.

## Steps

1. Read the file
2. Write output
3. Run Bash commands
SKILLEOF
  # Substitute SKILL_PLACEHOLDER with actual skill name (portable)
  # We write the raw content then substitute inline using our temp file trick
}

mkdir -p "${MOCK_VENDOR}/engineering"
mkdir -p "${MOCK_VENDOR}/productivity"

for skill in "${ENGINEERING_SKILLS[@]}"; do
  mkdir -p "${MOCK_VENDOR}/engineering/${skill}"
  content="---
name: ${skill}
tools: [Read, Write, Edit, Bash, Grep, Glob, CustomTool]
allowed-tools: [Read, Write, Bash]
---
# Skill: ${skill}

Use Read to read files. Use Write to write files. Use Bash to run commands.
This is body text that should NOT be tool-remapped.
"
  printf '%s' "${content}" > "${MOCK_VENDOR}/engineering/${skill}/SKILL.md"
done

for skill in "${PRODUCTIVITY_SKILLS[@]}"; do
  mkdir -p "${MOCK_VENDOR}/productivity/${skill}"
  content="---
name: ${skill}
tools: [Read, Write, Bash]
allowed-tools: [Read, Bash]
---
# Skill: ${skill}

Use Read to read files. Use Bash to run commands.
Body text — NOT remapped.
"
  printf '%s' "${content}" > "${MOCK_VENDOR}/productivity/${skill}/SKILL.md"
done

# Mock overlay with _shared template
MOCK_OVERLAY="${TEMP_DIR}/overlay/mattpocock-skills"
mkdir -p "${MOCK_OVERLAY}/_shared"

ANTIGRAVITY_TMPL="${MOCK_OVERLAY}/_shared/ANTIGRAVITY-NOTE.md.tmpl"
cp "${REPO_ROOT}/templates/global/skills/overlay/mattpocock-skills/_shared/ANTIGRAVITY-NOTE.md.tmpl" \
   "${ANTIGRAVITY_TMPL}"

TOOL_MAP="${MOCK_OVERLAY}/tool-map.json"
cp "${REPO_ROOT}/templates/global/skills/overlay/mattpocock-skills/tool-map.json" \
   "${TOOL_MAP}"

# Per-skill overlay example: tdd has an extra note
mkdir -p "${MOCK_OVERLAY}/tdd"
printf '# Extra TDD Note\nThis file is per-skill overlay content.\n' \
  > "${MOCK_OVERLAY}/tdd/EXTRA-NOTE.md"

# Destination (simulated ~/.gemini/antigravity-cli/skills/)
MOCK_DEST="${TEMP_DIR}/dest/skills"
mkdir -p "${MOCK_DEST}"

# ---------------------------------------------------------------------------
# Helper: invoke apply_overlay function in isolation (no azg dispatcher)
# ---------------------------------------------------------------------------
# apply_overlay SKILL_NAME VENDOR_DIR OVERLAY_DIR DEST_DIR
# We source common.sh + apply-overlay.sh, then call apply_overlay.
run_apply_overlay() {
  local skill="$1" vendor="$2" overlay="$3" dest="$4"
  bash -c "
    source '${REPO_ROOT}/lib/common.sh'
    source '${REPO_ROOT}/lib/apply-overlay.sh'
    apply_overlay '${skill}' '${vendor}' '${overlay}' '${dest}'
  "
}

# ---------------------------------------------------------------------------
# T E S T S
# ---------------------------------------------------------------------------

section "1. apply-overlay.sh — static code checks"

# Shebang
_shebang="$(head -1 "${REPO_ROOT}/lib/apply-overlay.sh")"
if [ "${_shebang}" = "#!/usr/bin/env bash" ]; then
  pass "apply-overlay.sh uses '#!/usr/bin/env bash' shebang"
else
  fail "apply-overlay.sh shebang wrong" "got: '${_shebang}'"
fi

# No sed -i
if grep -v '^[[:space:]]*#' "${REPO_ROOT}/lib/apply-overlay.sh" | grep -q 'sed -i'; then
  fail "apply-overlay.sh must NOT use 'sed -i' (BSD/GNU incompatible)"
else
  pass "apply-overlay.sh does not use 'sed -i'"
fi

# No ((VAR++))
if grep -v '^[[:space:]]*#' "${REPO_ROOT}/lib/apply-overlay.sh" | grep -qE '\(\([A-Za-z_]+\+\+\)\)'; then
  fail "apply-overlay.sh must NOT use ((VAR++))"
else
  pass "apply-overlay.sh does not use ((VAR++))"
fi

section "2. apply-overlay.sh — defines apply_overlay() and is sourceable"

if bash -c "
  source '${REPO_ROOT}/lib/common.sh' 2>/dev/null
  source '${REPO_ROOT}/lib/apply-overlay.sh' 2>/dev/null
  declare -f apply_overlay
" > /dev/null 2>&1; then
  pass "apply-overlay.sh defines apply_overlay() and sources without errors"
else
  fail "apply-overlay.sh must define apply_overlay() and source without errors"
fi

section "3. apply_overlay — no longer a stub (exits 0)"

assert_exit "apply_overlay exits 0 for a real skill" 0 \
  run_apply_overlay "tdd" \
    "${MOCK_VENDOR}/engineering" \
    "${MOCK_OVERLAY}" \
    "${MOCK_DEST}"

assert_output_not_contains "apply_overlay does not say 'not yet implemented'" \
  "not yet implemented" \
  run_apply_overlay "tdd" \
    "${MOCK_VENDOR}/engineering" \
    "${MOCK_OVERLAY}" \
    "${MOCK_DEST}"

section "4. apply_overlay — destination is created and populated"

assert_dir_exists "tdd destination dir exists after apply_overlay" \
  "${MOCK_DEST}/tdd"

assert_file_exists "tdd/SKILL.md exists in destination" \
  "${MOCK_DEST}/tdd/SKILL.md"

section "5. apply_overlay — tools: line remapped in frontmatter"

# Read → read_file
assert_file_contains "tools: line has 'read_file' after remap" \
  "${MOCK_DEST}/tdd/SKILL.md" "read_file"

# Write → write_file
assert_file_contains "tools: line has 'write_file' after remap" \
  "${MOCK_DEST}/tdd/SKILL.md" "write_file"

# Edit → edit_file
assert_file_contains "tools: line has 'edit_file' after remap" \
  "${MOCK_DEST}/tdd/SKILL.md" "edit_file"

# Bash → run_command
assert_file_contains "tools: line has 'run_command' after remap" \
  "${MOCK_DEST}/tdd/SKILL.md" "run_command"

# Grep → grep (unchanged name but should remain)
assert_file_contains "tools: line has 'grep' after remap" \
  "${MOCK_DEST}/tdd/SKILL.md" "grep"

# Glob → glob (unchanged name but should remain)
assert_file_contains "tools: line has 'glob' after remap" \
  "${MOCK_DEST}/tdd/SKILL.md" "glob"

section "6. apply_overlay — unmapped tokens pass through unchanged"

# CustomTool is not in tool-map.json — must survive
assert_file_contains "unmapped 'CustomTool' passes through" \
  "${MOCK_DEST}/tdd/SKILL.md" "CustomTool"

section "7. apply_overlay — upstream tool names removed from frontmatter"

# After remap, the original upstream names should NOT appear in tools:/allowed-tools: lines.
# We check specifically in the frontmatter (lines between --- markers).
_fm_end_line="$(grep -n '^---$' "${MOCK_DEST}/tdd/SKILL.md" | tail -1 | cut -d: -f1)"
_fm_content="$(head -n "${_fm_end_line}" "${MOCK_DEST}/tdd/SKILL.md")"

# "Read" alone (as a token, not "read_file") should NOT be in frontmatter tools: line
# We look for ", Read," or "[Read," or "Read]" patterns in frontmatter
if echo "${_fm_content}" | grep -E '^(tools|allowed-tools):' | grep -qE '\bRead\b'; then
  fail "original 'Read' token should be gone from frontmatter tools: after remap"
else
  pass "original 'Read' token gone from frontmatter tools: line"
fi

if echo "${_fm_content}" | grep -E '^(tools|allowed-tools):' | grep -qE '\bWrite\b'; then
  fail "original 'Write' token should be gone from frontmatter tools: after remap"
else
  pass "original 'Write' token gone from frontmatter tools: line"
fi

if echo "${_fm_content}" | grep -E '^(tools|allowed-tools):' | grep -qE '\bBash\b'; then
  fail "original 'Bash' token should be gone from frontmatter tools: after remap"
else
  pass "original 'Bash' token gone from frontmatter tools: line"
fi

section "8. apply_overlay — body text is NOT remapped"

# Body text contains "Use Read to read files." — "Read" should still appear in body.
# The body is after the closing --- of frontmatter.
_body_content="$(awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2{print}' "${MOCK_DEST}/tdd/SKILL.md")"

if echo "${_body_content}" | grep -q 'Use Read to read files'; then
  pass "body text 'Use Read to read files' preserved unchanged"
else
  fail "body text should NOT be remapped" \
    "expected 'Use Read to read files' in body, check: ${MOCK_DEST}/tdd/SKILL.md"
fi

if echo "${_body_content}" | grep -q 'Use Bash to run commands'; then
  pass "body text 'Use Bash to run commands' preserved unchanged"
else
  fail "body text should NOT be remapped (Bash)" \
    "expected 'Use Bash to run commands' in body"
fi

section "9. apply_overlay — allowed-tools: line is also remapped"

assert_file_matches "allowed-tools: line contains 'read_file'" \
  "${MOCK_DEST}/tdd/SKILL.md" "^allowed-tools:.*read_file"

assert_file_matches "allowed-tools: line contains 'run_command'" \
  "${MOCK_DEST}/tdd/SKILL.md" "^allowed-tools:.*run_command"

section "10. apply_overlay — ANTIGRAVITY-NOTE.md is rendered"

assert_file_exists "ANTIGRAVITY-NOTE.md created in destination" \
  "${MOCK_DEST}/tdd/ANTIGRAVITY-NOTE.md"

# {{SKILL_NAME}} must be substituted with the actual skill name
assert_file_not_contains "ANTIGRAVITY-NOTE.md has no raw {{SKILL_NAME}} placeholder" \
  "${MOCK_DEST}/tdd/ANTIGRAVITY-NOTE.md" "{{SKILL_NAME}}"

assert_file_contains "ANTIGRAVITY-NOTE.md contains the skill name 'tdd'" \
  "${MOCK_DEST}/tdd/ANTIGRAVITY-NOTE.md" "tdd"

assert_file_contains "ANTIGRAVITY-NOTE.md references 'Antigravity'" \
  "${MOCK_DEST}/tdd/ANTIGRAVITY-NOTE.md" "Antigravity"

section "11. apply_overlay — per-skill overlay contents copied additively"

# tdd has an EXTRA-NOTE.md in overlay/tdd/ — it should appear in dest/tdd/
assert_file_exists "per-skill overlay EXTRA-NOTE.md copied to destination" \
  "${MOCK_DEST}/tdd/EXTRA-NOTE.md"

assert_file_contains "per-skill overlay EXTRA-NOTE.md has expected content" \
  "${MOCK_DEST}/tdd/EXTRA-NOTE.md" "Extra TDD Note"

section "12. apply_overlay — existing dest replaced on re-run (rm -rf + cp -R)"

# Inject a sentinel file into the dest, then re-run — it should be gone
printf 'SENTINEL\n' > "${MOCK_DEST}/tdd/SENTINEL_SHOULD_BE_DELETED.md"

run_apply_overlay "tdd" \
  "${MOCK_VENDOR}/engineering" \
  "${MOCK_OVERLAY}" \
  "${MOCK_DEST}" > /dev/null 2>&1

if [ ! -f "${MOCK_DEST}/tdd/SENTINEL_SHOULD_BE_DELETED.md" ]; then
  pass "sentinel file removed on re-run (dest is rm -rf'd before copy)"
else
  fail "sentinel file should be gone after re-run of apply_overlay"
fi

# SKILL.md should still be present and remapped after re-run
assert_file_exists "SKILL.md present after re-run" "${MOCK_DEST}/tdd/SKILL.md"
assert_file_contains "tools: remapped correctly after re-run" \
  "${MOCK_DEST}/tdd/SKILL.md" "run_command"

section "13. apply_overlay — multiple tools on one line all remapped"

# Verify the full tools: line doesn't have leftover upstream names
_tools_line="$(grep '^tools:' "${MOCK_DEST}/tdd/SKILL.md" | head -1)"

if echo "${_tools_line}" | grep -qE '\bRead\b|\bWrite\b|\bEdit\b|\bBash\b'; then
  fail "tools: line still contains original upstream names" "got: '${_tools_line}'"
else
  pass "tools: line has no remaining original upstream names"
fi

# All mapped names must be present
for mapped in "read_file" "write_file" "edit_file" "run_command" "grep" "glob"; do
  if echo "${_tools_line}" | grep -qF "${mapped}"; then
    pass "tools: line contains '${mapped}'"
  else
    fail "tools: line missing '${mapped}'" "got: '${_tools_line}'"
  fi
done

section "14. apply_overlay — round-trip: all vendor skills processed without error"

_all_skills_ok=1
for skill in "${ENGINEERING_SKILLS[@]}"; do
  _exit=0
  run_apply_overlay "${skill}" \
    "${MOCK_VENDOR}/engineering" \
    "${MOCK_OVERLAY}" \
    "${MOCK_DEST}" > /dev/null 2>&1 || _exit=$?
  if [ "${_exit}" -eq 0 ]; then
    pass "engineering/${skill}: apply_overlay exits 0"
  else
    fail "engineering/${skill}: apply_overlay exited ${_exit}"
    _all_skills_ok=0
  fi
done

for skill in "${PRODUCTIVITY_SKILLS[@]}"; do
  _exit=0
  run_apply_overlay "${skill}" \
    "${MOCK_VENDOR}/productivity" \
    "${MOCK_OVERLAY}" \
    "${MOCK_DEST}" > /dev/null 2>&1 || _exit=$?
  if [ "${_exit}" -eq 0 ]; then
    pass "productivity/${skill}: apply_overlay exits 0"
  else
    fail "productivity/${skill}: apply_overlay exited ${_exit}"
    _all_skills_ok=0
  fi
done

section "15. azg setup — calls apply_overlay (end-to-end with mock vendor)"

# We need a TEMP_REPO with mock vendor populated so setup can run apply_overlay.
# Set up TEMP_REPO and TEMP_HOME for full integration.
TEMP_REPO="$(mktemp -d "${PWD}/tmp_azg_phase3-repo-XXXXXX")"
TEMP_HOME="$(mktemp -d "${PWD}/tmp_azg_phase3-home-XXXXXX")"

tar -cf - --exclude=.git --exclude='tmp_azg*' --exclude='tmp' -C "${REPO_ROOT}" . | tar -xf - -C "${TEMP_REPO}"
TEMP_AZG="${TEMP_REPO}/azg"

# Populate vendor in TEMP_REPO with our mock skills
TEMP_VENDOR="${TEMP_REPO}/templates/global/skills/vendor/mattpocock-skills"
mkdir -p "${TEMP_VENDOR}/engineering" "${TEMP_VENDOR}/productivity"

for skill in "${ENGINEERING_SKILLS[@]}"; do
  mkdir -p "${TEMP_VENDOR}/engineering/${skill}"
  printf -- "---\nname: %s\ntools: [Read, Write, Bash]\nallowed-tools: [Read]\n---\n# %s\nBody text with Read.\n" \
    "${skill}" "${skill}" > "${TEMP_VENDOR}/engineering/${skill}/SKILL.md"
done
for skill in "${PRODUCTIVITY_SKILLS[@]}"; do
  mkdir -p "${TEMP_VENDOR}/productivity/${skill}"
  printf -- "---\nname: %s\ntools: [Read, Bash]\nallowed-tools: [Read]\n---\n# %s\nBody text with Read.\n" \
    "${skill}" "${skill}" > "${TEMP_VENDOR}/productivity/${skill}/SKILL.md"
done

# Run azg setup with the temp repo and home
SETUP_EXIT=0
HOME="${TEMP_HOME}" AZG_ROOT="${TEMP_REPO}" "${TEMP_AZG}" setup --profile full > /dev/null 2>&1 \
  || SETUP_EXIT=$?

if [ "${SETUP_EXIT}" -eq 0 ]; then
  pass "azg setup exits 0 with mock vendor populated"
else
  fail "azg setup exited ${SETUP_EXIT} (expected 0)"
fi

GLOBAL_SKILLS="${TEMP_HOME}/.gemini/config/skills"

section "16. azg setup — installed skills have remapped SKILL.md"

_installed_with_remap=0
_installed_missing_remap=0
for skill in "${ENGINEERING_SKILLS[@]}" "${PRODUCTIVITY_SKILLS[@]}"; do
  skill_md="${GLOBAL_SKILLS}/${skill}/SKILL.md"
  if [ ! -f "${skill_md}" ]; then
    fail "SKILL.md missing for '${skill}'" "${skill_md}"
    _installed_missing_remap=$((_installed_missing_remap + 1))
    continue
  fi

  if grep -E '^(tools|allowed-tools):' "${skill_md}" | grep -qF "read_file"; then
    _installed_with_remap=$((_installed_with_remap + 1))
    pass "installed ${skill}/SKILL.md has 'read_file' (remap applied)"
  else
    fail "installed ${skill}/SKILL.md missing 'read_file' (remap NOT applied)" \
      "$(grep '^tools:' "${skill_md}")"
    _installed_missing_remap=$((_installed_missing_remap + 1))
  fi
done

section "17. azg setup — installed skills have ANTIGRAVITY-NOTE.md"

for skill in "${ENGINEERING_SKILLS[@]}" "${PRODUCTIVITY_SKILLS[@]}"; do
  assert_file_exists "installed ${skill}/ANTIGRAVITY-NOTE.md present" \
    "${GLOBAL_SKILLS}/${skill}/ANTIGRAVITY-NOTE.md"
done

section "18. azg setup — idempotency still holds after Phase 3"

# Second run of setup should exit 0 and produce same files
SETUP2_EXIT=0
HOME="${TEMP_HOME}" AZG_ROOT="${TEMP_REPO}" "${TEMP_AZG}" setup --profile full > /dev/null 2>&1 \
  || SETUP2_EXIT=$?

if [ "${SETUP2_EXIT}" -eq 0 ]; then
  pass "second azg setup run exits 0 (idempotent)"
else
  fail "second azg setup run exited ${SETUP2_EXIT} (expected 0)"
fi

# Spot-check: SKILL.md still has remap after second run
for skill in "tdd" "grill-me"; do
  assert_file_contains "idempotent: ${skill}/SKILL.md still has 'read_file'" \
    "${GLOBAL_SKILLS}/${skill}/SKILL.md" "read_file"
done

section "19. apply-overlay.sh — no sed -i (belt-and-suspenders check)"

if grep -v '^[[:space:]]*#' "${REPO_ROOT}/lib/apply-overlay.sh" | grep -q 'sed -i'; then
  fail "apply-overlay.sh must NOT use 'sed -i'"
else
  pass "apply-overlay.sh confirmed: no 'sed -i' present"
fi

section "20. Regression — Phase 0/1/2 stubs still correct after Phase 3"

# Commands that are still stubs (not yet implemented) must still exit non-zero.
# All commands implemented!

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
