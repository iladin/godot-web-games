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
