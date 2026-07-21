# Alpha-Zero-G

The system configuration and runtime harness for building production AI agent environments.

## Language

**Reliable Delivery**:
Completion of a user-requested task that passes explicit acceptance gates and achieves higher task success per cost than an equivalent no-harness run.
_Avoid_: Guaranteed output, good result

**Task Success**:
Delivery where all hard project gates and hidden task assertions pass, and a blind rubric judge meets the defined quality threshold.
_Avoid_: Done, completed run

**No-Harness Baseline**:
Paired evaluation run using same task, repository state, model, IDE, permissions, and budget as harness run, with only Alpha-Zero-G configuration removed.
_Avoid_: Historical baseline, default setup

**Delivery Cost**:
Native model usage or spend consumed by a task run. Wall time and human interventions are separate reported measures, not blended into this value.
_Avoid_: Composite efficiency score, elapsed time

**Long-Horizon Task**:
Task completed across forced fresh-context sessions, including a clean-device clone and a Cursor–Antigravity handoff before acceptance.
_Avoid_: Long chat, large task

**Minimal Setup**:
One device command and one project command, with at most one required confirmation of project validation command.
_Avoid_: Zero configuration, setup wizard

**Work Packet**:
Canonical Git-synced state for one active task: objective, acceptance criteria, status, files, decisions, blockers, and next action.
_Avoid_: Handoff file, task list

**Checkpoint**:
Git commit pairing in-progress work with a fresh Work Packet so another session can resume from one durable state.
_Avoid_: Autosave, IDE Stop

**Device Handoff**:
Pushed Checkpoint fetched on another device to resume same Work Packet from identical repository state.
_Avoid_: Chat transfer, synchronized folder

**Blind Judge**:
Fixed independent model scoring delivered output against task rubric without knowing treatment, periodically calibrated against human ratings.
_Avoid_: Self-review, Fable Judge

**Evaluation Suite**:
Two-tier task set combining deterministic harness contract cases with realistic hidden-assertion and blind-rubric delivery tasks.
_Avoid_: SWE-bench score, trap tests

**Statusline**:
The terminal status bar displayed at the bottom of the Antigravity TUI to show real-time agent execution state and resource usage.
_Avoid_: Status bar, info bar

**Context Rot**:
The degradation of agent instruction-following accuracy and reasoning capabilities that occurs as the active token count approaches model context limits.
_Avoid_: Context bloating, context overflow

**Context Rot Level**:
The classification of the current context window usage severity (Safe, Caution, Degrading, or Critical) calculated dynamically based on active token counts and capacity percentages.
_Avoid_: Warning level, rot severity

**Prompt Credits**:
The user's remaining billing balance for executing model calls, tracked as a currency or token pool.
_Avoid_: Account balance, model credits

**Sprint Quota**:
A short-term rolling rate-limit window that cooldowns every five hours.
_Avoid_: Cooldown quota, hourly limit

**Statusline Preset**:
The visual rendering style of the statusline (Nerd Font, Unicode, or ASCII) selected dynamically or via user settings to match font capabilities.
_Avoid_: Status bar theme, icon mode.

**Safety Hook**:
An interceptor script run automatically before any agent tool call to validate command patterns and file targets, preventing unauthorized alterations or system damage.
_Avoid_: Guardrail, safety command, block policy.

