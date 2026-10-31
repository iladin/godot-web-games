# Orbit Putt — design

Genre: physics puzzle (one-shot golf). Portrait 720x1280.

## Pitch
Slingshot a tiny comet-ball across a 9-hole space course and bend it around planets' gravity into the cup, scoring against par.

## Core loop (3–10 s)
Read the gravity wells → pull back to aim (dotted preview shows the first part of the curve) → release → watch the ball swing round planets → it sinks, stops drifting, or is lost/crashed → next stroke from where it stopped.

## Controls
- **Touch / mouse (one thumb):** press anywhere on the playfield and drag *away* from the shot direction (slingshot). Aim = opposite of drag vector; power = drag length / `DRAG_FULL` (260 px), clamped 0..1. Release to shoot. Release with drag < `DRAG_DEADZONE` (30 px) cancels. No buttons needed while playing. Tap to start / continue / restart.
- **Keyboard:** Left/Right rotate aim at `KEY_AIM_SPEED` (2.0 rad/s, hold Shift for 0.4 rad/s fine aim); Up/Down change power at `KEY_POWER_SPEED` (0.8 /s); Space/Enter shoots; Space/Enter also starts / continues / restarts.
- Keyboard and pointer share the same `aim_angle` / `aim_power` variables, so either input picks up where the other left off.

## Fail / Win
- A course is 9 holes. Finishing hole 9 → RESULTS screen (game over / win) → tap to restart from hole 1.
- **Sink:** ball within `CUP_RADIUS` of cup centre and speed < `SINK_MAX_SPEED` (900 px/s) → hole done.
- **Crash:** ball touches a planet surface → ball returns to the shot origin, +1 penalty stroke.
- **Lost in space:** ball more than `OOB_MARGIN` (90 px) outside the screen → back to shot origin, +1 penalty stroke.
- **Rest:** ball stops when speed < `STOP_SPEED` (22 px/s) after `MIN_FLIGHT` (0.4 s), or after `MAX_FLIGHT` (6.0 s) wherever it is (prevents endless orbits). Next stroke is from there.
- **Pick-up:** if strokes on a hole reach par + `PICKUP_OVER` (3) without sinking, the hole is forfeited and scored par + 4. This is the "fail" state per hole; the run always ends after 9 holes.

## Score
- Per hole: strokes (incl. penalties). Running total shown relative to par ("E", "+2", "−1").
- Hole result text: Hole-in-one / Eagle / Birdie / Par / Bogey / Double / Pick-up.
- Best = lowest course total vs par, saved in `user://save.cfg` `[score] best_rel` (default 99 = none). Also save `[score] best_hole_in_ones`.

## Ramp (by hole, numbers)
| Holes | Planets | Repulsors | Moving moon | Preview steps | Cup radius | Par |
|---|---|---|---|---|---|---|
| 1–3 | 1–2 | 0 | no | 90 (1.5 s) | 30 | 2,2,3 |
| 4–6 | 2–3 | 1 | no | 45 (0.75 s) | 27 | 3,3,3 |
| 7–9 | 3–4 | 1 | 1 (orbits a planet) | 20 (0.33 s) | 24 | 3,4,4 |

## Juice
1. Ball trail: last 24 positions drawn as fading, shrinking circles; trail tints toward planet colour when acceleration > 300 px/s².
2. Gravity rings: each planet shows 2 slowly expanding/fading rings whose max radius ∝ its influence (`radius * 3`); repulsor rings contract instead.
3. Sink: cup swirl (ball spirals in over 0.35 s, eased), 24-particle mint burst, result word pops in with scale 1.6→1.0 ease-out.
4. Crash: screen shake (12 px, 0.25 s decay), 14 debris particles in planet colour, short red flash (alpha 0.25).
5. Shot: release "thwip" (procedural AudioStreamGenerator blip, started only after first input), aim line pulses with power; stroke counter scales 1.3→1.0.

## Out of scope
Course editor, procedural holes, multiple courses, ball-ball interaction, bouncing off planets, wind/other forces, online leaderboard, music track.

