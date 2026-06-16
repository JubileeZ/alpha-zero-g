## Security Considerations

### The Five Principles of Trustworthy Agents (Anthropic, April 2026)

Anthropic published a formal framework for agent trustworthiness on April 9, 2026. The five principles parallel — and extend — the Evidence Gate thinking in this guide:

Principle | What it means | How this harness satisfies it  
---|---|---  
**Human control** | Meaningful human override at every decision point | Hooks gate tool calls; PreCompact blocking; Auto Mode classifier as check-layer  
**Value alignment** | Agent actions track user intent, not adjacent goals | CLAUDE.md as explicit intent specification; skills as capability scoping  
**Security** | Resistance to adversarial inputs and prompt injection | Sandbox + deny-rules + input validation at the hook layer  
**Transparency** | Auditable records of decisions and actions | Hook logging; session transcripts; skill-invocation traces  
**Privacy** | Appropriate data handling and governance | Credential env-var scrubbing; secret detection at hook layer  
  
Anthropic also donated MCP to the Linux Foundation’s Agentic AI Foundation, joining AGENTS.md (now jointly stewarded with OpenAI, Google, Cursor, Factory, Sourcegraph). Agent interoperability standards are now vendor-neutral.

> **Skill sandbox tooling:** For teams that treat skills as an attack surface, Permiso’s **SandyClaw** (launched April 2, 2026) runs skills in a dedicated sandbox and delivers evidence-backed verdicts from Sigma/YARA/Nova/Snort detection. First product in the skill-sandbox category.

### The Sandbox

Claude Code supports an optional sandbox mode (enabled via `settings.json` or the `/sandbox` command) that restricts network access and filesystem operations using OS-level isolation (seatbelt on macOS, bubblewrap on Linux). When enabled, the sandbox prevents the model from making arbitrary network requests or accessing files outside the project directory. Without sandboxing, Claude Code uses a permission-based model where you approve or deny individual tool calls.

**May 2026 security floor.** Claude Code v2.1.149 fixed a PowerShell working-directory permission bypass, several PowerShell allow-rule and stale-variable permission-analysis gaps, and a git-worktree sandbox write-allowlist bug that covered the full main repository root instead of only shared git internals. If your harness allows PowerShell or worktree-isolated agents, treat v2.1.149+ as the floor and keep shell rules narrow. Broad `PowerShell(*)` and all-repo write exceptions are orchestration shortcuts, not safety boundaries.

**OpenAI Agents SDK sandbox lockdown (v0.17.0, May 8, 2026).** On the OpenAI side, `openai-agents-python` v0.17.0 tightened a parallel boundary: `LocalFile.src` and `LocalDir.src` are now constrained to within the materialization `base_dir` (the SDK process current working directory when the manifest is applied), unless the source is explicitly granted via `Manifest.extra_path_grants` with `SandboxPathGrant`. Relative local sources resolve from `base_dir`; absolute paths must already sit inside it or carry a grant. This closes a local artifact boundary issue: prior versions allowed manifests to pull arbitrary host paths into a sandbox workspace. Migration: declare trusted host roots at the manifest level with `SandboxPathGrant(path=..., read_only=True)` for read-only mounts. Treat `extra_path_grants` as trusted application configuration; never populate grants from model output or untrusted manifest input.

**OpenAI Agents SDK follow-up floor (v0.17.3).** The 0.17.1-0.17.3 line added more sandbox and session hardening: archive extraction limits, GitRepo subpath validation, clearer sandbox-provider errors, mountpoint credentials kept out of sandbox commands, rejection of relative sandbox workspace roots, and Vercel-sandbox terminal-state handling. If you are using OpenAI-hosted or provider-backed sandboxes rather than only Claude Code hooks, treat 0.17.3 as the current floor for the patterns in this section.

### Permission Boundaries

The permission system gates operations at multiple levels:

