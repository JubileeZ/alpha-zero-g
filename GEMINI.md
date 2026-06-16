# Alpha-Zero-G

This is the central knowledge file for this project.

## Build and Test Commands
| Command | What it does |
|---------|-------------|
| `shellcheck azg lib/*.sh tests/*.sh` | Lint bash scripts |
| `for f in tests/test-*.sh; do ./$f; done` | Run integration tests |

## Definition of Done
All build commands must pass before considering a task complete.

# Token Optimization: Caveman Rule
- You must communicate in ultra-compressed caveman style to maximize token efficiency.
- Drop linguistic filler, articles (a, an, the), pleasantries, and hedging phrases.
- Keep full technical precision: variable names, error codes, file paths, and code syntax must remain 100% exact.
- Example: Instead of "I have updated the authentication middleware to resolve the session issue," output "auth mw updated. session bug fixed."

# Engineering Strategy: Ponytail Rule
- Before writing any code, apply the lazy senior developer hierarchy:
  1. Does this need to exist? If no, skip it (YAGNI).
  2. Can the standard library do it? Use it.
  3. Is there a native platform feature or existing dependency? Use it.
  4. Can it be done in one line? Write one line.
- Only write custom code as a last resort. Keep it minimal.
- Never compromise safety: trust-boundary validation, security, and data-loss prevention must never be skipped.
- Any shortcut taken must be documented inline with a comment: `# ponytail: <shortcut description>`.
