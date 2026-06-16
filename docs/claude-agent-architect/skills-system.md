## Skills System

Skills are model-invoked extensions. Claude discovers and applies them automatically based on context, without you explicitly calling them. The moment you catch yourself re-explaining the same context across sessions is the moment you should build a skill.

### When to Build a Skill

Situation | Build a… | Why  
---|---|---  
You paste the same checklist every session | **Skill** | Domain expertise that auto-activates  
You run the same command sequence explicitly | **Slash command** | User-invoked action with predictable trigger  
You need isolated analysis that shouldn’t pollute context | **Subagent** | Separate context window for focused work  
You need a one-time prompt with specific instructions | **Nothing** | Just type it. Not everything needs abstraction.  
  
Skills are for _knowledge Claude always has available_. Slash commands are for _actions you explicitly trigger_. If you are deciding between the two, ask: “Should Claude apply this automatically, or should I decide when to run it?”

### Creating a Skill

Skills live in four possible locations, from broadest to narrowest scope:

Scope | Location | Applies to  
---|---|---  
Enterprise | Managed settings | All users in organization  
Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects  
Project | `.claude/skills/<name>/SKILL.md` | This project only  
Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin is enabled  
  
Every skill requires a `SKILL.md` file with YAML frontmatter:

```yaml
---
name: code-reviewer
description: Review code for security vulnerabilities, performance issues,
  and best practice violations. Use when examining code changes, reviewing
  PRs, analyzing code quality, or when asked to review, audit, or check code.
allowed-tools: Read, Grep, Glob
---

# Code Review Expertise

## Security Checks
When reviewing code, verify:

### Input Validation
- All user input sanitized before database operations
- Parameterized queries (no string interpolation in SQL)
- Output encoding for rendered HTML content

### Authentication
- Session tokens validated on every protected endpoint
- Permission checks before data mutations
- No hardcoded credentials or API keys in source
``` 

### Frontmatter Reference

Field | Required | Purpose  
---|---|---  
`name` | Yes | Unique identifier (lowercase, hyphens, max 64 chars)  
`description` | Yes | Discovery trigger (max 1024 chars). Claude uses this to decide when to apply the skill  
`allowed-tools` | No | Restrict Claude’s capabilities (e.g., `Read, Grep, Glob` for read-only)  
`disable-model-invocation` | No | Prevents auto-activation; skill only activates via `/skill-name`  
`user-invocable` | No | Set `false` to hide from the `/` menu entirely  
`model` | No | Override which model to use when the skill is active  
`context` | No | Set to `fork` to run in isolated context window  
`agent` | No | Run as a subagent with its own isolated context  
`hooks` | No | Define lifecycle hooks scoped to this skill  
`$ARGUMENTS` | No | String substitution: replaced with user’s input after `/skill-name`  
  
### The Description Field Is Everything

At session start, Claude Code extracts every skill’s `name` and `description` and injects them into Claude’s context. When you send a message, Claude uses _language model reasoning_ to decide if any skill is relevant. Independent analysis of the Claude Code source confirms the mechanism: skill descriptions are injected into an `available_skills` section of the system prompt, and the model uses standard language understanding to select relevant skills.

**Bad description:**

```
description: Helps with code
``` 

**Effective description:**

```
description: Review code for security vulnerabilities, performance issues,
  and best practice violations. Use when examining code changes, reviewing
  PRs, analyzing code quality, or when asked to review, audit, or check code.
``` 

The effective description includes: what it does (review code for _specific issue types_), when to use it (examining changes, PRs, quality analysis), and trigger phrases (review, audit, check) that users naturally type.

### Context Budget

