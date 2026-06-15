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
  RED="\033[38;5;124m"
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
  SEP_CHAR="│"
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

# Determine task type (Reasoning vs. Agentic/Tool)
IS_REASONING=0
MODEL_LOWER=$(echo "$MODEL_NAME" | tr '[:upper:]' '[:lower:]')
if [[ "$MODEL_LOWER" =~ (thinking|opus|sonnet) ]]; then
  IS_REASONING=1
fi

# Convert percentage to integer
INT_PCT="${CONTEXT_PCT%%.*}"
if ! [[ "$INT_PCT" =~ ^[0-9]+$ ]]; then
  INT_PCT=0
fi

# Severity: 0 = Safe, 1 = Caution, 2 = Degrading, 3 = Critical
SEV_TOKENS=0
if [ "$IS_REASONING" -eq 1 ]; then
  if [ "$USED_TOKENS" -ge 50000 ]; then
    SEV_TOKENS=3
  elif [ "$USED_TOKENS" -ge 35000 ]; then
    SEV_TOKENS=2
  elif [ "$USED_TOKENS" -ge 20000 ]; then
    SEV_TOKENS=1
  fi
else
  if [ "$USED_TOKENS" -ge 120000 ]; then
    SEV_TOKENS=3
  elif [ "$USED_TOKENS" -ge 90000 ]; then
    SEV_TOKENS=2
  elif [ "$USED_TOKENS" -ge 60000 ]; then
    SEV_TOKENS=1
  fi
fi

SEV_PCT=0
if [ "$INT_PCT" -ge 75 ]; then
  SEV_PCT=3
elif [ "$INT_PCT" -ge 60 ]; then
  SEV_PCT=2
elif [ "$INT_PCT" -ge 40 ]; then
  SEV_PCT=1
fi

# Higher severity wins
FINAL_SEV=$SEV_TOKENS
if [ "$SEV_PCT" -gt "$FINAL_SEV" ]; then
  FINAL_SEV=$SEV_PCT
fi

TKN_DISPLAY=$(format_tokens "$INPUT_TOKENS")
IN_DISPLAY=$(format_tokens "$INPUT_TOKENS")
OUT_DISPLAY=$(format_tokens "$OUTPUT_TOKENS")

# ---------------------------------------------------------------------------
# 4. Fetch Quota Usage & State Specs
# ---------------------------------------------------------------------------
QUOTA_JSON=$(antigravity-usage quota --json 2>/dev/null || echo "{}")

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
    STATE_TXT="${STATE_THINKING_TXT}"
    STATE_BG=97
    STATE_FG=255
    STATE_CLR="${PURPLE}"
    ;;
  working|executing)
    STATE_TXT="${STATE_WORKING_TXT}"
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
    STATE_TXT="${STATE}"
    STATE_BG=236
    STATE_FG=250
    STATE_CLR="${GRAY}"
    ;;
esac

# Context parsing
CONTEXT_TXT=""
CONTEXT_BG=""
CONTEXT_FG=255
CONTEXT_CLR=""

case "$FINAL_SEV" in
  3)
    CONTEXT_TXT="Context: ${TKN_DISPLAY} (${IN_DISPLAY}/${OUT_DISPLAY}) (${INT_PCT}%) ${WARN_CRITICAL}"
    CONTEXT_BG=124
    CONTEXT_CLR="${RED}"
    ;;
  2)
    CONTEXT_TXT="Context: ${TKN_DISPLAY} (${IN_DISPLAY}/${OUT_DISPLAY}) (${INT_PCT}%) ${WARN_DEGRADING}"
    CONTEXT_BG=166
    CONTEXT_CLR="${ORANGE}"
    ;;
  1)
    CONTEXT_TXT="Context: ${TKN_DISPLAY} (${IN_DISPLAY}/${OUT_DISPLAY}) (${INT_PCT}%) ${WARN_CAUTION}"
    CONTEXT_BG=136
    CONTEXT_CLR="${YELLOW}"
    ;;
  *)
    CONTEXT_TXT="Context: ${TKN_DISPLAY} (${IN_DISPLAY}/${OUT_DISPLAY}) (${INT_PCT}%)"
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

