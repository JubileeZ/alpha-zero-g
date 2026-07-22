# Live agent compare — detailed step-by-step

**Open this file first** on any device/IDE after `git pull`.  
Root `task.md` is the short Work Packet; **this file is the full how-to**.

---

## What you are measuring

| Arm | What gets installed into the temp folder |
|-----|------------------------------------------|
| `core` | Fixture + `azg apply` → `AGENTS.md`, hooks, Cursor rules, etc. |
| `core+fable` | Same as core **plus** `.agents/skills/fable/` (currently a **stub** skill) |

You do **not** look for `AGENTS.md` / skills inside the `alpha-zero-g` harness repo root. Those appear only inside the **WORKDIR** after `run-pair`.

**Goal of a live pair:** same model, same IDE style, two fresh chats — one per arm — solve `TASK.md`, then score.  
**Not a promote decision** until many pairs + held-out claim. Stub Fable ≠ real Fable product.

---

## 0. One-time setup (each machine)

### 0.1 Tools

| Need | Check |
|------|--------|
| Git | `git --version` |
| Git Bash (Windows) | Start **Git Bash** (not PowerShell for these scripts) |
| `jq` | `jq --version` — install via winget/choco/brew/apt if missing |
| Cursor and/or Antigravity | Installed |

### 0.2 Clone / update harness

```bash
# If first time on this machine:
git clone https://github.com/JubileeZ/alpha-zero-g.git
cd alpha-zero-g

# Every session:
git pull origin main
cd /path/to/alpha-zero-g    # your clone path
```

Confirm guide exists:

```bash
ls evals/pilot/LIVE-AGENT-COMPARE.md
cat task.md | head -20
```

### 0.3 Pick constants for this session (write them down)

| Field | Example | Rule |
|-------|---------|------|
| Model | e.g. whatever you select in Agent | **Same for both arms** |
| IDE | `cursor` or `antigravity` | Prefer same IDE both arms |
| Operator | your name/handle | — |
| Fixture | start with `bug-fix` | Then `scoped-change`, `regression-feature` |

---

## 1. Mental model (read once)

```
alpha-zero-g/          ← harness only (do NOT solve TASK here)
   evals/run-pair.sh
        │
        ▼
   TEMP WORKDIR/       ← open THIS in IDE
      TASK.md          ← agent reads this
      AGENTS.md        ← from azg apply
      tools/           ← broken code to fix
      assertions/      ← hidden tests (agent may run check.sh)
      .agents/skills/fable/   ← only on core+fable arm
      scorecard.json   ← you fill after
```

**Wrong:** Agent chat with workspace = `alpha-zero-g`  
**Right:** Agent chat with workspace = the printed `WORKDIR`

---

## 2. Arm A — `core` (first half of the pair)

### Step 2.1 — Prepare workdir (Git Bash, harness repo)

```bash
cd /path/to/alpha-zero-g
bash evals/run-pair.sh bug-fix core
```

You should see something like:

```text
WORKDIR=/tmp/azg-eval-bug-fix-core-12345
TREATMENT=core
...
SCORECARD=.../scorecard.json
CHECK=bash .../assertions/check.sh
```

**Copy `WORKDIR` to a notepad.** On Windows Git Bash it may look like `/tmp/...` or `/c/Users/.../AppData/Local/Temp/...`.

Optional sanity check (still in Git Bash):

```bash
WORKDIR="/tmp/azg-eval-bug-fix-core-12345"   # paste yours
ls "$WORKDIR"
# expect: TASK.md  AGENTS.md  tools/  assertions/  scorecard.json  .agents/  ...
test -d "$WORKDIR/.agents/skills/fable" && echo "UNEXPECTED fable" || echo "ok: no fable on core"
```

### Step 2.2 — Open workdir in IDE

**Cursor**