All skill descriptions share a context budget that scales dynamically at 1% of the context window, with a fallback of 8,000 characters. If you have many skills, keep each description concise and put the key use case first. You can override the budget via the `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable, but the better fix is shorter, more precise descriptions. Run `/context` during a session to check whether any skills are being excluded.

### Supporting Files and Organization

Skills can reference additional files in the same directory:

```
~/.claude/skills/code-reviewer/
├── SKILL.md                    # Required: frontmatter + core expertise
├── SECURITY_PATTERNS.md        # Referenced: detailed vulnerability patterns
└── PERFORMANCE_CHECKLIST.md    # Referenced: optimization guidelines
``` 

Reference them from SKILL.md with relative links. Claude reads these files on-demand when the skill activates. Keep `SKILL.md` under 500 lines and move detailed reference material to supporting files.

### Sharing Skills via Git

Project skills (`.claude/skills/` in the repo root) are shared via version control:

```bash
mkdir -p .claude/skills/domain-expert
# ... write SKILL.md ...
git add .claude/skills/
git commit -m "feat: add domain-expert skill for payment processing rules"
git push
``` 

When teammates pull, they get the skill automatically. No installation, no configuration. This is the most effective way to standardize expertise across a team.

### Skills as a Prompt Library

Beyond single-purpose skills, the directory structure works as an organized prompt library:

```
~/.claude/skills/
├── code-reviewer/          # Activates on: review, audit, check
├── api-designer/           # Activates on: design API, endpoint, schema
├── sql-analyst/            # Activates on: query, database, migration
├── deploy-checker/         # Activates on: deploy, release, production
└── incident-responder/     # Activates on: error, failure, outage, debug
``` 

Each skill encodes a different facet of your expertise. Together, they form a knowledge base that Claude draws from automatically based on context. A junior developer gets senior-level guidance without asking for it.

### Skills Compose with Hooks

Skills can define their own hooks in frontmatter that activate only while the skill runs. This creates domain-specific behavior that does not pollute other sessions:

```yaml
---
name: deploy-checker
description: Verify deployment readiness. Use when preparing to deploy,
  release, or push to production.
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: "bash -c 'INPUT=$(cat); CMD=$(echo \"$INPUT\" | jq -r \".tool_input.command\"); if echo \"$CMD\" | grep -qE \"deploy|release|publish\"; then echo \"DEPLOYMENT COMMAND DETECTED. Running pre-flight checks.\" >&2; fi'"
---
``` 

Philosophy skills auto-activate via `SessionStart` hooks, injecting quality constraints into every session without explicit invocation. The skill itself is knowledge. The hook is enforcement. Together, they form a policy layer.

### Common Skill Mistakes

**Too-broad descriptions.** A `git-rebase-helper` skill that activates on any git-related prompt (rebases, merges, cherry-picks, even `git status`) pollutes context on 80% of sessions. The fix is either tightening the description or adding `disable-model-invocation: true` and requiring explicit `/skill-name` invocation.

**Too many skills competing for budget.** More skills means more descriptions competing for the 1% context budget. If you notice skills not activating, check `/context` for excluded ones. Prioritize fewer, well-described skills over many vague ones.

**Critical information buried in supporting files.** Claude reads SKILL.md immediately but only accesses supporting files when needed. If critical information is in a supporting file, Claude might not find it. Put essential information in SKILL.md directly.

### SDK Skill Surface (May 8, 2026)

Self-hosted harnesses on `claude-agent-sdk-python` v0.1.77+ should use the `skills` option on `ClaudeAgentOptions` to declare available skills, not the legacy `"Skill"` value in `allowed_tools`. The `"Skill"` shorthand is deprecated and the dedicated option gives Claude Code more structured information about which skills are available. Bundled CLI in v0.1.77 is v2.1.133.

### Plugin and Skill Convergence in `.claude/skills/` (May 29, 2026)

Skills have always loaded from a project’s `.claude/skills/` directory. Claude Code v2.1.157 extends that directory to plugins: a plugin placed in `.claude/skills/` now loads automatically with no marketplace registration, and `claude plugin init <name>` scaffolds a fresh one there with the manifest and SKILL.md already wired. That closes the gap between the two project-tooling shapes that used to live in different places — a bare skill committed straight to the repo, versus a plugin that bundles a skill plus hooks plus an MCP server but previously needed a marketplace to install. The practical effect for harness design: project-scoped tooling no longer needs a registry detour to ship — write it, commit it, and teammates get the same surface on `git pull`. Plugins still own the bundled-installable use case (hooks + skills + MCP servers + agents in one ZIP); the change is that a project no longer has to stand up a marketplace just to load one from its own tree.

### Hiding the Bundled Surface as Governance (June 8, 2026)

Skills are capability, and capability is attack surface. Claude Code v2.1.169 adds a `disableBundledSkills` setting (and the matching `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS` environment variable) that hides the bundled skills, workflows, and built-in slash commands from the model entirely. For a hardened or regulated harness, this is a deliberate attack-surface reduction: an operator who has audited and approved a specific set of project and personal skills can suppress everything Anthropic ships in the box, so the model only ever reasons over the surface the operator vetted. Treat it the same way you treat a tool allowlist — the default is broad capability, and turning the default off is a governance decision, not a convenience toggle.

* * *
