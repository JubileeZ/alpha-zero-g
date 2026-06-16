## Skills System

Skills are model-invoked extensions. Antigravity CLI (`agy`) discovers and applies them automatically based on context, without you explicitly calling them. The moment you catch yourself re-explaining the same context across sessions is the moment you should build a skill.

### When to Build a Skill

Situation | Build a… | Why  
---|---|---  
You paste the same checklist every session | **Skill** | Domain expertise that auto-activates  
You run the same command sequence explicitly | **Slash command / Skill trigger** | User-invoked action with predictable trigger  
You need isolated analysis that shouldn’t pollute context | **Subagent** | Separate context window for focused work  
You need a one-time prompt with specific instructions | **Nothing** | Just type it. Not everything needs abstraction.  
  
Skills are for _knowledge the agent always has available_. If you are deciding whether to build a skill, ask: “Should the agent apply this automatically, or should I decide when to run it?”

### Creating a Skill

Skills live in three possible locations, from broadest to narrowest scope:

Scope | Location | Applies to  
---|---|---  
Personal | `~/.gemini/antigravity-cli/skills/<name>/SKILL.md` | All your projects  
Project | `.agents/skills/<name>/SKILL.md` | This project only  
Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin is enabled  
  
Every skill requires a `SKILL.md` file with YAML frontmatter:

```yaml
---
name: code-reviewer
description: Review code for security vulnerabilities, performance issues,
  and best practice violations. Use when examining code changes, reviewing
  PRs, analyzing code quality, or when asked to review, audit, or check code.
allowed-tools: read_file, grep_search, find_by_name
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
`description` | Yes | Discovery trigger (max 1024 chars). `agy` uses this to decide when to apply the skill  
`allowed-tools` | No | Restrict capabilities (e.g., `read_file, grep_search, find_by_name` for read-only)  
`disable-model-invocation` | No | Prevents auto-activation; skill only activates via `/skill-name`  
`user-invocable` | No | Set `false` to hide from the menu entirely  
`model` | No | Override which model to use when the skill is active  
`context` | No | Set to `fork` to run in isolated context window  
`hooks` | No | Define lifecycle hooks scoped to this skill  
`$ARGUMENTS` | No | String substitution: replaced with user’s input after `/skill-name`  
  
### The Description Field Is Everything

At session start, `agy` extracts every skill’s `name` and `description` and injects them into the context. When you send a message, the model uses language understanding to select relevant skills.

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

The effective description includes what it does, when to use it, and natural trigger phrases.

### Context Budget

All skill descriptions share a context budget that scales dynamically at 1% of the context window, with a fallback of 8,000 characters. Keep each description concise and put the key use case first. Run `/skills` during a session to check active skills.

### Supporting Files and Organization

Skills can reference additional files in the same directory:

```
~/.gemini/antigravity-cli/skills/code-reviewer/
├── SKILL.md                    # Required: frontmatter + core expertise
├── SECURITY_PATTERNS.md        # Referenced: detailed vulnerability patterns
└── PERFORMANCE_CHECKLIST.md    # Referenced: optimization guidelines
``` 

Reference them from `SKILL.md` with relative links. Keep `SKILL.md` under 500 lines and move detailed reference material to supporting files.

### Sharing Skills via Git

Project skills (`.agents/skills/` in the repo root) are shared via version control:

```bash
mkdir -p .agents/skills/domain-expert
# ... write SKILL.md ...
git add .agents/skills/
git commit -m "feat: add domain-expert skill for payment processing rules"
git push
``` 

When teammates pull, they get the skill automatically.

### Skills Compose with Hooks

Skills can define their own hooks in frontmatter that activate only while the skill runs. This creates domain-specific behavior that does not pollute other sessions:

```yaml
---
name: deploy-checker
description: Verify deployment readiness. Use when preparing to deploy,
  release, or push to production.
hooks:
  PreToolUse:
    - matcher: run_command
      hooks:
        - type: command
          command: "bash -c 'INPUT=$(cat); CMD=$(echo \"$INPUT\" | jq -r \".toolCall.args.CommandLine // empty\"); if echo \"$CMD\" | grep -qE \"deploy|release|publish\"; then echo \"DEPLOYMENT COMMAND DETECTED. Running pre-flight checks.\" >&2; fi'"
---
``` 

### Plugin and Skill Convergence in `.agents/skills/`

Plugins placed in a project’s `.agents/skills/` directory load automatically without requiring a marketplace registration. Project-scoped tooling can be developed and versioned directly inside the repository.

### Hiding the Bundled Surface as Governance

Skills are capability, and capability is attack surface. The `disableBundledSkills` setting hides the bundled skills, workflows, and built-in slash commands from the model entirely. For a hardened or regulated harness, this is a deliberate attack-surface reduction.

* * *
