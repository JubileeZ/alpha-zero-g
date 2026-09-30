# Work Packet Safety Boundary and PreToolUse Exemption

Harness safety hook (`block-destructive-ops.sh`) previously denied all file writes and modifications matching `\.agents`, creating a deadlock with ADR 0022's requirement that code commits stage a **Work Packet** under `.agents/work-packets/`. When denied, agents fell back to generating brittle multi-line Bash heredocs (`cat << 'EOF' > ...`) that break in user terminals.

We redefine the **Zero Self-Modification Policy** boundary:
1. **Work Packet Whitelist**: File writes and edits under `.agents/` are strictly restricted to `^(\.agents/work-packets/[a-zA-Z0-9_.-]+\.md|\.agents/handoff-pointer)$`. Safety gates, hooks (`.agents/hooks/`, `hooks.json`, `.cursor/hooks/`), and arbitrary files remain hard-denied.
2. **Code Sneak Prevention**: Non-markdown files (e.g. `.sh`, `.py`, `.js`, binaries) in `.agents/work-packets/` are blocked from creation, blocked from interpreter execution or `chmod`, classified as code by `commit-scan.sh`, and hard-rejected by `commit-gate.sh`.
3. **No Heredocs in Manual Fallback**: When hooks legitimately block an action, agents must never emit multi-line heredocs; they must output single-line copy-pasteable commands or write payloads to temporary scratch paths.
4. **Autonomous Commit and Push**: When explicitly prompted by the user ("update progress and commit push"), agents autonomously update tracking docs, stage Work Packets, pass `tests/verify.sh`, commit, and push.

**Status:** accepted 2026-10-01

**Consequences:** `block-destructive-ops.sh` allows `.agents/work-packets/*.md` and `.agents/handoff-pointer` while keeping hooks protected; `commit-scan.sh` classifies only `*.md` as packets; `commit-gate.sh` denies non-markdown files in `work-packets/`; `AGENTS.md` instructs autonomous push and prohibits heredocs.

**Amends:** ADR 0002 (Zero Self-Modification scope clarified), ADR 0022 (Work Packet staging unblocked).