1. File → **New Window**
2. File → **Open Folder…**
3. Paste/browse to the WORKDIR path  
   - If path is `/tmp/...` in Git Bash, in Explorer it may be under your user temp; or use Git Bash: `explorer "$(cygpath -w "$WORKDIR")"` then Open Folder from there  
   - Or: `cd "$WORKDIR" && pwd -W` (Git Bash) to get a Windows path
4. Confirm the window title/folder is the **eval workdir**, not `alpha-zero-g`

**Antigravity**

1. Open a new window/workspace on that same WORKDIR folder
2. Same rule: workspace root must be WORKDIR

### Step 2.3 — Start agent (core)

1. Start a **new** Agent chat (do not continue an old chat)
2. Select your **locked model** (write it down)
3. Note start time
4. Paste this prompt:

```text
You are working only in this project folder.

1. Read TASK.md and follow it.
2. Make this command succeed: bash assertions/check.sh
3. Do NOT open, search for, or copy from any directory named reference/
4. Do NOT look at any other repo (especially alpha-zero-g) for the solution.
5. Prefer minimal changes that satisfy the task.
```

5. Let the agent work until it stops or you decide to stop
6. Count **interventions** = how many times you manually fixed code or gave the answer (0 if hands-off)

### Step 2.4 — Score core (Git Bash, harness repo)

```bash
cd /path/to/alpha-zero-g
WORKDIR="/paste/your/core/workdir"    # exact path from step 2.1

# Hard gate
bash "$WORKDIR/assertions/check.sh"
CORE_OK=$?          # 0 = pass → task_success 1; nonzero → 0
echo "check_exit=$CORE_OK"

# Estimate delivery_cost: prefer token/spend from IDE usage UI.
# If unknown, put a number you can compare (e.g. estimated USD or token thousands)
# and say so in notes. Wall time alone is NOT Delivery Cost per CONTEXT.md
# but wall_time_sec is still recorded separately.

bash evals/record-scorecard.sh "$WORKDIR/scorecard.json" \
  --task-success "$( [ "$CORE_OK" -eq 0 ] && echo 1 || echo 0 )" \
  --delivery-cost 1.0 \
  --wall-time-sec 300 \
  --interventions 0 \
  --model "YOUR_MODEL_ID" \
  --ide "cursor" \
  --operator "YOUR_NAME" \
  --notes "live agent core arm bug-fix"

cat "$WORKDIR/scorecard.json"
```

Replace `1.0`, `300`, `0`, model, ide, operator with real values.

Optional Blind Judge:

```bash
bash evals/prepare-judge-packet.sh "$WORKDIR"
bash evals/judge-score.sh "$WORKDIR"
cat "$WORKDIR/judge-result.json"
```

### Step 2.5 — Save core numbers

Write down:

| | value |
|--|--|
| core_ok | 0 or 1 |
| core_cost | delivery_cost you recorded |
| core_wall | wall_time_sec |
| core_interventions | N |

Leave the core IDE window alone or close it. **Do not reuse that chat for the fable arm.**

---

## 3. Arm B — `core+fable` (second half)

### Step 3.1 — Prepare

```bash
cd /path/to/alpha-zero-g
bash evals/run-pair.sh bug-fix core+fable
```

You may see a warn about experimental Fable — that is expected while claim is false.  
Copy the **new** `WORKDIR` (different from core).

Sanity:

```bash
WORKDIR="/paste/fable/workdir"
ls "$WORKDIR/AGENTS.md"
ls "$WORKDIR/.agents/skills/fable/"
# expect: fable-loop/  FABLE.lock.json  .fable-installed
```

### Step 3.2 — Open in IDE

New window → Open Folder → **this** WORKDIR (not core’s, not harness).

### Step 3.3 — Start agent (fable)

1. **New** chat  
2. **Same model** as core  
3. Note start time  
4. Prompt:

```text
You are working only in this project folder.

1. Read TASK.md and follow it.
2. Make this command succeed: bash assertions/check.sh
3. Do NOT open, search for, or copy from any directory named reference/
4. Do NOT look at any other repo for the solution.
5. If .agents/skills/fable/ exists, read and follow those skills when helpful.
6. Prefer minimal changes that satisfy the task.
```

