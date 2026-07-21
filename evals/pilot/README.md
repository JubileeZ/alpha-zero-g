# Pilot runs

- Prereg: [`PREREG.md`](PREREG.md) / [`prereg.json`](prereg.json)
- Held-out: [`HELD-OUT.md`](HELD-OUT.md)
- Exploratory log: [`exploratory-log.jsonl`](exploratory-log.jsonl)
- Confirmation / held-out logs: `confirmation-log.jsonl`, `held-out-log.jsonl`
- Gate: `bash evals/analyze-pilot-gate.sh`

```bash
# After both arms of a pair finished + scorecards + optional judge:
bash evals/record-pilot-pair.sh exploratory \
  --fixture bug-fix \
  --core-scorecard /path/core/scorecard.json \
  --baseline-scorecard /path/baseline/scorecard.json \
  --notes "exploratory only"
```
