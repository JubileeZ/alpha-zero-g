#!/usr/bin/env bash
# templates/global/statusline.sh — custom statusline script for Antigravity CLI
# Reads session state JSON from stdin, queries local quota cache, and prints formatted output.

set -uo pipefail

# Read stdin
input=$(cat)

# Extract basic fields
STATE=$(echo "$input" | jq -r '.agent_state // "idle"')
MODEL_NAME=$(echo "$input" | jq -r '.model.display_name // empty')
CONTEXT_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
WIDTH=$(echo "$input" | jq -r '.terminal_width // 100')

# Extract VCS fields
VCS_BRANCH=$(echo "$input" | jq -r '.vcs.branch // empty')
VCS_DIRTY=$(echo "$input" | jq -r '.vcs.dirty // false')
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir // empty')
PROJECT_NAME=""
if [ -n "$PROJECT_DIR" ] && [ "$PROJECT_DIR" != "null" ]; then
  PROJECT_NAME=$(basename "$PROJECT_DIR")
fi

# ---------------------------------------------------------------------------
# 1. Preset Resolution
# ---------------------------------------------------------------------------
SETTINGS_FILE="${HOME}/.gemini/antigravity-cli/settings.json"
PRESET=""
if [ -f "$SETTINGS_FILE" ]; then
  PRESET=$(jq -r '.statusLine.preset // empty' "$SETTINGS_FILE" 2>/dev/null)
fi

# Override with environment variable if present
PRESET="${AZG_STATUSLINE_PRESET:-$PRESET}"

# Auto-detection fallback (defaulting to unicode)
if [ -z "$PRESET" ] || [ "$PRESET" = "null" ]; then
  if [ -n "${TERM_PROGRAM:-}" ] && [[ "${TERM_PROGRAM}" =~ (Apple_Terminal|iTerm\.app|vscode) ]]; then
    PRESET="unicode"
  elif [ -n "${TERM:-}" ] && [[ "${TERM}" =~ (kitty|alacritty|wezterm|tmux|screen) ]]; then
    PRESET="unicode"
  else
    PRESET="unicode"
  fi
fi

# Validate preset value
if [[ ! "$PRESET" =~ ^(nerd-font|unicode|ascii)$ ]]; then
  PRESET="unicode"
fi

# ---------------------------------------------------------------------------
# 2. Color Palette & Glyph Setup
# ---------------------------------------------------------------------------
# Colors are enabled unless NO_COLOR is set
if [ -z "${NO_COLOR:-}" ]; then
  RESET="\033[0m"
  BOLD="\033[1m"
  DIM="\033[2m"

  # Foreground colors for unicode/ascii presets
  GREEN="\033[38;5;71m"
  YELLOW="\033[38;5;179m"
  ORANGE="\033[38;5;166m"
  RED="\033[38;5;196m"
  BLUE="\033[38;5;67m"
  PURPLE="\033[38;5;97m"
  CYAN="\033[38;5;37m"
  GRAY="\033[38;5;244m"
else
  RESET=""
  BOLD=""
  DIM=""
  GREEN=""
  YELLOW=""
  ORANGE=""
  RED=""
  BLUE=""
  PURPLE=""
  CYAN=""
  GRAY=""
fi

# Glyph mappings
if [ "$PRESET" = "nerd-font" ]; then
  STATE_IDLE_TXT="󰾆 IDLE"
  STATE_THINKING_TXT=" THINKING"
  STATE_WORKING_TXT="⚙ WORKING"
  STATE_WAITING_TXT="⏸ WAITING"
  VCS_ICON=""
  WARN_CAUTION=""
  WARN_DEGRADING=""
  WARN_CRITICAL=""
  SEP_LEFT=""
  SEP_RIGHT=""
  SEP_CHAR=""
elif [ "$PRESET" = "unicode" ]; then
  STATE_IDLE_TXT="● IDLE"
  STATE_THINKING_TXT="◈ THINKING"
  STATE_WORKING_TXT="⚙ WORKING"
  STATE_WAITING_TXT="⏸ WAITING"
  VCS_ICON="⎇"
  WARN_CAUTION="⚠"
  WARN_DEGRADING="⚡"
  WARN_CRITICAL="🔥"
  SEP_LEFT=""
  SEP_RIGHT=""
  SEP_CHAR="|"
