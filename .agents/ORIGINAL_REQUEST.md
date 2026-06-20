# Original User Request

## Initial Request — 2026-06-20T17:29:47Z

A reusable, token-efficient custom teamwork skill for daily development across projects, which orchestrates specialized subagents sequentially and relies on local programmatic verification to minimize LLM token overhead while ensuring high reliability.

Working directory: /Users/jubilee/Alpha-Zero-G
Integrity mode: development

## Reference Material

- **Writing Great Skills**: Design the `SKILL.md` using the predictability-focused rules in `writing-great-skills` (e.g. using leading words, avoiding duplication, progressive disclosure, and pruning no-ops).

## Requirements

### R1. Core Skill Structure
Create a custom skill under `/Users/jubilee/Alpha-Zero-G/templates/global/skills/lightweight-teamwork/` featuring a `SKILL.md` file. It must define YAML metadata and instructions for a structured development loop.

### R2. Sequential Orchestration Protocol
The instructions must guide the agent to perform tasks sequentially through clear phases (Planning -> Implementing -> Verifying) by spawning separate, short-lived subagents one-by-one rather than all in parallel.

### R3. Test-Driven Verification
Integrate local shell test runners so verification is programmatic and driven by local command execution, avoiding token-heavy peer-auditing or self-certification.

### R4. Model/Cost Constraint
Explicitly prompt or configure subagents to use cheaper/faster models (like Gemini 3.5 Flash) by default.

## Verification Mechanisms

- **Programmatic Validation**: A Python script `tests/verify_lightweight_teamwork.py` that validates:
  - The existence and YAML structure of `templates/global/skills/lightweight-teamwork/SKILL.md`.
  - The presence of core keywords (`sequential`, `Flash`, `verify`, `context`, `command`) in the skill file.
  - The active session's `transcript.jsonl` (parsed from the conversation log directory) to confirm that any `invoke_subagent` calls were preceded by a `/model gemini-3.5-flash` command or contained the model-constraint text inside the prompt parameter.
- **Agent-as-Judge Validation**: An independent auditing subagent runs against a checklist to verify the quality and clarity of the sequential workflow instructions in `SKILL.md`.

## Acceptance Criteria

### AC1. Skill File Layout
- [ ] File `templates/global/skills/lightweight-teamwork/SKILL.md` exists and contains valid YAML frontmatter (`name: lightweight-teamwork` and a non-empty `description`).

### AC2. Verification Script Execution
- [ ] Script `tests/verify_lightweight_teamwork.py` exists, runs successfully (exit status 0), and validates the keywords and YAML formatting.

### AC3. Real spawn validation via Transcript Logs
- [ ] The programmatic verification script uses the current conversation log (`transcript.jsonl`) to assert that any subagent invocations were intentionally run with the model constraint, checking that `/model gemini-3.5-flash` or explicit prompt parameters were passed.

### AC4. Orchestration Rules compliance
- [ ] `SKILL.md` instructs the agent to work sequentially (Planning -> Implementing -> Verifying) using separate `invoke_subagent` calls, and explicitly forbids parallel subagent runs to save token budget.
- [ ] `SKILL.md` instructions dictate that subagents must log the exact test command and test output to prevent self-certification.
