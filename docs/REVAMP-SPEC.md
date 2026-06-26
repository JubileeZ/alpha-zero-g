# Alpha-Zero-G v4 Revamp — Design Specification

**Canonical spec.** If any other doc disagrees with this file, this file wins.

**Audience:** AI agents and humans implementing the revamp. Read with `ROADMAP.md` (phases) and `docs/agents/current-state.md` (gaps).

---

## 1. What Alpha-Zero-G is

Alpha-Zero-G is an **outer agent harness** installer and template system. It does **not** replace IDE agent loops (Cursor, Antigravity `agy`). It ships **repo + global configuration** so solo developers and small teams produce reliable agent output with limited token budget, across **Windows, macOS, and Linux**, using **Cursor and/or Antigravity**.

| Layer | Owner | Alpha-Zero-G provides |
|-------|--------|---------------------|
| Inner harness | IDE vendor | Nothing — use built-in tools, indexing, models |
| Outer harness | Alpha-Zero-G | Rules, hooks, skills install, work-state files, verification gates |

**Product shape:** `templates/` is the single source of truth. Users get harness files via:

- **Greenfield:** `git clone` + `azg setup` + `azg new my-app`
- **Brownfield:** `azg apply` into an existing repo

Both paths consume the same `templates/project/` tree.

---

## 2. Target users & constraints

| Constraint | Decision |
|------------|----------|
| Token budget | Thin always-on `AGENTS.md` (~80 lines managed block); skills user-invoked where possible; `gh` CLI over MCP by default |
| Multi-device | Git-synced project harness; global machine UX via `azg setup` |
| Multi-IDE | `AGENTS.md` cross-tool truth; `.agents/` Antigravity home; `.cursor/rules/` thin Cursor deltas only |
| No GitHub required for work state | Filesystem layers (`task.md`, `current-state.md`, handoff) always work; GitHub is default **adapter** only |

---

## 3. Distribution & onboarding

```bash
git clone <alpha-zero-g-repo>   # e.g. https://github.com/<org>/Alpha-Zero-G.git
cd alpha-zero-g
azg setup                              # once per machine (global)
azg new my-app --tracker github        # greenfield
bash tests/test-harness.sh             # meta-harness gate (in scaffolded project)
```

Brownfield (instead of `azg new`):

```bash
cd existing-repo && azg apply --tracker github
```

- `azg setup` **fails fast** if global dirs missing prerequisites; does **not** hide setup inside `new`.
- `azg apply` **is** the upgrade path for harness files (`--dry-run` supported).
- Merge contract: `<!-- AZG:MANAGED:START/END -->` and `<!-- PONYTAIL:MANAGED:START/END -->` blocks only; never clobber user prose outside blocks.

---

## 4. Global vs project split

| Global (`azg setup` → `~/.gemini/antigravity-cli/`) | Project (git repo) |
|------------------------------------------------------|---------------------|
| Ponytail ladder (`PONYTAIL:MANAGED` in global `AGENTS.md`) | Project `AGENTS.md` managed block |
| 9 default skills (minimal profile) | `.agents/hooks.json` + hook scripts |
| Statusline script | `.cursor/rules/` (thin) |
| MCP config stub (`gh` default; commented read-only GitHub MCP) | `docs/agents/*` work-state & adapters |
| | Continuity files: `task.md`, `ROADMAP.md`, `current-state.md`, handoff |

**Never** put team-critical rules only in `~/.cursor/` — other devs and cloud agents cannot see them.

---

## 5. Day-0 project template (harness-only)

No app code, no stack wizard in v4. Template ships **agent infrastructure only**:

```
AGENTS.md                    # thin managed block
ROADMAP.md                   # empty phase scaffold (- [ ] placeholders)
task.md                      # from task.md.tmpl
docs/agents/
  current-state.md           # reality snapshot
  progress.md                # three-layer update ritual
  issue-tracker.md           # GitHub default (pre-seeded)
  triage-labels.md
  domain.md
  CONTEXT.md.tmpl            # reference only — not at repo root until needed
.agents/
  hooks.json
  hooks/
    block-destructive-ops.sh
    commit-gate.sh             # NEW v4
    checkpoint.sh              # NEW v4 — Stop hook, not PreCompact block
  session-handoff.md           # SFDBN template
  spawn-budget.json            # max_spawns: 3, max_depth: 2
.cursor/rules/                 # 2–3 Cursor-only deltas max
.vscode/settings.json        # terminal cwd = workspace (Windows-safe)
tests/test-harness.sh        # meta-harness self-check (no app stack required)
```

### `AGENTS.md` managed block must include

- Project identity (this repo: Alpha-Zero-G CLI itself)
- Verify commands (`shellcheck`, `bash tests/test-azg.sh`, phase tests)
- Safety rules (secrets, destructive ops, hook deny handling)
- Session start ritual (read `current-state.md` → `task.md` → `git log -5`; do not rely on chat)
- Domain vocabulary trigger: if terms ambiguous, create `CONTEXT.md` from `docs/agents/CONTEXT.md.tmpl` before more implementation
- Pointer to `docs/agents/progress.md` and issue tracker adapter

