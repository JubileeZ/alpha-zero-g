# Evaluation Suite (Phase 9 Core Pilot)

Fixed fixtures for paired **core** vs **No-Harness Baseline** runs. No Fable. Blind Judge and live pilot runs are later Phase 9 bullets.

## Fixtures

| id | kind | Task |
|----|------|------|
| `bug-fix` | bug fix | Make `clamp` inclusive on upper bound |
| `scoped-change` | scoped change | Add `--json` without breaking text output |
| `regression-feature` | regression-prone | Add percent discount; keep existing totals green |

Each fixture: agent-facing `TASK.md`, broken `workspace/`, hidden `assertions/check.sh`, known-good `reference/` to validate assertions.

## Prepare a paired run

```bash
# Core harness treatment (azg apply into copy)
bash evals/run-pair.sh bug-fix core

# No-Harness Baseline (same workspace, no azg apply)
bash evals/run-pair.sh bug-fix baseline
```

Prints workdir + empty scorecard path. Operator (or agent) does the task in that workdir, then:

```bash
bash evals/record-scorecard.sh <workdir>/scorecard.json \
  --task-success 1 \
  --delivery-cost 1.23 \
  --wall-time-sec 480 \
  --interventions 0
```

Hidden gate (Task Success hard checks):

```bash
bash <workdir>/assertions/check.sh
```

## CI / structural

```bash
bash tests/test-evals.sh
```

Asserts suite manifest, three fixtures, assertions fail on broken workspace and pass on reference.

## Blind Judge

Treatment-blind packet + rubric (see `evals/judge/`).

```bash
# After a run-pair workdir exists (and agent finished):
bash evals/prepare-judge-packet.sh "$WORKDIR"
bash evals/judge-score.sh "$WORKDIR"    # stub unless AZG_JUDGE_CMD is set
cat "$WORKDIR/judge-result.json"
```

Human calibration: `evals/judge/CALIBRATION.md`. Fixed model id in `evals/judge/config.json`.

## Long-Horizon

```bash
bash evals/run-long-horizon.sh bug-fix core
# Session1 in IDE A (new chat) → Checkpoint commit →
bash evals/run-long-horizon.sh bug-fix core --sync-clone "$SESSION1"
# Session2 clean clone in IDE B (other IDE, new chat) → assertions/check.sh
```

See `evals/long-horizon/README.md` and `checklist.md`.
