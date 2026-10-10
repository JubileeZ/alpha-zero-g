# Project Skills Safety Boundary and Script Exemption

Harness safety hook (`block-destructive-ops.sh`) previously restricted agent file writes under `.agents/` strictly to `.agents/work-packets/*.md` and `.agents/handoff-pointer`, blocking agents from creating or maintaining project-local skills under `.agents/skills/` and project rules under `.cursor/rules/`. Furthermore, regex matching on `\.agents` inadvertently blocked operations on template scaffolds under `templates/project/.agents/` within the Alpha-Zero-G repository.

We refine the **Zero Self-Modification Policy** boundary:
1. **Project Skills Whitelist**: File-writing tools and granular shell operations may create and modify project-local skills under `.agents/skills/**` (including `SKILL.md`, assets, and skill scripts) and project rules under `.cursor/rules/**`.
2. **Skill Script Execution**: Agents are permitted to execute helper scripts located inside `.agents/skills/` via interpreters (`bash`, `python`, `node`), while execution of scripts out of `.agents/work-packets/` remains strictly forbidden.
3. **Template Scaffolding Immunity**: Path matching in the safety hook is anchored to the repository root active `.agents/` directory, preventing false-positive denials when editing template fixtures under `templates/project/.agents/`.
4. **Protected Boundary Invariant**: Direct modifications to hook configurations or scripts (`.agents/hooks/`, `hooks.json`, `.cursor/hooks/`, `.cursor/hooks.json`), the base work packet template (`.agents/work-packet.md.tmpl`), permissions tampering (`chmod`), and recursive root deletion (`rm -r .agents`) remain hard-denied.

**Status:** accepted 2026-10-10

**Consequences:** `block-destructive-ops.sh` allows `.agents/skills/**` and `.cursor/rules/**` while preserving hard denial on safety hooks and configurations; `AGENTS.md` clarifies that code files remain forbidden in `work-packets/` while permitted in `skills/`; `commit-scan.sh` classifies skill modifications as code requiring a staged Work Packet.

**Amends:** ADR 0002 (Zero Self-Modification scope clarified), ADR 0023 (Work Packet safety boundary expanded to project skills).
