## CLAUDE.md Design

CLAUDE.md is operational policy for an AI agent, not a README for humans. The agent does not need to understand _why_ you use conventional commits. It needs to know the exact command to run and what “done” looks like.

### The Precedence Hierarchy

Location | Scope | Shared | Use Case  
---|---|---|---  
Enterprise managed settings | Organization | All users | Company standards  
`./CLAUDE.md` or `./.claude/CLAUDE.md` | Project | Via git | Team context  
`~/.claude/CLAUDE.md` | User | All projects | Personal preferences  
`./CLAUDE.local.md` | Project-local | Never | Personal project notes  
`.claude/rules/*.md` | Project rules | Via git | Categorized policies  
`~/.claude/rules/*.md` | User rules | All projects | Personal policies  
  
Rules files load automatically and provide structured context without cluttering CLAUDE.md.

### What Gets Ignored

These patterns reliably produce no observable change in agent behavior:

**Prose paragraphs without commands.** “We value clean, well-tested code” is documentation, not operations. The agent reads it and proceeds to write code without tests because there is no actionable instruction.

**Ambiguous directives.** “Be careful with database migrations” is not a constraint. “Run `alembic check` before applying migrations. Abort if downgrade path is missing.” is.

**Contradictory priorities.** “Move fast and ship quickly” plus “Ensure comprehensive test coverage” plus “Keep runtime under 5 minutes” plus “Run full integration tests before every commit.” The agent cannot satisfy all four simultaneously and defaults to skipping verification.

**Style guides without enforcement.** “Follow the Google Python Style Guide” without `ruff check --select D` gives the agent no mechanism to verify compliance.

### What Works

**Command-first instructions:**

```bash
## Build and Test Commands
- Install: `pip install -r requirements.txt`
- Lint: `ruff check . --fix`
- Format: `ruff format .`
- Test: `pytest -v --tb=short`
- Type check: `mypy app/ --strict`
- Full verify: `ruff check . && ruff format --check . && pytest -v`
``` 

**Closure definitions:**

```
## Definition of Done
A task is complete when ALL of the following pass:
1. `ruff check .` exits 0
2. `pytest -v` exits 0 with no failures
3. `mypy app/ --strict` exits 0
4. Changed files have been staged and committed
5. Commit message follows conventional format: `type(scope): description`
``` 

**Task-organized sections:**

```
## When Writing Code
- Run `ruff check .` after every file change
- Add type hints to all new functions

## When Reviewing Code
- Check for security issues: `bandit -r app/`
- Verify test coverage: `pytest --cov=app --cov-fail-under=80`

## When Releasing
- Update version in `pyproject.toml`
- Run full suite: `pytest -v && ruff check . && mypy app/`
``` 

**Escalation rules:**

```
## When Blocked
- If tests fail after 3 attempts: stop and report the failing test with full output
- If a dependency is missing: check `requirements.txt` first, then ask
- Never: delete files to resolve errors, force push, or skip tests
``` 

### Writing Order

If starting from scratch, add sections in this priority order:

  1. **Build and test commands** (the agent needs these before it can do anything useful)
  2. **Definition of done** (prevents false completions)
  3. **Escalation rules** (prevents destructive workarounds)
  4. **Task-organized sections** (reduces irrelevant instruction parsing)
  5. **Directory scoping** (monorepos: keeps service instructions isolated)



Skip style preferences until the first four are working.

### File Imports

Reference other files within CLAUDE.md:

```
See @README.md for project overview
Coding standards: @docs/STYLE_GUIDE.md
API documentation: @docs/API.md
Personal preferences: @~/.claude/preferences.md
``` 

Import syntax: relative (`@docs/file.md`), absolute (`@/absolute/path.md`), or home directory (`@~/.claude/file.md`). Maximum depth: 5 levels of imports.

### Cross-Tool Instruction Compatibility

AGENTS.md is an open standard recognized by every major AI coding tool. If your team uses multiple tools, write AGENTS.md as the canonical source and mirror relevant sections to tool-specific files:

Tool | Native File | Reads AGENTS.md?  
---|---|---  
Codex CLI | AGENTS.md | Yes (native)  
Cursor | `.cursor/rules` | Yes (native)  
GitHub Copilot | `.github/copilot-instructions.md` | Yes (native)  
Amp | AGENTS.md | Yes (native)  
Windsurf | `.windsurfrules` | Yes (native)  
Claude Code | CLAUDE.md | No (separate format)  
  
The patterns in AGENTS.md (command-first, closure-defined, task-organized) work in any instruction file regardless of tool. Do not maintain parallel instruction sets that drift apart. Write one authoritative source and mirror.

### Codex Parity Notes

Codex now has first-class equivalents for the major harness layers, but the migration is a pattern translation, not a file copy. Codex reads `AGENTS.md` before work begins, layering global guidance from `~/.codex` with project and nested repository instructions. Codex skills use the same `SKILL.md` mental model with progressive disclosure: Codex starts with the skill name, description, and file path, then loads the full skill only when it decides to use it. Codex also has native hooks, plugin-bundled hooks, managed hooks, MCP support, and explicit subagent workflows.

Codex v0.138.0–v0.139.0 hardened that AGENTS.md discovery for non-trivial workspaces: loading now routes through the environment’s filesystem abstraction and preserves logical paths during the discovery walk, so the right file is selected even when the workspace is a remote filesystem or a symlinked tree. This matters whenever your canonical `AGENTS.md` is the authoritative source and the agent is operating over a mounted, container-materialized, or symlinked checkout — the cases where a naive path walk silently picks the wrong instruction file or none at all. If you mirror one authoritative `AGENTS.md` across services, treat this as the floor for trusting that the file the agent actually loaded is the one you wrote.

The practical mapping:

Claude Code harness layer | Codex equivalent | Migration rule  
---|---|---  
`CLAUDE.md` / `.claude/rules/` | `AGENTS.md` / nested `AGENTS.override.md` | Keep commands and completion rules canonical; split only when directory scope genuinely differs  
`.claude/skills/<name>/SKILL.md` | `.agents/skills/<name>/SKILL.md` or plugin skill | Port reusable workflows, but rewrite descriptions for Codex’s activation wording and budget  
`.claude/settings.json` hooks | Codex `config.toml`, plugin hooks, or managed requirements hooks | Port deterministic gates first; test each hook with real tool events before enabling broadly  
`.claude/agents/*.md` | `~/.codex/agents/*.toml`, `.codex/agents/*.toml`, or built-in `worker` / `explorer` | Port only agents with repeated value; prefer explicit delegation because Codex subagents are explicit  
Plugins | Codex plugins | Use plugins as the distribution unit after local hooks and skills are proven  
  
The important difference: Claude subagents can be selected automatically from descriptions, while Codex currently documents subagent workflows as explicit. That makes skills and hooks the right default for always-on harness behavior in Codex; subagents are for deliberate parallel work, review, and exploration.

### Testing Your Instructions

Verify the agent actually reads and follows your instructions:

```
# Check active instructions
claude --print "What instructions are you following for this project?"

# Verify specific rules are active
claude --print "What is your definition of done?"
``` 

**The acid test:** Ask the agent to explain your build commands. If it cannot reproduce them verbatim, the instructions are either too verbose (content pushed out of context), too vague (agent cannot extract actionable instructions), or not being discovered. GitHub’s analysis of 2,500 repositories found that vagueness causes most failures.

* * *
