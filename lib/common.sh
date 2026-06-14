#!/usr/bin/env bash
# lib/common.sh — shared helpers for all azg subcommands
# Source this file: source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
# POSIX-safe: no sed -i, no ((VAR++)) with set -e, no bashisms beyond arrays

set -euo pipefail

# ---------------------------------------------------------------------------
# Version
# ---------------------------------------------------------------------------
AZG_VERSION="$(cat "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/VERSION" 2>/dev/null || echo "unknown")"
AZG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------------------------------------------------------------------------
# Colors (disabled when not a terminal or NO_COLOR is set)
# ---------------------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  CLR_RESET="\033[0m"
  CLR_BOLD="\033[1m"
  CLR_RED="\033[0;31m"
  CLR_GREEN="\033[0;32m"
  CLR_YELLOW="\033[0;33m"
  CLR_BLUE="\033[0;34m"
  CLR_CYAN="\033[0;36m"
  CLR_DIM="\033[2m"
else
  CLR_RESET=""
  CLR_BOLD=""
  CLR_RED=""
  CLR_GREEN=""
  CLR_YELLOW=""
  CLR_BLUE=""
  CLR_CYAN=""
  CLR_DIM=""
fi

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
info()    { printf "${CLR_BLUE}[azg]${CLR_RESET} %s\n" "$*"; }
ok()      { printf "${CLR_GREEN}[azg]${CLR_RESET} %s\n" "$*"; }
warn()    { printf "${CLR_YELLOW}[azg warn]${CLR_RESET} %s\n" "$*" >&2; }
err()     { printf "${CLR_RED}[azg error]${CLR_RESET} %s\n" "$*" >&2; }
die()     { err "$*"; exit 1; }
step()    { printf "${CLR_CYAN}[azg]${CLR_RESET} ${CLR_BOLD}%s${CLR_RESET}\n" "$*"; }

# ---------------------------------------------------------------------------
# OS detection
# ---------------------------------------------------------------------------
# Sets: AZG_OS ("linux" | "macos" | "unknown")
#       AZG_ARCH ("x86_64" | "arm64" | "unknown")
detect_os() {
  local uname_s
  uname_s="$(uname -s 2>/dev/null || echo "Unknown")"
  case "${uname_s}" in
    Linux*)  AZG_OS="linux"   ;;
    Darwin*) AZG_OS="macos"   ;;
    *)       AZG_OS="unknown" ;;
  esac

  local uname_m
  uname_m="$(uname -m 2>/dev/null || echo "unknown")"
  case "${uname_m}" in
    x86_64|amd64) AZG_ARCH="x86_64" ;;
    arm64|aarch64) AZG_ARCH="arm64" ;;
    *) AZG_ARCH="unknown" ;;
  esac
}

detect_os

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------
# require_cmd CMD [INSTALL_HINT]
# Exits non-zero with an install hint if CMD is not in PATH.
require_cmd() {
  local cmd="${1}"
  local hint="${2:-}"
  if ! command -v "${cmd}" > /dev/null 2>&1; then
    if [ -n "${hint}" ]; then
      die "Required command '${cmd}' not found. ${hint}"
    else
      die "Required command '${cmd}' not found."
    fi
  fi
}

# Checks for jq; prints OS-specific install hint and exits if missing.
require_jq() {
  if command -v jq > /dev/null 2>&1; then
    return 0
  fi
  local hint
  case "${AZG_OS}" in
    linux)
      # Detect distro for a better hint
      if command -v pacman > /dev/null 2>&1; then
        hint="Install with: sudo pacman -S jq  (or: paru -S jq)"
      elif command -v apt-get > /dev/null 2>&1; then
        hint="Install with: sudo apt-get install jq"
      elif command -v dnf > /dev/null 2>&1; then
        hint="Install with: sudo dnf install jq"
      else
        hint="Install jq from https://jqlang.github.io/jq/download/"
      fi
      ;;
    macos)
      hint="Install with: brew install jq"
      ;;
    *)
      hint="Install jq from https://jqlang.github.io/jq/download/"
      ;;
  esac
  die "'jq' is required but not found. ${hint}"
}

