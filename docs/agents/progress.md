# Agent Progress Updates

How agents record progress so the **next** agent (or device) can continue without chat history.

---

## Three layers (update the right one)

| Layer | File | Update when | Purpose |
|-------|------|-------------|---------|
| **1 — Task** | GitHub Issue or `task.md` | Start / finish a focused chunk of work | Why, scope, blockers, link to commits |
| **2 — Phase checklist** | `ROADMAP.md` | A roadmap bullet is **done** (code + tests + lint pass) | `- [ ]` → `- [x]` on the matching line |
| **3 — Reality snapshot** | `docs/agents/current-state.md` | Something moves from "planned" to "exists" | Next agent knows what is on disk **today** |

**Do not** use chat history as the source of truth. **Do** commit doc updates in the **same PR/commit** as the code they describe.

---

## Workflow per work session

```mermaid
flowchart LR
    Start["Read current-state.md"] --> Issue["Pick / create task or issue"]
    Issue --> Work["Implement + test + lint"]
    Work --> Roadmap["Check ROADMAP box if bullet done"]
    Roadmap --> State["Update current-state.md if exists-table changed"]
    State --> Close["Close task or issue with summary"]
```

### 1. Start

1. Read `docs/agents/current-state.md` (what exists now).
2. Read `ROADMAP.md` (find the first unchecked item in the active phase).
3. Optional: list open issues or use a task runner to assign a chunk of work.

### 2. During work

- Comment on the issue/task if blocked or scope changes.
- Do **not** check ROADMAP boxes for partial work.

### 3. Before finishing (pre-commit gate)

- Run all linting and test commands to verify success.

### 4. On completion — update docs

| If you… | Then update… |
|---------|----------------|
| Finished a `ROADMAP.md` bullet | `- [x]` that bullet only — not whole phases |
| Added a file/dir listed in "does NOT exist" | Move row to **What exists**; remove from "does NOT exist" |
| Changed architecture (hard to reverse) | New ADR in `docs/adr/` — do not bury in ROADMAP |
| Resolved new domain term | `CONTEXT.md` glossary entry only |
| Advanced to next phase (all bullets in phase done) | `current-state.md` **Active phase** header + `ROADMAP.md` status line |

---

## What NOT to update on every small change

| File | When to touch |
|------|----------------|
| `CONTEXT.md` | New or clarified **domain terms** only — not implementation progress |
| `docs/deployment.md` | Production deployment guides only — not local dev tweaks |
| `AGENTS.md` | New commands, safety rules, or structure changes — not routine progress |

---

## Multi-device sync

| Syncs via git | Does not sync via git |
|---------------|------------------------|
| `ROADMAP.md`, `current-state.md`, code, ADRs | Temporary files, local build caches |
| Task/Issue state | Local `.env` |

Pull before starting on a new device. Read `current-state.md` after pull — not the previous chat.

---

## Checklist for agents (copy mentally)

- [ ] Read `current-state.md` at session start
- [ ] Task/issue created or referenced
- [ ] Tests + lint pass
- [ ] `ROADMAP.md` checkbox(es) match **only** what this commit ships
- [ ] `current-state.md` updated if existence table changed
- [ ] Task closed with a summary
