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
| Phase 4 | Hook library — 3 hooks + `hooks.json` template | ⬜ Pending |
| Phase 5 | `GEMINI.md.tmpl` / `AGENTS.md.tmpl` | ⬜ Pending |
| Phase 6 | `azg new` — 8-question scaffold flow | ⬜ Pending |
| Phase 7 | `azg apply` — managed-block retrofit | ⬜ Pending |
| Phase 8 | `azg update [--vendor]`, `azg uninstall` | ⬜ Pending |
| Phase 9 | `tests/test-azg.sh` — temp-HOME integration test | ⬜ Pending |
| Phase 10 | Cross-device validation — CachyOS + macOS | ⬜ Pending |
| Phase 11 | `docs/antigravity-agent-architecture.md`, README quickstart | ⬜ Pending |

---

## Phase 3 Detail — COMPLETE ✅

### Deliverables
- ✅ `lib/apply-overlay.sh` implementation
  - Remap `tools:` and `allowed-tools:` in `SKILL.md` using `tool-map.json`
  - Render `ANTIGRAVITY-NOTE.md`
  - Copy overlay contents
- ✅ Update `lib/setup.sh` to invoke `apply-overlay.sh`
- ✅ Pass all Phase 3 tests

### Test Results

| Suite | Result |
|-------|--------|
| `test-phase0.sh` | ✅ Passing |
| `test-phase1.sh` | ✅ 22/23 passed, 1 skipped (resolves via Phase 2/3 regression tests) |
| `test-phase2.sh` | ✅ 45/45 passed |
| `test-phase3.sh` | ✅ 79/79 passed |

---

## Definition of Done (v3.0.0)

- [ ] `azg setup` runs cleanly on CachyOS and macOS
- [ ] `azg new test-project` produces a working directory
- [ ] `azg setup` is idempotent
- [ ] `azg uninstall` leaves no orphaned files
- [ ] `VENDOR.lock` present and accurate after first vendor pull
- [ ] `tests/test-azg.sh` passes for setup, new, and apply
