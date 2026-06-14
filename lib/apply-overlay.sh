#!/usr/bin/env bash
# lib/apply-overlay.sh — tool-map remap + ANTIGRAVITY-NOTE injection
#
# Implements the apply_overlay() contract from the Phase 3 plan:
#   1. rm -rf the destination under ~/.gemini/antigravity-cli/skills/<name>/
#   2. cp -R from vendor/mattpocock-skills/<category>/<name>/
#   3. Remap tools:/allowed-tools: lines in SKILL.md frontmatter only,
#      using tool-map.json. Unmapped tokens pass through unchanged.
#   4. Render _shared/ANTIGRAVITY-NOTE.md.tmpl → <dest>/ANTIGRAVITY-NOTE.md
#      with {{SKILL_NAME}} substituted.
#   5. If overlay/<name>/ exists, copy its contents into <dest>/ (additive).
#
# Usage:
#   apply_overlay SKILL_NAME VENDOR_CATEGORY_DIR OVERLAY_DIR DEST_DIR
#
#   SKILL_NAME           — e.g. "tdd"
#   VENDOR_CATEGORY_DIR  — e.g. "templates/global/skills/vendor/mattpocock-skills/engineering"
#   OVERLAY_DIR          — e.g. "templates/global/skills/overlay/mattpocock-skills"
#   DEST_DIR             — e.g. "~/.gemini/antigravity-cli/skills"
#
# Called by: azg setup (via setup.sh)
# Sourced by setup.sh; do NOT run directly.
#
# Cross-platform guarantees:
#   - No sed -i (uses tmp-file pattern via sed_portable from common.sh)
#   - No ((VAR++))
#   - #!/usr/bin/env bash shebang

# shellcheck source=lib/common.sh
# common.sh is already sourced by the dispatcher before this file is sourced.

apply_overlay() {
  local skill_name="${1}"
  local vendor_category_dir="${2}"
  local overlay_dir="${3}"
  local dest_dir="${4}"

  local skill_src="${vendor_category_dir}/${skill_name}"
  local skill_dest="${dest_dir}/${skill_name}"
  local skill_md="${skill_dest}/SKILL.md"
  local note_tmpl="${overlay_dir}/_shared/ANTIGRAVITY-NOTE.md.tmpl"
  local note_dest="${skill_dest}/ANTIGRAVITY-NOTE.md"
  local tool_map="${overlay_dir}/tool-map.json"
  local per_skill_overlay="${overlay_dir}/${skill_name}"

  # -------------------------------------------------------------------------
  # Validate inputs
  # -------------------------------------------------------------------------
  if [ -z "${skill_name}" ]; then
    die "apply_overlay: SKILL_NAME is required"
  fi

  if [ ! -d "${skill_src}" ]; then
    die "apply_overlay: vendor source not found: ${skill_src}"
  fi

  if [ ! -f "${note_tmpl}" ]; then
    die "apply_overlay: ANTIGRAVITY-NOTE.md.tmpl not found: ${note_tmpl}"
  fi

  if [ ! -f "${tool_map}" ]; then
    die "apply_overlay: tool-map.json not found: ${tool_map}"
  fi

  # -------------------------------------------------------------------------
  # Step 1 + 2: rm -rf destination, then cp -R from vendor
  # -------------------------------------------------------------------------
  rm -rf "${skill_dest}"
  cp -R "${skill_src}" "${skill_dest}"

  # -------------------------------------------------------------------------
  # Step 3: Remap tools:/allowed-tools: lines in SKILL.md frontmatter only
  # -------------------------------------------------------------------------
  if [ -f "${skill_md}" ]; then
    _remap_skill_frontmatter "${skill_md}" "${tool_map}"
  fi

  # -------------------------------------------------------------------------
  # Step 4: Render ANTIGRAVITY-NOTE.md.tmpl → ANTIGRAVITY-NOTE.md
  # -------------------------------------------------------------------------
  _render_antigravity_note "${note_tmpl}" "${note_dest}" "${skill_name}"

  # -------------------------------------------------------------------------
  # Step 5: If per-skill overlay exists, copy its contents additively
  # -------------------------------------------------------------------------
  if [ -d "${per_skill_overlay}" ]; then
    cp -R "${per_skill_overlay}/." "${skill_dest}/"
  fi

  ok "Overlay applied: ${skill_name}"
}

