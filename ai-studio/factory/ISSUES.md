# Game Factory — GitHub issues handled

One row per issue the factory has looked at. `scripts/factory_issues.py` skips issues listed here unless they've been updated since (an edit, a new comment, or a reopen).
Statuses:
- `done`: committed with `Closes #N`; GitHub closes the issue when `main` is pushed.
- `partial`: committed with `Refs #N`; the rest is still open.
- `declined`: out of scope, so nothing was done; Daniel closes or rewrites it.
- `ignored`: the author isn't in `state.json` → `issues.authors`.
- `forwarded`: sent to another workflow, such as the Void Sovereign studio INBOX.
- `failed`: tried, but it didn't pass `check.sh`.

| Issue | Status | Run | Issue updated_at | Commit / reason |
|---|---|---|---|---|
