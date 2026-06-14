# Alpha-Zero-G v3.0.0 — Implementation Plan

A complete system for building production AI agent harnesses for Antigravity CLI (`agy`). Skills, hooks, memory, subagents, and scaffold tooling, delivered as a versioned snapshot that installs cleanly to two devices (CachyOS Linux + macOS) and can be fully removed.

---

## 1. Scope

**In scope (v3.0.0):**
- `azg` CLI dispatcher (POSIX bash, runs on CachyOS + macOS)
- `azg setup` — machine-level install of global skills + MCP config to `~/.gemini/antigravity-cli/`
- `azg new` — interactive scaffold engine for new Antigravity projects
- `azg apply` — retrofit existing projects with the harness
- `azg update` / `azg update --vendor` — refresh Alpha-Zero-G and re-vendor skill library
- `azg uninstall` — clean removal of all managed files
- Vendored skill library from `mattpocock/skills` (engineering + productivity, 11 skills)
- Hook library: safety-gate, quality-gate, auto-lint
- `GEMINI.md` / `AGENTS.md` project templates

**Out of scope (defer to v3.1+):**
- Windows support
- Live-sync / symlink mode
- Multi-agent deliberation orchestration scripts (separate doc, not part of install)
- Auto-installing `agy` itself (detect + point to official install docs only)

---

## 2. Repo Layout

```
alpha-zero-g/
├── azg                              # dispatcher entrypoint (bash)
├── VERSION
├── README.md
├── lib/
│   ├── setup.sh                     # azg setup
│   ├── scaffold.sh                  # azg new
│   ├── apply.sh                     # azg apply
│   ├── update.sh                    # azg update [--vendor]
│   ├── uninstall.sh                 # azg uninstall
│   ├── vendor-sync.sh               # re-vendor mattpocock/skills
│   ├── apply-overlay.sh             # tool-map remap + note injection
│   └── common.sh                    # OS detection, shared helpers
├── templates/
│   ├── global/
│   │   ├── skills/
│   │   │   ├── vendor/mattpocock-skills/
│   │   │   │   ├── VENDOR.lock
│   │   │   │   ├── engineering/      # 8 skills, byte-identical to upstream
│   │   │   │   └── productivity/     # 3 skills, byte-identical to upstream
│   │   │   └── overlay/mattpocock-skills/
│   │   │       ├── tool-map.json
│   │   │       └── _shared/ANTIGRAVITY-NOTE.md.tmpl
│   │   └── mcp_config.json
│   └── project/
│       ├── GEMINI.md.tmpl
│       ├── AGENTS.md.tmpl
│       └── .agents/
│           ├── skills/.gitkeep
│           ├── hooks/
│           │   ├── block-destructive-ops.sh
│           │   ├── auto-lint.sh
│           │   └── quality-gate.sh
│           ├── hooks.json
│           └── mcp_config.json
├── tests/
│   └── test-azg.sh                  # runs setup/new/apply in a temp HOME
└── docs/
    └── antigravity-agent-architecture.md   # already written, copy in as-is
```

---

## 3. Cross-Platform Constraints

| Aspect | CachyOS (Linux) | macOS | Handling |
|---|---|---|---|
| Shell | bash/zsh | zsh default | All scripts `#!/usr/bin/env bash`, POSIX-safe constructs only |
| `sed -i` | GNU sed | BSD sed | Never use `sed -i` directly. Use `sed ... > tmp && mv tmp file` everywhere |
| `jq` | `pacman`/`paru` | `brew` | `common.sh` checks for `jq`; if missing, print OS-specific install hint and exit |
| Global config path | `~/.gemini/antigravity-cli/` | `~/.gemini/antigravity-cli/` | Identical, no branching needed |
| `agy` binary | `~/.local/bin/agy` | `~/.local/bin/agy` | `common.sh` checks `agy --version`; if missing, print install command from `antigravity.google/docs/cli-install` and exit (do not auto-curl) |
| Atomic file writes | `mv` same-filesystem | `mv` same-filesystem | Standard atomic write pattern (`.tmp` + `mv`) throughout |

---

## 4. Vendored Skill Library (mattpocock/skills)

11 skills, vendored byte-identical, overlay applied at copy-time only.

