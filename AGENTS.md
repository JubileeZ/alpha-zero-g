# Alpha-Zero-G
---

## Project Identity

Outer agent harness installer: templates + `azg` CLI for Cursor and/or Antigravity (`agy`). v4 complete. Spec: `docs/SPEC.md`.

**Stack:** Bash (3.2-safe `lib/`; prefer ≥4.0 locally) · jq · Python 3.x · Git · agy

---

## Repo Structure

```
.agents/          # hooks, skills
docs/             # ADR, agent guides, architect refs
lib/              # azg CLI scripts
templates/        # global/ + project/ scaffolds
tests/            # verify, run-all, phase suites
azg               # CLI entrypoint
CONTEXT.md        # glossary
VERSION           # release version
```

---

## Key Commands

| Command | When |
|---------|------|
| `bash tests/verify.sh` | Iteration / checkpoint (seconds) |
| `bash tests/run-all.sh` | Pre-PR; CI parity; broad `templates/`/`lib/` (minutes) |
| `AZG_STRICT=1 bash tests/run-all.sh` | Strict CI parity (fails if shellcheck/python3 missing) |
| `shellcheck azg lib/*.sh evals/*.sh tests/*.sh` | Lint edited Bash |
| `bash tests/run-all.sh --list` | Suite order when unsure |
| `bash tests/run-verify-docs.sh` | Docs-only link check (python3 / python / `py -3`) |

**Diff → suite:** setup/common/Cursor device → `test-cursor-device-setup.sh` · scaffold/apply → `test-azg.sh` + `test-phase*.sh` · `templates/project/` → `test-phase10.sh` + `test-mutation-verify.sh` · `evals/traps/` → `test-traps.sh` + `test-eval-isolation.sh` · hooks → `host-contract-smoke.sh` + `test-phase5.sh`

**Commit Readiness:** Run smallest checks for touched area (Diff -> 
suite); confirm pass before commit.Ensure CI passes after changes.; 
confirm they pass before proposing a commit. Pre-PR / CI parity: 
`bash tests/run-all.sh` (or `AZG_STRICT=1` when matching CI).

**Windows:** run azg CLI, hooks, and `tests/*.sh` in Git Bash or another Bash-capable shell. App/node commands may use PowerShell.

---

## Safety Rules

- Never commit, print, or paste secret values (from `.env`, credentials, tokens, or chat). App/harness code may read env vars; do not exfiltrate their values.
- `templates/` / `lib/` edits → run matching phase tests after
- No breaking Downstream harness: preserve `AZG:MANAGED` user-zone merge; don't break `azg apply` / hooks contracts without an explicit migration
- Agent harness device changes: implement scalably for current/future devices and new repos

---

## Code Conventions

- `lib/*.sh` sources `lib/common.sh` (`info`/`warn`/`die`, cross-platform helpers)
- Shellcheck clean; inline disables only when necessary

---

## Agent guidance

- Downstream client `AGENTS.md`: hybrid layout (user zone above markers; managed between)
- Keep `AGENTS.md` light; detail → `docs/agents/`

### Eval campaigns — agent owns the watch

When this agent **starts** or **inherits** a Behavior Corpus Process Gate campaign (setsid, background `run-process-gate` / `run-trap-campaign`):

1. **Do not** leave the user to `tail -f` / poll alone. Agent watches until finish or hard block. Launch long runner with stdout visible and `notify_on_output` matcher `^AZG_TRAP_CAMPAIGN_FINISHED`; do not redirect away completion event. Preview pause may need human `y` or `--yes`.
2. Poll: filled scorecards vs expected · `campaign.log` / `campaign.pid` · terminal artifacts (`LEDGER.md`, `aggregate.json`, `LAST-GATE.md`).
3. Cadence: completion event → report immediately. Without event, fixed 120-second heartbeat: first check at 120s, then every 120s; never stretch interval. On process exit without artifact → diagnose.
4. **On finish:** report outcome (overall + Coverage + recommend) in chat; update the bound Work Packet + `evals/traps/CAMPAIGN.md` and/or `docs/agents/current-state.md` as needed. Do not end the turn with only "watch this path."

Live camps (gitignored): `evals/traps/campaigns/<id>/`.

---

<!-- AZG:MANAGED:START -->
## Placeholder fill

`<!-- AGENT: ... -->` in agent/tracking docs (e.g. `AGENTS.md`, `ROADMAP.md`, `docs/agents/*`):
1. Ask fill or skip; skip → leave comment exact.
2. One section at a time; ≤3 options, recommended first.
3. Done → drop resolved comments + inapplicable sections; telegraphic prose.

---

## Session start

Once per session (not every turn). Continuity from listed files (chat ≠ continuity):

1. `current-state.md` (reality).
2. `ROADMAP.md` active phase / first unchecked only.
3. `git status` + `git log -5 --oneline` before edit.
4. Other docs JIT via pointers.

Do not read Work Packet bodies at start. **Independent Request** (no change asked): no packet I/O.

**Bind** only when the user says continue / handoff / a Packet ID, or asks to continue and `.agents/handoff-pointer` names one. Change asked with no bind: attended — ask new vs which open slug (≤3); unattended — create `.agents/work-packets/<slug>.md` from `.agents/work-packet.md.tmpl`. Never auto-bind the last leftover packet.

Session start done when: `current-state` + ROADMAP slice + git status/log. Bound packet read only after Bind.

Missing required continuity doc: restore from git if history exists; else ask user.

During work / before Checkpoint: update tracking docs when state changes
(see `docs/agents/progress.md`). Before Checkpoint: refresh bound packet SFDBN, or delete the packet if finished.

JIT (read when task needs): full `CONTEXT.md`, `progress.md`, `issue-tracker.md`, archived ROADMAP, research notes.

---

## Harness Safety

- Safety-hook deny: explain block; give exact manual command/content; leave hook unchanged (do not execute blocked action). Never emit multi-line heredocs (`cat << 'EOF'`); use single-line commands or write payload to temporary scratch files.
- Work Packets only in `.agents/`: `.agents/work-packets/` contains only `*.md` Work Packets. Code files, scripts, or executables in `.agents/` strictly forbidden.

---

## Domain Vocabulary

- Ambiguous domain terms: follow `docs/agents/domain.md` (read `CONTEXT.md` / `CONTEXT-MAP.md` + relevant ADRs; use glossary/ADR terms only).
- Glossary/ADR writes: `/grill-with-docs` (uses `/domain-modeling`) after a term is resolved — domain concepts only; glossary-only; lazy create/update per that skill.

---

## Work State & Checkpoints

- Tracker: `docs/agents/issue-tracker.md`. Updates/compaction/archive/cleanup: `docs/agents/progress.md`.
- Autonomous progress & push: user prompt asking to update progress and commit/push authorizes full cycle: update packet/docs, run `bash tests/verify.sh`, commit, and `git push`.
- Code commits: stage a Work Packet under `.agents/work-packets/` with code — `commit-gate` enforces. Finished packet: delete the file in the same Checkpoint. Trivial: minimal packet OK.
- Handoff / device switch / leave-for-other-agent: write Packet ID to `.agents/handoff-pointer` and commit the packet. Other device: pull, then Bind that Packet ID.
- Cleanup when task complete: delete `implementation_plan.md` / `walkthrough.md`; **delete** the packet file (do not empty). Next task: new packet from `.agents/work-packet.md.tmpl`. Durable state stays in ROADMAP / current-state / git.
<!-- AZG:MANAGED:END -->
