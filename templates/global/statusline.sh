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
# 1. Color Palette & Glyph Setup (Unicode-only; ADR 0001 amended)
# ---------------------------------------------------------------------------
# Colors are enabled unless NO_COLOR is set
if [ -z "${NO_COLOR:-}" ]; then
  RESET="\033[0m"
  BOLD="\033[1m"

  # Foreground colors
  GREEN="\033[38;5;71m"
  YELLOW="\033[38;5;179m"
  ORANGE="\033[38;5;166m"
  RED="\033[38;5;196m"
  BLUE="\033[38;5;67m"
  PURPLE="\033[38;5;97m"
  CYAN="\033[38;5;37m"
  GRAY="\033[38;5;244m"
  MUTED_GRAY="\033[38;5;238m"
  TIMER_GRAY="\033[38;5;244m"
  DIM_WHITE="\033[38;5;248m"
else
  RESET=""
  BOLD=""
  GREEN=""
  YELLOW=""
  ORANGE=""
  RED=""
  BLUE=""
  PURPLE=""
  CYAN=""
  GRAY=""
  MUTED_GRAY=""
  TIMER_GRAY=""
  DIM_WHITE=""
fi

# Unicode glyph mappings
STATE_IDLE_TXT="● IDLE"
STATE_THINKING_TXT="◐ THINKING"
STATE_WORKING_TXT="⚙ WORKING"
STATE_WAITING_TXT="⏸ WAITING"
VCS_ICON="⎇"
WARN_CAUTION="⚠"
WARN_DEGRADING="⚡"
WARN_CRITICAL="🔥"
SEP_CHAR="│"

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
    if [ "$hr" -gt 0 ]; then
      echo "${day}d${hr}h"
    else
      echo "${day}d"
    fi
  elif [ "$hr" -gt 0 ]; then
    if [ "$min" -gt 0 ]; then
      echo "${hr}h${min}m"
    else
      echo "${hr}h"
    fi
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
# Format percentage to 1 decimal place (e.g. 12.3, 52.0, 0.0)
FMT_PCT=$(awk -v p="$CONTEXT_PCT" 'BEGIN { printf "%.1f", (p+0) }' 2>/dev/null || echo "0.0")

# Convert percentage to integer for severity thresholds
INT_PCT="${FMT_PCT%%.*}"
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

# ---------------------------------------------------------------------------
# 4. Fetch Quota Usage & State Specs
# ---------------------------------------------------------------------------
QUOTA_JSON=$(echo "$input" | jq -r '.quota // empty' 2>/dev/null)
if [ -z "$QUOTA_JSON" ] || [ "$QUOTA_JSON" = "null" ]; then
  QUOTA_JSON="{}"
fi

ELAPSED_SEC=0
if [ "$QUOTA_JSON" != "{}" ]; then
  CACHE_FILE="${HOME}/.gemini/antigravity-cli/quota_cache.json"
  NOW=$(date +%s)
  CURRENT_HASH=$(echo "$QUOTA_JSON" | md5sum | awk '{print $1}')
  if [ -f "$CACHE_FILE" ]; then
    CACHED_HASH=$(jq -r '.hash // empty' "$CACHE_FILE" 2>/dev/null)
    if [ "$CURRENT_HASH" != "$CACHED_HASH" ]; then
      jq -n --arg h "$CURRENT_HASH" --arg t "$NOW" '{hash: $h, time: $t}' > "$CACHE_FILE" 2>/dev/null
    else
      CACHED_TIME=$(jq -r '.time // 0' "$CACHE_FILE" 2>/dev/null)
      if [ -n "$CACHED_TIME" ] && [ "$CACHED_TIME" != "null" ] && [ "$CACHED_TIME" -gt 0 ] 2>/dev/null; then
        ELAPSED_SEC=$(( NOW - CACHED_TIME ))
      fi
    fi
  else
    jq -n --arg h "$CURRENT_HASH" --arg t "$NOW" '{hash: $h, time: $t}' > "$CACHE_FILE" 2>/dev/null
  fi
fi

# Active Model Detection
ACTIVE_FAMILY=""
M_LOWER=$(echo "${MODEL_NAME}" | tr '[:upper:]' '[:lower:]')
if echo "$M_LOWER" | grep -q "argon"; then
  ACTIVE_FAMILY="argon"
