# Live agent: core vs core+fable

**Device handoff.** Pull `main`, read this + root `task.md`. Do **not** solve fixtures inside the `alpha-zero-g` repo chat — that leaks answers.

**Status:** Reference smoke done (`compare-core-fable-smoke.json`). Live agent pairs **not** started. Fable skill tree is still a **stub** (process test, weak promote signal until real upstream).

---

## Prerequisites

- Git clone of this repo on `main`
- Git Bash (Windows) or bash 4+
- `jq` on PATH
- Cursor and/or Antigravity — **same model** for both arms of a pair

```bash
git pull origin main
cd <repo-root>
```

---

## One pair (start here: bug-fix)

### A. Core arm

```bash
bash evals/run-pair.sh bug-fix core
```

Note printed `WORKDIR=...`.

1. Open **that folder** as the IDE workspace (new window).
2. **New** Agent chat. Lock model.
3. Prompt (example):

> Read TASK.md. Make `bash assertions/check.sh` exit 0.
> Do not open or copy from any `reference/` directory.
> Do not browse the alpha-zero-g harness repo for the answer.

4. When agent stops, in Git Bash:

```bash
WORKDIR="<paste path>"   # from run-pair output
bash "$WORKDIR/assertions/check.sh"
echo "exit=$?"           # 0 = task_success 1, else 0

bash evals/record-scorecard.sh "$WORKDIR/scorecard.json" \
  --task-success 0_or_1 \
  --delivery-cost <tokens_or_usd> \
  --wall-time-sec <seconds> \
  --interventions <human_fixes> \
  --model "<same-model-id>" \
  --ide "cursor|antigravity" \
  --operator "<you>" \
  --notes "live agent core arm"
```

Optional Blind Judge:

```bash
bash evals/prepare-judge-packet.sh "$WORKDIR"
bash evals/judge-score.sh "$WORKDIR"
```

### B. core+fable arm

```bash
bash evals/run-pair.sh bug-fix core+fable
```

New `WORKDIR`. **New** IDE window + **new** chat. **Same model.**

Extra prompt line:

> If `.agents/skills/fable/` exists, use those skills when helpful.

Score the same way; set `--notes "live agent core+fable arm"`.

### Or prepare both workdirs first

```bash
bash evals/compare-core-fable.sh bug-fix
# COMPARE_ROOT=... → each fixture has core.workdir + core-fable.workdir files
```

---

## After each pair

| Keep | Discard |
|------|---------|
| scorecard.json values (copy into notes or a log under `evals/pilot/`) | Temp WORKDIR under `/tmp` or `%TEMP%` (ephemeral) |
| judge-result.json if run | — |

Append a one-line summary to `evals/pilot/live-compare-log.md` (create if missing):

```markdown
| date | fixture | model | ide | core_ok | fable_ok | core_cost | fable_cost | notes |
|------|---------|-------|-----|---------|----------|-----------|------------|-------|
```

---

## Fixtures to cover

1. `bug-fix` (start)
2. `scoped-change`
3. `regression-feature`

Same model/IDE/budget rules every time.

---

## Promote? (do not skip)

Default Fable only if **all** hold:

1. Live pairs show better Task Success per Delivery Cost for `core+fable` (not reference smoke)
2. No portability regression
3. Phase 9 held-out claim: `reliability_claim_allowed=true` via `evals/analyze-pilot-gate.sh --apply-claim` after green confirmation+held-out

Until then: keep `--experimental`; issues #52–55 stay paused (ADR 0005).

---

## Pitfalls

- Solving in this harness repo chat = contaminated run
- Peeking at `evals/fixtures/*/reference/` = invalid
- Different models across arms = invalid pair
- Wall-clock alone ≠ Delivery Cost (prefer tokens/spend)
- Stub Fable ≠ real Fable benefit

## Related

- `task.md` — Work Packet
- `ROADMAP.md` — Phase 10 checklist
- `evals/README.md` — suite overview
- `docs/adr/0005-evidence-gated-fable-adoption.md`
