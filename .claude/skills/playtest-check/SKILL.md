---
name: playtest-check
description: Verify a Godot game in this repo runs without a human — parse check, headless smoke run, optional logic assertions, and export check. Use before declaring a game done, after any GDScript change, or when CI fails.
---

# Playtest check

## The gate
```bash
./scripts/check.sh <slug>
```
What it does:
1. `godot --headless --import` — imports resources; parse errors in any script show up here.
2. `godot --headless --fixed-fps 60 --quit-after 300` — runs the main scene for 300 frames at a fixed 60 fps (5 s of game time) with a dummy renderer and no input. Catches runtime errors in `_ready`/`_process`/`_draw` on the title screen.
3. If `scripts/selftest.gd` exists in the game, runs it (`--script`) and requires it to print `SELFTEST OK`.
4. Fails if output contains `SCRIPT ERROR`, `Parse Error`, `Failed to load`, or `Invalid call`.

It prints `PASS` or `FAIL <reason>`.

## The smoke run only sees the title screen
Gameplay code isn't exercised unless something starts the game. Two ways:

**A. Autostart flag** — the template's `main.gd` reads a `--autoplay` user arg and jumps straight to PLAYING with a simple bot input. `check.sh` passes it on a second run, so keep that hook working when you modify the state machine:
```gdscript
if "--autoplay" in OS.get_cmdline_user_args():
	autoplay = true
	_start_game()
```

**B. Selftest script** — for pure logic (scoring, grid rules, match detection), put it in plain functions and assert on them:
```gdscript
# games/<slug>/scripts/selftest.gd
extends SceneTree

func _init() -> void:
	var Rules := preload("res://scripts/rules.gd")
	assert(Rules.score_for_match(3) == 100)
	assert(Rules.score_for_match(5) == 400)
	print("SELFTEST OK")
	quit()
```
`assert` only fires in debug builds — `--script` runs debug, so this works.

## Reading failures
- `Parse Error: Identifier "X" not declared` → typo or Godot 3 API. Check `godot-web-gdscript` traps table.
- `Invalid call. Nonexistent function` → wrong method name for this class in Godot 4.
- `Node not found` → `@onready` path wrong or node created after access; build nodes in `_ready` before use.
- `Cannot infer the type` → `:=` on a Variant (e.g. dictionary value); add an explicit type.

## Browser check (when a browser is available)
After `./scripts/export_all.sh && ./scripts/serve.sh`, open `http://localhost:8000/<slug>/`, check the devtools console for errors, click once, play 30 s, test with the window narrowed to phone width.

## Without Godot installed
Say it plainly. Run `bash -n scripts/*.sh`, re-read changed scripts against the traps table, and tell the user CI will run the same checks on push (the workflow fails the build if `check.sh` fails).
