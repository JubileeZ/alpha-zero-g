#!/usr/bin/env bash
# tests/test-statusline.sh — Test suite for statusline dynamic multi-quota & active-first formatting

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

STATUSLINE="${REPO_ROOT}/templates/global/statusline.sh"

run_statusline() {
  local json="$1"
  local width="${2:-140}"
  echo "${json}" | jq -c --argjson w "${width}" '.terminal_width = $w' | NO_COLOR=1 bash "${STATUSLINE}"
}

section "1. Argon active model & dynamic multi-quota discovery"

JSON_ARGON_ACTIVE='{
  "agent_state": "idle",
  "model": { "display_name": "Gemini 4 Argon (High)" },
  "context_window": {
    "total_input_tokens": 45200,
    "total_output_tokens": 3100,
    "used_percentage": 52
  },
  "quota": {
    "argon-weekly": {
      "remaining_fraction": 0.78,
      "reset_in_seconds": 302400
    },
    "gemini-5h": {
      "remaining_fraction": 0.90,
      "reset_in_seconds": 17400
    },
    "3p-5h": {
      "remaining_fraction": 0.80,
      "reset_in_seconds": 4500
    }
  }
}'

out=$(run_statusline "${JSON_ARGON_ACTIVE}" 140)

# Check active marker and ordering
if echo "${out}" | grep -qE "▸(Argon|Arg): 78% \(3d12h\)"; then
  pass "Argon identified as active and displays 78% (3d12h)"
else
  fail "Argon active quota missing or wrong format" "${out}"
fi

if echo "${out}" | grep -qE "▸(Argon|Arg):.*·.*(Gem|3P)"; then
  pass "Active model quota placed first in quota cluster"
else
  fail "Active model quota not placed first" "${out}"
fi

# Check standby models show compact timers
if echo "${out}" | grep -qE "(Gemini|Gem): 90% \(4h50m\)"; then
  pass "Gemini standby displays 90% (4h50m)"
else
  fail "Gemini standby quota missing or wrong format" "${out}"
fi

if echo "${out}" | grep -qE "3P: 80% \(1h15m\)"; then
  pass "3P standby displays 80% (1h15m)"
else
  fail "3P standby quota missing or wrong format" "${out}"
fi

# Check context trim: total tokens and percentage present, but in/out token split dropped
if echo "${out}" | grep -qE "Ctx: 48\.3k · 52%"; then
  pass "Context shows compact total tokens and percentage"
else
  fail "Context missing compact total tokens or percentage" "${out}"
fi

if echo "${out}" | grep -qF "(45.2k↓/3.1k↑)"; then
  fail "Context still contains redundant in/out token breakdown" "${out}"
else
  pass "Redundant in/out token breakdown omitted"
fi

section "2. Dual-window weekly surfacing: use-it-or-lose-it and run-out risk"

JSON_USE_IT_OR_LOSE_IT='{
  "agent_state": "idle",
  "model": { "display_name": "Gemini 4 Argon (High)" },
  "context_window": { "used_percentage": 20 },
  "quota": {
    "argon-weekly": {
      "remaining_fraction": 0.78,
      "reset_in_seconds": 302400
    },
    "3p-5h": {
      "remaining_fraction": 0.80,
      "reset_in_seconds": 4500
    },
    "3p-weekly": {
      "remaining_fraction": 0.65,
      "reset_in_seconds": 32400
    }
  }
}'

out_urgent=$(run_statusline "${JSON_USE_IT_OR_LOSE_IT}" 140)

# Weekly reset is in 9 hours with 65% remaining -> should surface weekly timer
if echo "${out_urgent}" | grep -qE "3P: 80% \(1h15m\)/65% \(9h\)"; then
  pass "Use-it-or-lose-it weekly reset (<24h with >20% unused) surfaced for 3P"
else
  fail "Use-it-or-lose-it weekly reset not surfaced" "${out_urgent}"
fi

JSON_HEALTHY_WEEKLY='{
  "agent_state": "idle",
  "model": { "display_name": "Gemini 4 Argon (High)" },
  "context_window": { "used_percentage": 20 },
  "quota": {
    "argon-weekly": {
      "remaining_fraction": 0.78,
      "reset_in_seconds": 302400
    },
    "3p-5h": {
      "remaining_fraction": 0.80,
      "reset_in_seconds": 4500
    },
    "3p-weekly": {
      "remaining_fraction": 0.95,
      "reset_in_seconds": 432000
    }
  }
}'

