# Contributing

Thanks for improving this project.

## Scope

- Keep onboarding simple and non-technical.
- Keep README claims aligned with actual agent behavior in `CLAUDE.md`, `run.sh`, `init_db.sql`, and `marketing.db`.
- Prefer small, focused pull requests.

## Local checks

Run before opening a PR:

```bash
bash -n run.sh
sqlite3 marketing.db ".schema" > /dev/null
```

## Pull request checklist

- Describe what changed and why.
- Include before/after screenshots or GIFs for README visual changes.
- Note any behavior changes in `CLAUDE.md`.
- Confirm setup, delivery, and output details in README are still accurate.
