# Alpha-Zero-G — Research Reference
**Compiled:** 2026-06-01 | **Scope:** Agent harness, Antigravity CLI, skills, ADRs

This file is a reference for AI agents building or maintaining Alpha-Zero-G.
It summarises current ecosystem state so you do not need to re-research before acting.

---

## 1. The Agent Instruction File Ecosystem (June 2026)

### Current standard: AGENTS.md

AGENTS.md is the cross-tool open standard for repo-level AI agent instructions.
It is governed by the Linux Foundation's Agentic AI Foundation (alongside Anthropic's MCP).

**Tools that read AGENTS.md natively (as of June 2026):**
Antigravity IDE/CLI, Cursor, OpenAI Codex CLI, GitHub Copilot, Google Jules,
Windsurf, Zed, RooCode, Factory, Amp.

**Claude Code status:** Does NOT auto-load AGENTS.md as of June 2026 (GitHub issue #34235
open, thousands of upvotes). Workaround: `ln -s AGENTS.md CLAUDE.md` on Mac/Linux,
or add `@./AGENTS.md` as file content on Windows.

### Priority hierarchy inside Antigravity (highest → lowest)

| Priority | File | Scope |
|----------|------|-------|
| 1 (highest) | `GEMINI.md` | Antigravity-specific rules and overrides |
| 2 | `AGENTS.md` | Cross-tool shared rules |
| 3 | `.agent/rules/*.md` | Supplemental workspace rules |
| 4 | System rules | Google DeepMind immutable core |

### Global vs. project-level

```
~/.gemini/AGENTS.md              → global cross-tool rules (all projects, all tools)
~/.gemini/GEMINI.md              → global Antigravity-only overrides
~/.claude/CLAUDE.md              → global Claude Code rules (@-imports global AGENTS.md)

project-root/AGENTS.md           → project-scoped rules
project-root/GEMINI.md           → project Antigravity overrides
project-root/CLAUDE.md           → symlink → AGENTS.md (or @./AGENTS.md on Windows)
project-root/.agent/rules/*.md   → supplemental rule files
```

**Known conflict:** Both Antigravity IDE and Gemini CLI used `~/.gemini/GEMINI.md` for
global config. The workaround is to keep shared rules in `~/.gemini/AGENTS.md` and use
`~/.gemini/GEMINI.md` for Antigravity-only settings only. Gemini CLI shuts down 2026-06-18.

### Keep files lean — critical finding

ETH Zurich research (Thibaud Gloaguen et al., 2026) found:
- LLM-generated context files reduced task success by ~3% vs no file.
- Including context files increased inference costs by >20%.
- Root cause: restating what the code already says wastes context window.

**Rule:** Every line in an agent file must pass this test:
> "Would removing this cause the agent to make a mistake it cannot recover from?"
If no: remove it. Target under 100 lines per file.

---

## 2. Antigravity CLI (agy) — Current State

### Release context

Antigravity CLI (`agy`) is the Go-based terminal successor to Gemini CLI, released at
Google I/O on 2026-05-19. Gemini CLI shuts down 2026-06-18. Antigravity CLI shares the
same agent harness as Antigravity 2.0 (desktop). Config syncs bidirectionally between CLI
and desktop.

**Supported platforms:** macOS, Linux, Windows (native PowerShell, no WSL required).

### Install paths

| Platform | Binary location |
|----------|-----------------|
| Mac/Linux | `~/.local/bin/agy` |
| Windows | `%LOCALAPPDATA%\agy\bin\agy.exe` |

If PATH is not updated by the installer, it will print instructions. Add to shell profile
manually if needed (`~/.zshrc` or `~/.bashrc`).

### Config file locations

| File | Purpose |
|------|---------|
| `~/.gemini/antigravity-cli/settings.json` | All user settings: model, statusLine, colorScheme, permissions, trustedWorkspaces |
| `~/.gemini/AGENTS.md` | Global cross-tool rules |
| `~/.gemini/GEMINI.md` | Global Antigravity-only rules |
| `~/.gemini/antigravity-cli/skills/` | Global skills directory |
| `~/.gemini/antigravity/brain/<GUID>/` | Task artifacts (task.md, implementation_plan.md, walkthrough.md) |
| `.agents/skills/` | Per-project skills |
| `.agents/rules/` | Per-project supplemental rules |

### settings.json structure (relevant fields)

```json
{
  "colorScheme": "dark",
  "model": "Gemini 3.5 Flash (High)",
  "statusLine": {
    "type": "custom",
    "command": "python3 ~/.agent-config/statusline.py",
    "enabled": true
  },
  "permissions": {
    "allow": ["command(git)", "command(pytest)", "command(Rscript)"],
    "deny":  ["command(rm -rf)"]
  },
  "trustedWorkspaces": []
}
```

**Windows note:** Use `%USERPROFILE%` paths in `settings.json` on Windows, not `~`.
Use `python` not `python3` for the command field on Windows.

### Statusline

