# Echo Tap — design

## Pitch
Four glowing pads play a short rhythmic phrase once — echo it back, on beat, before the phrase grows longer and the tempo climbs.

## Core loop
Listen/watch a phrase (2–4 s) → repeat it on the same beat grid (2–4 s) → get Perfect/Good/Miss feedback → next, longer phrase.

## Controls
| Action | Keyboard | Touch / mouse |
|---|---|---|
| Start / restart | Space / Enter | Tap anywhere |
| Pad 0 (top, cyan) | ↑ / W / I | Tap top quadrant |
| Pad 1 (right, magenta) | → / D / L | Tap right quadrant |
| Pad 2 (bottom, gold) | ↓ / S / K | Tap bottom quadrant |
| Pad 3 (left, lime) | ← / A / J | Tap left quadrant |
| Pause | Esc / P | Pause button top-right (88×88 px) |
Pads are four big wedges (diamond layout) filling a 640 px circle — two-thumb friendly. Actions registered via `InputMap.add_action`: `pad_0..pad_3`, `start`, `pause`. Input during the LISTEN phase is ignored (pads dim).

## Fail / win
- 3 lives (hearts). A round fails if any note is wrong pad or misses its timing window, or the player is silent > 1 beat past the last expected note. Failed round = −1 life, the same phrase replays once.
- 0 lives → game over. Endless; chase high score.

## Score
- Per note: Perfect (|err| ≤ 60 ms) = 100, Good (≤ 140 ms) = 50, else Miss (fails the round).
- Round clear bonus: 50 × phrase length; "flawless" (all Perfect) ×2 bonus.
- Streak multiplier: +0.25× per consecutive cleared round, cap ×3, reset on failure.
- Best score saved in `user://save.cfg` `[save] best`.

## Ramp (numbers)
- Phrase length: starts 3 notes, +1 every round cleared, cap 12.
- Tempo: 90 BPM, +4 BPM per round cleared, cap 170 BPM.
- Rhythm: rounds 1–3 quarter notes only; from round 4 notes may sit on eighth-note subdivisions (chance 30% → +5%/round, cap 60%); from round 8 a note can be a rest gap of 2 beats.
- Timing windows shrink after round 10: Good 140 → 110 ms.
- Round 1 timeline: count-in 4 ticks, phrase, 1 beat gap, count-in 2 ticks, echo window.

## Juice list
- Pad lights up with scale pop (1.0 → 1.12 → 1.0, ease out back 0.15 s) and plays its own tone (sine via AudioStreamGenerator: C5, E5, G5, B5).
- Judgement text pops at pad ("PERFECT" gold / "GOOD" white / "MISS" red), rising and fading 0.5 s.
- Centre ring pulses on every beat (metronome visual); ring fills as the echo progresses.
- Screen shake 10 px + red flash + low buzz on fail; particle burst ring on flawless clear.
- Background hue drifts subtly as tempo rises.

## Out of scope
Music tracks, more than 4 pads, hold notes, online leaderboards, difficulty select, latency calibration menu (use a fixed `INPUT_OFFSET_MS` constant).

## Look
Palette:
- `#0d0b1e` background (deep indigo)
- `#3fe0ff` pad 0 cyan (also accent)
- `#ff4fa3` pad 1 magenta
- `#ffd23f` pad 2 gold
- `#8cff6b` pad 3 lime
(dim state = colour × 0.25 alpha over `#1c1838` wedge base; HUD text `#f2f0ff`)
Entities:
- Pads: four wedges built with `draw_colored_polygon` from arc points (inner radius 110, outer 320, 6° gaps), centred at (360, 700).
- Centre hub: circle radius 90 `#1c1838`, beat-pulse ring (`draw_arc`, width 6) and progress arc showing notes echoed / total.
- Phase banner above the circle: "LISTEN" / "ECHO" / "GET READY" (Label, 44 px).
- Hearts: 3 small polygons top-left; score + streak top-centre (32 px); round # top-right.
- Particles: simple Array of {pos, vel, life, col} drawn as circles in `_draw` (no CPUParticles needed).

## Build plan
Scene `main.tscn` (template). Scripts:
- `scripts/main.gd` — state machine TITLE → PLAYING (sub-phase LISTEN / GAP / ECHO / RESULT) → GAME_OVER; input mapping; HUD; save/load; focus-loss pause (`NOTIFICATION_APPLICATION_FOCUS_OUT`); audio gate (`audio_unlocked` set on first input).
- `scripts/pads.gd` (Node2D, `_draw`) — wedge geometry, hit-test `pad_at(pos: Vector2) -> int` (angle + radius), lit state & pop animation, particles.
- `scripts/echo_logic.gd` (`class_name EchoLogic`, RefCounted, pure static funcs) — phrase generation & judging, used by selftest.
- `scripts/tone.gd` — AudioStreamGenerator pushing short enveloped sine bursts (no threads; fill buffer in `_process`).
- `scripts/selftest.gd` — assertions.

