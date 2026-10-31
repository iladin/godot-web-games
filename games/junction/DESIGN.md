# Junction — design

Genre: real-time routing puzzle-action (endless, lives). Portrait 720x1280.

## Pitch
Coloured trains pour out of a tunnel into a branching rail yard; flip the points in time so every train rolls into the station that matches it.

## Core loop (3–10 s)
See the next train's colour (shown in the tunnel mouth 1.5 s before it leaves) → trace its route down the tree → flip the 1–3 switches on that route before the train reaches them → train docks: correct (+points, combo) or wrong (lose a life) → meanwhile the next train is already rolling.

## Controls
- **Touch / mouse (one thumb):** tap a switch to flip it. Each switch has a big circular hit area of radius `SWITCH_HIT_R` (64 px) — switches are ≥ 160 px apart so hits never overlap. Tap anywhere to start / resume / restart.
- **Keyboard:** keys `1`–`4` flip switch 1–4 directly (numbers drawn on each switch). Alternatively Left/Right (or A/D) move a selection ring between switches and Space/Enter flips the selected one. Space/Enter starts / restarts.
- A switch cannot flip while a train is within `SWITCH_LOCK_DIST` (26 px) of it (it shakes and buzzes instead) — prevents trains teleporting mid-turn.

## Fail / Win
- Endless. Start with `LIVES` = 3. A train docking at a wrong-colour station costs 1 life. 0 lives → GAME OVER (score, best, "NEW BEST") → tap to restart after `RESTART_DELAY`.
- No win state; the goal is a high score (beat best).

## Score
- Correct delivery: `BASE_POINTS` (10) × combo multiplier. Combo = consecutive correct deliveries, multiplier = `min(1 + combo / COMBO_STEP, COMBO_MAX)` with COMBO_STEP 4, COMBO_MAX 5 (integer division). A wrong delivery resets combo to 0.
- HUD: score (top centre, 56 px), lives as 3 small locomotive icons (top left), combo "×3" (top right).
- Best score saved in `user://save.cfg` `[score] best`.

## Ramp (by `delivered` = trains docked, right or wrong)
- Train speed: `SPEED_START` 110 px/s + `SPEED_PER_TRAIN` 3.5 per delivery, capped at `SPEED_MAX` 270.
- Spawn interval: `SPAWN_START` 4.2 s − `SPAWN_PER_TRAIN` 0.07 per delivery, floor `SPAWN_MIN` 1.5 s.
- Active colours (stations that can receive trains): 3 at start; 4 once `score_correct >= 6`; 5 once `>= 16`. Locked stations are drawn dim with a padlock glyph and never chosen as a train colour.
- Repeat bias: from delivery 25 on, `REPEAT_CHANCE_LATE` 0.15 → each new train has only 15 % chance to share the previous train's colour (forces more flips); before that 0.35.
- Expected feel: ~1 train every 4 s for the first minute, ~2–3 trains on the board at once after ~2 minutes.

## Juice
1. Switch flip: blade animates between branches over 0.12 s (ease-out), small click blip, switch ring pulses 1.25→1.0.
2. Correct dock: station roof flashes white, 20 confetti particles in train colour, floating "+30" text rising 60 px and fading over 0.7 s.
3. Wrong dock: screen shake 14 px / 0.3 s, red full-screen flash alpha 0.3, the lost life icon pops and falls off.
4. Trains: 3-car consist (loco + 2 wagons) following the path at fixed spacing, with a puff of 3 smoke circles from the loco every 0.4 s; trains lean slightly (rotate along path tangent).
5. Next-train preview: tunnel mouth glows in the upcoming colour and pulses faster in the final 0.5 s.

## Out of scope
Train collisions, multiple entry tunnels, editable track layouts, more than one level layout, signals/stop lights, music track, power-ups.

## Look
| Role | Hex | Drawn as |
|---|---|---|
| Background | `#1b1f2a` slate | full-screen rect + faint 40 px grid dots (alpha 0.06) for a "yard map" feel |
| Track | `#8a93a6` steel | each edge = two parallel `draw_polyline` rails (width 3, ±7 px offset) + sleepers every 22 px (short `draw_line`, darker `#5a6275`) |
| Accent / UI | `#ffd166` amber | switch rings, selection ring, HUD numbers, tunnel arch |
| Danger | `#ff5d73` | wrong-dock flash, lives icons |
| Train / station colours | `#4cc9f0` cyan ●, `#f72585` magenta ■, `#80ed99` green ▲, `#ff9f1c` orange ◆, `#b388ff` violet ★ | trains: rounded rects (loco gets a cab block + headlight); stations: 100×70 platform rect with roof triangle and the colour's **glyph** drawn in white so colour is never the only cue (colour-blind safe) |

All shapes via `_draw()` (`draw_rect`, `draw_colored_polygon`, `draw_circle`, `draw_arc`); no textures. HUD font ≥ 30 px.