The `statusLine.command` field runs an arbitrary shell command. Its stdout becomes the
statusline text displayed in the `agy` TUI.

- Configure via `/settings` or `/config` inside `agy`, or edit `settings.json` directly.
- In-session control: `/statusline enable`, `/statusline disable`, `/statusline reset`
- CHANGELOG note: `/statusline` subcommands are case-insensitive as of a recent patch.
- Known issue: documentation is sparse (confirmed open thread on Google AI Developers Forum,
  2026-05-19). Use `/settings` inside `agy` to explore fields interactively.
- The script must output one line to stdout. Use Python 3 stdlib only for cross-platform safety.

### Key slash commands to know

```
/settings or /config    Open settings.json in editor
/permissions            View and edit permission allow/deny list
/statusline             Control the statusline
/skills                 List installed skills
/agents                 Manage subagents
/tasks                  View background tasks
/resume                 Resume previous conversation
/rewind                 Step back in conversation
/handoff                (from mattpocock skills) Write session handoff doc
!<command>              Run a raw shell command without leaving the TUI
@<path>                 Attach a file to the current prompt
```

### Migration from Gemini CLI

On first run, `agy` offers a one-time import of Gemini CLI settings, skills, and
extensions. Accept this if you have an existing Gemini CLI setup.

---

## 3. mattpocock/skills

**Repo:** https://github.com/mattpocock/skills (MIT license, 113k+ stars)
**Philosophy:** Small, composable, model-agnostic. Constraints encoded in tooling,
not dependent on the developer remembering to prompt correctly.

### Skill file structure

```
skill-name/
├── SKILL.md          # Required: frontmatter + instructions
├── REFERENCE.md      # Optional: detailed docs
├── EXAMPLES.md       # Optional: usage examples
└── scripts/          # Optional: utility scripts
```

The `description` field in SKILL.md YAML frontmatter is the only thing the agent sees
when deciding which skill to load. Write it carefully.

### Engineering skills (install all)

| Skill | What it does |
|-------|-------------|
| `setup-matt-pocock-skills` | One-time per-repo setup: configures issue tracker, triage labels, domain doc layout. **Run first before using any other engineering skill.** |
| `tdd` | Red-green-refactor loop. Never writes implementation before tests. |
| `to-issues` | Breaks any plan/spec/PRD into independently-grabbable GitHub issues as vertical slices. |
| `to-prd` | Turns current conversation context into a PRD, submits as a GitHub issue. |
| `zoom-out` | Tells the agent to step back and give higher-level context on unfamiliar code. |
| `diagnose` | Structured debugging loop wrapping best debugging practices. |
| `improve-codebase-architecture` | Rescues a "ball of mud" codebase. Recommended to run every few days on agent-developed projects. |

### Productivity skills (selected subset)

| Skill | What it does |
|-------|-------------|
| `handoff` | Writes a `docs/handoff.md` session summary so the next session (or agent) has context. Critical for maintaining continuity. |
| `write-a-skill` | Creates new skills with proper structure, progressive disclosure, and bundled resources. |
| `caveman` | Switches to concise, caveman-style technical responses. Useful for fast iteration loops. |

### Install paths for Antigravity CLI

| Scope | Path |
|-------|------|
| Global (all projects) | `~/.gemini/antigravity-cli/skills/` |
| Per-project | `.agents/skills/` in project root |

After cloning the repo to `~/.agent-skills/mattpocock/`, symlink individual skill
directories into the global skills path. Do not copy the whole repo to the skills dir
(avoid loading unused skills and bloating the context window).

### Important: run `/setup-matt-pocock-skills` first per repo

This skill configures the other engineering skills with:
- Which issue tracker (GitHub, Linear, or local files)
- Triage label vocabulary
- Domain doc layout (where `CONTEXT.md` and ADRs live)

Without this, `to-issues`, `to-prd`, `triage`, `diagnose`, `tdd`, and
`improve-codebase-architecture` will be missing key context.

---

## 4. Architecture Decision Records (ADRs)

### Purpose

ADRs capture *why* a decision was made, not just what was built. They give agents
(and humans) the reasoning context to avoid re-litigating settled decisions.

**ADRs answer:** "What did we decide and why?"
**AGENTS.md answers:** "Given what we decided, what must never happen when changing this code?"

They are complementary, not redundant.

### When to write an ADR (agent trigger conditions)

Write an ADR when:
- Choosing a library or tool dependency
- Changing data schema or output contract
- Modifying project folder structure
- Adopting or changing a testing strategy
- Making any decision that would be hard to reverse

### Workflow: research → ADR → code

1. **Research spike first:** `docs/research/YYYY-MM-DD-topic.md`
   - Raw notes, links, pros/cons. Not polished. Agent-writable.
2. **ADR:** `docs/adr/ADR-NNN-slug.md`
   - Accepted decisions. Immutable after acceptance. Supersede with new ADR if changed.
3. **Tag source files:** add `# ADR-NNN` comment near affected code.
   - Agents can grep this to understand constraints before editing.

### ADR file naming

