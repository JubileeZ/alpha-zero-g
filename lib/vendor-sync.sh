#!/usr/bin/env bash
# lib/vendor-sync.sh — re-vendor mattpocock/skills and ponytail skills from upstream
#
# Shallow-clones upstreams (or uses overrides for testing),
# copies skills into the vendor tree, writes VENDOR.lock, and prints summary.
#
# Called by: azg update --vendor  (via update.sh)
# Sourced by update.sh; do NOT run directly.

vendor_sync() {
  # Respect AZG_ROOT from environment or fall back to the value set by common.sh
  local azg_root="${AZG_ROOT:-}"
  if [ -z "${azg_root}" ]; then
    azg_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  fi

  local upstream_matt="${AZG_VENDOR_UPSTREAM:-https://github.com/mattpocock/skills.git}"
  local upstream_pony="${AZG_PONYTAIL_UPSTREAM:-https://github.com/DietrichGebert/ponytail.git}"

  # -------------------------------------------------------------------------
  # Dependency check
  # -------------------------------------------------------------------------
  if ! command -v git > /dev/null 2>&1; then
    err "Required command 'git' not found."
    err "Install git from https://git-scm.com/downloads and re-run."
    return 1
  fi

  # 1. Sync mattpocock-skills
  step "vendor-sync: syncing mattpocock-skills"
  _sync_one_repo "${upstream_matt}" "${azg_root}/templates/global/skills/vendor/mattpocock-skills" "skills/engineering skills/productivity" ""
  
  # 2. Sync ponytail-skills
  step "vendor-sync: syncing ponytail-skills"
  _sync_one_repo "${upstream_pony}" "${azg_root}/templates/global/skills/vendor/ponytail-skills" "skills" "ponytail"

  ok "vendor-sync complete"
  ok "Run 'azg setup' on each device to push vendor changes to ~/.gemini/antigravity-cli/"
}

_sync_one_repo() {
  local upstream="${1}"
  local dest_base="${2}"
  local sparse_dirs="${3}"
  local rename_category="${4:-}" # if set, copy tmp_clone/repo/skills to dest_base/$rename_category

  local today
  today="$(date -u '+%Y-%m-%d')"
  local vendor_lock="${dest_base}/VENDOR.lock"

  info "Upstream: ${upstream}"

  local tmp_clone
  tmp_clone="$(mktemp -d "${PWD}/tmp_azg-vendor-clone-XXXXXX")"
  # Always clean up clone dir, even on error
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp_clone}'" RETURN

  info "Cloning upstream (shallow, sparse)…"

  # If upstream is a local path, plain clone is fine and faster.
  if [ -d "${upstream}" ]; then
    git clone --quiet "${upstream}" "${tmp_clone}/repo" 2>/dev/null \
      || { err "git clone failed from: ${upstream}"; return 1; }
  else
    git clone --quiet --depth=1 --filter=blob:none --sparse \
      "${upstream}" "${tmp_clone}/repo" 2>/dev/null \
      || { err "git clone failed from: ${upstream}"; return 1; }
    # shellcheck disable=SC2086
    git -C "${tmp_clone}/repo" sparse-checkout set ${sparse_dirs} 2>/dev/null \
      || { err "git sparse-checkout failed"; return 1; }
  fi

  # Capture the pinned commit SHA (full 40-char)
  local commit_sha
  commit_sha="$(git -C "${tmp_clone}/repo" rev-parse HEAD 2>/dev/null)" \
    || { err "Could not determine HEAD commit SHA"; return 1; }

  info "Pinned commit: ${commit_sha}"

  ensure_dir "${dest_base}"

  local total_added=0
  local total_removed=0

  if [ -n "${rename_category}" ]; then
    local src_dir="${tmp_clone}/repo/skills"
    local dst_dir="${dest_base}/${rename_category}"

    if [ ! -d "${src_dir}" ]; then
      warn "skills/ directory not found in upstream — skipping"
      return 1
    fi

    # Count before
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

    local diff_count=$((after_count - before_count))
    if [ "${diff_count}" -ge 0 ]; then
      total_added=$((total_added + diff_count))
    else
      total_removed=$((total_removed + (-diff_count)))
    fi
    info "  ${rename_category}/: ${after_count} skills"
  else
    # Loop over categories inside sparse_dirs (which are space-separated)
    # shellcheck disable=SC2086
    for category_path in ${sparse_dirs}; do
      local category
      category="$(basename "${category_path}")"
      local src_dir="${tmp_clone}/repo/${category_path}"
      local dst_dir="${dest_base}/${category}"

      if [ ! -d "${src_dir}" ]; then
        warn "Category '${category}' not found in upstream — skipping"
        continue
      fi

      # Count before
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

      local diff_count=$((after_count - before_count))
      if [ "${diff_count}" -ge 0 ]; then
        total_added=$((total_added + diff_count))
      else
        total_removed=$((total_removed + (-diff_count)))
      fi
      info "  ${category}/: ${after_count} skills"
    done
  fi

  # Write VENDOR.lock (atomic)
  local lock_content
  lock_content="source: ${upstream}
commit: ${commit_sha}
date_vendored: ${today}"

  if [[ "${dest_base}" == *mattpocock-skills* ]]; then
    lock_content="${lock_content}
license: MIT (verify against upstream before publishing)
included:
  - skills/engineering
  - skills/productivity
excluded:
  - skills/deprecated
  - skills/in-progress
  - skills/misc
  - skills/personal"
  fi

  lock_content="${lock_content}
"
  atomic_write "${vendor_lock}" "${lock_content}"

  info "  Commit  : ${commit_sha}"
  info "  Date    : ${today}"
  if [ "${total_added}" -gt 0 ] || [ "${total_removed}" -gt 0 ]; then
    info "  Changes : +${total_added} / -${total_removed} skill directories"
  else
    info "  Changes : none (already up-to-date)"
  fi
  info "  VENDOR.lock written to: ${vendor_lock}"
}
