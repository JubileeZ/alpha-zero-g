# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues. Prefer the `gh` CLI.

## Auth (agents — try in order)

1. **`gh` already authenticated** — `gh auth status` succeeds → use `gh` as usual.
2. **`gh` missing** — install portable or system GitHub CLI; do **not** block the user on winget UAC if a portable zip works.
3. **`gh` present but not logged in** — pull a token from **git’s credential store**, then run with `GH_TOKEN` (never print/log the secret):

   ```bash
   # Git Bash / agents: fill host github.com credentials
   printf 'protocol=https\nhost=github.com\n\n' | git credential fill
   # Use password= value as GH_TOKEN for this process only
   GH_TOKEN='…' gh issue list
   ```

   PowerShell equivalent: pipe `protocol=https` / `host=github.com` into `git credential fill`, set `$env:GH_TOKEN` from `password=`, call `gh`.
4. **No token in git credentials** — **ask the user** for a PAT (or run `gh auth login`). Do not invent workarounds that expose secrets into the repo.

Never commit tokens. Never echo `password=` / `GH_TOKEN` into chat, logs, or files.

## Conventions

- **Create**: `gh issue create --title "..." --body "..."` (heredoc for multi-line bodies).
- **Read**: `gh issue view <number> --comments`
- **List**: `gh issue list --state open`
- **Comment**: `gh issue comment <number> --body "..."`
- **Labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --reason "not planned|completed|duplicate" --comment "..."`

Infer repo from `git remote` when inside a clone.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.