## Build plan
Files in `scripts/` (target ≈ 600 lines):
- `main.gd` (~280) — template state machine TITLE → PLAYING → GAME_OVER; spawning; input (tap hit-test, number keys, select+flip); scoring/lives; save; focus pause; `--autoplay`; HUD/banners/flash/shake.
- `yard.gd` (`class_name Yard`, static, ~120) — pure track graph and rules:
  - Node table `NODES: Dictionary` id → `{pos: Vector2, kind: "entry"|"switch"|"station", left: String, right: String, station: int}`.
  - Layout (720×1280): `entry` (360,150) → `S1` (360,330) [left `S2`, right `S3`]; `S2` (200,560) [left `st0`, right `S4`]; `S4` (300,800) [left `st1`, right `st2`]; `S3` (520,560) [left `st3`, right `st4`]. Stations at y = 1100: `st0` x 90, `st1` x 230, `st2` x 370, `st3` x 510, `st4` x 650. Switch numbering for keys: S1=1, S2=2, S3=3, S4=4.
  - Edges are 3-point polylines: parent → (parent.x, parent.y + 60) → child (gentle bend), built by `static func edge_points(from_id, to_id) -> PackedVector2Array`.
  - `static func next_node(node_id: String, switches: Dictionary) -> String` (switch false = left, true = right; entry → S1).
  - `static func destination(switches: Dictionary) -> int` — follow from entry to a station, return station index.
  - `static func flips_needed(switches: Dictionary, target: int) -> Array[String]` — switch ids that must change for a train entering now to reach `target` (used by autoplay and tutorial hint).
  - `static func spawn_interval(delivered: int) -> float`, `train_speed(delivered) -> float`, `active_colours(correct: int) -> int`, `multiplier(combo: int) -> int`.
- `train.gd` (~80) — plain `RefCounted` class: `colour: int`, `from_id`, `to_id`, `path: PackedVector2Array`, `dist: float`, `length: float`; `advance(delta, speed) -> bool` (true when edge finished); `point_at(d: float) -> Vector2` / `tangent_at(d)` for drawing the 3 cars at `dist`, `dist - CAR_GAP`, `dist - 2*CAR_GAP` (cars behind the edge start are drawn on the previous edge's stored path). Main decides the next edge at the moment a train finishes an edge by reading the *current* switch state.
- `audio.gd` (~50) — AudioStreamGenerator blips (flip click, dock chime, wrong buzz); enabled on first input.
- `selftest.gd` — see checklist.

Runtime state in main: `switches: Dictionary` (id → bool), `trains: Array[Train]`, `next_colour: int`, `spawn_timer: float`, `score`, `correct`, `delivered`, `combo`, `lives`, `selected: int`, plus juice arrays (`particles: Array[Dictionary]`, `popups`).

Tunables:
```
BG #1b1f2a, TRACK #8a93a6, SLEEPER #5a6275, ACCENT #ffd166, DANGER #ff5d73
TRAIN_COLOURS := [#4cc9f0, #f72585, #80ed99, #ff9f1c, #b388ff]
LIVES := 3
BASE_POINTS := 10 ; COMBO_STEP := 4 ; COMBO_MAX := 5
SPEED_START := 110.0 ; SPEED_PER_TRAIN := 3.5 ; SPEED_MAX := 270.0
SPAWN_START := 4.2 ; SPAWN_PER_TRAIN := 0.07 ; SPAWN_MIN := 1.5
COLOURS_START := 3 ; UNLOCK_4_AT := 6 ; UNLOCK_5_AT := 16
REPEAT_CHANCE_EARLY := 0.35 ; REPEAT_CHANCE_LATE := 0.15 ; LATE_AT := 25
PREVIEW_TIME := 1.5
SWITCH_HIT_R := 64.0 ; SWITCH_LOCK_DIST := 26.0 ; FLIP_ANIM := 0.12
CAR_GAP := 34.0 ; CAR_LEN := 30.0 ; CAR_W := 22.0
RAIL_OFFSET := 7.0 ; SLEEPER_STEP := 22.0
SHAKE_PX := 14.0 ; SHAKE_TIME := 0.3 ; FLASH_ALPHA := 0.3
POPUP_TIME := 0.7 ; CONFETTI := 20
RESTART_DELAY := 0.6
AUTOPLAY_REACTION := 0.35   # s after spawn before autoplay applies flips_needed
```
Autoplay: for the train nearest to its next switch, apply `flips_needed` for that train's colour starting from the switch it is heading to (skip locked switches); deliberately mis-route every 7th train so the life-loss path is exercised within the 900-frame check.

## Acceptance checklist
1. `./scripts/check.sh junction` prints `PASS` (import, title smoke, autoplay, selftest).
2. Title → tap/Space → trains spawn from the tunnel; game over after 3 wrong docks; tap restarts with score 0 and lives 3.
3. Tapping within 64 px of a switch flips it on a 720×1280 window and at a phone-sized window (stretch mode keeps hit areas correct); keys 1–4 and Left/Right+Space also flip.
4. A switch with a train within 26 px refuses to flip (visible shake), and a train already past a switch is unaffected by flipping it.
5. 4th and 5th stations unlock at 6 and 16 correct deliveries; locked stations never receive a train colour.
6. Best score persists in `user://save.cfg` across reloads; "NEW BEST" shown when beaten.
7. Focus loss pauses movement and spawn timer; no audio before first input.
8. **Selftest (pure logic):**
   - All switches false (left) → `Yard.destination(sw) == 0`; `{S1:false,S2:true,S4:true}` → `2`; `{S1:true,S3:true}` → `4`.
   - For every target 0..4 and a few random starting switch states, applying `Yard.flips_needed(sw, t)` then `Yard.destination(sw) == t`.
   - `Yard.spawn_interval(0) == 4.2`, `Yard.spawn_interval(1000) == 1.5`; `Yard.train_speed(1000) == 270.0`.
   - `Yard.active_colours(0) == 3`, `(6) == 4`, `(16) == 5`; `Yard.multiplier(0) == 1`, `(4) == 2`, `(100) == 5`.