| Skill | Category | Notes |
|---|---|---|
| `setup-matt-pocock-skills` | engineering | Run once per project via `azg new`/`azg apply`. Writes issue tracker, labels, doc layout config that the skills below consume. |
| `tdd` | engineering | Red-green-refactor loop |
| `to-issues` | engineering | Plan/PRD → GitHub issues |
| `to-prd` | engineering | Conversation → PRD → GitHub issue |
| `triage` | engineering | Issue triage with label vocab |
| `diagnose` | engineering | Debugging loop |
| `improve-codebase-architecture` | engineering | Periodic architecture rescue |
| `zoom-out` | engineering | Broader context on unfamiliar code |
| `caveman` | productivity | Token-compressed responses |
| `teach` | productivity | Stateful multi-session teaching |
| `write-a-skill` | productivity | Meta: create new skills |

### `VENDOR.lock` format

```yaml
source: https://github.com/mattpocock/skills
commit: <pinned-sha>
date_vendored: YYYY-MM-DD
license: <verify and record at first vendor pull>
included:
  - skills/engineering
  - skills/productivity
excluded:
  - skills/deprecated
  - skills/in-progress
  - skills/misc
  - skills/personal
```

### `tool-map.json` (overlay, applied at copy-time)

```json
{
  "Read": "read_file",
  "Write": "write_file",
  "Edit": "edit_file",
  "Bash": "run_command",
  "Grep": "grep",
  "Glob": "glob"
}
```

### `apply-overlay.sh` contract

For each of the 11 skills, on every `azg setup`:
1. `rm -rf` the destination under `~/.gemini/antigravity-cli/skills/<name>/`
2. `cp -R` from `vendor/mattpocock-skills/<category>/<name>/`
3. Remap `tools:`/`allowed-tools:` line(s) in `SKILL.md` frontmatter only, using `tool-map.json`. Unmapped tokens pass through unchanged.
4. Render `_shared/ANTIGRAVITY-NOTE.md.tmpl` → `<dest>/ANTIGRAVITY-NOTE.md` with `{{SKILL_NAME}}` substituted
5. If `overlay/mattpocock-skills/<name>/` exists, copy its contents into `<dest>/` (additive, for any future per-skill overrides)

**Destination is a build artifact.** Never hand-edit inside `~/.gemini/antigravity-cli/skills/`. Source of truth is `vendor/` + `overlay/`.

---

## 5. Hook Library (project template)

All three ship in `templates/project/.agents/hooks/`, registered in `templates/project/.agents/hooks.json`. JSON decision contract (not exit codes):

```json
{
  "safety-gate": {
    "enabled": true,
    "PreToolUse": [
      { "matcher": "run_command", "hooks": [{ "type": "command", "command": "./hooks/block-destructive-ops.sh" }] }
    ]
  },
  "quality-gate": {
    "enabled": false,
    "PreToolUse": [
      { "matcher": "run_command", "hooks": [{ "type": "command", "command": "./hooks/quality-gate.sh" }] }
    ]
  },
  "auto-lint": {
    "enabled": false,
    "PostToolUse": [
      { "matcher": "write_file", "hooks": [{ "type": "command", "command": "./hooks/auto-lint.sh" }] }
    ]
  }
}
```

| Hook | Default | Behavior |
|---|---|---|
| `block-destructive-ops.sh` | enabled | Denies `rm -rf /`, force-push, `git reset --hard`, `chmod 777`, `curl\|bash` patterns |
| `quality-gate.sh` | disabled | On `git commit`, runs project lint command (read from `GEMINI.md` build-commands table); denies on failure |
| `auto-lint.sh` | disabled | On file write, runs formatter matched by extension |

`azg new` question 4 toggles `enabled` flags in the generated `hooks.json`.

---

## 6. `azg new` — 8-Question Scaffold Flow

1. **Project name** → directory + `GEMINI.md` title
2. **Stack** (Python+uv / Node / R / other) → determines default build-commands table
3. **Build commands** (lint/format/test/typecheck) → populates `GEMINI.md` "Build and Test Commands" + "Definition of Done"
4. **Hooks to enable** (safety-gate always on; quality-gate, auto-lint opt-in)
5. **Run `setup-matt-pocock-skills` now?** (yes/no, default yes) — if yes, instruct user to run it inside the first `agy` session post-scaffold (cannot run agent skills from a bash scaffold script)
6. **MCP servers** (none / github / browser / custom path)
7. **Write `AGENTS.md` alongside `GEMINI.md`?** (yes/no, default yes)
8. **Git init + initial commit?** (yes/no, default yes)

