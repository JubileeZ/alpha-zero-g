# Pilot runs

- Prereg: [`PREREG.md`](PREREG.md) / [`prereg.json`](prereg.json)
- Held-out: [`HELD-OUT.md`](HELD-OUT.md)
- Exploratory / confirmation / held-out logs: `*-log.jsonl`
- Gate: `bash evals/analyze-pilot-gate.sh`
- Fable live compare (parked promote): [`LIVE-AGENT-COMPARE.md`](LIVE-AGENT-COMPARE.md) · [`live-compare-log.md`](live-compare-log.md)

```bash
# After both arms of a pair finished + scorecards + optional judge:
bash evals/record-pilot-pair.sh exploratory \
  --fixture bug-fix \
  --core-scorecard /path/core/scorecard.json \
  --baseline-scorecard /path/baseline/scorecard.json \
  --notes "exploratory only"
```