## Look
| Role | Hex | Drawn as |
|---|---|---|
| Background | `#0b1026` | full-screen rect + 90 static star dots (seeded RNG, 1–2 px, alpha 0.3–0.8) |
| Planet | `#ff8a5c` coral | `draw_circle` + darker inner circle offset (−0.25r) for shading + 2 gravity rings (`draw_arc`, width 2) |
| Repulsor | `#b48cff` violet | circle with 6 outward spikes (Polygon via `draw_colored_polygon`), contracting rings |
| Ball | `#f4f1e8` cream | 11 px circle + trail |
| Cup / accent | `#7dffb3` mint | ring (`draw_arc` r=CUP_RADIUS, width 4) + small triangular flag on a 40 px pole; also HUD accent, aim dots |

Moving moon uses planet colour lerped 50% to cream. HUD font ≥ 30 px.

## Build plan
Files (all in `scripts/`, target ≈ 650 lines total):
- `main.gd` (~280) — template state machine TITLE → PLAYING → HOLE_DONE (1.4 s banner, tap skips) → RESULTS; input → aim; calls `Physics.step`; save/load; focus pause; `--autoplay`; drawing of HUD + banners. Keep the template's helpers.
- `physics.gd` (`class_name OrbitPhysics`, static funcs, ~110) — pure logic, no nodes:
  - `static func accel_at(p: Vector2, bodies: Array[Dictionary], t: float) -> Vector2`
  - `static func body_pos(b: Dictionary, t: float) -> Vector2` (static bodies return `b.pos`; moons: `center + Vector2.from_angle(phase + t*speed) * orbit_r`)
  - `static func step(pos: Vector2, vel: Vector2, bodies, t: float, dt: float) -> Array` → `[pos, vel]` semi-implicit Euler with `vel *= 1 - LINEAR_DAMP*dt`
  - `static func simulate(pos, vel, bodies, t0, max_steps, cup: Vector2, cup_r: float) -> Dictionary` → `{result: "sink"|"crash"|"lost"|"rest", pos: Vector2, steps: int, path: PackedVector2Array}`
  - `static func shot_velocity(angle: float, power: float) -> Vector2` = `Vector2.from_angle(angle) * lerp(MIN_SHOT, MAX_SHOT, power)`
  - `static func result_name(strokes: int, par: int) -> String`
- `course.gd` (`class_name Course`, ~90) — `const HOLES: Array` of 9 dictionaries (data below) + `static func hole(i: int) -> Dictionary` (converts to typed bodies) + `static func preview_steps(i)` / `cup_radius(i)`.
- `solver.gd` (~60) — `static func best_shot(pos, bodies, t, cup, cup_r) -> Vector2(angle, power)`: sample `SOLVER_ANGLES` × `SOLVER_POWERS`, run `simulate` with `SOLVER_STEPS`, return the shot that sinks, else the one whose rest/end point is closest to the cup (crash/lost scored +10000). Used by `--autoplay` and selftest.
- `audio.gd` (~50) — AudioStreamGenerator blips (shoot, sink, crash); `enable()` called on first input only.
- `selftest.gd` — see checklist.

Body dictionary: `{pos: Vector2, r: float, strength: float (+ attract / − repel), moon: bool, center: Vector2, orbit_r: float, speed: float, phase: float}`. Physics time `t` resets to 0 at each hole start and keeps running (moons move) while aiming.

Hole data (720×1280 space; tee, cup, par, bodies as [x, y, r, kind] where kind 0 planet, 1 repulsor, 2 moon of radius r orbiting the previous planet entry at `orbit_r = parent_r + MOON_GAP` (70 px), `speed` 0.6 rad/s, phase 0). Implementer may nudge numbers so the selftest solver condition passes:
1. tee (360,1120) cup (360,240) par 2 — [360,700,70,0]
2. tee (160,1120) cup (560,230) par 2 — [430,740,90,0]
3. tee (360,1120) cup (360,200) par 3 — [220,640,70,0], [500,480,80,0]
4. tee (600,1120) cup (120,300) par 3 — [360,700,110,0], [140,880,40,1]
5. tee (120,1120) cup (600,620) par 3 — [420,860,70,0], [600,330,60,0], [300,520,45,1]
6. tee (360,1120) cup (360,160) par 3 — [180,700,80,0], [540,700,80,0], [360,450,50,1]
7. tee (600,1140) cup (140,180) par 3 — [380,640,90,0], [380,640,22,2], [150,560,45,1]
8. tee (120,1140) cup (600,200) par 4 — [260,820,70,0], [520,560,85,0], [520,560,20,2], [250,330,45,1]
9. tee (360,1140) cup (360,640) par 4 (cup sits between two planets) — [190,640,70,0], [530,640,70,0], [360,380,80,0], [360,380,20,2], [360,900,40,1]

