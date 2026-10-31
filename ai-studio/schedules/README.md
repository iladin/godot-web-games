# Scheduled tasks — kept in git

Every Claude scheduled task that works on this repo is defined here. Each one is two files:
- `<name>.json`: the settings (trigger id, name, cron, enabled, model, computer, folders, permission mode, notifications, and `synced_at`).
- `<name>.prompt.md`: the exact prompt each run starts with.

**Git is the source of truth.** Running tasks should match these files, and any difference is drift.

| File | Scheduled task | Schedule (UTC) | State |
|---|---|---|---|
| `game-factory` | Game Factory: hourly batch (Opus designs, Sonnet builds) | `59 * * * *` | on |
| `void-sovereign-studio` | Void Sovereign AI studio cycle | `55 * * * *` | off |

`python3 scripts/schedules.py show` prints this from the files.

## Keeping Claude and git in sync

1. **Changing a scheduled task** (in a Claude session or in the Claude app): update its files here in the same session, and commit with a subject starting `schedules: sync`. Set `synced_at` to the task's `updated_at` *after* the change; `list_triggers` shows it.
2. **Editing these files** (by hand or in a session): apply the change to the scheduled task in the same session, then make the `schedules: sync` commit.
   - `name`, `cron` and `enabled`: `update_trigger` changes them directly.
   - `prompt`: `update_trigger` with the full text of the prompt file (`python3 scripts/schedules.py prompt <name>`). On a computer-bound task, it only takes effect once Daniel approves it in a conversation linked to his computer. Until then it returns `needs_device_approval`; record that under **Pending** below.
   - `model` and `folders` on a computer-bound task: only Daniel can change them, in the Claude desktop app (scheduled task settings). Ask him, and add the request to **Pending**.
   - Creating, deleting, or "run now": permission checks may block these. Ask Daniel. Never delete and recreate a computer-bound task to change it; that loses its run history and its computer.
3. **Checking for drift** (whenever a session works on schedules):
   - Call `list_triggers`, save its JSON to `.tools/live_schedules.json`, and run `python3 scripts/schedules.py diff .tools/live_schedules.json`.
   - The script says which way each difference should go:
     - changed in Claude since the last sync → copy the live values into git (Daniel's app edits win);
     - changed in git → apply them to the scheduled task;
     - both → ask Daniel.
   - `UNTRACKED` means a live scheduled task with no files here. Add its files.
4. **Every scheduled run** checks itself at the start: it compares the prompt it was started with to its `<name>.prompt.md`. If they differ, it writes `DRIFT: prompt` into its log and its final message, then carries on. It doesn't try to fix the drift.

## Pending
Changes that git already describes but the live scheduled task doesn't have yet. Remove each line once it's applied.
(nothing pending)
