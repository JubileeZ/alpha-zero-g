# Host-contract smoke

Prove IDE hooks **deny** actually prevent the pending action. Synthetic JSON tests are not enough — this doc is the human/host check; `bash tests/host-contract-smoke.sh` locks the deny→no-side-effect protocol in CI.

---

## Automated (CI)

```bash
bash tests/host-contract-smoke.sh
```

Simulator: hook stdout `deny` / `permission:deny` → side-effect command is **not** run; `allow` → side effect runs. Cursor `failClosed: true` asserted on template hooks.json.

---

## Manual — Cursor

1. Scaffold or apply harness into a throwaway repo (`azg new smoke-app` or `azg apply`).
2. Open the repo in Cursor; confirm `.cursor/hooks.json` loaded (Hooks output / agent settings).
3. Ask the agent to run a destructive shell command, e.g. `rm -rf /tmp/azg-smoke-should-not-exist` (or any pattern blocked by policy you care about). Prefer a matcher that hits `beforeShellExecution` / project hooks.
4. For commit gate: stage a code file **without** updating `task.md`, ask agent to `git commit`. Expect **deny** (verify or Checkpoint) and **no commit**.
5. Pass criteria: action blocked in UI; working tree / canary path unchanged; agent sees deny reason.
6. Fail criteria: command runs, commit lands, or hook never fires.

---

## Manual — Antigravity (`agy`)

1. Same throwaway repo with `.agents/hooks.json` + hooks present.
2. Start an `agy` session in that repo.
3. Ask the agent to `rm -rf /` (or `git push --force`). Expect PreToolUse **deny** from `block-destructive-ops.sh`.
4. Ask for `git commit` with broken harness (delete `AGENTS.md` temporarily). Expect `commit-gate.sh` deny; no commit object created.
5. Pass criteria: tool call cancelled; reason shown; no side effect on disk/git.
6. Fail criteria: command executes despite deny JSON (host bug — escalate; do not weaken repo gate).

---

## Record result

After a manual pass on each host, note date + Cursor/agy version in the PR or issue. Repo-native gate remains source of truth (ADR 0004); IDE smoke only proves adapters are wired.

Spawn budget: deny is enforced on PreToolUse `START_SUBAGENT` (ADR 0006). `SubagentStart` may still fire the script but cannot block on Antigravity.
