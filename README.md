# Alpha-Zero-G (v3.0.0)

The complete system for building production AI agent harnesses for Antigravity CLI (`agy`). Skills, hooks, memory, subagents, multi-agent orchestration, and the patterns that make AI coding agents reliable infrastructure.

## Documentation

**[Agent Architecture Guide](docs/antigravity-agent-architecture.md)** — Start here. A complete guide to building programmable agent runtimes using JSON lifecycle hooks, dynamic subagents, and auto-activating skills.

## Installation

Install the global skill library, MCP configuration, and statusline script for Antigravity CLI. This provisions the `~/.gemini/antigravity-cli/` directory.

```bash
# Set up global configs, skills, and statusline
./azg setup
```

*(Note: Alpha-Zero-G does not install `agy` itself. Ensure you have the Antigravity CLI installed first.)*

### Global Statusline Syncing

During `azg setup`, a premium global statusline script is provisioned at `~/.gemini/antigravity-cli/statusline.sh` and automatically registered in your `settings.json`.

This shared statusline displays:
- **Active Model & Provider** (e.g., `Gemini 3.5 Flash`)
- **Agent Cycle State** (Idle `●`, Thinking `◈`, Working `⚙`, Waiting `⏸`)
- **Context Window Usage** (color-coded percentage)
- **Sprint/Weekly Quotas & API Reset Cooldown Countdown** (using `antigravity-usage`)
- **Remaining Account Credits**
- **VCS Info** (Git branch name and dirty status)

## Usage

### 1. New Projects (`azg new`)

Scaffold a completely new project with the agent harness, templates, and hooks pre-configured.

```bash
./azg new my-project-name
```

This interactive wizard will ask you for:
- Your technology stack
- Custom build commands (lint, test, format)
- Optional hooks to enable (e.g., quality-gate, auto-lint)
- MCP server configurations

### 2. Retrofitting Projects (`azg apply`)

Add the agent harness to an **existing** repository.

```bash
cd my-existing-project
/path/to/Alpha-Zero-G/azg apply .
```

This will safely inject `.agents/`, create or merge `GEMINI.md` and `AGENTS.md`, and install the hook pipeline without overwriting your existing work.

## Updating

Keep your Alpha-Zero-G setup and vendored skills up to date:

```bash
# Pull latest Alpha-Zero-G updates
./azg update

# Sync the latest vendored skills
./azg update --vendor

# Apply updates globally
./azg setup
```

## Uninstalling

Remove all globally managed files from `~/.gemini/antigravity-cli/`. (Note: this does not affect project-level `.agents/` directories).

```bash
./azg uninstall
```