Tunables (top of `main.gd` / `physics.gd`):
```
BG #0b1026, PLANET #ff8a5c, REPULSOR #b48cff, BALL #f4f1e8, ACCENT #7dffb3
GRAVITY_K := 1400.0        # accel at planet surface (px/s²); accel = K * strength * r² / d²
MIN_ACCEL_DIST := 40.0     # clamp d to avoid singularities
REPULSOR_STRENGTH := -0.8
MOON_GAP := 70.0 ; MOON_SPEED := 0.6 ; MOON_STRENGTH := 0.5
LINEAR_DAMP := 0.35        # per second
MIN_SHOT := 180.0          # px/s at power 0
MAX_SHOT := 950.0          # px/s at power 1
BALL_RADIUS := 11.0
CUP_RADIUS_EARLY/MID/LATE := 30.0 / 27.0 / 24.0
SINK_MAX_SPEED := 900.0
STOP_SPEED := 22.0
MIN_FLIGHT := 0.4
MAX_FLIGHT := 6.0
OOB_MARGIN := 90.0
DT := 1.0 / 60.0           # fixed physics step (use _physics_process)
DRAG_FULL := 260.0
DRAG_DEADZONE := 30.0
KEY_AIM_SPEED := 2.0 ; KEY_AIM_FINE := 0.4 ; KEY_POWER_SPEED := 0.8
PREVIEW_STEPS := [90, 45, 20]
PICKUP_OVER := 3
HOLE_BANNER_TIME := 1.4
RESTART_DELAY := 0.6
TRAIL_LEN := 24
SHAKE_PX := 12.0 ; SHAKE_DECAY := 0.25
SOLVER_ANGLES := 24 ; SOLVER_POWERS := 4 ; SOLVER_STEPS := 300
AUTOPLAY_AIM_DELAY := 0.5  # seconds autoplay "aims" before shooting
```

## Acceptance checklist
1. `./scripts/check.sh orbit-putt` prints `PASS` (import, title smoke, autoplay 900 frames, selftest).
2. Title shows name, one-line hint, best score (or "—"); tap/Space starts hole 1.
3. Drag-release on a phone-sized window shoots; preview dots follow the curve; drag < 30 px cancels without a stroke.
4. Keyboard alone can finish all 9 holes (aim, power, shoot, continue, restart).
5. Crash and out-of-bounds both reset to the shot origin and add exactly 1 penalty stroke.
6. After 9 holes the RESULTS screen shows per-hole strokes vs par and total; lower total than saved best shows "NEW BEST" and persists across reload.
7. Window focus loss pauses (physics and moon time frozen); tap resumes. No audio before first input.
8. **Selftest (pure logic):**
   - `OrbitPhysics.accel_at(Vector2(0,-200), [planet at (0,0) r=50 strength 1], 0)` points toward +y (toward the planet) and its length equals `GRAVITY_K * 2500 / 40000` within 0.01; repulsor gives the opposite direction.
   - `simulate` of a ball fired straight at a planet with no other bodies returns `result == "crash"`; fired straight at the cup from 200 px away on an empty board returns `"sink"`.
   - `OrbitPhysics.result_name(1, 3) == "Hole-in-one"`, `(2,3) == "Birdie"`, `(3,3) == "Par"`, `(5,3) == "Double"`.
   - For every hole i in 0..8, iterating `Solver.best_shot` from the tee sinks within `par + 2` strokes (guarantees each authored hole is solvable).