else # ascii
  STATE_IDLE_TXT="IDLE"
  STATE_THINKING_TXT="THINKING"
  STATE_WORKING_TXT="WORKING"
  STATE_WAITING_TXT="WAITING"
  VCS_ICON="branch:"
  WARN_CAUTION="!"
  WARN_DEGRADING="!!"
  WARN_CRITICAL="!!!"
  SEP_LEFT=""
  SEP_RIGHT=""
  SEP_CHAR="|"
fi

# Helper to format milliseconds
format_time() {
  local ms="$1"
  if [ -z "$ms" ] || [ "$ms" = "null" ] || [ "$ms" -le 0 ]; then
    echo ""
    return
  fi
  local total_sec=$((ms / 1000))
  local min=$(( (total_sec / 60) % 60 ))
  local hr=$(( (total_sec / 3600) % 24 ))
  local day=$(( total_sec / 86400 ))

  if [ "$day" -gt 0 ]; then
    echo "${day}d ${hr}h"
  elif [ "$hr" -gt 0 ]; then
    echo "${hr}h ${min}m"
  elif [ "$min" -gt 0 ]; then
    echo "${min}m"
  else
    echo "${total_sec}s"
  fi
}

# Helper to format tokens
format_tokens() {
  local tkn="$1"
  if [ -z "$tkn" ] || [ "$tkn" -le 0 ]; then
    echo "0"
    return
  fi
  if [ "$tkn" -ge 1000 ]; then
    local k=$((tkn / 1000))
    local r=$(( (tkn % 1000) / 100 ))
    if [ "$r" -gt 0 ]; then
      echo "${k}.${r}k"
    else
      echo "${k}k"
    fi
  else
    echo "$tkn"
  fi
}

# ---------------------------------------------------------------------------
# 3. Context Severity Calculations
# ---------------------------------------------------------------------------
INPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUTPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
USED_TOKENS=$((INPUT_TOKENS + OUTPUT_TOKENS))

# Convert percentage to integer
INT_PCT="${CONTEXT_PCT%%.*}"
if ! [[ "$INT_PCT" =~ ^[0-9]+$ ]]; then
  INT_PCT=0
fi

# Severity based on percentage: 0 = Safe, 1 = Caution (>=50%), 2 = Degrading (>=70%), 3 = Critical (>=85%)
FINAL_SEV=0
if [ "$INT_PCT" -ge 85 ]; then
  FINAL_SEV=3
elif [ "$INT_PCT" -ge 70 ]; then
  FINAL_SEV=2
elif [ "$INT_PCT" -ge 50 ]; then
  FINAL_SEV=1
fi

TKN_DISPLAY=$(format_tokens "$USED_TOKENS")
IN_DISPLAY=$(format_tokens "$INPUT_TOKENS")
OUT_DISPLAY=$(format_tokens "$OUTPUT_TOKENS")

# ---------------------------------------------------------------------------
# 4. Fetch Quota Usage & State Specs
# ---------------------------------------------------------------------------
# Try stdin JSON first; fall back to external binary if available
# ponytail: single jq call for stdin, command -v guard avoids fork when binary missing
QUOTA_JSON=$(echo "$input" | jq -r '.quota // empty' 2>/dev/null)
if [ -z "$QUOTA_JSON" ] || [ "$QUOTA_JSON" = "null" ]; then
  QUOTA_JSON="{}"
fi

# Extract active elapsed time if present
ACTIVE_MS=$(echo "$input" | jq -r '.active_duration_ms // .elapsed_ms // empty')
ELAPSED_TXT=""
if [ -n "$ACTIVE_MS" ] && [ "$ACTIVE_MS" != "null" ]; then
  ELAPSED_TXT=" $(format_time "$ACTIVE_MS")"
fi

