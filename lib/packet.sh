#!/usr/bin/env bash
# lib/packet.sh — Manage .agents/work-packets/ lifecycle
# Bash 3.2 safe. Sourced by azg dispatcher.

if [ -z "${AZG_ROOT:-}" ]; then
  AZG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# shellcheck source=lib/common.sh
source "${AZG_ROOT}/lib/common.sh"

_load_packet_scan() {
  if [ -f ".agents/hooks/commit-scan.sh" ]; then
    # shellcheck source=/dev/null
    source ".agents/hooks/commit-scan.sh"
  elif [ -f "${AZG_ROOT}/templates/project/.agents/hooks/commit-scan.sh" ]; then
    # shellcheck source=/dev/null
    source "${AZG_ROOT}/templates/project/.agents/hooks/commit-scan.sh"
  fi
}

cmd_packet_list() {
  local dir="${1:-.agents/work-packets}"
  if [ ! -d "${dir}" ]; then
    info "No work packets directory found at '${dir}'."
    return 0
  fi

  shopt -s nullglob
  local pkts=("${dir}"/*.md)
  shopt -u nullglob

  if [ "${#pkts[@]}" -eq 0 ]; then
    info "No work packets found under '${dir}'."
    return 0
  fi

  _load_packet_scan

  printf "%-30s %-16s %-10s %s\n" "PACKET" "STATUS" "TODOS" "LIFECYCLE"
  printf "%-30s %-16s %-10s %s\n" "------" "------" "-----" "---------"

  local pkt
  for pkt in "${pkts[@]}"; do
    local base
    base="$(basename "${pkt}" .md)"
    local status
    status=$(grep -iE '^[[:space:]]*(-[[:space:]]+)?(\*\*)?[Ss]tatus:?' "${pkt}" 2>/dev/null | head -n1 | sed -E 's/^[[:space:]]*(-[[:space:]]+)?(\*\*)?[Ss]tatus:?(\*\*)?[[:space:]]*//' | tr -d '\r\n')
    [ -z "${status}" ] && status="Unknown"

    local checked open total
    checked=$(grep -c -E '\- \[[xX]\]' "${pkt}" 2>/dev/null || true)
    open=$(grep -c -E '\- \[[[:space:]]*\]' "${pkt}" 2>/dev/null || true)
    checked="${checked:-0}"
    open="${open:-0}"
    total=$((checked + open))

    local lifecycle="Active"
    if type azg_packet_is_finished >/dev/null 2>&1 && azg_packet_is_finished "${pkt}"; then
      lifecycle="Finished"
    elif echo "${status}" | grep -qi 'parked'; then
      lifecycle="Parked"
    elif echo "${status}" | grep -qi 'blocked'; then
      lifecycle="Blocked"
    fi

    printf "%-30s %-16s %-10s %s\n" "${base}" "${status}" "${checked}/${total}" "${lifecycle}"
  done
}

cmd_packet_close() {
  local id="${1:-}"
  if [ -z "${id}" ]; then
    err "Usage: azg packet close <packet-id>"
    exit 1
  fi

  local pkt="${id}"
  [[ "${pkt}" != *.md ]] && pkt="${pkt}.md"
  [[ "${pkt}" != .agents/work-packets/* ]] && pkt=".agents/work-packets/${pkt}"

  if [ ! -f "${pkt}" ]; then
    err "Work packet not found: ${pkt}"
    exit 1
  fi

  rm -f "${pkt}"
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git rm -f --cached "${pkt}" >/dev/null 2>&1 || true
  fi
  ok "Closed and deleted work packet: ${pkt}"
}

cmd_packet_prune() {
  local dir="${1:-.agents/work-packets}"
  if [ ! -d "${dir}" ]; then
    info "No work packets directory found at '${dir}'."
    return 0
  fi

  shopt -s nullglob
  local pkts=("${dir}"/*.md)
  shopt -u nullglob

  if [ "${#pkts[@]}" -eq 0 ]; then
    info "No work packets found under '${dir}'."
    return 0
  fi

  _load_packet_scan

  local pruned=0
  local pkt
  for pkt in "${pkts[@]}"; do
    if type azg_packet_is_finished >/dev/null 2>&1 && azg_packet_is_finished "${pkt}"; then
      rm -f "${pkt}"
      if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git rm -f --cached "${pkt}" >/dev/null 2>&1 || true
      fi
      ok "Pruned finished work packet: ${pkt}"
      pruned=$((pruned + 1))
    fi
  done

  if [ "${pruned}" -eq 0 ]; then
    info "No finished work packets to prune."
  else
    ok "Successfully pruned ${pruned} finished work packet(s)."
  fi
}

cmd_packet() {
  local subcmd="${1:-list}"
  shift || true

  case "${subcmd}" in
    list)
      cmd_packet_list "$@"
      ;;
    close)
      cmd_packet_close "$@"
      ;;
    prune)
      cmd_packet_prune "$@"
      ;;
    *)
      err "Unknown packet subcommand: '${subcmd}'"
      echo "Usage: azg packet [list|close <id>|prune]"
      exit 1
      ;;
  esac
}
