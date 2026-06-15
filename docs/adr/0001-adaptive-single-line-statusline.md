# 1. Adaptive Single-Line Statusline

We decided to implement a single-line custom statusline that dynamically hides less critical segments (credits, VCS branch, and execution state) based on the terminal width, rather than using multi-line wrapping. This keeps the layout compact and compatible with the single-row status bar allocated by the Antigravity TUI.

Key design decisions:
- **Dual-Quota Display**: We show both Claude and Gemini remaining quotas inline with their respective reset cooldown timers (e.g. `Claude: 14% (4d 6h) │ Gemini: 90% (4h 50m)`) to allow monitoring both providers.
- **Context Rot Level Triggers**: The warnings for Context Rot are calculated using both absolute token count and percentage thresholds, choosing the higher severity level of the two.
- **Task-Based Thresholds**: We classify active models into Reasoning tasks (using 20K/35K/50K token thresholds) and Agentic/tool tasks (using 60K/90K/120K token thresholds) with a 40%/60%/75% percentage fallback.
- **Dynamic Truncation**: We automatically drop the credits, VCS branch, and execution state if the statusline length exceeds the terminal width.
- **Visual Presets (Nerd Font, Unicode, ASCII)**: We support three visual presets (`nerd-font`, `unicode`, and `ascii`) selected via settings or environment variables, falling back gracefully to ensure compatibility. `nerd-font` uses solid background blocks with Powerline triangles (``/``) and specialized icons, while the others use clean foreground-only layouts.
- **Dual-Aligned Left/Right Split**: We align execution and model info on the left, and quotas/VCS info on the right, dynamically padding the center to fill the exact terminal width.


