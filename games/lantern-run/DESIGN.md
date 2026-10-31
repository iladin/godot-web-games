# Lantern Run — design

## Pitch
Sprint through a pitch-black cavern by the light of a dying lantern: jump pits and stalagmites you can barely see, and snatch oil flasks to push the darkness back.

## Core loop
Scan the edge of your light circle → spot a hazard or oil flask → jump (or double-jump) at the right moment → land, repeat (~1–2 s per obstacle).

## Controls
| Action | Keyboard | Touch / mouse |
|---|---|---|
| Start / restart | Space / Enter | Tap anywhere |
| Jump (tap again mid-air = double jump) | Space / W / ↑ | Tap anywhere (left half or right half, same) |
| Short hop | Release jump early (variable height) | Release finger early |
| Pause | Esc / P | Pause button top-right (88×88 px) |
Actions registered in code via `InputMap.add_action`: `jump`, `pause`, `start`.

## Fail / win
- Fall into a pit or hit a stalagmite / hanging spike → game over.
- Light radius reaches `LIGHT_MIN` (lantern goes out) → 1.5 s grace "flicker", then game over unless oil is grabbed.
- Endless; goal is distance high score.

## Score
- Distance: 1 point per 10 px travelled (shown as metres).
- Oil flask: +50 and +`OIL_LIGHT_GAIN` radius.
- Ember shard (rare, high/risky placement): +200.
- Best score saved in `user://save.cfg` `[save] best`.

## Ramp (numbers)
- Run speed: 320 px/s → +6 px/s per second, cap 720 px/s.
- Light drain: 14 px/s radius → +0.25 px/s per second, cap 30 px/s.
- Obstacle gap (px between hazards): 620 → −4 px per second, min 300 (scaled so gap ≥ speed × 0.45 s).
- Pit width: 120–180 px early; after 45 s 160–260 px (needs double-jump).
- Hanging spikes appear after 30 s (25% of hazards), forcing low hops.
- Oil spawn: every 3 hazards early, every 5 hazards after 60 s.

## Juice list
- Lantern light flickers (radius ± 4 px noise, sin + randf) and pulses bigger on oil pickup (tween, elastic out).
- Ember particles trail from the lantern; spark burst + "+50" popup on oil.
- Screen shake (8 px, 0.25 s) + white flash on death; camera squash on landing (player scale 1.2×0.8 → 1, 0.12 s).
- Dust puff on land / jump; low-light vignette pulses red when radius < 120.
- Footstep tick sound and jump blip via AudioStreamGenerator (only after first input).

## Out of scope
Multiple biomes, enemies that move, power-ups beyond oil/embers, slide/duck, leaderboards, music track.

## Look
Palette:
- `#07060d` background void (darkness)
- `#2a2238` rock silhouettes (floor, stalagmites) — only visible inside light
- `#ffb347` lantern light / accent (warm amber)
- `#ffe9a8` flame core, oil flask glint, HUD text
- `#e2493b` danger: spikes tint, low-light vignette
Entities:
- Darkness: full-screen ColorRect with a canvas_item shader (gl_compatibility-safe) that alpha-cuts a radial gradient around the lantern position (uniforms `light_pos`, `light_radius`). Fallback if shader trouble: draw a huge ring polygon with `draw_polygon` of a circle hole.
- Player: small hooded figure from `draw_polygon` (triangle cloak `#2a2238` outlined amber) + circle head; lantern = 10 px circle `#ffe9a8` held ahead, swinging on a sin.
- Ground: segments drawn as rects `#2a2238` with a 3 px amber-ish top edge (`#ffb347` at 30% alpha); pits are just gaps.
- Stalagmite: triangle polygon, 40–70 px tall. Hanging spike: inverted triangle from ceiling, tint `#e2493b` at tips.
- Oil flask: rounded rect body + small neck, `#ffe9a8` with a bobbing glint.
- Ember shard: diamond polygon `#ffb347`, rotating.

## Build plan
Single scene `main.tscn`, scripts:
- `scripts/main.gd` — state machine TITLE → PLAYING → GAME_OVER (from template), input, HUD (Labels, font 32+), save/load, audio, focus pause (`NOTIFICATION_APPLICATION_FOCUS_OUT` → paused).
- `scripts/world.gd` (Node2D, `_draw`) — owns world arrays, scrolling, spawning, drawing ground/hazards/pickups.
- `scripts/runner_logic.gd` (`class_name RunnerLogic`, RefCounted, pure static funcs) — for selftest.
- `scripts/darkness.gdshader` — radial light mask.
- `scripts/selftest.gd` — assertions.
Player is not a physics body: custom kinematics (`pos_y`, `vel_y`, `on_ground`, `jumps_left`).

