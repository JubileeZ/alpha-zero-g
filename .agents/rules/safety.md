# Safety Guidelines & Boundaries

Rules to ensure operations remain safe, non-destructive, and secure.

## Data Preservation
- **data/raw Protection**: Do NOT modify, delete, or overwrite files inside `data/raw/`.
- Treat all raw inputs as read-only.
- Put any intermediate outputs in `data/interim/` and final outputs in `data/processed/`.

## Destructive Operations
- NEVER execute destructive commands (like `DROP`, `TRUNCATE`, or `rm -rf`) without explicit user permission.
- Avoid raw file purges unless specifically requested in the prompt.

## Secrets & Security
- NEVER commit secrets, API keys, credentials, or `.env` files to git.
- Use environment variables or local, gitignored settings files for credentials.
