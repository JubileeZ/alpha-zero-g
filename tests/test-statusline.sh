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
if echo "${out}" | grep -qE "▸(Argon|Arg): 78% ▰▰▰▰▱ \(3d12h\)"; then
  pass "Argon identified as active and displays 78% ▰▰▰▰▱ (3d12h)"
else
  fail "Argon active quota missing or wrong format" "${out}"
fi

if echo "${out}" | grep -qE "▸(Argon|Arg):.*·.*(Gem|Other|Oth)"; then
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

if echo "${out}" | grep -qE "(Other|Oth): 80% \(1h15m\)"; then
  pass "Other standby displays 80% (1h15m)"
else
  fail "Other standby quota missing or wrong format" "${out}"
fi

# Check context: decimal percentage and 10-cell progress bar present, raw token numbers omitted
if echo "${out}" | grep -qE "Ctx: 52\.0% █████░░░░░ ⚠"; then
  pass "Context shows 1-decimal percentage and 10-cell progress bar"
else
  fail "Context missing 1-decimal percentage or 10-cell progress bar" "${out}"
fi

if echo "${out}" | grep -qE "(48\.3k|45\.2k)"; then
  fail "Context still contains raw token values" "${out}"
else
  pass "Raw token values omitted from context"
fi

section "2. Dual-window weekly surfacing: use-it-or-lose-it and run-out risk"

# Standby with healthy weekly (<24h reset, 65% remaining):
# Per user rule, standby models show ONLY 5-hour window unless exhausted or <20%
JSON_STANDBY_HEALTHY='{
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

out_healthy=$(run_statusline "${JSON_STANDBY_HEALTHY}" 140)

if echo "${out_healthy}" | grep -qE "(Other|Oth): 80% \(1h15m\)( *·| *$)" && ! echo "${out_healthy}" | grep -qE "(Other|Oth):.*wk"; then
  pass "Standby healthy weekly hidden; only 5h sprint shown"
else
  fail "Standby healthy weekly unexpectedly surfaced" "${out_healthy}"
fi

# Standby with run-out risk (<20% remaining): surfaces weekly window with warning
JSON_STANDBY_RISK='{
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
      "remaining_fraction": 0.15,
      "reset_in_seconds": 32400
    }
  }
}'

out_risk=$(run_statusline "${JSON_STANDBY_RISK}" 140)

if echo "${out_risk}" | grep -qE "(Other|Oth): 80% \(1h15m\) ╱ 15%wk ⚠ \(9h\)"; then
  pass "Standby almost exhausted (<20%) weekly surfaced with warning"
else
  fail "Standby run-out risk weekly not surfaced" "${out_risk}"
fi

# Active model with splurge (<24h reset, >=20% remaining): surfaces ⚡ indicator
JSON_ACTIVE_SPLURGE='{
  "agent_state": "idle",
  "model": { "display_name": "Gemini 3.8 Flash (High)" },
  "context_window": { "used_percentage": 20 },
  "quota": {
    "gemini-5h": {
      "remaining_fraction": 0.90,
      "reset_in_seconds": 17400
    },
    "gemini-weekly": {
      "remaining_fraction": 0.65,
      "reset_in_seconds": 32400
    }
  }
}'

out_splurge=$(run_statusline "${JSON_ACTIVE_SPLURGE}" 140)

if echo "${out_splurge}" | grep -qE "▸(Gemini|Gem): 90% ▰▰▰▰▰ \(4h50m\) ╱ 65%wk \(⚡9h\)"; then
  pass "Active model splurge window (<24h, >=20%) surfaced with ⚡"
else
  fail "Active model splurge window not surfaced" "${out_splurge}"
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

if echo "${out_gemini}" | grep -qE "▸(Gemini|Gem): 90% ▰▰▰▰▰ \(4h50m\) ╱ 82%wk \(3d\)"; then
  pass "Gemini identified as active and placed first with dual-window"
else
  fail "Gemini not identified as active" "${out_gemini}"
fi

if echo "${out_gemini}" | grep -qE "(Argon|Arg): 78% \(3d12h\)"; then
  pass "Argon listed in standby with 78% (3d12h)"
else
  fail "Argon standby quota missing or wrong format" "${out_gemini}"
fi

section "4. Responsive width truncation"

# At width 90, context progress bar drops while decimal percentage and active quota are preserved
out_90=$(run_statusline "${JSON_ARGON_ACTIVE}" 90)