### Step 3.4 — Score fable

Same as step 2.4, with the fable WORKDIR and `--notes "live agent core+fable arm bug-fix"`.

### Step 3.5 — Log the pair

Edit `evals/pilot/live-compare-log.md` in the **harness** repo and add a row:

```markdown
| 2026-07-22 | bug-fix | YOUR_MODEL | cursor | 1 | 1 | 1.0 | 1.2 | first live pair |
```

Columns: `date | fixture | model | ide | core_ok | fable_ok | core_cost | fable_cost | notes`

Commit when convenient:

```bash
cd /path/to/alpha-zero-g
git add evals/pilot/live-compare-log.md
git commit -m "chore: log live compare pair bug-fix"
git push
```

---

## 4. Shortcut — prepare both folders first

```bash
bash evals/compare-core-fable.sh bug-fix
```

Note `COMPARE_ROOT=...`. Then:

```bash
COMPARE_ROOT="/paste/compare/root"
cat "$COMPARE_ROOT/bug-fix/core.workdir"        # path for arm A
cat "$COMPARE_ROOT/bug-fix/core-fable.workdir"  # path for arm B
```

Still open each path in a **separate** window/chat. Score each as above.

---

## 5. Next fixtures

Repeat sections 2–3 for:

2. `scoped-change`  
3. `regression-feature`  

Always: same model, same IDE, new chats, no peeking at `evals/fixtures/*/reference/` in the harness.

---

## 6. What “done” looks like for Phase 10 promote

| Checkpoint | Status meaning |
|------------|----------------|
| Reference smoke | Already done — portability only |
| ≥1 live pair logged | Process works |
| All 3 fixtures live-paired | Directional signal |
| Held-out claim (`reliability_claim_allowed`) | Required for default |
| core+fable better success/cost | Required for default |

Until those hold: Fable stays opt-in/`--experimental`. Do **not** reopen #52–55 for default install.

---

## 7. Troubleshooting

| Problem | Fix |
|---------|-----|
| `jq: command not found` | Install jq; reopen Git Bash |
| `unknown fixture` | Run from repo root; `git pull`; fixture id typo |
| No `AGENTS.md` in folder | You opened harness root — open WORKDIR from `run-pair` |
| No fable skills on core+fable | Re-run `run-pair ... core+fable`; check warn + `.fable-installed` |
| `check.sh` not executable | `chmod +x "$WORKDIR/assertions/check.sh"` |
| Windows path confusion | In Git Bash: `cygpath -w "$WORKDIR"` → use that in Open Folder |
| Agent “knows” the answer already | Contaminated — new workdir + new chat; don’t use harness chat |
| PowerShell script errors | Use **Git Bash** for all `evals/*.sh` |

---

## 8. Quick checklist (print / keep open)

- [ ] `git pull` on harness  
- [ ] Constants: model / ide / operator written down  
- [ ] `run-pair bug-fix core` → copy WORKDIR  
- [ ] Open WORKDIR (not harness) → new chat → prompt → agent runs  
- [ ] `assertions/check.sh` → `record-scorecard.sh`  
- [ ] `run-pair bug-fix core+fable` → new WORKDIR → new chat → same model  
- [ ] Score fable arm  
- [ ] Row in `evals/pilot/live-compare-log.md`  
- [ ] Later: other fixtures; never promote from smoke alone  

---

## Related files

| File | Role |
|------|------|
| `task.md` | Short Work Packet / resume |
| `evals/pilot/live-compare-log.md` | Your pair table |
| `evals/pilot/compare-core-fable-smoke.json` | Reference smoke (not live) |
| `evals/README.md` | Suite overview |
| `ROADMAP.md` | Phase 10 checklist |
| `docs/adr/0005-evidence-gated-fable-adoption.md` | Why Fable stays gated |
| `CONTEXT.md` | Task Success / Delivery Cost definitions |
