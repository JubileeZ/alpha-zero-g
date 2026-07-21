# Pilot preregistration (Phase 9)

**Status:** thresholds locked in `prereg.json` (2026-07-21).  
**Not a reliability claim.** Exploratory runs may not be used to “pass” confirmation.

## Layers

| Layer | Purpose | May claim Reliable Delivery? |
|-------|---------|------------------------------|
| **Exploratory** | Shake out scripts, IDE friction, scorecard habit | **No** |
| **Confirmation** | Preregistered N + thresholds on Evaluation Suite | Only if green **and** held-out also green |
| **Held-out** | Fresh pairs after confirmation; same rules | Required before any public claim |

## Confirmation sample size (locked)

- **3** paired runs per fixture × **3** fixtures = **9** pairs  
- Each pair = one `core` + one `baseline` on the same fixture, same model/IDE rules  
- **≥1** Long-Horizon completion on `bug-fix`  
- Blind Judge: fixed model in `evals/judge/config.json`; calibration gap ≤ 1.0 before confirmation starts

## Primary threshold (locked)

`task_success_rate(core) − task_success_rate(baseline) ≥ 0`  
(Task Success = assertions pass **and** Blind Judge pass.)

## Secondary (locked)

- median Delivery Cost(core) / median(baseline) ≤ **1.25**  
- median interventions(core) − median(baseline) ≤ **0**

## Held-out (locked)

- **2** pairs per fixture (**6** pairs); **no** reuse of confirmation pairs  

Change control: edit `prereg.json` only by appending a new `version` and new `locked_at` **before** any confirmation pair is started. Never rewrite after.

## Exploratory log

Append JSON lines to `exploratory-log.jsonl` via `evals/record-pilot-pair.sh` or by hand. Every line must include `"phase":"exploratory"` and `"reliability_claim":false`.

## Held-out

See [`HELD-OUT.md`](HELD-OUT.md). Analyze: `bash evals/analyze-pilot-log.sh held-out` then `bash evals/analyze-pilot-gate.sh`.
