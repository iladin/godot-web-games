# Agent instructions — Godot Web Games

This repo holds many small Godot 4 games, each exported to HTML5 and published as a static site. Your job is usually: take a pitch, produce a fun, finished, browser-playable game, and prove it runs.

## Repo map
- `template/` — starting skeleton. Never edit it while building a specific game; copy it with `scripts/new_game.sh`.
- `games/<slug>/` — one Godot project per game. Everything for that game lives here.
  - `project.godot`, `export_presets.cfg` (preset name must stay `Web`)
  - `scenes/`, `scripts/`, `assets/`
  - `game.json` — gallery metadata (title, tagline, controls, accent color)
  - `DESIGN.md` — one-page design doc you write before coding
- `scripts/` — tooling. `check.sh <slug>` is the gate; run it before saying you're done.
- `.claude/skills/` — load the relevant skill before starting:
  - `new-game` — full pitch → shipped game workflow (start here)
  - `godot-web-gdscript` — GDScript 4 conventions and web-export constraints
  - `game-feel` — juice/polish checklist
  - `playtest-check` — how to verify without a human
  - `export-and-deploy` — exporting, local serving, hosting options

## Hard rules
1. **Godot 4.x, GDScript, static typing.** `var speed: float = 300.0`, typed function signatures, `@onready`, `@export`. No Godot 3 APIs (`yield`, `KinematicBody2D`, `instance()`, `rand_range`).
2. **Compatibility renderer only.** `rendering_method="gl_compatibility"`. Forward+/Mobile don't run on the web.
3. **No threads.** Keep `variant/thread_support=false`. Don't use `Thread`, `WorkerThreadPool`, or `OS.delay_*` busy loops.
4. **Every game must work with keyboard AND touch/mouse.** Phones are half the audience. Use the built-in `ui_*` actions or add actions in code (`InputMap.add_action`) — don't hand-edit `[input]` in project.godot.
5. **Assets: generate or draw, don't download.** Prefer `_draw()`, `Polygon2D`, shaders, and `ThemeDB.fallback_font`. If you add files, they must be original or CC0 and recorded in `games/<slug>/CREDITS.md`.
6. **Small payload.** Target < 10 MB exported. No 4K textures, no uncompressed WAV music.
7. **Persistence = `user://`** (maps to IndexedDB on web). Use `ConfigFile`. Never assume a real filesystem.
8. **Audio starts only after first user input** (browser autoplay policy). Gate music on the first click/key.
9. **Pause on focus loss** (`NOTIFICATION_APPLICATION_FOCUS_OUT`).
10. **A game is finished when** it has: title screen → play → game over/win → restart, a score or goal, difficulty that ramps, and passes `scripts/check.sh <slug>`.

## Commands
```bash
./scripts/new_game.sh <slug> "<Title>"   # scaffold from template
./scripts/check.sh <slug>                # parse + 5s headless smoke run; must print PASS
./scripts/export_all.sh                  # export every game to build/
python3 scripts/build_site.py            # gallery -> build/index.html
./scripts/serve.sh                       # serve build/ on :8000
./scripts/zip_for_itch.sh <slug>         # dist/<slug>-web.zip for itch.io
```
`GODOT` env var overrides the binary (default: `godot` on PATH). On macOS: `GODOT=/Applications/Godot.app/Contents/MacOS/Godot`.

If Godot isn't available in your environment, say so plainly, still run `bash -n` on scripts, and tell the user CI will run the checks on push. Never claim a check passed that you didn't run.

## Style
- One script per responsibility; keep `main.gd` under ~300 lines, split into nodes/scripts beyond that.
- Constants at the top in SCREAMING_CASE for every tunable (speeds, spawn rates, colors) so the user can tweak feel quickly.
- Signals over node-path reaching. `get_node("../../X")` is a smell.
- Commit message per game: `Add <Title>` / `<Title>: <change>`.

## AI studio (autonomous development loop)
Games can be developed by a role-based AI studio — strategy in `docs/AI_STUDIO.md`, procedure in `ai-studio/studio-cycle.md`, roles in `ai-studio/roles/` (game-developer, qa-tester, game-critic, balance-analyst, feature-scout). Its scheduled task for `void-sovereign` is currently off (`ai-studio/schedules/void-sovereign-studio.json`).

Studio state per game lives in `games/<slug>/HANDOVER.md` and `games/<slug>/studio/` (BACKLOG, INBOX, LOG, state.json, metrics.csv, reviews/). The `studio/` folder has a `.gdignore`, so Godot never imports or exports it.

**HANDOVER rule — applies to every session that touches a game with a `HANDOVER.md`, scheduled or manual:**
1. Read `games/<slug>/HANDOVER.md` before doing anything else; its "Next session should" list is the default plan.
2. Before ending the session — including failed, aborted or partial sessions — rewrite `HANDOVER.md` with the template in the studio-cycle skill: what you did, the state of the build, uncommitted/in-flight work, and an ordered, concrete "Next session should" list for whoever comes next.
3. If you're running out of time or context, write the handover first, then stop.

Studio tooling: `scripts/studio/ensure_godot.sh` (find/install Godot into gitignored `.tools/`), `backlog.py`, `shots.sh`, `balance.sh`, `snapshot.sh`.

## Game Factory (hourly new games)
A scheduled session runs `ai-studio/game-factory.md` every hour: an Opus designer subagent writes design docs for `batch_size` new games, Sonnet builder subagents implement them in parallel, and the orchestrator re-runs `check.sh`, commits each passing game to `main` and tries to push. The sandbox has no GitHub credentials, so pushing is done by `scripts/push_loop.sh` running in Daniel's WSL. Settings, the lock and the pause flag are in `ai-studio/factory/state.json`; the pitch queue is `ai-studio/factory/IDEAS.md`; the run log is `ai-studio/factory/LOG.md`. Before building new games, each run does a quick GitHub-issue check (`scripts/factory_issues.py`). It acts only on in-scope game-development issues from the authors in `state.json` → `issues.authors`, records every issue it looks at in `ai-studio/factory/ISSUES.md`, and closes finished ones with `Closes #N` in the commit message (GitHub closes them when `main` is pushed).

## Scheduled tasks (kept in git)
Every Claude scheduled task for this repo is defined in `ai-studio/schedules/`: `<name>.json` holds the settings and `<name>.prompt.md` the exact prompt. Git is the source of truth. The full rules are in `ai-studio/schedules/README.md`; in short:
- If you create, change, pause or delete a scheduled task, update its files in the same session and commit with a subject starting `schedules: sync`. Set `synced_at` to the task's new `updated_at`.
- If you edit those files, apply the change to the scheduled task in the same session (`update_trigger`). Prompt changes on computer-bound tasks need Daniel's approval in a conversation linked to his computer. Model and folder changes are his to make in the Claude desktop app. List anything unapplied under **Pending** in the README.
- To check for drift, run `python3 scripts/schedules.py diff <saved list_triggers JSON>`.
- A scheduled run compares the prompt it started with to its `.prompt.md` file. If they differ, it reports `DRIFT: prompt` in its log and final message and carries on.
