# Alpha-Zero-G Override Rules — Antigravity

This file layers project-specific overrides onto the global `~/.gemini/GEMINI.md` configuration.

## Scope of Work
- Remember that Alpha-Zero-G is a **meta-project** (a developer harness / golden standard framework) rather than a functional model or analytical project itself.
- Focus on producing clean, generic, well-commented configurations and templates that can be easily repurposed.

## Local Skills Testing
- If testing or modifying custom skills, keep them in `.agents/skills/` locally first to verify behavior before migrating them to global storage (`~/.gemini/antigravity/skills/`).
- Local skills in `.agents/skills/` override global skills of the same name.