out_healthy=$(run_statusline "${JSON_HEALTHY_WEEKLY}" 140)

# Weekly is 5 days away and 95% remaining (healthy) -> should NOT surface redundant weekly
if echo "${out_healthy}" | grep -qF "/95%"; then
  fail "Redundant healthy weekly quota unexpectedly surfaced" "${out_healthy}"
else
  pass "Redundant healthy weekly quota hidden when safe and far from reset"
fi

section "3. Active model switch: Gemini Flash active"

JSON_GEMINI_ACTIVE='{
  "agent_state": "idle",
  "model": { "display_name": "Gemini 3.8 Flash (High)" },
  "context_window": { "used_percentage": 20 },
  "quota": {
    "argon-weekly": {
      "remaining_fraction": 0.78,
      "reset_in_seconds": 302400
    },
    "gemini-5h": {
      "remaining_fraction": 0.90,
      "reset_in_seconds": 17400
    },
    "gemini-weekly": {
      "remaining_fraction": 0.82,
      "reset_in_seconds": 259200
    },
    "3p-5h": {
      "remaining_fraction": 0.80,
      "reset_in_seconds": 4500
    }
  }
}'

out_gemini=$(run_statusline "${JSON_GEMINI_ACTIVE}" 140)

if echo "${out_gemini}" | grep -qE "▸(Gemini|Gem): 90% \(4h50m\)"; then
  pass "Gemini identified as active and placed first"
else
  fail "Gemini not identified as active" "${out_gemini}"
fi

if echo "${out_gemini}" | grep -qE "(Argon|Arg): 78% \(3d12h\)"; then
  pass "Argon listed in standby with 78% (3d12h)"
else
  fail "Argon standby quota missing or wrong format" "${out_gemini}"
fi

section "4. Responsive width truncation"

# At width 90, context ASCII bar should drop before quotas drop
out_90=$(run_statusline "${JSON_ARGON_ACTIVE}" 90)

if echo "${out_90}" | grep -qF "████"; then
  fail "Context ASCII bar should drop at width 90" "${out_90}"
else
  pass "Context ASCII bar dropped at compact width"
fi

if echo "${out_90}" | grep -qE "▸(Argon|Arg)"; then
  pass "Active quota preserved at compact width"
else
  fail "Active quota prematurely dropped at compact width" "${out_90}"
fi

section "5. Future model auto-discovery (e.g. Xenon)"

JSON_FUTURE_MODEL='{
  "agent_state": "idle",
  "model": { "display_name": "Gemini 5 Xenon (Ultra)" },
  "context_window": { "used_percentage": 10 },
  "quota": {
    "xenon-weekly": {
      "remaining_fraction": 0.60,
      "reset_in_seconds": 172800
    },
    "gemini-5h": {
      "remaining_fraction": 0.95,
      "reset_in_seconds": 18000
    }
  }
}'

out_future=$(run_statusline "${JSON_FUTURE_MODEL}" 140)

if echo "${out_future}" | grep -qE "▸Xenon: 60% \(2d\)"; then
  pass "Future model Xenon automatically discovered and set active"
else
  fail "Future model Xenon not discovered" "${out_future}"
fi

section "6. Legacy .models[] array backward compatibility"

JSON_LEGACY='{
  "agent_state": "idle",
  "model": { "display_name": "Claude 3.5 Sonnet" },
  "context_window": { "used_percentage": 30 },
  "quota": {
    "models": [
      {
        "label": "gemini-1.5-flash",
        "remainingPercentage": 0.88,
        "isExhausted": false,
        "timeUntilResetMs": 14400000
      },
      {
        "label": "claude-3-5-sonnet",
        "remainingPercentage": 0.72,
        "isExhausted": false,
        "timeUntilResetMs": 7200000
      }
    ]
  }
}'

out_legacy=$(run_statusline "${JSON_LEGACY}" 140)

if echo "${out_legacy}" | grep -qE "▸3P: 72% \(2h\)"; then
  pass "Legacy models array sets 3P active with 72% (2h)"
else
  fail "Legacy models array failed for active 3P" "${out_legacy}"
fi

if echo "${out_legacy}" | grep -qE "(Gemini|Gem): 88% \(4h\)"; then
  pass "Legacy models array sets Gemini standby with 88% (4h)"
else
  fail "Legacy models array failed for standby Gemini" "${out_legacy}"
fi

test_summary
