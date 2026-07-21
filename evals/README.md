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