# ---------------------------------------------------------------------------
# _remap_skill_frontmatter SKILL_MD TOOL_MAP_JSON
#
# Rewrites only the `tools:` and `allowed-tools:` lines in the YAML frontmatter
# of SKILL_MD (the block between the first pair of `---` lines).
# Uses tool-map.json for the token substitutions.
# Body content (after the closing ---) is NEVER touched.
#
# Remapping is done with a pure-bash word-replacement approach so we never
# need to invoke jq at apply time (it may not be installed on all machines).
# tool-map.json keys are embedded at source time via a static lookup table.
# ---------------------------------------------------------------------------
_remap_skill_frontmatter() {
  local skill_md="${1}"
  local tool_map_json="${2}"

  # Build lookup pairs from tool-map.json using grep+sed (no jq required).
  # Expected format (one per line, indented, key-colon-value):
  #   "Read": "read_file",
  # We parse key and value out of each line.
  local tmp_map
  tmp_map="$(mktemp /tmp/azg-toolmap-XXXXXX)"
  # shellcheck disable=SC2064
  trap "rm -f '${tmp_map}'" RETURN

  # Extract lines like:  "Read": "read_file",
  # Output format per line: READ_KEY=mapped_value  (key is literal, value is literal)
  # We store them as: "FROM=TO" pairs, one per line.
  grep -E '"[^"]+": *"[^"]+"' "${tool_map_json}" | \
    sed 's/^[[:space:]]*"\([^"]*\)":[[:space:]]*"\([^"]*\)".*/\1=\2/' \
    > "${tmp_map}"

  # Now rewrite SKILL_MD:
  # - Find the frontmatter block (between first and second `---`)
  # - Only remap lines that start with `tools:` or `allowed-tools:` inside that block
  # - Leave everything else untouched.
  local tmp_out
  tmp_out="${skill_md}.azg.tmp"

  awk -v mapfile="${tmp_map}" '
    BEGIN {
      # Load the mapping into an awk associative array
      while ((getline line < mapfile) > 0) {
        n = index(line, "=")
        if (n > 0) {
          k = substr(line, 1, n-1)
          v = substr(line, n+1)
          mapping[k] = v
        }
      }
      close(mapfile)
      fm_count = 0   # counts how many --- we have seen
    }

    /^---$/ {
      fm_count++
      print
      next
    }

    # Inside frontmatter (between first and second ---)
    fm_count == 1 && /^(tools|allowed-tools):/ {
      line = $0
      # For each mapping entry, replace whole-word occurrences in this line.
      # We use a simple token replacement: look for the key surrounded by
      # non-identifier characters (spaces, brackets, commas).
      for (k in mapping) {
        v = mapping[k]
        # Replace all occurrences of k that are preceded and followed by
        # non-word boundary characters (or start/end of field).
        # awk does not support \b, so we use a character class approach:
        # match token boundaries: before k must be start-of-string, "[", " ", or ","
        # after k must be end-of-string, "]", " ", or ","
        # We iterate replacing until stable.
        prev = ""
        while (prev != line) {
          prev = line
          # Build the replacement using split trick
          result = ""
          remaining = line
          while (length(remaining) > 0) {
            # Find k in remaining
            pos = index(remaining, k)
            if (pos == 0) {
              result = result remaining
              remaining = ""
            } else {
              before = substr(remaining, 1, pos - 1)
              after = substr(remaining, pos + length(k))
              # Check boundary before k
              pre_char = (pos > 1) ? substr(before, length(before), 1) : ""
              # Check boundary after k
              post_char = (length(after) > 0) ? substr(after, 1, 1) : ""
              # Valid boundary chars: space, [, ], comma, empty (start/end)
              pre_ok  = (pre_char  == "" || pre_char  == " " || pre_char  == "[" || pre_char  == ",")
              post_ok = (post_char == "" || post_char == " " || post_char == "]" || post_char == ",")
              if (pre_ok && post_ok) {
                result = result before v
                remaining = after
              } else {
                # Not a clean word boundary — skip this occurrence
                result = result before k
                remaining = after
              }
            }
          }
          line = result
        }
      }
      print line
      next
    }

    # Everything else: print unchanged
    { print }
  ' "${skill_md}" > "${tmp_out}"

  mv "${tmp_out}" "${skill_md}"
}

# ---------------------------------------------------------------------------
# _render_antigravity_note TEMPLATE DEST SKILL_NAME
#
# Renders the ANTIGRAVITY-NOTE.md.tmpl to DEST, substituting {{SKILL_NAME}}.
# Uses the portable sed_portable helper (no sed -i).
# ---------------------------------------------------------------------------
_render_antigravity_note() {
  local tmpl="${1}"
  local dest="${2}"
  local skill_name="${3}"

  local tmp
  tmp="${dest}.azg.tmp"
  sed "s/{{SKILL_NAME}}/${skill_name}/g" "${tmpl}" > "${tmp}"
  mv "${tmp}" "${dest}"
}
