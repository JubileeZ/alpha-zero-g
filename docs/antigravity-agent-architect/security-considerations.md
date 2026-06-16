## Security Considerations

### Principles of Trustworthy Agents

Google and OpenAI publish guidelines for agent trustworthiness. The principles map to evidence gates and deterministic hooks:

Principle | What it means | How this harness satisfies it  
---|---|---  
**Human control** | Meaningful human override at every decision point | Hooks gate tool calls; PreCompact blocking; Auto Mode classifier as check-layer  
**Value alignment** | Agent actions track user intent, not adjacent goals | `GEMINI.md` as explicit intent specification; skills as capability scoping  
**Security** | Resistance to adversarial inputs and prompt injection | Sandbox + deny-rules + input validation at the hook layer  
**Transparency** | Auditable records of decisions and actions | Hook logging; session transcripts; skill-invocation traces  
**Privacy** | Appropriate data handling and governance | Credential env-var scrubbing; secret detection at hook layer  
  
The Model Context Protocol (MCP) is hosted under the Linux Foundation’s Agentic AI Foundation, alongside AGENTS.md. Agent interoperability standards are vendor-neutral.

> **Skill sandbox tooling:** For teams that treat skills as an attack surface, Permiso’s **SandyClaw** runs skills in a dedicated sandbox and delivers evidence-backed verdicts from Sigma/YARA/Nova/Snort detection.

### The Sandbox

Antigravity CLI supports sandbox modes that restrict network access and filesystem operations using OS-level isolation (seatbelt on macOS, bubblewrap on Linux). When enabled, the sandbox prevents the model from making arbitrary network requests or accessing files outside the project directory. Without sandboxing, the agent runtime uses a permission-based model where you approve or deny individual tool calls.

**Sandbox security floor.** Keep shell rules narrow. Broad shell write exceptions are orchestration shortcuts, not safety boundaries.

**OpenAI Agents SDK sandbox lockdown.** On the OpenAI side, `openai-agents-python` constrains `LocalFile.src` and `LocalDir.src` to within the materialization `base_dir` unless the source is explicitly granted via `Manifest.extra_path_grants` with `SandboxPathGrant`.

### Permission Boundaries

The permission system gates operations at multiple levels:

Level | Controls | Example  
---|---|---  
**Tool permissions** | Which tools can be used | Restrict subagent to `read_file, grep_search, find_by_name`  
**File permissions** | Which files can be modified | Block writes to `.env`, `credentials.json`  
**Command permissions** | Which shell commands can run | Block `rm -rf`, `git push --force`  
**Network permissions** | Which domains can be accessed | Allowlist for MCP server connections  
  
### Prompt Injection Defense

Skills and hooks provide defense-in-depth against prompt injection:

**Skills with tool restrictions** prevent a compromised prompt from gaining write access:

```yaml
allowed-tools: read_file, grep_search, find_by_name
``` 

**PreToolUse hooks** validate every tool call regardless of how the model was prompted:

```bash
# Block credential file access regardless of prompt
if echo "$FILE_PATH" | grep -qE "\.(env|pem|key|credentials)$"; then
    echo '{"decision":"deny", "reason":"Sensitive file access blocked"}'
    exit 0
fi
``` 

**Subagent isolation** limits blast radius. A subagent with read-only tool permissions cannot make modifications even if its prompt is compromised.

### Agent Logs and Guardrails Are Security Surfaces

Agent infrastructure creates new places for sensitive content and executable policy to leak or escape. Treat agent transcripts, tool payloads, logs, and guardrail execution as sensitive infrastructure. Redact before persistence, apply retention limits, and keep custom guardrail code sandboxed and reviewable. A prompt-level “do not log secrets” rule is not enough; the logging and guardrail path needs deterministic tests.

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

Hooks fire for subagent actions too. If the lead agent spawns a subagent, your PreToolUse and PostToolUse hooks execute for every tool the subagent uses. Without recursive hook enforcement, a subagent could bypass your safety gates. The `SubagentStop` event lets you run cleanup or validation when a subagent completes.

### Cost as Architecture

Cost is an architectural decision, not an operational afterthought. Three levels:

*   **Token level:** System prompt compression. Remove tutorial code examples, collapse duplicate rules, and replace explanations with constraints.
*   **Agent level:** Fresh spawns over long conversations. Each story gets a new agent with a clean context. The context never balloons because each agent starts fresh.
*   **Architecture level:** CLI-first over MCP when the operation is stateless. A `agy --print` call for a one-shot evaluation costs less and adds no connection overhead.

* * *