Data structures:
- `ground: Array[Vector2]` — list of (x_start, x_end) solid segments in world-x.
- `hazards: Array[Dictionary]` — `{x: float, kind: int (STALAG/SPIKE), h: float}`.
- `pickups: Array[Dictionary]` — `{x: float, y: float, kind: int (OIL/EMBER), taken: bool}`.
- `cam_x: float` world scroll; despawn anything with x < cam_x − 200.

Pure functions (RunnerLogic):
- `static func drain_light(radius: float, rate: float, dt: float) -> float` → `max(LIGHT_MIN, radius − rate*dt)`.
- `static func add_oil(radius: float) -> float` → `min(LIGHT_MAX, radius + OIL_LIGHT_GAIN)`.
- `static func speed_at(t: float) -> float` → `min(SPEED_MAX, SPEED_START + SPEED_RAMP*t)`.
- `static func gap_at(t: float, speed: float) -> float` → `max(GAP_MIN, GAP_START − GAP_RAMP*t, speed*0.45)`.
- `static func is_over_pit(x: float, ground: Array) -> bool`.
- `static func score_for(distance_px: float, oil: int, embers: int) -> int`.

Tunable constants (top of runner_logic.gd / main.gd):
```
const GRAVITY := 2600.0
const JUMP_VELOCITY := -980.0
const DOUBLE_JUMP_VELOCITY := -860.0
const JUMP_CUT := 0.45            # vel_y multiplier on early release
const MAX_JUMPS := 2
const COYOTE_TIME := 0.08
const JUMP_BUFFER := 0.1
const PLAYER_SCREEN_X := 200.0
const GROUND_Y := 900.0
const CEILING_Y := 360.0
const PLAYER_SIZE := Vector2(34, 56)
const SPEED_START := 320.0
const SPEED_RAMP := 6.0
const SPEED_MAX := 720.0
const LIGHT_START := 340.0
const LIGHT_MAX := 420.0
const LIGHT_MIN := 60.0
const LIGHT_DRAIN_START := 14.0
const LIGHT_DRAIN_RAMP := 0.25
const LIGHT_DRAIN_MAX := 30.0
const OIL_LIGHT_GAIN := 110.0
const OUT_GRACE := 1.5
const GAP_START := 620.0
const GAP_RAMP := 4.0
const GAP_MIN := 300.0
const PIT_MIN_EARLY := 120.0
const PIT_MAX_EARLY := 180.0
const PIT_MIN_LATE := 160.0
const PIT_MAX_LATE := 260.0
const LATE_PIT_TIME := 45.0
const SPIKE_TIME := 30.0
const SPIKE_CHANCE := 0.25
const STALAG_H_MIN := 40.0
const STALAG_H_MAX := 70.0
const OIL_EVERY_EARLY := 3
const OIL_EVERY_LATE := 5
const OIL_LATE_TIME := 60.0
const EMBER_CHANCE := 0.12
const PX_PER_POINT := 10.0
const OIL_POINTS := 50
const EMBER_POINTS := 200
const SAFE_START_PX := 900.0      # no hazards in first 900 px
const SHAKE_PX := 8.0
const SHAKE_TIME := 0.25
const LOW_LIGHT_WARN := 120.0
```

## Acceptance checklist
1. Title screen shows name, best score, "Tap or Space to start"; tap/Space starts; game over screen shows score + best; tap/Space restarts with fresh world.
2. Jump works with Space/↑/W and tap; second press mid-air double-jumps; third press does nothing; early release gives a visibly shorter hop.
3. Touching a stalagmite/spike or falling below GROUND_Y + 200 ends the run; first 900 px are hazard-free.
4. Light radius shrinks visibly over time; collecting oil grows it (capped) with pulse + popup; at LIGHT_MIN the lantern flickers 1.5 s then game over.
5. Speed and darkness drain increase over time; spikes appear after ~30 s; double-jump pits after ~45 s.
6. Best score persists across reloads via `user://save.cfg`.
7. Window focus loss pauses; no audio before first input; runs with gl_compatibility in browser.
8. selftest assertions (scripts/selftest.gd):
   - `RunnerLogic.drain_light(100.0, 20.0, 1.0) == 80.0` and `drain_light(65.0, 20.0, 1.0) == LIGHT_MIN`.
   - `RunnerLogic.add_oil(LIGHT_MAX - 10.0) == LIGHT_MAX`.
   - `RunnerLogic.speed_at(0.0) == SPEED_START` and `speed_at(10000.0) == SPEED_MAX`.
   - `RunnerLogic.is_over_pit(150.0, [Vector2(0,100), Vector2(200,400)]) == true` and `is_over_pit(50.0, same) == false`.
9. `./scripts/check.sh lantern-run` ends with PASS.
