#!/usr/bin/env bash
# lib/vendor-sync.sh — re-vendor mattpocock/skills from upstream
#
# Shallow-clones upstream (or uses AZG_VENDOR_UPSTREAM override for testing),
# copies skills/engineering/ and skills/productivity/ into the vendor tree,
# writes VENDOR.lock, and prints a diff summary.
#
# Called by: azg update --vendor  (via update.sh)
# Sourced by update.sh; do NOT run directly.
#
# Environment overrides (for testing):
#   AZG_VENDOR_UPSTREAM   Path or URL to the upstream git repo
#                         Defaults to: https://github.com/mattpocock/skills.git
#   AZG_ROOT              Root of the alpha-zero-g repo
#                         Defaults to: resolved at source time via common.sh

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
_VENDOR_UPSTREAM_DEFAULT="https://github.com/mattpocock/skills.git"
_VENDOR_INCLUDED_CATEGORIES=("engineering" "productivity")
_VENDOR_EXCLUDED_DIRS=("deprecated" "in-progress" "misc" "personal")
_VENDOR_LICENSE_DEFAULT="MIT (verify against upstream before publishing)"

vendor_sync() {
  # Respect AZG_ROOT from environment or fall back to the value set by common.sh
  local azg_root="${AZG_ROOT:-}"
  if [ -z "${azg_root}" ]; then
    azg_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  fi

  local upstream="${AZG_VENDOR_UPSTREAM:-${_VENDOR_UPSTREAM_DEFAULT}}"
  local vendor_base="${azg_root}/templates/global/skills/vendor/mattpocock-skills"
  local vendor_lock="${vendor_base}/VENDOR.lock"

  # -------------------------------------------------------------------------
  # Dependency check
  # -------------------------------------------------------------------------
  if ! command -v git > /dev/null 2>&1; then
    err "Required command 'git' not found."
    err "Install git from https://git-scm.com/downloads and re-run."
    return 1
  fi

  step "vendor-sync: starting"
  info "Upstream: ${upstream}"

  # -------------------------------------------------------------------------
  # Shallow clone into a temp directory
  # -------------------------------------------------------------------------
  local tmp_clone
  tmp_clone="$(mktemp -d "${PWD}/tmp_azg-vendor-clone-XXXXXX")"
  # Always clean up clone dir, even on error
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp_clone}'" RETURN

  info "Cloning upstream (shallow, sparse)…"

  # If upstream is a local path, plain clone is fine and faster.
  # For remote URLs we use --depth=1 --filter=blob:none --sparse.
  if [ -d "${upstream}" ]; then
    # Local repo (test mock or local mirror)
    git clone --quiet "${upstream}" "${tmp_clone}/repo" 2>/dev/null \
      || { err "git clone failed from: ${upstream}"; return 1; }
  else
    git clone --quiet --depth=1 --filter=blob:none --sparse \
      "${upstream}" "${tmp_clone}/repo" 2>/dev/null \
      || { err "git clone failed from: ${upstream}"; return 1; }
    git -C "${tmp_clone}/repo" sparse-checkout set \
      skills/engineering skills/productivity 2>/dev/null \
      || { err "git sparse-checkout failed"; return 1; }
  fi

  # Capture the pinned commit SHA (full 40-char)
  local commit_sha
  commit_sha="$(git -C "${tmp_clone}/repo" rev-parse HEAD 2>/dev/null)" \
    || { err "Could not determine HEAD commit SHA"; return 1; }

  info "Pinned commit: ${commit_sha}"

  # -------------------------------------------------------------------------
  # Replace vendor categories wholesale
  # -------------------------------------------------------------------------
  ensure_dir "${vendor_base}"

  local total_added=0
  local total_removed=0

  for category in "${_VENDOR_INCLUDED_CATEGORIES[@]}"; do
    local src_dir="${tmp_clone}/repo/skills/${category}"
    local dst_dir="${vendor_base}/${category}"

    if [ ! -d "${src_dir}" ]; then
      warn "Category '${category}' not found in upstream — skipping"
      continue
    fi

    # Count before (for diff summary)
    local before_count=0
    if [ -d "${dst_dir}" ]; then
      before_count="$(find "${dst_dir}" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
    fi

    # Wholesale replace
    rm -rf "${dst_dir}"
    cp -R "${src_dir}" "${dst_dir}"

    # Count after
    local after_count
    after_count="$(find "${dst_dir}" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"

    local diff_count
    diff_count=$((after_count - before_count))
    if [ "${diff_count}" -ge 0 ]; then
      total_added=$((total_added + diff_count))
    else
      total_removed=$((total_removed + (-diff_count)))
    fi

    info "  ${category}/: ${after_count} skills"
  done

  # -------------------------------------------------------------------------
  # Write VENDOR.lock (atomic)
  # -------------------------------------------------------------------------
  local today
  today="$(date -u '+%Y-%m-%d')"

  local lock_content
  lock_content="source: https://github.com/mattpocock/skills
commit: ${commit_sha}
date_vendored: ${today}
license: ${_VENDOR_LICENSE_DEFAULT}
included:
  - skills/engineering
  - skills/productivity
excluded:
  - skills/deprecated
  - skills/in-progress
  - skills/misc
  - skills/personal
"

  atomic_write "${vendor_lock}" "${lock_content}"

  # -------------------------------------------------------------------------
  # Diff summary
  # -------------------------------------------------------------------------
  ok "vendor-sync complete"
  info "  Commit  : ${commit_sha}"
  info "  Date    : ${today}"
  if [ "${total_added}" -gt 0 ] || [ "${total_removed}" -gt 0 ]; then
    info "  Changes : +${total_added} / -${total_removed} skill directories"
  else
    info "  Changes : none (already up-to-date)"
  fi
  info "  VENDOR.lock written to: ${vendor_lock}"
  ok "Run 'azg setup' on each device to push vendor changes to ~/.gemini/antigravity-cli/"
}