**Do not** inline encyclopedic content in `AGENTS.md`. Depth lives in `docs/agents/`.

---

## 6. Hooks (v4)

| Hook | Event | Purpose |
|------|-------|---------|
| `block-destructive-ops.sh` | PreToolUse / shell | Block `rm -rf`, force-push main, credential leaks |
| `commit-gate.sh` | PreToolUse on `git commit` | Block commit until `bash tests/test-harness.sh` (and project tests when configured) pass |
| `checkpoint.sh` | **Stop** (Cursor + Antigravity) | Enforce fresh `current-state.md` or handoff before agent stops; return continue/followup if stale |
| `spawn-budget.sh` | subagentStart | Read `.agents/spawn-budget.json`; deny when `max_spawns: 3` or `max_depth: 2` exceeded |

**PreCompact:** Cursor `preCompact` is **observability only** (log/toast) — cannot block compaction on Cursor or Antigravity. Do not design around blocking PreCompact.

---

## 7. Work-state & continuity (three layers)

| Layer | File | Purpose |
|-------|------|---------|
| 1 — Task | `task.md` or GitHub issue | Active chunk: why, scope, blockers |
| 2 — Phase | `ROADMAP.md` | Checkboxes; mark done only when code + tests pass |
| 3 — Reality | `docs/agents/current-state.md` | What exists on disk today |

**Handoff:** `.agents/session-handoff.md` — SFDBN (Status / Files / Decision / Blocked / Next). Commit when switching device or IDE.

**Issue tracker:** Adapter pattern. Default GitHub (`gh` CLI). `docs/agents/issue-tracker.md` names active backend. Filesystem layers work without any hosted tracker.

---

## 8. Global skills (minimal profile)

Ship via `azg setup` when `VENDOR.lock` SHA changes (smart merge — skip if already at pin).

**9 default skills** (user-invoked where marked):

| Skill | Invocation |
|-------|------------|
| grill-with-docs | user |
| grilling | model (dependency) |
| domain-modeling | model (dependency) |
| handoff | user |
| ask-matt | user |
| triage | user |
| to-issues | user |
| diagnosing-bugs | model |
| tdd | model |

**Ponytail:** global `AGENTS.md` managed block — **not** the `ponytail` skill (duplicate).

**Absorb `setup-matt-pocock-skills` for GitHub default:** pre-seed `issue-tracker.md`, `triage-labels.md`, `domain.md` in `azg apply` / `azg new`. Keep setup skill only for non-GitHub tracker reconfiguration.

**Standing token cost target:** ~170–200 tokens for model-invoked skill descriptions.

---

## 9. MCP policy

- **Default:** `gh` CLI documented in `issue-tracker.md`; no active MCP servers required.
- **Opt-in:** `mcp_config.json` stub with **commented** read-only GitHub MCP example.
- Do not enable full GitHub MCP (25k+ schema tax) by default.

---

## 10. Vendor & update workflow

```
Maintainer:  azg update --vendor  →  refreshes templates/global/skills/vendor/* + ponytail block
User:        git pull              →  get new Alpha-Zero-G
             azg setup             →  sync global skills if VENDOR.lock SHA changed; merge ponytail block
             azg apply --dry-run   →  preview project harness upgrades
             azg apply             →  merge AZG managed blocks in project repos
```

---

## 11. Explicitly OUT of v4 (v4.1+)

- `azg new --stack` language/framework wizard
- Jira / Linear / beads issue-tracker adapter templates
- Separate `azg update` command (use `azg apply` for projects)
- Blocking PreCompact hooks
- Full GitHub MCP enabled by default
- `implement` skill (broken `/review` upstream reference)
- `to-prd`, `prototype`, `improve-codebase-architecture` in default bundle
- ponytail-review / audit / debt skills in default bundle
- Multi-agent deliberation orchestration beyond spawn-budget guard

---

## 12. Success criteria (revamp done when)

1. `azg new` produces harness-only tree matching §5 with no app scaffold questions.
2. `azg apply` pre-seeds GitHub adapter docs without running setup skill.
3. All four v4 hooks pass shellcheck and integration tests on Linux + documented Windows path.
4. `azg setup --profile minimal` installs exactly 9 skills + ponytail block.
5. `azg setup` skips skill copy when `VENDOR.lock` commit unchanged.
6. Cold-start agent reading only onboarding docs produces the same build plan (validated by subagent test).

---

## Doc map

| Question | Read |
|----------|------|
| Zero context start | `docs/AGENT-ONBOARDING.md` |
| What to build (this file) | `docs/REVAMP-SPEC.md` |
| Phase checklist | `ROADMAP.md` |
| What exists vs gaps | `docs/agents/current-state.md` |
| Progress update ritual | `docs/agents/progress.md` |
| Legacy v3 plan | `docs/archive/V3-PLAN.md` (historical only) |
