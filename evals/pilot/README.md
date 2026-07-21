# Pilot runs

- Prereg: [`PREREG.md`](PREREG.md) / [`prereg.json`](prereg.json)
- Exploratory log: [`exploratory-log.jsonl`](exploratory-log.jsonl)
- Confirmation / held-out logs: create when those phases start (`confirmation-log.jsonl`, `held-out-log.jsonl`)

```bash
# After both arms of a pair finished + scorecards + optional judge:
bash evals/record-pilot-pair.sh exploratory \
  --fixture bug-fix \
  --core-scorecard /path/core/scorecard.json \
  --baseline-scorecard /path/baseline/scorecard.json \
  --notes "exploratory only"
```
