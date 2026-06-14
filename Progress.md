# Alpha-Zero-G v3.0.0 — Progress Tracker

> Auto-updated by agent as phases complete.  
> Last updated: 2026-06-14

---

## Build Order

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 0 | Repo skeleton — `azg` dispatcher, `VERSION`, `common.sh` | ✅ Done |
| Phase 1 | `azg setup` — copy global skills, `mcp_config`, idempotent | ✅ Done |
| Phase 2 | `vendor-sync.sh` — pin mattpocock/skills commit, populate `vendor/` | ✅ Done |
| Phase 3 | `apply-overlay.sh` — tool-map remap + ANTIGRAVITY-NOTE injection | ✅ Done |
| Phase 4 | Hook library — 3 hooks + `hooks.json` template | ✅ Done |
| Phase 5 | `GEMINI.md.tmpl` / `AGENTS.md.tmpl` | ✅ Done |
| Phase 6 | `azg new` — 8-question scaffold flow | ✅ Done |
| Phase 7 | `azg apply` — managed-block retrofit | ✅ Done |
| Phase 8 | `azg update [--vendor]`, `azg uninstall` | ✅ Done |
| Phase 9 | `tests/test-azg.sh` — temp-HOME integration test | ⬜ Pending |
| Phase 10 | Cross-device validation — CachyOS + macOS | ⬜ Pending |
| Phase 11 | `docs/antigravity-agent-architecture.md`, README quickstart | ⬜ Pending |

---

## Phase 0 Detail — COMPLETE ✅

### Deliverables
- ✅ Repo skeleton created (`azg` dispatcher, `VERSION`)
- ✅ `lib/common.sh` created (OS detection, shared helpers)
- ✅ `tests/test-phase0.sh` TDD suite written and passing

### Test Results

| Suite | Result |
|-------|--------|
| `test-phase0.sh` | ✅ Passing |

---

## Phase 1 Detail — COMPLETE ✅

### Deliverables
- ✅ `lib/setup.sh` implementation (`azg setup` — copy global skills, `mcp_config`, idempotent checks)
- ✅ `tests/test-phase1.sh` TDD suite written and passing

### Test Results

| Suite | Result |
|-------|--------|
| `test-phase1.sh` | ✅ 22/23 passed, 1 skipped (resolves via Phase 2/3 regression tests) |

---

## Phase 2 Detail — COMPLETE ✅

### Deliverables
- ✅ `lib/vendor-sync.sh` implementation (`azg update --vendor`)
- ✅ Pin `mattpocock/skills` commit and populate `vendor/`
- ✅ `tests/test-phase2.sh` TDD suite written and passing

### Test Results

| Suite | Result |
|-------|--------|
| `test-phase2.sh` | ✅ 45/45 passed |

---

## Phase 3 Detail — COMPLETE ✅

### Deliverables
- ✅ `lib/apply-overlay.sh` implementation
  - Remap `tools:` and `allowed-tools:` in `SKILL.md` using `tool-map.json`
  - Render `ANTIGRAVITY-NOTE.md`
  - Copy overlay contents
- ✅ Update `lib/setup.sh` to invoke `apply-overlay.sh`
- ✅ `tests/test-phase3.sh` TDD suite written and passing

### Test Results

| Suite | Result |
|-------|--------|
| `test-phase3.sh` | ✅ 79/79 passed |

---

## Phase 4 Detail — COMPLETE ✅

### Deliverables
- ✅ `templates/project/.agents/hooks/block-destructive-ops.sh` implemented
- ✅ `templates/project/.agents/hooks/quality-gate.sh` implemented
- ✅ `templates/project/.agents/hooks/auto-lint.sh` implemented
- ✅ `templates/project/.agents/hooks.json` template implemented
- ✅ `tests/test-phase4.sh` TDD suite written and passing

### Test Results

| Suite | Result |
|-------|--------|
| `test-phase4.sh` | ✅ 25/25 passed |

---

## Phase 5 Detail — COMPLETE ✅

### Deliverables
- ✅ `templates/project/GEMINI.md.tmpl` implemented
- ✅ `templates/project/AGENTS.md.tmpl` implemented
- ✅ `tests/test-phase5.sh` TDD suite written and passing

### Test Results

| Suite | Result |
|-------|--------|
| `test-phase5.sh` | ✅ 4/4 passed |

---

## Phase 6 Detail — COMPLETE ✅

### Deliverables
- ✅ `azg new` implemented in `lib/scaffold.sh`
- ✅ Interactive CLI questions working properly
- ✅ `atomic_write` fixed to correctly handle stdin
- ✅ Multiline template substitution correctly handled via `ENVIRON`
- ✅ `tests/test-phase6.sh` TDD suite written and passing

### Test Results

| Suite | Result |
|-------|--------|
| `test-phase6.sh` | ✅ 13/13 passed |

---

## Definition of Done (v3.0.0)

- [ ] `azg setup` runs cleanly on CachyOS and macOS
- [ ] `azg new test-project` produces a working directory
- [ ] `azg setup` is idempotent
- [ ] `azg uninstall` leaves no orphaned files
- [ ] `VENDOR.lock` present and accurate after first vendor pull
- [ ] `tests/test-azg.sh` passes for setup, new, and apply