```
ADR-001-project-init.md
ADR-002-use-uv-for-deps.md
ADR-003-renv-for-r-packages.md
```

Pad to 3 digits. Auto-detect next number by scanning `docs/adr/` directory.

### ADR status lifecycle

`Proposed` → `Accepted` → `Superseded by ADR-NNN`

Accepted ADRs are immutable. Never edit a decision after acceptance; write a new ADR that
supersedes the old one and cross-reference both.

---

## 5. Harness Engineering Principles

These principles should inform how AGENTS.md and project structure are designed.

**Core insight:** "Agent = Model + Harness. A well-built harness can make a weaker model
outperform a stronger model in a poorly-scaffolded system."

**Practical rules:**

1. **Anything the agent cannot access in-context does not exist.** Knowledge in Google
   Docs, Slack, or heads is invisible to the agent. Put it in files.

2. **Encode standards into the harness, not into prompts.** If you have to remind the
   agent every session, it belongs in AGENTS.md.

3. **Layer rules hierarchically.**
   - Root `AGENTS.md`: system-wide invariants (never touch `data/raw/`)
   - Sub-module `AGENTS.md` or `.agent/rules/`: domain-specific constraints

4. **Make rules testable.** If AGENTS.md says "all API handlers must include error
   boundaries," add a lint rule that verifies it. Agents can run the test to confirm
   compliance after writing code.

5. **AGENTS.md is a living document; ADRs are immutable.**
   - Update AGENTS.md as the project evolves.
   - Supersede old ADRs with new ones; never edit them in place.

6. **Watch for architectural drift.** Agents accelerate code generation and therefore
   accelerate entropy. Run `/improve-codebase-architecture` every few days.

---

## 6. Known Issues and Gotchas

| Issue | Detail |
|-------|--------|
| Gemini CLI EOL | Shuts down 2026-06-18. Remove all Gemini CLI dependencies. |
| `~/.gemini/GEMINI.md` conflict | Both Antigravity IDE and Gemini CLI used this path. Use `~/.gemini/AGENTS.md` for shared global rules. |
| Windows symlinks | Creating symlinks on Windows requires admin rights or Developer Mode. Workaround: write `@./AGENTS.md` to `CLAUDE.md` as file content. |
| agy PATH on Mac | Installer may not add `~/.local/bin` to PATH. Check with `which agy` after install. |
| statusline docs | Officially sparse as of June 2026. Use `/settings` inside `agy` TUI to explore. `settings.json` at `~/.gemini/antigravity-cli/settings.json`. |
| Claude Code AGENTS.md | Not natively supported (GitHub issue #34235). Symlink workaround until resolved. |
| mattpocock skills are Claude Code native | SKILL.md format is compatible with Antigravity's skill system. No format conversion needed; copy or symlink SKILL.md directories directly. |

---

## 7. Sources

| Source | URL | Date |
|--------|-----|------|
| Blink: AGENTS.md vs CLAUDE.md | https://blink.new/blog/agents-md-vs-claude-md | April 2026 |
| HiveTrail: AGENTS.md cross-tool standard | https://hivetrail.com/blog/agents-md-vs-claude-md-cross-tool-standard | April 2026 |
| Agentpedia: Antigravity AGENTS.md guide | https://agentpedia.codes/blog/antigravity-agents-md-guide | March 2026 |
| Agentpedia: Antigravity rules / GEMINI.md | https://agentpedia.codes/blog/user-rules | March 2026 |
| Termdock: SKILL.md vs CLAUDE.md vs AGENTS.md | https://www.termdock.com/blog/skill-md-vs-claude-md-vs-agents-md | March 2026 |
| mattpocock/skills README | https://github.com/mattpocock/skills | May 2026 |
| Google Cloud (Medium): Antigravity CLI tutorial | https://medium.com/google-cloud/antigravity-cli-tutorial-series-12b46cfe3bf2 | May 2026 |
| DEV: Antigravity CLI hands-on | https://dev.to/arindam_1729/antigravity-cli-a-hands-on-guide-to-googles-terminal-coding-agent-5bc7 | May 2026 |
| Agentpedia: Antigravity CLI deep dive | https://agentpedia.codes/blog/antigravity-cli-deep-dive | May 2026 |
| Google AI Developers Forum: statusline settings | https://discuss.ai.google.dev/t/antigravity-cli-settings/145561 | May 2026 |
| antigravity-cli CHANGELOG | https://github.com/google-antigravity/antigravity-cli/blob/main/CHANGELOG.md | May 2026 |
| JohnClick: ADR-first development | https://johnclick.ai/blog/adr-first-development-architecture-decision-records/ | March 2026 |
| ZBuild: Harness engineering complete guide | https://www.zbuild.io/resources/news/harness-engineering-complete-guide-ai-agent-codex-2026 | March 2026 |
| OpenAI: Harness engineering blog | https://openai.com/index/harness-engineering/ | 2026 |
| walkinglabs: learn-harness-engineering | https://github.com/walkinglabs/learn-harness-engineering | May 2026 |