if [ -n "$QUOTA_JSON" ] && [ "$QUOTA_JSON" != "{}" ]; then
  CLAUDE_INFO=$(echo "$QUOTA_JSON" | jq -r '
    .models[]? | select(.label | ascii_downcase | contains("claude")) |
    "\(.remainingPercentage) \(.isExhausted) \(.timeUntilResetMs)"
  ' 2>/dev/null | head -n 1 || true)

  GEMINI_INFO=$(echo "$QUOTA_JSON" | jq -r '
    .models[]? | select(.label | ascii_downcase | contains("gemini")) |
    "\(.remainingPercentage) \(.isExhausted) \(.timeUntilResetMs)"
  ' 2>/dev/null | head -n 1 || true)

  if [ -n "${CLAUDE_INFO}" ]; then
    read -r CL_PCT CL_EXH CL_RESET <<< "${CLAUDE_INFO}"
    if [ -n "$CL_PCT" ] && [ "$CL_PCT" != "null" ]; then
      CL_PCT_VAL=$(echo "$CL_PCT" | awk '{print int($1 * 100)}')
      CL_EXH_VAL="$CL_EXH"
      if [ -n "$CL_RESET" ] && [ "$CL_RESET" != "null" ] && [ "$CL_RESET" -gt 0 ] 2>/dev/null; then
        CL_RESET_VAL=$(format_time "$CL_RESET")
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
    fi
  fi

  CREDITS_REM=$(echo "$QUOTA_JSON" | jq -r '.promptCredits.remainingPercentage // empty')
  CREDITS_AV=$(echo "$QUOTA_JSON" | jq -r '.promptCredits.available // empty')
  CREDITS_MON=$(echo "$QUOTA_JSON" | jq -r '.promptCredits.monthly // empty')
fi

CR_PCT_VAL=""
CR_AV_VAL=""
CR_MON_VAL=""
if [ -n "$CREDITS_REM" ] && [ "$CREDITS_REM" != "null" ] && [ "$CREDITS_REM" != "1" ] && [ "$CREDITS_REM" != "1.0" ] && [ "$CREDITS_REM" != "" ]; then
  if [ "$CREDITS_AV" != "500" ] || [ "$CREDITS_MON" != "50000" ]; then
    CR_PCT_VAL=$(echo "$CREDITS_REM" | awk '{print int($1 * 100)}')
    CR_AV_VAL="$CREDITS_AV"
    CR_MON_VAL="$CREDITS_MON"
  fi
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

populate_segments() {
  L_TXT=() L_BG=() L_FG=() L_CLR=()
  R_TXT=() R_BG=() R_FG=() R_CLR=()

  # Left segments
  if [ "$SHOW_STATE" = "true" ] && [ -n "${STATE_TXT}" ]; then
    L_TXT+=("${STATE_TXT}")
    L_BG+=("${STATE_BG}")
    L_FG+=("${STATE_FG}")
    L_CLR+=("${STATE_CLR}")
  fi

  if [ -n "${MODEL_NAME}" ]; then
    local display_model="${MODEL_NAME}"
    if [ "$WIDTH" -lt 65 ] && [ "${#display_model}" -gt 12 ]; then
      display_model="${display_model:0:9}..."
    fi
    L_TXT+=("Model: ${display_model}")
    L_BG+=(236)
    L_FG+=(250)
    L_CLR+=("${BOLD}${CYAN}")
  fi

  if [ -n "${CONTEXT_TXT}" ]; then
    L_TXT+=("${CONTEXT_TXT}")
    L_BG+=("${CONTEXT_BG}")
    L_FG+=("${CONTEXT_FG}")
    L_CLR+=("${CONTEXT_CLR}")
  fi

  # Right segments
  if [ "$SHOW_CLAUDE" = "true" ] && [ -n "$CL_PCT_VAL" ]; then
    local txt=""
    local bg=""
    local clr=""
    if [ "$CL_EXH_VAL" = "true" ]; then
      txt="Claude: Exh"
      bg=124
      clr="${RED}"
    else
      txt="Claude: ${CL_PCT_VAL}%"
      [ -n "$CL_RESET_VAL" ] && txt="${txt} (${CL_RESET_VAL})"
      if [ "$CL_PCT_VAL" -lt 20 ]; then
        bg=124; clr="${RED}"
      elif [ "$CL_PCT_VAL" -lt 50 ]; then
        bg=136; clr="${YELLOW}"
      else
        bg=65; clr="${GREEN}"
      fi
    fi
    R_TXT+=("${txt}")
    R_BG+=("${bg}")
    R_FG+=(255)
    R_CLR+=("${clr}")
  fi

  if [ "$SHOW_GEMINI" = "true" ] && [ -n "$GEM_PCT_VAL" ]; then
    local txt=""
    local bg=""
    local clr=""
    if [ "$GEM_EXH_VAL" = "true" ]; then
      txt="Gemini: Exh"
      bg=124
      clr="${RED}"
    else
      txt="Gemini: ${GEM_PCT_VAL}%"
      [ -n "$GEM_RESET_VAL" ] && txt="${txt} (${GEM_RESET_VAL})"
      if [ "$GEM_PCT_VAL" -lt 20 ]; then
        bg=124; clr="${RED}"
      elif [ "$GEM_PCT_VAL" -lt 50 ]; then
        bg=136; clr="${YELLOW}"
      else
        bg=65; clr="${GREEN}"
      fi
    fi
    R_TXT+=("${txt}")
    R_BG+=("${bg}")
    R_FG+=(255)
    R_CLR+=("${clr}")
  fi

  if [ "$SHOW_CREDITS" = "true" ] && [ -n "$CR_PCT_VAL" ]; then
    local txt="Credits: ${CR_PCT_VAL}% (${CR_AV_VAL}/${CR_MON_VAL})"
    local bg=""
    local clr=""
    if [ "$CR_PCT_VAL" -lt 10 ]; then
      bg=124; clr="${RED}"
    elif [ "$CR_PCT_VAL" -lt 30 ]; then
      bg=136; clr="${YELLOW}"
    else
      bg=236; clr="${GREEN}"
    fi
    R_TXT+=("${txt}")
    R_BG+=("${bg}")
    R_FG+=(250)
    R_CLR+=("${clr}")
  fi

  if [ "$SHOW_VCS" = "true" ] && [ -n "$VCS_BRANCH" ] && [ "$VCS_BRANCH" != "null" ]; then
    local txt=""
    if [ "$VCS_DIRTY" = "true" ]; then
      txt="${VCS_ICON} ${VCS_BRANCH}*"
    else
      txt="${VCS_ICON} ${VCS_BRANCH}"
    fi
    R_TXT+=("${txt}")
    R_BG+=(239)
    R_FG+=(248)
    R_CLR+=("${GRAY}")
  fi
}

calculate_visible_length() {
  local l_len=0
  for txt in "${L_TXT[@]}"; do
    l_len=$((l_len + ${#txt}))
  done

  local r_len=0
  for txt in "${R_TXT[@]}"; do
    r_len=$((r_len + ${#txt}))
  done

  local n=${#L_TXT[@]}
  local m=${#R_TXT[@]}

  local total_l=0
  local total_r=0

  if [ "$PRESET" = "nerd-font" ]; then
    [ $n -gt 0 ] && total_l=$((l_len + 3 * n))
    [ $m -gt 0 ] && total_r=$((r_len + 3 * m))
  else
    [ $n -gt 0 ] && total_l=$((l_len + 3 * (n - 1)))
    [ $m -gt 0 ] && total_r=$((r_len + 3 * (m - 1)))
  fi

  local gap=0
  [ $n -gt 0 ] && [ $m -gt 0 ] && gap=4

  echo $((total_l + gap + total_r))
}

# Run first populate
populate_segments
LEN=$(calculate_visible_length)

# Prioritized drop order: Credits -> VCS -> Claude -> Gemini -> State
if [ "$LEN" -gt "$WIDTH" ] && [ "$SHOW_CREDITS" = "true" ]; then
  SHOW_CREDITS="false"
  populate_segments
  LEN=$(calculate_visible_length)
fi

if [ "$LEN" -gt "$WIDTH" ] && [ "$SHOW_VCS" = "true" ]; then
  SHOW_VCS="false"
  populate_segments
  LEN=$(calculate_visible_length)
fi

if [ "$LEN" -gt "$WIDTH" ] && [ "$SHOW_CLAUDE" = "true" ]; then
  SHOW_CLAUDE="false"
  populate_segments
  LEN=$(calculate_visible_length)
fi

if [ "$LEN" -gt "$WIDTH" ] && [ "$SHOW_GEMINI" = "true" ]; then
  SHOW_GEMINI="false"
  populate_segments
  LEN=$(calculate_visible_length)
fi

if [ "$LEN" -gt "$WIDTH" ] && [ "$SHOW_STATE" = "true" ]; then
  SHOW_STATE="false"
  populate_segments
  LEN=$(calculate_visible_length)
fi

# ---------------------------------------------------------------------------
# 6. Render Output
# ---------------------------------------------------------------------------
L_LEN=0
for txt in "${L_TXT[@]}"; do
  L_LEN=$((L_LEN + ${#txt}))
done

R_LEN=0
for txt in "${R_TXT[@]}"; do
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
[ $N -gt 0 ] && [ $M -gt 0 ] && GAP_LEN=4

# Clear the rest of the line to prevent rendering glitches in TUI status bars
TOTAL_TEXT_LEN=$((L_LEN + GAP_LEN + R_LEN))
TRAILING_LEN=$((WIDTH - TOTAL_TEXT_LEN))
[ $TRAILING_LEN -lt 0 ] && TRILING_LEN=0

gap_spaces=""
[ $GAP_LEN -gt 0 ] && gap_spaces="    "

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