Timing: all timing from a single `song_time: float` accumulated in `_process(delta)` while unpaused (not wall clock), so pause is safe. Input timestamps = song_time at event (+ INPUT_OFFSET_MS).

Data structures:
- `phrase: Array[Dictionary]` — `{pad: int, beat: float}` beat offset from phrase start (0, 1, 1.5, ...).
- `echo_start_time: float`, `next_note_idx: int`, `results: Array[int]` (JUDGE_PERFECT/GOOD/MISS).
- `rng: RandomNumberGenerator` seeded per run (seed stored for selftest determinism).

Pure functions (EchoLogic):
- `static func beat_len(bpm: float) -> float` → `60.0 / bpm`.
- `static func bpm_for_round(r: int) -> float` → `min(BPM_MAX, BPM_START + BPM_STEP*(r-1))`.
- `static func length_for_round(r: int) -> int` → `min(LEN_MAX, LEN_START + r - 1)`.
- `static func make_phrase(rng: RandomNumberGenerator, r: int) -> Array` — no pad repeated more than 3 times in a row; beats strictly increasing.
- `static func judge(err_sec: float, good_window: float) -> int` → PERFECT / GOOD / MISS.
- `static func multiplier(streak: int) -> float` → `min(MULT_MAX, 1.0 + MULT_STEP*streak)`.

Tunable constants:
```
const PAD_COUNT := 4
const LIVES := 3
const LEN_START := 3
const LEN_MAX := 12
const BPM_START := 90.0
const BPM_STEP := 4.0
const BPM_MAX := 170.0
const EIGHTH_FROM_ROUND := 4
const EIGHTH_CHANCE_START := 0.30
const EIGHTH_CHANCE_STEP := 0.05
const EIGHTH_CHANCE_MAX := 0.60
const REST_FROM_ROUND := 8
const REST_CHANCE := 0.15
const MAX_SAME_PAD_RUN := 3
const PERFECT_WINDOW := 0.060
const GOOD_WINDOW := 0.140
const GOOD_WINDOW_LATE := 0.110
const TIGHT_FROM_ROUND := 10
const COUNT_IN_LISTEN := 4
const COUNT_IN_ECHO := 2
const GAP_BEATS := 1
const SILENCE_FAIL_BEATS := 1.0
const INPUT_OFFSET_MS := 0.0
const PERFECT_POINTS := 100
const GOOD_POINTS := 50
const CLEAR_BONUS_PER_NOTE := 50
const FLAWLESS_MULT := 2
const MULT_STEP := 0.25
const MULT_MAX := 3.0
const PAD_CENTER := Vector2(360, 700)
const PAD_R_INNER := 110.0
const PAD_R_OUTER := 320.0
const PAD_GAP_DEG := 6.0
const POP_SCALE := 1.12
const POP_TIME := 0.15
const TONE_HZ := [523.25, 659.25, 783.99, 987.77]
const TONE_LEN := 0.18
const SHAKE_PX := 10.0
const SHAKE_TIME := 0.3
const RESULT_PAUSE := 0.8
```

## Acceptance checklist
1. Title shows name, best, "Tap or Space to start"; game over shows score, best, round reached; tap/Space restarts at round 1 with 3 lives.
2. LISTEN phase lights each pad on its beat with its tone; player input is ignored (pads dim) until "ECHO".
3. Arrow keys / WASD and tapping a quadrant both trigger the correct pad (tap hit-test by angle; centre hub ignored).
4. Correct-order, on-time echo clears the round: phrase length +1, BPM +4, score increases; flawless doubles bonus.
5. Wrong pad, off-window tap, or silence > 1 beat past the last note → MISS, −1 life, shake + flash, same phrase replays; 0 lives → game over.
6. Eighth-note subdivisions appear from round 4; tempo visibly faster by round 10.
7. Best score persists via `user://save.cfg`; focus loss pauses (song_time stops); no audio before first input.
8. selftest assertions (scripts/selftest.gd):
   - `EchoLogic.judge(0.03, 0.14) == PERFECT`, `judge(-0.1, 0.14) == GOOD`, `judge(0.2, 0.14) == MISS`.
   - `EchoLogic.length_for_round(1) == 3` and `length_for_round(50) == 12`; `bpm_for_round(1) == 90.0`, `bpm_for_round(100) == 170.0`.
   - `make_phrase(rng seeded 42, 6)` returns 8 notes, beats strictly increasing, pads in 0..3, no run of >3 identical pads.
   - `EchoLogic.multiplier(0) == 1.0` and `multiplier(20) == 3.0`.
9. `./scripts/check.sh echo-tap` ends with PASS.
