# Held-out confirmation

After **confirmation** log is green vs `prereg.json`, run a **fresh** sample. Do not reuse confirmation pairs.

## Sample (locked)

- **2** pairs × **3** fixtures = **6** pairs (`core` + `baseline` each)
- Same primary/secondary thresholds as confirmation
- Same Blind Judge model; no mid-flight model swap

## Procedure

1. Confirm `confirmation-log.jsonl` has ≥9 pairs and `bash evals/analyze-pilot-log.sh confirmation` prints `primary_pass: true` (and secondaries).
2. For each held-out pair: `run-pair` → agent → assertions → judge → scorecards →  
   `bash evals/record-pilot-pair.sh held-out --fixture … --core-scorecard … --baseline-scorecard …`
3. `bash evals/analyze-pilot-log.sh held-out`
4. `bash evals/analyze-pilot-gate.sh` — both layers green → `gate-status.json`
5. Only then: `bash evals/analyze-pilot-gate.sh --apply-claim` to set `reliability_claim_allowed: true` in `prereg.json`

Until step 5, **no Reliable Delivery claim** (CONTEXT.md).

## Logs

| File | Phase |
|------|--------|
| `exploratory-log.jsonl` | friction only |
| `confirmation-log.jsonl` | prereg N=9 |
| `held-out-log.jsonl` | prereg N=6 fresh |
| `gate-status.json` | written by analyze-pilot-gate.sh |
