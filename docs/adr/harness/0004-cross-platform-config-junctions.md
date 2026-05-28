# ADR-0004: Cross-Platform Environment Seeding and Non-Privileged Symlinks

## Context

The Alpha-Zero-G developer harness is designed to synchronize configuration files (`settings.json`, `AGENTS.md`, `GEMINI.md`, and custom skills) across multiple developer devices using Google Drive as a shared mount point. 

When establishing this on a Windows desktop environment, several platform-specific barriers were encountered:
1. Virtual environments (`.venv`) synchronized via Google Drive carry OS-specific binary layouts, paths, and interpreter signatures (e.g. macOS paths or Mach-O executable formats) which break Python execution on Windows.
2. Standard Unix symbolic linking (`ln -s`) inside Git Bash / MINGW environments fails or is rejected on Windows when target locations are directories unless Windows Developer Mode is enabled or the terminal has administrative/elevated privileges.
3. Local model context configurations, such as enabling AI billing credits (`useAiCredits` or "g1 credits"), are stored inside the `~/.gemini/config/` directory. If the shared mount lacks a source-of-truth configuration, the local symlinks break, rendering essential settings inaccessible.

## Decision

* **Status:** `accepted`
* **Date:** 2026-05-28

We will implement native cross-platform resilience within the core bootstrapping and global synchronization scripts:

1. **Dynamic Virtual Environment Recovery (`init.sh`)**: The bootstrapper will inspect the local Python interpreter inside `.venv`. If it is missing, invalid, or OS-mismatched, the script will automatically purge the invalid `.venv` and rebuild a pristine local environment. Activation will dynamically resolve to `.venv/Scripts/activate` (Windows) or `.venv/bin/activate` (Unix).
2. **Directory Junction Fallback (`setup-global-harness.sh`)**: In MINGW/MSYS shell environments, we will convert UNIX paths using `cygpath -w` and invoke native Windows linking (`cmd.exe /c mklink`). For directory links, the script will default to directory junctions (`mklink /j`), which do not require administrative privileges or Windows Developer Mode.
3. **Automated Configuration Folder Seeding (`setup-global-harness.sh`)**: The synchronization script will automatically manage the `~/.gemini/config/` directory, backing up local settings, creating the shared folder on Google Drive, and seeding it with a standard `config.json` (AI credits enabled) and `mcp_config.json` baseline to avoid broken symlinks.

## Consequences

* **Positive:**
  * Delivers a seamless, one-command setup on standard, non-elevated Windows environments.
  * Ensures critical configurations (like billing credits, model preferences, and active MCP servers) are automatically synchronized across all devices in real-time.
  * Eradicates environment corruption errors caused by cross-device Google Drive folder sync.
* **Negative:**
  * Introduces minor environment detection logic (`uname -s`) and path conversions (`cygpath`) into scripts.