elif echo "$M_LOWER" | grep -qE "claude|sonnet|opus|haiku"; then
  ACTIVE_FAMILY="3p"
fi

# Dynamic Quota Families Extraction
declare -a PARSED_FAMILIES=()
if [ "$QUOTA_JSON" != "{}" ]; then
  JQ_PARSER='
    def parse_items:
      if .models and (.models | length > 0) then
        .models[] | {
          family: (
            if (.label | ascii_downcase | contains("claude")) then "3p"
            elif (.label | ascii_downcase | contains("argon")) then "argon"
            elif (.label | ascii_downcase | contains("gemini")) then "gemini"
            else (.label | ascii_downcase | split(" ")[0]) end
          ),
          window: "primary",
          fraction: (.remainingPercentage // 1.0),
          exhausted: (.isExhausted // false),
          reset_sec: (((.timeUntilResetMs // 0) / 1000) - ($e | tonumber) | if . < 0 then 0 else . end)
        }
      elif (. | type == "object") then
        to_entries[] | select(.key != "promptCredits") | {
          family: (
            # Strip window suffix, then a leading gemini-[<ver>-] when a sub-model follows
            # (gemini-argon-weekly / gemini-4-argon-weekly -> argon; gemini-5h -> gemini)
            .key | ascii_downcase | sub("-(5h|weekly|daily|monthly)$"; "")
            | if test("^gemini-([0-9.]+-)?[a-z]") then sub("^gemini-([0-9.]+-)?"; "") else . end
          ),
          window: (
            if (.key | endswith("-weekly")) then "weekly"
            elif (.key | endswith("-5h")) then "5h"
            else "primary" end
          ),
          fraction: (.value.remaining_fraction // 1.0),
          exhausted: ((.value.remaining_fraction // 1.0) <= 0),
          reset_sec: (((.value.reset_in_seconds // 0)) - ($e | tonumber) | if . < 0 then 0 else . end)
        }
      else empty end;

    [parse_items] | group_by(.family)[] | 
      # [..][0] (not .[] streams) so a family never emits duplicate rows
      ([.[] | select(.window != "weekly")][0] // .[0]) as $prim |
      (if $prim.window != "weekly" then [.[] | select(.window == "weekly")][0] else null end) as $wk |
      [
        .[0].family,
        (($prim.fraction * 100) | floor),
        ($prim.exhausted),
        ($prim.reset_sec | floor),
        (if $wk then (($wk.fraction * 100) | floor) else -1 end),
        (if $wk then ($wk.reset_sec | floor) else -1 end),
        (if $wk then ($wk.exhausted) else false end),
        ($prim.window == "weekly")
      ] | @tsv
  '
  while IFS= read -r line; do
    [ -n "$line" ] && PARSED_FAMILIES+=("$line")
  done < <(echo "$QUOTA_JSON" | jq -r --arg e "$ELAPSED_SEC" "$JQ_PARSER" 2>/dev/null || true)
fi

# Fallback active family if still empty: check non-gemini families first, then gemini
if [ -z "$ACTIVE_FAMILY" ]; then
  for item in "${PARSED_FAMILIES[@]+"${PARSED_FAMILIES[@]}"}"; do
    fam="${item%%$'\t'*}"
    if [ -n "$fam" ] && [ "$fam" != "gemini" ] && echo "$M_LOWER" | grep -q "$fam"; then
      ACTIVE_FAMILY="$fam"
      break
    fi
  done
  if [ -z "$ACTIVE_FAMILY" ] && echo "$M_LOWER" | grep -q "gemini"; then
    ACTIVE_FAMILY="gemini"
  fi
fi

# Active sub-model without its own bucket (e.g. Argon, no argon-* key) -> fall back to gemini
_active_found="false"
for item in "${PARSED_FAMILIES[@]+"${PARSED_FAMILIES[@]}"}"; do
  [ "${item%%$'\t'*}" = "$ACTIVE_FAMILY" ] && _active_found="true" && break
done
if [ "$_active_found" = "false" ] && echo "$M_LOWER" | grep -q "gemini"; then
  ACTIVE_FAMILY="gemini"
fi

# Order families: Active first, then argon -> gemini -> 3p, then others (alphabetical from jq)
ORDERED_FAMILIES=()
_seen="|"
for want in "$ACTIVE_FAMILY" argon gemini 3p "*"; do
  for item in "${PARSED_FAMILIES[@]+"${PARSED_FAMILIES[@]}"}"; do
    fam="${item%%$'\t'*}"
    case "$_seen" in *"|${fam}|"*) continue ;; esac
    if [ "$want" = "*" ] || [ "$fam" = "$want" ]; then
      ORDERED_FAMILIES+=("$item")
      _seen="${_seen}${fam}|"
    fi
  done
done

CREDITS_REM=$(echo "$QUOTA_JSON" | jq -r '.promptCredits.remainingPercentage // empty' 2>/dev/null)
CREDITS_AV=$(echo "$QUOTA_JSON" | jq -r '.promptCredits.available // empty' 2>/dev/null)
CREDITS_MON=$(echo "$QUOTA_JSON" | jq -r '.promptCredits.monthly // empty' 2>/dev/null)
CR_PCT_VAL=""
if [ -n "$CREDITS_REM" ] && [ "$CREDITS_REM" != "null" ] && [ "$CREDITS_REM" != "" ]; then
  CR_PCT_VAL=$(echo "$CREDITS_REM" | awk '{print int($1 * 100)}')
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

# ---------------------------------------------------------------------------
# 5. Segment Assembly & Truncation Loop
# ---------------------------------------------------------------------------
# Flags for dynamic truncation
SHOW_STATE="true"
SHOW_MODEL="true"
SHOW_CONTEXT="true"
SHOW_CONTEXT_BAR="true"
SHOW_QUOTAS="true"
SHOW_QUOTA_BAR="true"
SHOW_STANDBY_QUOTAS="true"
SHOW_HEALTHY_STANDBY_TIMERS="true"
FOLD_NON_CRITICAL_STANDBY_WEEKLY="false"
SHOW_CREDITS="true"
SHOW_VCS="true"

ABBREV_CTX="false"
ABBREV_NAMES="false"

# Declare arrays for segments
declare -a L_TXT
declare -a L_RAW_TXT
declare -a L_BG
declare -a L_FG
declare -a L_CLR

declare -a R_TXT
declare -a R_RAW_TXT
declare -a R_BG
declare -a R_FG
declare -a R_CLR

populate_segments() {
  L_TXT=() L_RAW_TXT=() L_BG=() L_FG=() L_CLR=()
  R_TXT=() R_RAW_TXT=() R_BG=() R_FG=() R_CLR=()

  # 1. PROJECT & GIT (VCS)
  if [ "$SHOW_VCS" = "true" ]; then
    local txt=""
    if [ -n "$PROJECT_NAME" ]; then
      if [ "$ABBREV_NAMES" = "true" ] && [ ${#PROJECT_NAME} -gt 16 ]; then
        txt="${PROJECT_NAME:0:13}.."
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
      L_RAW_TXT+=("${txt}")
      L_BG+=(239)
      L_FG+=(248)
      L_CLR+=("${GRAY}")
    fi
  fi

  # 2. STATE
  if [ "$SHOW_STATE" = "true" ] && [ -n "${STATE_TXT}" ]; then
    local st_txt="${STATE_TXT}"
    if [ "$ABBREV_NAMES" = "true" ]; then
      st_txt=$(echo "$st_txt" | sed -E 's/ [0-9]+[a-z]+//g')
    fi
    L_TXT+=("${st_txt}")
    L_RAW_TXT+=("${st_txt}")
    L_BG+=("${STATE_BG}")
    L_FG+=("${STATE_FG}")
    L_CLR+=("${STATE_CLR}")
  fi

  # 3. MODEL
  if [ -n "${MODEL_NAME}" ] && [ "$SHOW_MODEL" != "false" ]; then
    local display_model="${MODEL_NAME}"
    if [ "$ABBREV_NAMES" = "true" ]; then
      display_model=$(echo "$display_model" | sed 's/^Gemini //;s/^Claude //')
      if [ ${#display_model} -gt 14 ]; then
        display_model="${display_model:0:12}.."
      fi
    fi
    L_TXT+=("✦ ${display_model}")
    L_RAW_TXT+=("✦ ${display_model}")
    L_BG+=(236)
    L_FG+=(250)
    L_CLR+=("${BOLD}${CYAN}")
  fi

  # 4. CONTEXT
  if [ "$SHOW_CONTEXT" != "false" ] && [ -n "${CONTEXT_PCT}" ]; then
    local ctx_prefix=""
    if [ "$WIDTH" -ge 65 ]; then
      ctx_prefix="Ctx: "
    fi

    local ctx_bar=""
    if [ "$SHOW_CONTEXT_BAR" = "true" ] && [ "$WIDTH" -ge 95 ]; then
      local num_cells=$(( (INT_PCT + 5) / 10 ))
      [ "$num_cells" -gt 10 ] && num_cells=10
      [ "$num_cells" -lt 0 ] && num_cells=0
      local num_empty=$(( 10 - num_cells ))
      local FULL_BAR="██████████"
      local EMPTY_BAR="░░░░░░░░░░"
      ctx_bar=" ${FULL_BAR:0:num_cells}${EMPTY_BAR:0:num_empty}"
    fi

    local txt="${ctx_prefix}${FMT_PCT}%${ctx_bar}"

    local c_bg=65
    local c_clr="${GREEN}"
    case "$FINAL_SEV" in
      3) txt="${txt} ${WARN_CRITICAL}"; c_bg=124; c_clr="${RED}" ;;
      2) txt="${txt} ${WARN_DEGRADING}"; c_bg=166; c_clr="${ORANGE}" ;;
      1) txt="${txt} ${WARN_CAUTION}"; c_bg=136; c_clr="${YELLOW}" ;;
      *) c_bg=65; c_clr="${GREEN}" ;;
    esac

    L_TXT+=("${txt}")
    L_RAW_TXT+=("${txt}")
    L_BG+=("${c_bg}")
    L_FG+=("${CONTEXT_FG:-255}")
    L_CLR+=("${c_clr}")
  fi

  # 5. QUOTAS (Unified Cluster, Active First)
  if [ "$SHOW_QUOTAS" = "true" ] && [ ${#ORDERED_FAMILIES[@]} -gt 0 ]; then
    local quota_items=()
    local quota_raw_items=()

    for item in "${ORDERED_FAMILIES[@]}"; do
      local fam prim_pct prim_exh prim_reset_sec wk_pct wk_reset_sec wk_exh is_wk_only
      IFS=$'\t' read -r fam prim_pct prim_exh prim_reset_sec wk_pct wk_reset_sec wk_exh is_wk_only <<< "$item"
      [ "$wk_pct" = "-1" ] && wk_pct=""
      [ "$wk_reset_sec" = "-1" ] && wk_reset_sec=""

      local is_active="false"
      [ "$fam" = "$ACTIVE_FAMILY" ] && is_active="true"

      if [ "$is_active" = "false" ] && [ "$SHOW_STANDBY_QUOTAS" = "false" ]; then
        continue
      fi

      local lbl=""
      if [ "$fam" = "argon" ]; then
        if [ "$is_active" = "true" ] || [ "$ABBREV_NAMES" != "true" ]; then lbl="Argon"; else lbl="Arg"; fi
      elif [ "$fam" = "gemini" ]; then
        if [ "$is_active" = "true" ] || [ "$ABBREV_NAMES" != "true" ]; then lbl="Gemini"; else lbl="Gem"; fi
      elif [ "$fam" = "3p" ]; then
        if [ "$is_active" = "true" ] || [ "$ABBREV_NAMES" != "true" ]; then lbl="Other"; else lbl="Oth"; fi
      else
        lbl="$(echo "${fam:0:1}" | tr '[:lower:]' '[:upper:]')${fam:1}"
        if [ "$is_active" != "true" ] && [ "$ABBREV_NAMES" = "true" ] && [ ${#lbl} -gt 4 ]; then
          lbl="${lbl:0:3}"
        fi
      fi

      local pfx=""
      [ "$is_active" = "true" ] && pfx="▸"

      local q_bar=""
      if [ "$is_active" = "true" ] && [ "$SHOW_QUOTA_BAR" = "true" ]; then
        local num_pills=0
        if [ "$prim_exh" != "true" ]; then
          num_pills=$(( (prim_pct + 10) / 20 ))
          [ "$num_pills" -gt 5 ] && num_pills=5
          [ "$num_pills" -lt 0 ] && num_pills=0
        fi
        local num_empty=$(( 5 - num_pills ))
        local FULL_PILLS="▰▰▰▰▰"
        local EMPTY_PILLS="▱▱▱▱▱"
        q_bar=" ${FULL_PILLS:0:num_pills}${EMPTY_PILLS:0:num_empty}"
      fi

      local prim_pct_str=""
      if [ "$prim_exh" = "true" ]; then
        prim_pct_str="Exh"
      else
        prim_pct_str="${prim_pct}%"
      fi

      local prim_txt="${prim_pct_str}${q_bar}"

      local show_timer="true"
      if [ "$is_active" != "true" ] && [ "$SHOW_HEALTHY_STANDBY_TIMERS" = "false" ]; then
        if [ "$prim_exh" != "true" ] && [ "$prim_pct" -ge 20 ]; then
          show_timer="false"
        fi
      fi

      local t_txt=""
      if [ "$show_timer" = "true" ] && [ -n "$prim_reset_sec" ] && [ "$prim_reset_sec" -gt 0 ]; then
        t_txt=$(format_time "$((prim_reset_sec * 1000))")
        if [ "$is_wk_only" = "true" ] && [ "$prim_reset_sec" -le 86400 ] && [ "$prim_pct" -ge 20 ]; then
          t_txt="⚡${t_txt}"
        fi
        [ -n "$t_txt" ] && prim_txt="${prim_txt} (${t_txt})"
      fi

      local wk_txt=""
      local wk_pct_str=""
      local wt_txt=""
      local show_wk="false"
      if [ -n "$wk_pct" ] && [ "$is_wk_only" = "false" ]; then
        local week_pct_left=0
        [ -n "$wk_reset_sec" ] && [ "$wk_reset_sec" -gt 0 ] && week_pct_left=$(( wk_reset_sec * 100 / 604800 ))

        if [ "$is_active" = "true" ]; then
          if [ "$FOLD_NON_CRITICAL_STANDBY_WEEKLY" != "true" ] || [ "$wk_pct" -lt "$week_pct_left" ] || [ "$wk_pct" -lt 50 ]; then
            show_wk="true"
          fi
        else
          # Standby models: only surface weekly if exhausted or almost exhausted (<20%)
          if [ "$wk_exh" = "true" ] || [ "$wk_pct" -lt 20 ]; then
            show_wk="true"
          fi
        fi

        if [ "$show_wk" = "true" ]; then
          local splurge="false"
          local risk="false"
          if [ "$wk_exh" = "true" ] || [ "$wk_pct" -lt 20 ]; then
            risk="true"
          elif [ -n "$wk_reset_sec" ] && [ "$wk_reset_sec" -le 86400 ] && [ "$wk_pct" -ge 20 ]; then
            splurge="true"
          fi

          if [ "$wk_exh" = "true" ]; then
            wk_pct_str="Exh"
          else
            wk_pct_str="${wk_pct}%wk"
          fi

          if [ "$risk" = "true" ]; then
            wk_pct_str="${wk_pct_str} ⚠"
          fi

          if [ "$show_timer" = "true" ] && [ -n "$wk_reset_sec" ] && [ "$wk_reset_sec" -gt 0 ]; then
            wt_txt=$(format_time "$((wk_reset_sec * 1000))")
            if [ "$splurge" = "true" ]; then
              wt_txt="⚡${wt_txt}"
            fi
          fi

          wk_txt=" ╱ ${wk_pct_str}"
          [ -n "$wt_txt" ] && wk_txt="${wk_txt} (${wt_txt})"
        fi
      fi

      local clr="${GREEN}"
      local is_red="false"
      local is_yellow="false"

      if [ "$prim_exh" = "true" ] || [ "$prim_pct" -lt 20 ]; then
        is_red="true"
      elif [ -n "$wk_pct" ] && { [ "$wk_exh" = "true" ] || [ "$wk_pct" -lt 20 ]; }; then
        is_red="true"
      elif [ "$prim_pct" -lt 50 ]; then
        is_yellow="true"
      elif [ -n "$wk_pct" ] && [ -n "$wk_reset_sec" ]; then
        local week_pct_left=$(( wk_reset_sec * 100 / 604800 ))
        if [ "$wk_pct" -lt "$week_pct_left" ] || [ "$wk_pct" -lt 50 ]; then
          is_yellow="true"
        fi
      elif [ "$is_wk_only" = "true" ] && [ -n "$prim_reset_sec" ]; then
        local week_pct_left=$(( prim_reset_sec * 100 / 604800 ))
        if [ "$prim_pct" -lt "$week_pct_left" ]; then
          is_yellow="true"
        fi
      fi

      if [ "$is_red" = "true" ]; then
        clr="${RED}"
      elif [ "$is_yellow" = "true" ]; then
        clr="${YELLOW}"
      elif [ "$is_active" != "true" ]; then
        clr="${DIM_WHITE}"
      fi

      local item_rendered="${pfx}${lbl}: ${prim_txt}${wk_txt}"
      quota_raw_items+=("${item_rendered}")

      local item_ansi=""
      if [ -n "$RESET" ]; then
        local wk_ansi=""
        if [ "$show_wk" = "true" ]; then
          local wk_clr="${GREEN}"
          if [ "$wk_exh" = "true" ] || [ "$wk_pct" -lt 20 ]; then
            wk_clr="${RED}"
          elif [ "$wk_pct" -lt 50 ]; then
            wk_clr="${YELLOW}"
          elif [ "$is_active" != "true" ]; then
            wk_clr="${DIM_WHITE}"
          fi
          wk_ansi=" ${MUTED_GRAY}╱${RESET} ${BOLD}${wk_clr}${wk_pct_str}${RESET}"
          [ -n "$wt_txt" ] && wk_ansi="${wk_ansi} ${TIMER_GRAY}(${wt_txt})${RESET}"
        fi

        if [ "$is_active" = "true" ]; then
          item_ansi="${BOLD}${clr}${pfx}${lbl}:${RESET} ${BOLD}${clr}${prim_pct_str}${q_bar}${RESET}"
          [ -n "$t_txt" ] && item_ansi="${item_ansi} ${TIMER_GRAY}(${t_txt})${RESET}"
          [ -n "$wk_ansi" ] && item_ansi="${item_ansi}${wk_ansi}"
        else
          item_ansi="${clr}${lbl}:${RESET} ${clr}${prim_pct_str}${RESET}"
          [ -n "$t_txt" ] && item_ansi="${item_ansi} ${TIMER_GRAY}(${t_txt})${RESET}"
          [ -n "$wk_ansi" ] && item_ansi="${item_ansi}${wk_ansi}"
        fi
      else
        item_ansi="${item_rendered}"
      fi
      quota_items+=("${item_ansi}")
    done

    if [ ${#quota_items[@]} -gt 0 ]; then
      local joined_quota=""
      local raw_joined_quota=""
      for ((qi=0; qi<${#quota_items[@]}; qi++)); do
        if [ $qi -eq 0 ]; then
          joined_quota="${quota_items[qi]}"
          raw_joined_quota="${quota_raw_items[qi]}"
        else
          if [ -n "$RESET" ]; then
            joined_quota="${joined_quota}${MUTED_GRAY} · ${RESET}${quota_items[qi]}"
          else
            joined_quota="${joined_quota} · ${quota_items[qi]}"
          fi
          raw_joined_quota="${raw_joined_quota} · ${quota_raw_items[qi]}"
        fi
      done

      if [ -n "$RESET" ]; then
        L_TXT+=("${joined_quota}")
      else
        L_TXT+=("${raw_joined_quota}")
      fi
      L_RAW_TXT+=("${raw_joined_quota}")
      L_BG+=(236)
      L_FG+=(250)
      L_CLR+=("")
    fi
  fi
}

calculate_visible_length() {
  local l_len=0
  for txt in "${L_RAW_TXT[@]+"${L_RAW_TXT[@]}"}"; do
    l_len=$((l_len + ${#txt}))
  done
  local r_len=0
  for txt in "${R_RAW_TXT[@]+"${R_RAW_TXT[@]}"}"; do
    r_len=$((r_len + ${#txt}))
  done
  local n=${#L_RAW_TXT[@]}
  local m=${#R_RAW_TXT[@]}
  local total_l=0
  [ $n -gt 0 ] && total_l=$((l_len + 3 * (n - 1)))
  local total_r=0
  [ $m -gt 0 ] && total_r=$((r_len + 3 * (m - 1)))
  local gap=0
  [ $n -gt 0 ] && [ $m -gt 0 ] && gap=4
  echo $((total_l + gap + total_r))
}

# Initial population
populate_segments
LEN=$(calculate_visible_length)

# (1) Drop context progress bar (saving 11 columns)
if [ "$LEN" -gt "$WIDTH" ]; then
  SHOW_CONTEXT_BAR="false"; populate_segments; LEN=$(calculate_visible_length)
fi

# (2) Abbreviate standby names (Gemini -> Gem, Other -> Oth)
if [ "$LEN" -gt "$WIDTH" ]; then
  ABBREV_NAMES="true"; populate_segments; LEN=$(calculate_visible_length)
fi

# (3) Drop active quota progress bar (▰▰▰▰▱)
if [ "$LEN" -gt "$WIDTH" ]; then
  SHOW_QUOTA_BAR="false"; populate_segments; LEN=$(calculate_visible_length)
fi

# (4) Fold non-critical standby weekly sub-windows
if [ "$LEN" -gt "$WIDTH" ]; then
  FOLD_NON_CRITICAL_STANDBY_WEEKLY="true"; populate_segments; LEN=$(calculate_visible_length)
fi

# (5) Drop healthy standby reset timers (preserving exhausted or <20% timers)
if [ "$LEN" -gt "$WIDTH" ]; then
  SHOW_HEALTHY_STANDBY_TIMERS="false"; populate_segments; LEN=$(calculate_visible_length)
fi

# (6) Drop standby quotas (preserving Active Quota)
if [ "$LEN" -gt "$WIDTH" ]; then
  SHOW_STANDBY_QUOTAS="false"; populate_segments; LEN=$(calculate_visible_length)
fi

# (7) Drop VCS (project ⎇ branch)
if [ "$LEN" -gt "$WIDTH" ] && [ "$SHOW_VCS" = "true" ]; then
  SHOW_VCS="false"; populate_segments; LEN=$(calculate_visible_length)
fi

# (8) Drop Context entirely
if [ "$LEN" -gt "$WIDTH" ] && [ "$SHOW_CONTEXT" = "true" ]; then
  SHOW_CONTEXT="false"; populate_segments; LEN=$(calculate_visible_length)
fi


L_LEN=0
for txt in "${L_RAW_TXT[@]+"${L_RAW_TXT[@]}"}"; do
  L_LEN=$((L_LEN + ${#txt}))
done

R_LEN=0
for txt in "${R_RAW_TXT[@]+"${R_RAW_TXT[@]}"}"; do
  R_LEN=$((R_LEN + ${#txt}))
done

N=${#L_TXT[@]}
M=${#R_TXT[@]}

[ $N -gt 0 ] && L_LEN=$((L_LEN + 3 * (N - 1)))
[ $M -gt 0 ] && R_LEN=$((R_LEN + 3 * (M - 1)))

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

# Assemble outputs (Unicode foreground styling)
left_output=""
r_output=""

for ((i=0; i<N; i++)); do
  clr="${L_CLR[i]}"
  txt="${L_TXT[i]}"
  if [ -n "$clr" ]; then
    if [ $i -eq 0 ]; then
      left_output+="${clr}${txt}${RESET}"
    else
      left_output+="${MUTED_GRAY} ${SEP_CHAR} ${RESET}${clr}${txt}${RESET}"
    fi
  else
    if [ $i -eq 0 ]; then
      left_output+="${txt}"
    else
      left_output+="${MUTED_GRAY} ${SEP_CHAR} ${RESET}${txt}"
    fi
  fi
done

for ((j=0; j<M; j++)); do
  clr="${R_CLR[j]}"
  txt="${R_TXT[j]}"
  if [ $j -eq 0 ]; then
    r_output+="${clr}${txt}${RESET}"
  else
    r_output+="${MUTED_GRAY} ${SEP_CHAR} ${RESET}${clr}${txt}${RESET}"
  fi
done

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