Output: fully scaffolded directory, `.agents/` populated, `GEMINI.md`/`AGENTS.md` written, ready for `agy` to start.

---

## 7. `azg apply` — Retrofit Mode

Target: existing repos (e.g. FPL-Jubilee-Ascent).

- `.agents/hooks/`, `.agents/skills/` → additive copy, never overwrite existing files with the same name (skip + warn)
- `.agents/hooks.json` → merge JSON (preserve existing keys, add missing default gates as `enabled: false`)
- `GEMINI.md`/`AGENTS.md` → if absent, write from template. If present, insert/update a managed block:

```markdown
<!-- AZG:MANAGED:START -->
... azg-generated sections ...
<!-- AZG:MANAGED:END -->
```

Re-running `azg apply` only replaces content between these markers.

---

## 8. `azg update` / `azg update --vendor`

- `azg update`: `git pull` the Alpha-Zero-G repo itself
- `azg update --vendor`:
  1. Shallow clone `mattpocock/skills@main`
  2. Replace `templates/global/skills/vendor/mattpocock-skills/{engineering,productivity}/` wholesale
  3. Update `VENDOR.lock` (commit + date)
  4. Print diff summary (changed files per skill)
  5. `overlay/` untouched
- After either: re-run `azg setup` on each device to push changes to `~/.gemini/antigravity-cli/`

---

## 9. `azg uninstall`

Removes everything `azg setup` created under `~/.gemini/antigravity-cli/` (skills + mcp_config). Does not touch any project's `.agents/` directories (those are owned by the project repo, not Alpha-Zero-G). Print a summary of removed paths.

---

## 10. Build Order

```
[ ] Phase 0: Repo skeleton — azg dispatcher, VERSION, common.sh (OS detection)
[ ] Phase 1: azg setup — copy global skills (no vendor yet), mcp_config, idempotent
[ ] Phase 2: vendor-sync.sh — pin mattpocock/skills commit, populate vendor/
[ ] Phase 3: apply-overlay.sh — tool-map remap + ANTIGRAVITY-NOTE injection
[ ] Phase 4: Hook library — 3 hooks + hooks.json template
[ ] Phase 5: GEMINI.md.tmpl / AGENTS.md.tmpl
[ ] Phase 6: azg new — 8-question scaffold flow
[ ] Phase 7: azg apply — managed-block retrofit
[ ] Phase 8: azg update [--vendor], azg uninstall
[ ] Phase 9: tests/test-azg.sh — temp-HOME integration test for setup/new/apply
[ ] Phase 10: Cross-device validation — run full flow on CachyOS, then macOS
[ ] Phase 11: docs/antigravity-agent-architecture.md copied in, README quickstart
```

---

## 11. Definition of Done (v3.0.0)

1. `azg setup` runs cleanly on a fresh CachyOS install and a fresh macOS install, producing identical `~/.gemini/antigravity-cli/skills/` trees (modulo `tool-map.json` remap, which is OS-independent)
2. `azg new test-project` produces a directory where `agy` starts and the `caveman` global skill + `safety-gate` hook are both active
3. `azg setup` is idempotent: running it twice produces no diff on the second run
4. `azg uninstall` leaves no orphaned files under `~/.gemini/antigravity-cli/`
5. `VENDOR.lock` present and accurate after first vendor pull
6. `tests/test-azg.sh` passes for setup, new, and apply in a temp `HOME`

---

## 12. When Blocked

- If `jq` or `agy` is missing: print the OS-specific install command and exit non-zero. Do not attempt to auto-install either.
- If `mattpocock/skills` upstream structure changes (skill added/removed/renamed) during `azg update --vendor`: stop, report the diff, do not auto-update `VENDOR.lock` `included`/`excluded` lists without confirmation.
- Never use `sed -i` (BSD/GNU incompatibility). Never use `((VAR++))` with `set -e` (zero-value exit-1 trap).
