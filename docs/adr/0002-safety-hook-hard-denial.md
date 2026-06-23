# 2. Safety Hook Hard Denial

We decided to keep the safety hook outputting `deny` (hard block) rather than `force_ask` for all blocked operations (including both guardrail modifications and destructive commands). This enforces a strict security boundary where the agent is physically unable to execute dangerous tools directly. If the user wants to execute a blocked command or modify safety rules, the agent will instead generate and present the necessary code/command for the user to run manually in their own terminal.

Key design decisions:
- **Zero Self-Modification Policy**: The hook denies any agent-initiated attempt to modify `hooks.json` or scripts under `.agents/hooks/`. Modifying the security controls can only be done manually by the user.
- **Explicit Copy-Paste for Destructive Commands**: Common developer commands like `git reset --hard` or `git clean -f` are intercepted and blocked by the safety hook. The agent will instruct the user to run the exact command themselves to verify intent and avoid click-through approval errors.
- **No force_ask for Safety Hooks**: We avoid using the `force_ask` gating decision for these cases to completely eliminate the risk of user confirmation complacency or social-engineering vectors where the agent convinces the user to allow a destructive call.
