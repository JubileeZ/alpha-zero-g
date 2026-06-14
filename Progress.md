# Alpha-Zero-G v3.0.0 — Progress Tracker

> Auto-updated by agent as phases complete.  
> Last updated: 2026-06-14

---

## Build Order

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 0 | Repo skeleton — `azg` dispatcher, `VERSION`, `common.sh` | ✅ Done |
| Phase 1 | `azg setup` — copy global skills, `mcp_config`, idempotent | ✅ Done |
| **Phase 2** | **`vendor-sync.sh` — pin mattpocock/skills commit, populate `vendor/`** | 🔄 In Progress |
| Phase 3 | `apply-overlay.sh` — tool-map remap + ANTIGRAVITY-NOTE injection | ⬜ Pending |
| Phase 4 | Hook library — 3 hooks + `hooks.json` template | ⬜ Pending |
| Phase 5 | `GEMINI.md.tmpl` / `AGENTS.md.tmpl` | ⬜ Pending |
| Phase 6 | `azg new` — 8-question scaffold flow | ⬜ Pending |
| Phase 7 | `azg apply` — managed-block retrofit | ⬜ Pending |
| Phase 8 | `azg update [--vendor]`, `azg uninstall` | ⬜ Pending |
| Phase 9 | `tests/test-azg.sh` — temp-HOME integration test | ⬜ Pending |
| Phase 10 | Cross-device validation — CachyOS + macOS | ⬜ Pending |
| Phase 11 | `docs/antigravity-agent-architecture.md`, README quickstart | ⬜ Pending |

---

## Phase 2 Detail

### TDD Approach
- ✅ Write failing tests (`test-phase2.sh`) first — RED
- ⬜ Implement `vendor-sync.sh` — make tests GREEN
- ⬜ Wire `update.sh` `--vendor` path
- ⬜ Verify all 3 test suites pass (phase0, phase1, phase2)
- ⬜ Commit

### Test Results

| Suite | Result |
|-------|--------|
| `test-phase0.sh` | ✅ Passing (baseline) |
| `test-phase1.sh` | ✅ 22 passed, 1 skipped (un-skips after Phase 2) |
| `test-phase2.sh` | 🔄 Writing tests... |

---

## Definition of Done (v3.0.0)

- [ ] `azg setup` runs cleanly on CachyOS and macOS
- [ ] `azg new test-project` produces a working directory
- [ ] `azg setup` is idempotent
- [ ] `azg uninstall` leaves no orphaned files
- [ ] `VENDOR.lock` present and accurate after first vendor pull
- [ ] `tests/test-azg.sh` passes for setup, new, and apply
