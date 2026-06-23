# Alpha-Zero-G

The system configuration and runtime harness for building production AI agent environments.

## Language

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