# Checks for agy; prints install hint and exits if missing.
require_agy() {
  if command -v agy > /dev/null 2>&1; then
    return 0
  fi
  die "'agy' (Antigravity CLI) is not found in PATH. See: https://antigravity.google/docs/cli-install"
}

# ---------------------------------------------------------------------------
# Path constants (set after detect_os runs)
# ---------------------------------------------------------------------------
AZG_GLOBAL_DIR="${HOME}/.gemini/antigravity-cli"
AZG_GLOBAL_SKILLS_DIR="${AZG_GLOBAL_DIR}/skills"
AZG_GLOBAL_MCP_CONFIG="${AZG_GLOBAL_DIR}/mcp_config.json"

# ---------------------------------------------------------------------------
# Atomic file write helpers
# ---------------------------------------------------------------------------
# atomic_write DEST CONTENT
# Writes CONTENT to a temp file then moves it into place (same-filesystem mv).
atomic_write() {
  local dest="${1}"
  local content="${2}"
  local tmp
  tmp="${dest}.azg.tmp"
  printf '%s' "${content}" > "${tmp}"
  mv "${tmp}" "${dest}"
}

# atomic_copy SRC DEST
# Copies SRC to a temp file alongside DEST, then mv (atomic on same filesystem).
atomic_copy() {
  local src="${1}"
  local dest="${2}"
  local tmp
  tmp="${dest}.azg.tmp"
  cp "${src}" "${tmp}"
  mv "${tmp}" "${dest}"
}

# ---------------------------------------------------------------------------
# Misc helpers
# ---------------------------------------------------------------------------
# ensure_dir DIR — mkdir -p, then print if it was freshly created
ensure_dir() {
  local dir="${1}"
  if [ ! -d "${dir}" ]; then
    mkdir -p "${dir}"
  fi
}

# sed_portable PATTERN FILE
# A cross-platform sed substitute that avoids sed -i (BSD/GNU incompatibility).
# Rewrites FILE in-place using a tmp file approach.
# Usage: sed_portable 's/foo/bar/g' myfile
sed_portable() {
  local pattern="${1}"
  local file="${2}"
  local tmp="${file}.azg.tmp"
  sed "${pattern}" "${file}" > "${tmp}" && mv "${tmp}" "${file}"
}

# prompt_yn QUESTION DEFAULT
# Prints QUESTION [Y/n] or [y/N] based on DEFAULT ("y" or "n").
# Returns 0 for yes, 1 for no.
prompt_yn() {
  local question="${1}"
  local default="${2:-y}"
  local prompt_suffix
  if [ "${default}" = "y" ]; then
    prompt_suffix="[Y/n]"
  else
    prompt_suffix="[y/N]"
  fi
  local reply
  printf "%s %s " "${question}" "${prompt_suffix}"
  read -r reply </dev/tty || reply="${default}"
  reply="${reply:-${default}}"
  case "${reply}" in
    [Yy]*) return 0 ;;
    [Nn]*) return 1 ;;
    *)     # fallback to default
      if [ "${default}" = "y" ]; then return 0; else return 1; fi
      ;;
  esac
}

# prompt_choice QUESTION OPTION1 OPTION2 ...
# Prints numbered options, reads a selection, echoes the chosen value.
prompt_choice() {
  local question="${1}"; shift
  local options=("$@")
  printf "%s\n" "${question}"
  local i=1
  for opt in "${options[@]}"; do
    printf "  %d) %s\n" "${i}" "${opt}"
    i=$((i + 1))
  done
  local reply
  printf "Choice [1-%d]: " "${#options[@]}"
  read -r reply </dev/tty || reply="1"
  reply="${reply:-1}"
  # Validate range
  if [ "${reply}" -ge 1 ] 2>/dev/null && [ "${reply}" -le "${#options[@]}" ] 2>/dev/null; then
    echo "${options[$((reply - 1))]}"
  else
    echo "${options[0]}"
  fi
}
