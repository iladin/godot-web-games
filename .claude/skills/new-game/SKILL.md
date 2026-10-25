---
name: new-game
description: Build a complete browser-playable Godot 4 game in this repo from a short pitch — scaffold, design doc, GDScript implementation, polish, checks. Use when the user asks to make, create or generate a new game, or invokes /new-game.
---

# New game: pitch → shipped

Input: a slug (kebab-case) and a pitch. If only a pitch is given, derive the slug. If the pitch is one word ("pong", "snake"), pick an interesting twist and say what you picked — don't stall with questions.

## 1. Scaffold
```bash
./scripts/new_game.sh <slug> "<Title>"
```
Never build inside `template/`.

## 2. Design first (5 minutes, ~30 lines)
Write `games/<slug>/DESIGN.md`:
- **Pitch** — one sentence.
- **Core loop** — the 3–10 second action the player repeats.
- **Controls** — keyboard AND touch, side by side. Touch must be one-thumb or two-thumb, no tiny buttons.
- **Fail / win condition** and **score**.
- **Ramp** — what gets harder over time (speed, spawn rate, enemy types) with numbers.
- **Juice list** — 3–5 feedback effects from the `game-feel` skill.
- **Out of scope** — what you're deliberately not building.

Keep scope to something finishable in one session. A tight arcade loop beats a sprawling half-game.

## 3. Implement
Load `godot-web-gdscript` before writing code.
- Start from the template's `scripts/main.gd` state machine (TITLE → PLAYING → GAME_OVER). Keep it.
- Put every tunable in constants at the top.
- Visuals: `_draw()` / `Polygon2D` / `ColorRect` / shaders with a deliberate 3–5 color palette (set `ACCENT` and the background in code and the `accent` in `game.json`). Avoid default grey boxes — pick a look.
- Larger games: split into scenes (`player.tscn`, `enemy.tscn`) with their own scripts, communicating via signals. Hand-written `.tscn` files must use `format=3` and `ExtResource("id")` syntax.
- Save the best score with `ConfigFile` at `user://save.cfg`.
- Update `game.json`: `title`, `tagline`, `controls`, `accent`.

## 4. Polish
Run through the `game-feel` checklist. At minimum: screen shake or flash on hit, particles on score, eased motion, readable HUD at phone size (font ≥ 28px at 720-wide viewport).

## 5. Verify
```bash
./scripts/check.sh <slug>
```
Must end with `PASS`. Fix every `SCRIPT ERROR`, `Parse Error`, and warning about missing resources. See `playtest-check` for what the check does and how to add a logic assertion. If Godot isn't installed here, say so and stop at `bash -n`/review — don't claim it passed.

## 6. Report back
Tell the user, briefly: what the game is, controls, what's tunable at the top of `main.gd`, and the command to play it locally (`./scripts/export_all.sh && ./scripts/serve.sh` → `localhost:8000/<slug>/`). Offer one concrete next improvement.

## Good pitches to suggest if asked
Lane runner · one-button jumper · tower-defense-lite · breakout with power-ups · asteroid shooter with twin-stick touch · match-3 · snake with portals · rhythm tapper · top-down survivor (waves) · physics stacker (RigidBody2D).
