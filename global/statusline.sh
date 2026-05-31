#!/bin/bash

# Required dependencies: jq, bc
if ! command -v jq >/dev/null 2>&1; then
    echo -e "\033[1;31m[jq missing]\033[0m"
    exit 0
fi

# 1. Read JSON payload from CLI stdin
input=$(cat)

# 2. Extract Native Context Metrics
model_name=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
used_pct_raw=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
used_pct=$(echo "$used_pct_raw" | awk '{printf "%.1f", $1}')

# Derive actual used tokens from percentage * window_size (more accurate than input_tokens alone)
used_tokens=$(echo "$used_pct_raw $window_size" | awk '{printf "%.0f", $1 * $2 / 100}')

# Format helper for large token counts (e.g., 2000000 -> 2.0M, 98500 -> 98.5k)
format_tokens() {
    local val=$1
    if [ "$val" -ge 1000000 ]; then
        printf "%.1fM" "$(echo "scale=2; $val/1000000" | bc)"
    elif [ "$val" -ge 1000 ]; then
        printf "%.1fk" "$(echo "scale=1; $val/1000" | bc)"
    else
        echo "$val"
    fi
}

formatted_used=$(format_tokens "$used_tokens")
formatted_size=$(format_tokens "$window_size")

# 3. Query Quota Cache & Parse Gemini vs Claude
gemini_pct="0.0%"
gemini_reset=""
claude_pct="0.0%"
claude_reset=""

CACHE_FILE="/tmp/antigravity_quota_cache.json"
NOW=$(date +%s)

# Trigger cache refresh in the background if older than 60s
if command -v antigravity-usage >/dev/null 2>&1; then
    if [ -f "$CACHE_FILE" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            mtime=$(stat -f "%m" "$CACHE_FILE")
        else
            mtime=$(stat -c "%Y" "$CACHE_FILE")
        fi
        age=$((NOW - mtime))
    else
        age=999
    fi

    if [ "$age" -gt 60 ]; then
        if [ ! -f "$CACHE_FILE" ] || [ ! -s "$CACHE_FILE" ]; then
            antigravity-usage --json > "$CACHE_FILE" 2>/dev/null
        else
            antigravity-usage --json > "$CACHE_FILE" 2>/dev/null &
        fi
    fi
fi

# Format ms to human-readable reset time
format_reset_time() {
    local time_ms=$1
    if [ -n "$time_ms" ] && [ "$time_ms" != "null" ] && [ "$time_ms" -gt 0 ]; then
        local time_secs=$((time_ms / 1000))
        if [ "$time_secs" -ge 3600 ]; then
            local hrs=$((time_secs / 3600))
            local mins=$(((time_secs % 3600) / 60))
            echo " (${hrs}h ${mins}m)"
        else
            local mins=$((time_secs / 60))
            echo " (${mins}m)"
        fi
    fi
}

# Parse Gemini and Claude quotas & reset times from Cache File
if [ -s "$CACHE_FILE" ]; then
    if jq -e . "$CACHE_FILE" >/dev/null 2>&1; then
        # 1. Parse Gemini Quota & Reset Time
        gemini_model_info=$(jq -c '.models[] | select(.label | contains("Gemini"))' "$CACHE_FILE" 2>/dev/null | head -n 1)
        if [ -n "$gemini_model_info" ]; then
            gemini_quota_raw=$(echo "$gemini_model_info" | jq -r '.remainingPercentage // empty')
            if [ -n "$gemini_quota_raw" ] && [ "$gemini_quota_raw" != "null" ]; then
                gemini_pct=$(echo "$gemini_quota_raw" | awk '{printf "%.1f%%", $1 * 100}')
            fi
            gemini_time_ms=$(echo "$gemini_model_info" | jq -r '.timeUntilResetMs // empty')
            gemini_reset=$(format_reset_time "$gemini_time_ms")
        fi

        # 2. Parse Claude Quota & Reset Time
        claude_model_info=$(jq -c '.models[] | select(.label | contains("Claude"))' "$CACHE_FILE" 2>/dev/null | head -n 1)
        if [ -n "$claude_model_info" ]; then
            claude_quota_raw=$(echo "$claude_model_info" | jq -r '.remainingPercentage // empty')
            if [ -n "$claude_quota_raw" ] && [ "$claude_quota_raw" != "null" ]; then
                claude_pct=$(echo "$claude_quota_raw" | awk '{printf "%.1f%%", $1 * 100}')
            fi
            claude_time_ms=$(echo "$claude_model_info" | jq -r '.timeUntilResetMs // empty')
            claude_reset=$(format_reset_time "$claude_time_ms")
        fi
    fi
fi

# 4. Format & Print ANSI Colored Output (renders directly in TUI status line)
color_model="\033[1;34m"    # Bold Blue
color_context="\033[1;32m"  # Bold Green
color_quota="\033[1;33m"    # Bold Yellow
color_reset="\033[0m"       # Reset Formatting

echo -e "${color_model}Model: ${model_name}${color_reset} | ${color_context}Context: ${formatted_used}/${formatted_size} (${used_pct}%)${color_reset} | ${color_quota}Gemini: ${gemini_pct}${gemini_reset} | Claude: ${claude_pct}${claude_reset}${color_reset}"