# State parsing
STATE_TXT=""
STATE_BG=""
STATE_FG=255
STATE_CLR=""

case "${STATE}" in
  idle)
    STATE_TXT="${STATE_IDLE_TXT}"
    STATE_BG=60
    STATE_FG=255
    STATE_CLR="${BLUE}"
    ;;
  thinking)
    STATE_TXT="${STATE_THINKING_TXT}${ELAPSED_TXT}"
    STATE_BG=97
    STATE_FG=255
    STATE_CLR="${PURPLE}"
    ;;
  working|executing)
    STATE_TXT="${STATE_WORKING_TXT}${ELAPSED_TXT}"
    STATE_BG=172
    STATE_FG=232
    STATE_CLR="${YELLOW}"
    ;;
  waiting)
    STATE_TXT="${STATE_WAITING_TXT}"
    STATE_BG=37
    STATE_FG=232
    STATE_CLR="${CYAN}"
    ;;
  *)
    STATE_TXT="${STATE}${ELAPSED_TXT}"
    STATE_BG=236
    STATE_FG=250
    STATE_CLR="${GRAY}"
    ;;
esac

# Context parsing - Responsive layout
CONTEXT_TXT=""
CONTEXT_BG=""
CONTEXT_FG=255
CONTEXT_CLR=""

# Choose labels / symbols based on width tier
# Wide (>=100): "Context: 48.3k (45.2k↓/3.1k↑) · 52% ⚠"
# Medium (65-99): "Ctx: 52% ⚠"
# Narrow (<65): "52% ⚠"
if [ "$WIDTH" -ge 100 ]; then
  CTX_PREFIX="Context: ${TKN_DISPLAY} (${IN_DISPLAY}↓/${OUT_DISPLAY}↑) | "
elif [ "$WIDTH" -ge 65 ]; then
  CTX_PREFIX="Ctx: "
else
  CTX_PREFIX=""
fi

CONTEXT_BAR=""
if [ "$WIDTH" -ge 100 ]; then
  FULL_BAR="██████████"
  EMPTY_BAR="░░░░░░░░░░"
  num_filled=$(( (INT_PCT + 5) / 10 ))
  [ "$num_filled" -gt 10 ] && num_filled=10
  num_empty=$(( 10 - num_filled ))
  CONTEXT_BAR=" [${FULL_BAR:0:num_filled}${EMPTY_BAR:0:num_empty}]"
fi

case "$FINAL_SEV" in
  3)
    CONTEXT_TXT="${CTX_PREFIX}${INT_PCT}%${CONTEXT_BAR} ${WARN_CRITICAL}"
    CONTEXT_BG=124
    CONTEXT_CLR="${RED}"
    ;;
  2)
    CONTEXT_TXT="${CTX_PREFIX}${INT_PCT}%${CONTEXT_BAR} ${WARN_DEGRADING}"
    CONTEXT_BG=166
    CONTEXT_CLR="${ORANGE}"
    ;;
  1)
    CONTEXT_TXT="${CTX_PREFIX}${INT_PCT}%${CONTEXT_BAR} ${WARN_CAUTION}"
    CONTEXT_BG=136
    CONTEXT_CLR="${YELLOW}"
    ;;
  *)
    CONTEXT_TXT="${CTX_PREFIX}${INT_PCT}%${CONTEXT_BAR}"
    CONTEXT_BG=65
    CONTEXT_CLR="${GREEN}"
    ;;
esac

# Claude and Gemini info parsing
CL_PCT_VAL=""
CL_RESET_VAL=""
CL_EXH_VAL=""
GEM_PCT_VAL=""
GEM_RESET_VAL=""
GEM_EXH_VAL=""
CREDITS_REM=""
CREDITS_AV=""
CREDITS_MON=""
GMW_PCT_VAL=""
GMW_EXH_VAL=""
GMW_RESET_VAL=""
CLW_PCT_VAL=""
CLW_EXH_VAL=""
CLW_RESET_VAL=""