if echo "${out_90}" | grep -qF "████"; then
  fail "Context progress bar should drop at width 90" "${out_90}"
else
  pass "Context progress bar dropped at compact width"
fi

if echo "${out_90}" | grep -qE "Ctx: 52\.0%"; then
  pass "Context decimal percentage preserved at compact width"
else
  fail "Context decimal percentage missing at compact width" "${out_90}"
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

if echo "${out_future}" | grep -qE "▸Xenon: 60% ▰▰▰▱▱ \(2d\)"; then
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

if echo "${out_legacy}" | grep -qE "▸(Other|Oth): 72% ▰▰▰▰▱ \(2h\)"; then
  pass "Legacy models array sets Other active with 72% (2h)"
else
  fail "Legacy models array failed for active Other" "${out_legacy}"
fi

if echo "${out_legacy}" | grep -qE "(Gemini|Gem): 88% \(4h\)"; then
  pass "Legacy models array sets Gemini standby with 88% (4h)"
else
  fail "Legacy models array failed for standby Gemini" "${out_legacy}"
fi

section "7. Gemini-prefixed Argon bucket keys (no collision, no duplicates)"

for argon_key in "gemini-argon-weekly" "gemini-4-argon-weekly"; do
  JSON_PREFIXED='{
    "agent_state": "idle",
    "model": { "display_name": "Gemini 4 Argon (High)" },
    "context_window": { "used_percentage": 20 },
    "quota": {
      "gemini-5h": { "remaining_fraction": 0.90, "reset_in_seconds": 17400 },
      "gemini-weekly": { "remaining_fraction": 0.82, "reset_in_seconds": 259200 },
      "'"${argon_key}"'": { "remaining_fraction": 0.78, "reset_in_seconds": 302400 },
      "3p-5h": { "remaining_fraction": 0.80, "reset_in_seconds": 4500 }
    }
  }'
  out_pref=$(run_statusline "${JSON_PREFIXED}" 140)

  if echo "${out_pref}" | grep -qE "▸Argon: 78% ▰▰▰▰▱ \(3d12h\) · Gemini: 90% \(4h50m\)[^·]* · Other: 80% \(1h15m\)"; then
    pass "${argon_key}: order Active Argon → Gemini → Other"
  else
    fail "${argon_key}: Argon missing or wrong order" "${out_pref}"
  fi

  gem_count=$(echo "${out_pref}" | grep -o "Gemini:" | wc -l | tr -d ' ')
  if [ "${gem_count}" = "1" ]; then
    pass "${argon_key}: Gemini rendered exactly once"
  else
    fail "${argon_key}: Gemini rendered ${gem_count} times" "${out_pref}"
  fi
done

section "8. Standby order and sub-model fallback"

JSON_ORDER='{
  "agent_state": "idle",
  "model": { "display_name": "Claude Opus 5.5 (Medium)" },
  "context_window": { "used_percentage": 20 },
  "quota": {
    "gemini-5h": { "remaining_fraction": 0.90, "reset_in_seconds": 17400 },
    "argon-weekly": { "remaining_fraction": 0.78, "reset_in_seconds": 302400 },
    "3p-5h": { "remaining_fraction": 0.80, "reset_in_seconds": 4500 }
  }
}'
out_order=$(run_statusline "${JSON_ORDER}" 140)
if echo "${out_order}" | grep -qE "▸Other: 80% ▰▰▰▰▱ \(1h15m\) · Argon: 78% \(3d12h\) · Gemini: 90% \(4h50m\)"; then
  pass "Other active: standby Argon before Gemini"
else
  fail "Other active: wrong standby order" "${out_order}"
fi

JSON_NO_ARGON='{
  "agent_state": "idle",
  "model": { "display_name": "Gemini 4 Argon (High)" },
  "context_window": { "used_percentage": 20 },
  "quota": {
    "3p-5h": { "remaining_fraction": 0.80, "reset_in_seconds": 4500 },
    "gemini-5h": { "remaining_fraction": 0.90, "reset_in_seconds": 17400 }
  }
}'
out_noarg=$(run_statusline "${JSON_NO_ARGON}" 140)
if echo "${out_noarg}" | grep -qE "▸Gemini: 90% ▰▰▰▰▰ \(4h50m\).* · Other: 80%"; then
  pass "Argon active w/o own bucket falls back to Gemini first"
else
  fail "Argon active w/o bucket: Gemini not promoted" "${out_noarg}"
fi

test_summary
