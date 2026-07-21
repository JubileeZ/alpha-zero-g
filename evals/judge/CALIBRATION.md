# Human calibration notes

Periodic calibration keeps Blind Judge scores aligned with humans (CONTEXT.md).

## Procedure

1. Sample **N ≥ 5** completed fixture deliveries (mix of pass/fail assertions; both treatments).
2. Strip treatment: use `bash evals/prepare-judge-packet.sh <workdir>` only — never hand humans the raw scorecard.
3. Two humans score independently with `RUBRIC.md` (same 1–5 dimensions).
4. Run the fixed judge model with `PROMPT.md` + packet (or `AZG_JUDGE_CMD`).
5. Record in `evals/judge/calibration-log.jsonl` (append one JSON object per sample):

```json
{
  "sample_id": "bug-fix-001",
  "fixture_id": "bug-fix",
  "human_a": {"correctness": 4, "scope_discipline": 5, "clarity": 4, "safety": 5, "overall": 4.5},
  "human_b": {"correctness": 4, "scope_discipline": 4, "clarity": 4, "safety": 5, "overall": 4.25},
  "model": {"correctness": 4, "scope_discipline": 4, "clarity": 3, "safety": 5, "overall": 4.0},
  "assertions_pass": true,
  "date": "YYYY-MM-DD"
}
```

## Pass criteria for calibration

- Mean |human_mean − model_overall| ≤ **1.0** on the sample set
- No systematic treatment leakage (humans must not be told core vs baseline)
- If calibration fails: adjust prompt wording only; do **not** change model mid-pilot without restarting the pilot series

## Stub judge (CI)

`evals/judge-score.sh` without `AZG_JUDGE_CMD` uses a deterministic stub (assertions + diff size heuristics). Stub is for wiring tests only — **not** for reliability claims.