Level | Controls | Example  
---|---|---  
**Tool permissions** | Which tools can be used | Restrict subagent to Read, Grep, Glob  
**File permissions** | Which files can be modified | Block writes to `.env`, `credentials.json`  
**Command permissions** | Which bash commands can run | Block `rm -rf`, `git push --force`  
**Network permissions** | Which domains can be accessed | Allowlist for MCP server connections  
  
### Prompt Injection Defense

Skills and hooks provide defense-in-depth against prompt injection:

**Skills with tool restrictions** prevent a compromised prompt from gaining write access:

```
allowed-tools: Read, Grep, Glob
``` 

**PreToolUse hooks** validate every tool call regardless of how the model was prompted:

```
# Block credential file access regardless of prompt
if echo "$FILE_PATH" | grep -qE "\.(env|pem|key|credentials)$"; then
    echo "BLOCKED: Sensitive file access" >&2
    exit 2
fi
``` 

**Subagent isolation** limits blast radius. A subagent with `permissionMode: plan` cannot make changes even if its prompt is compromised.

### Agent Logs and Guardrails Are Security Surfaces

Two May 2026 advisories reinforce a pattern: agent infrastructure creates new places for sensitive content and executable policy to leak or escape. GitHub Advisory GHSA-f3jg-756w-gm35 covers a Gryph Agents payload-filter issue where sensitive tool-payload content could remain in local SQLite logs under default logging behavior. OSV GHSA-wxxx-gvqv-xp7p covers a LiteLLM custom-code guardrail sandbox escape in an admin-protected proxy endpoint.

The production rule: treat agent transcripts, tool payloads, SQLite logs, and guardrail execution as sensitive infrastructure. Redact before persistence, apply retention limits, and keep custom guardrail code sandboxed and reviewable. A prompt-level “do not log secrets” rule is not enough; the logging and guardrail path needs deterministic tests.

### Hook Security

HTTP hooks that interpolate environment variables into headers require an explicit `allowedEnvVars` list to prevent arbitrary environment variable exfiltration:

```json
{
  "type": "http",
  "url": "https://api.example.com/notify",
  "headers": {
    "Authorization": "Bearer $MY_TOKEN"
  },
  "allowedEnvVars": ["MY_TOKEN"]
}
``` 

### The Human-Agent Division of Responsibility

Security in agent architectures requires a clear division between human and agent responsibilities:

Human Responsibility | Agent Responsibility  
---|---  
Problem definition | Pipeline execution  
Confidence thresholds | Execution within thresholds  
Consensus requirements | Consensus computation  
Quality gate criteria | Quality gate enforcement  
Error analysis | Error detection  
Architecture decisions | Architecture options  
Domain context injection | Documentation generation  
  
The pattern: humans own decisions that require organizational context, ethical judgment, or strategic direction. Agents own decisions that require computational search across large possibility spaces. Hooks enforce the boundary.

### Recursive Hook Enforcement

Hooks fire for subagent actions too. If Claude spawns a subagent via the Agent tool, your PreToolUse and PostToolUse hooks execute for every tool the subagent uses. Without recursive hook enforcement, a subagent could bypass your safety gates. The `SubagentStop` event lets you run cleanup or validation when a subagent completes.

This is not optional. An agent that spawns a subagent without your security hooks is an agent that can force-push to main, read credential files, or run destructive commands while your gates watch the main conversation do nothing.

### Cost as Architecture

Cost is an architectural decision, not an operational afterthought. Three levels:

**Token level.** System prompt compression. Remove tutorial code examples (the model knows the APIs), collapse duplicate rules across files, and replace explanations with constraints. “Reject tool calls matching sensitive paths” does the same work as a 15-line explanation of why credentials should not be read.

**Agent level.** Fresh spawns over long conversations. Each story in an autonomous run gets a new agent with a clean context. The context never balloons because each agent starts fresh. Briefing instead of memory: models execute a clear briefing better than they navigate 30 steps of accumulated context.

**Architecture level.** CLI-first over MCP when the operation is stateless. A `claude --print` call for a one-shot evaluation costs less and adds no connection overhead. MCP makes sense when the tool needs persistent state or streaming.

* * *