if [ -n "$QUOTA_JSON" ] && [ "$QUOTA_JSON" != "{}" ]; then
  CLAUDE_INFO=$(echo "$QUOTA_JSON" | jq -r '
    if .models then
      .models[]? | select(.label | ascii_downcase | contains("claude")) | "\(.remainingPercentage) \(.isExhausted) \(.timeUntilResetMs)"
    elif ."3p-5h" then
      ."3p-5h" | "\(.remaining_fraction) \(.remaining_fraction <= 0) \(.reset_in_seconds * 1000)"
    else
      empty
    end
  ' 2>/dev/null | head -n 1 || true)

  GEMINI_INFO=$(echo "$QUOTA_JSON" | jq -r '
    if .models then
      .models[]? | select(.label | ascii_downcase | contains("gemini")) | "\(.remainingPercentage) \(.isExhausted) \(.timeUntilResetMs)"
    elif ."gemini-5h" then
      ."gemini-5h" | "\(.remaining_fraction) \(.remaining_fraction <= 0) \(.reset_in_seconds * 1000)"
    else
      empty
    end
  ' 2>/dev/null | head -n 1 || true)

  CLAUDE_WEEKLY=$(echo "$QUOTA_JSON" | jq -r '
    if ."3p-weekly" then
      ."3p-weekly" | "\(.remaining_fraction) \(.remaining_fraction <= 0) \(.reset_in_seconds * 1000)"
    else empty end
  ' 2>/dev/null | head -n 1 || true)

  GEMINI_WEEKLY=$(echo "$QUOTA_JSON" | jq -r '
    if ."gemini-weekly" then
      ."gemini-weekly" | "\(.remaining_fraction) \(.remaining_fraction <= 0) \(.reset_in_seconds * 1000)"
    else empty end
  ' 2>/dev/null | head -n 1 || true)

  if [ -n "${CLAUDE_INFO}" ]; then
    read -r CL_PCT CL_EXH CL_RESET <<< "${CLAUDE_INFO}"
    if [ -n "$CL_PCT" ] && [ "$CL_PCT" != "null" ]; then
      CL_PCT_VAL=$(echo "$CL_PCT" | awk '{print int($1 * 100)}')
      CL_EXH_VAL="$CL_EXH"
      if [ -n "$CL_RESET" ] && [ "$CL_RESET" != "null" ] && [ "$CL_RESET" -gt 0 ] 2>/dev/null; then
        CL_RESET_VAL=$(format_time "$CL_RESET")
      fi
      if [ -n "${CLAUDE_WEEKLY}" ]; then
        read -r CLW_PCT CLW_EXH CLW_RESET <<< "${CLAUDE_WEEKLY}"
        if [ -n "$CLW_PCT" ] && [ "$CLW_PCT" != "null" ]; then
          CLW_PCT_VAL=$(echo "$CLW_PCT" | awk '{print int($1 * 100)}')
          CLW_EXH_VAL="$CLW_EXH"
          if [ -n "$CLW_RESET" ] && [ "$CLW_RESET" != "null" ] && [ "$CLW_RESET" -gt 0 ] 2>/dev/null; then
            CLW_RESET_VAL=$(format_time "$CLW_RESET")
          fi
        fi
      fi
    fi
  fi

  if [ -n "${GEMINI_INFO}" ]; then
    read -r GEM_PCT GEM_EXH GEM_RESET <<< "${GEMINI_INFO}"
    if [ -n "$GEM_PCT" ] && [ "$GEM_PCT" != "null" ]; then
      GEM_PCT_VAL=$(echo "$GEM_PCT" | awk '{print int($1 * 100)}')
      GEM_EXH_VAL="$GEM_EXH"
      if [ -n "$GEM_RESET" ] && [ "$GEM_RESET" != "null" ] && [ "$GEM_RESET" -gt 0 ] 2>/dev/null; then
        GEM_RESET_VAL=$(format_time "$GEM_RESET")
      fi
      if [ -n "${GEMINI_WEEKLY}" ]; then
        read -r GMW_PCT GMW_EXH GMW_RESET <<< "${GEMINI_WEEKLY}"
        if [ -n "$GMW_PCT" ] && [ "$GMW_PCT" != "null" ]; then
          GMW_PCT_VAL=$(echo "$GMW_PCT" | awk '{print int($1 * 100)}')
          GMW_EXH_VAL="$GMW_EXH"
          if [ -n "$GMW_RESET" ] && [ "$GMW_RESET" != "null" ] && [ "$GMW_RESET" -gt 0 ] 2>/dev/null; then
            GMW_RESET_VAL=$(format_time "$GMW_RESET")
          fi
        fi
      fi
    fi
  fi

  CREDITS_REM=$(echo "$QUOTA_JSON" | jq -r '.promptCredits.remainingPercentage // empty')
  CREDITS_AV=$(echo "$QUOTA_JSON" | jq -r '.promptCredits.available // empty')
  CREDITS_MON=$(echo "$QUOTA_JSON" | jq -r '.promptCredits.monthly // empty')
fi

CR_PCT_VAL=""
CR_AV_VAL=""
CR_MON_VAL=""
if [ -n "$CREDITS_REM" ] && [ "$CREDITS_REM" != "null" ] && [ "$CREDITS_REM" != "" ]; then
  CR_PCT_VAL=$(echo "$CREDITS_REM" | awk '{print int($1 * 100)}')
  CR_AV_VAL="$CREDITS_AV"
  CR_MON_VAL="$CREDITS_MON"
fi

# ---------------------------------------------------------------------------
# 5. Segment Assembly & Truncation Loop
# ---------------------------------------------------------------------------
# Flags for dynamic truncation
SHOW_STATE="true"
SHOW_CLAUDE="true"
SHOW_GEMINI="true"
SHOW_CREDITS="true"
SHOW_VCS="true"

# Declare arrays for segments
declare -a L_TXT
declare -a L_BG
declare -a L_FG
declare -a L_CLR

declare -a R_TXT
declare -a R_BG
declare -a R_FG
declare -a R_CLR


ABBREV_QUOTAS="false"
ABBREV_CTX="false"
ABBREV_NAMES="false"

populate_segments() {
  L_TXT=() L_BG=() L_FG=() L_CLR=()
  R_TXT=() R_BG=() R_FG=() R_CLR=()

  # 1. PROJECT & GIT (VCS)
  if [ "$SHOW_VCS" = "true" ]; then
    local txt=""
    if [ -n "$PROJECT_NAME" ]; then
      if [ "$ABBREV_NAMES" = "true" ] && [ ${#PROJECT_NAME} -gt 10 ]; then
        txt="${PROJECT_NAME:0:7}.."
      else
        txt="${PROJECT_NAME}"
      fi
    fi
    
    if [ -n "$VCS_BRANCH" ] && [ "$VCS_BRANCH" != "null" ]; then
      local vcs_txt=""
      local branch_name="$VCS_BRANCH"
      if [ "$ABBREV_NAMES" = "true" ] && [ ${#branch_name} -gt 10 ]; then
        branch_name="${branch_name:0:7}.."
      fi
      if [ "$VCS_DIRTY" = "true" ]; then
        vcs_txt="${VCS_ICON} ${branch_name}*"
      else
        vcs_txt="${VCS_ICON} ${branch_name}"
      fi
      if [ -n "$txt" ]; then txt="${txt} ${vcs_txt}"
      else txt="${vcs_txt}"; fi
    fi
    
    if [ -n "$txt" ]; then
      L_TXT+=("${txt}")
      L_BG+=(239)
      L_FG+=(248)
      L_CLR+=("${GRAY}")
    fi
  fi

  # 2. STATE
  if [ "$SHOW_STATE" = "true" ] && [ -n "${STATE_TXT}" ]; then
    local st_txt="${STATE_TXT}"
    if [ "$ABBREV_NAMES" = "true" ]; then
      # Remove elapsed time if abbreviated heavily
      st_txt=$(echo "$st_txt" | sed -r 's/ [0-9]+[a-z]+//g')
    fi
    L_TXT+=("${st_txt}")
    L_BG+=("${STATE_BG}")
    L_FG+=("${STATE_FG}")
    L_CLR+=("${STATE_CLR}")
  fi

  # 3. MODEL
  if [ -n "${MODEL_NAME}" ] && [ "$SHOW_MODEL" != "false" ]; then
    local display_model="${MODEL_NAME}"
    if [ "$ABBREV_NAMES" = "true" ]; then
      display_model="${display_model:0:9}.."
    fi
    L_TXT+=("Model: ${display_model}")
    L_BG+=(236)
    L_FG+=(250)
    L_CLR+=("${BOLD}${CYAN}")
  fi

  # 4. CONTEXT
  if [ "$SHOW_CONTEXT" != "false" ] && [ -n "${CONTEXT_PCT}" ]; then
    local ctx_prefix=""
    if [ "$ABBREV_CTX" = "false" ] && [ "$WIDTH" -ge 100 ]; then
      ctx_prefix="Context: ${TKN_DISPLAY} (${IN_DISPLAY}↓/${OUT_DISPLAY}↑) "
    else
      ctx_prefix="Ctx: "
    fi
    
    local txt="${ctx_prefix}${INT_PCT}%"
    
    if [ "$ABBREV_CTX" = "false" ] && [ "$WIDTH" -ge 100 ]; then
      FULL_BAR="██████████"
      EMPTY_BAR="░░░░░░░░░░"
      local num_filled=$(( (INT_PCT + 5) / 10 ))
      [ "$num_filled" -gt 10 ] && num_filled=10
      local num_empty=$(( 10 - num_filled ))
      txt="${txt} [${FULL_BAR:0:num_filled}${EMPTY_BAR:0:num_empty}]"
    fi
    
    case "$FINAL_SEV" in
      3) txt="${txt} ${WARN_CRITICAL}"; CONTEXT_BG=124; CONTEXT_CLR="${RED}" ;;
      2) txt="${txt} ${WARN_DEGRADING}"; CONTEXT_BG=166; CONTEXT_CLR="${ORANGE}" ;;
      1) txt="${txt} ${WARN_CAUTION}"; CONTEXT_BG=136; CONTEXT_CLR="${YELLOW}" ;;
      *) CONTEXT_BG=65; CONTEXT_CLR="${GREEN}" ;;
    esac

    L_TXT+=("${txt}")
    L_BG+=("${CONTEXT_BG}")
    L_FG+=("${CONTEXT_FG:-255}")
    L_CLR+=("${CONTEXT_CLR}")
  fi

  # 5. GEMINI
  if [ "$SHOW_GEMINI" = "true" ] && [ -n "$GEM_PCT_VAL" ]; then
    local txt=""
    local bg=""
    local clr=""
    local lbl="Gemini"
    [ "$ABBREV_NAMES" = "true" ] && lbl="Gem"

    if [ "$GEM_EXH_VAL" = "true" ]; then
      txt="${lbl}: Exh"
      bg=124; clr="${RED}"
    else
      txt="${lbl}: ${GEM_PCT_VAL}%"
      if [ "$GEM_PCT_VAL" -lt 20 ]; then bg=124; clr="${RED}"
      elif [ "$GEM_PCT_VAL" -lt 50 ]; then bg=136; clr="${YELLOW}"
      else bg=65; clr="${GREEN}"; fi
    fi

    if [ "$ABBREV_QUOTAS" = "false" ]; then
      [ -n "$GEM_RESET_VAL" ] && txt="${txt} (${GEM_RESET_VAL})"
    fi

    if [ -n "${GMW_PCT_VAL:-}" ]; then
      txt="${txt} / "
      if [ "${GMW_EXH_VAL:-}" = "true" ]; then
        txt="${txt}Exh"
      else
        txt="${txt}${GMW_PCT_VAL}%"
      fi
      if [ "$ABBREV_QUOTAS" = "false" ]; then
        [ -n "${GMW_RESET_VAL:-}" ] && txt="${txt} (${GMW_RESET_VAL})"
      fi
    fi

    L_TXT+=("${txt}")
    L_BG+=("${bg}")
    L_FG+=(255)
    L_CLR+=("${clr}")
  fi

  # 6. 3RD PARTY
  if [ "$SHOW_CLAUDE" = "true" ] && [ -n "$CL_PCT_VAL" ]; then
    local txt=""
    local bg=""
    local clr=""
    local lbl="3rd Party"
    [ "$ABBREV_NAMES" = "true" ] && lbl="3P"

    if [ "$CL_EXH_VAL" = "true" ]; then
      txt="${lbl}: Exh"
      bg=124; clr="${RED}"
    else
      txt="${lbl}: ${CL_PCT_VAL}%"
      if [ "$CL_PCT_VAL" -lt 20 ]; then bg=124; clr="${RED}"
      elif [ "$CL_PCT_VAL" -lt 50 ]; then bg=136; clr="${YELLOW}"
      else bg=65; clr="${GREEN}"; fi
    fi

    if [ "$ABBREV_QUOTAS" = "false" ]; then
      [ -n "$CL_RESET_VAL" ] && txt="${txt} (${CL_RESET_VAL})"
    fi

    if [ -n "${CLW_PCT_VAL:-}" ]; then
      txt="${txt} / "
      if [ "${CLW_EXH_VAL:-}" = "true" ]; then
        txt="${txt}Exh"
      else
        txt="${txt}${CLW_PCT_VAL}%"
      fi
      if [ "$ABBREV_QUOTAS" = "false" ]; then
        [ -n "${CLW_RESET_VAL:-}" ] && txt="${txt} (${CLW_RESET_VAL})"
      fi
    fi

    L_TXT+=("${txt}")
    L_BG+=("${bg}")
    L_FG+=(255)
    L_CLR+=("${clr}")
  fi
}

calculate_visible_length() {
  local l_len=0
  for txt in "${L_TXT[@]+"${L_TXT[@]}"}"; do
    l_len=$((l_len + ${#txt}))
  done
  local n=${#L_TXT[@]}
  local total_l=0
  if [ "$PRESET" = "nerd-font" ]; then
    [ $n -gt 0 ] && total_l=$((l_len + 3 * n))
  else
    [ $n -gt 0 ] && total_l=$((l_len + 3 * (n - 1)))
  fi
  echo $((total_l))
}

# Initial population
SHOW_MODEL="true"
SHOW_CONTEXT="true"
populate_segments
LEN=$(calculate_visible_length)

# Responsive adaptation drops
if [ "$LEN" -gt "$WIDTH" ]; then
  ABBREV_QUOTAS="true"; populate_segments; LEN=$(calculate_visible_length)
fi

if [ "$LEN" -gt "$WIDTH" ]; then
  ABBREV_CTX="true"; populate_segments; LEN=$(calculate_visible_length)
fi

if [ "$LEN" -gt "$WIDTH" ]; then
  ABBREV_NAMES="true"; populate_segments; LEN=$(calculate_visible_length)
fi

# Hard drops
if [ "$LEN" -gt "$WIDTH" ] && [ "$SHOW_CLAUDE" = "true" ]; then
  SHOW_CLAUDE="false"; populate_segments; LEN=$(calculate_visible_length)
fi

if [ "$LEN" -gt "$WIDTH" ] && [ "$SHOW_GEMINI" = "true" ]; then
  SHOW_GEMINI="false"; populate_segments; LEN=$(calculate_visible_length)
fi

if [ "$LEN" -gt "$WIDTH" ] && [ "$SHOW_VCS" = "true" ]; then
  SHOW_VCS="false"; populate_segments; LEN=$(calculate_visible_length)
fi

if [ "$LEN" -gt "$WIDTH" ] && [ "$SHOW_CONTEXT" = "true" ]; then
  SHOW_CONTEXT="false"; populate_segments; LEN=$(calculate_visible_length)
fi


L_LEN=0
for txt in "${L_TXT[@]+"${L_TXT[@]}"}"; do
  L_LEN=$((L_LEN + ${#txt}))
done

R_LEN=0
for txt in "${R_TXT[@]+"${R_TXT[@]}"}"; do
  R_LEN=$((R_LEN + ${#txt}))
done

N=${#L_TXT[@]}
M=${#R_TXT[@]}

if [ "$PRESET" = "nerd-font" ]; then
  [ $N -gt 0 ] && L_LEN=$((L_LEN + 3 * N))
  [ $M -gt 0 ] && R_LEN=$((R_LEN + 3 * M))
else
  [ $N -gt 0 ] && L_LEN=$((L_LEN + 3 * (N - 1)))
  [ $M -gt 0 ] && R_LEN=$((R_LEN + 3 * (M - 1)))
fi

# Fixed 4-space gap if both groups are present
GAP_LEN=0

# Clear the rest of the line to prevent rendering glitches in TUI status bars
TOTAL_TEXT_LEN=$((L_LEN + GAP_LEN + R_LEN))
TRAILING_LEN=$((WIDTH - TOTAL_TEXT_LEN))
[ $TRAILING_LEN -lt 0 ] && TRAILING_LEN=0

gap_spaces=""
[ $GAP_LEN -gt 0 ] && gap_spaces=""

trailing_spaces=""
if [ $TRAILING_LEN -gt 0 ]; then
  trailing_spaces=$(printf "%${TRAILING_LEN}s" "")
fi

# Assemble outputs
left_output=""
r_output=""

if [ "$PRESET" = "nerd-font" ]; then
  # Left assembly with solid background blocks
  for ((i=0; i<N; i++)); do
    bg="${L_BG[i]}"
    fg="${L_FG[i]}"
    txt="${L_TXT[i]}"
    if [ $i -eq 0 ]; then
      left_output+="\033[38;5;${fg};48;5;${bg}m ${txt} "
    else
      prev_bg="${L_BG[i-1]}"
      left_output+="\033[38;5;${prev_bg};48;5;${bg}m${SEP_LEFT}\033[38;5;${fg};48;5;${bg}m ${txt} "
    fi
  done
  if [ $N -gt 0 ]; then
    last_bg="${L_BG[N-1]}"
    left_output+="\033[38;5;${last_bg};49m${SEP_LEFT}\033[0m"
  fi

  # Right assembly with solid background blocks
  for ((j=0; j<M; j++)); do
    bg="${R_BG[j]}"
    fg="${R_FG[j]}"
    txt="${R_TXT[j]}"
    if [ $j -eq 0 ]; then
      r_output+="\033[38;5;${bg};49m${SEP_RIGHT}\033[38;5;${fg};48;5;${bg}m ${txt} "
    else
      prev_bg="${R_BG[j-1]}"
      r_output+="\033[38;5;${bg};48;5;${prev_bg}m${SEP_RIGHT}\033[38;5;${fg};48;5;${bg}m ${txt} "
    fi
  done
  if [ $M -gt 0 ]; then
    r_output+="\033[0m"
  fi

else
  # Standard unicode/ascii layouts (foreground styling only)
  for ((i=0; i<N; i++)); do
    clr="${L_CLR[i]}"
    txt="${L_TXT[i]}"
    if [ $i -eq 0 ]; then
      left_output+="${clr}${txt}${RESET}"
    else
      left_output+="${GRAY} ${SEP_CHAR} ${RESET}${clr}${txt}${RESET}"
    fi
  done

  for ((j=0; j<M; j++)); do
    clr="${R_CLR[j]}"
    txt="${R_TXT[j]}"
    if [ $j -eq 0 ]; then
      r_output+="${clr}${txt}${RESET}"
    else
      r_output+="${GRAY} ${SEP_CHAR} ${RESET}${clr}${txt}${RESET}"
    fi
  done
fi

# Print final statusline
if [ $N -gt 0 ] && [ $M -gt 0 ]; then
  echo -e "${left_output}${gap_spaces}${r_output}${trailing_spaces}"
elif [ $N -gt 0 ]; then
  echo -e "${left_output}${trailing_spaces}"
elif [ $M -gt 0 ]; then
  echo -e "${r_output}${trailing_spaces}"
else
  echo -e "${trailing_spaces}"
fi
