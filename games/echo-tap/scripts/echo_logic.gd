class_name EchoLogic
extends RefCounted
## Pure rules for Echo Tap: phrase generation, ramp, judging, scoring. No nodes, no state.

const PAD_COUNT := 4
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
const PERFECT_POINTS := 100
const GOOD_POINTS := 50
const CLEAR_BONUS_PER_NOTE := 50
const FLAWLESS_MULT := 2
const MULT_STEP := 0.25
const MULT_MAX := 3.0

const JUDGE_PERFECT := 0
const JUDGE_GOOD := 1
const JUDGE_MISS := 2


static func beat_len(bpm: float) -> float:
	return 60.0 / bpm


static func bpm_for_round(r: int) -> float:
	return minf(BPM_MAX, BPM_START + BPM_STEP * float(r - 1))


static func length_for_round(r: int) -> int:
	return mini(LEN_MAX, LEN_START + r - 1)


static func good_window_for_round(r: int) -> float:
	return GOOD_WINDOW_LATE if r >= TIGHT_FROM_ROUND else GOOD_WINDOW


static func eighth_chance(r: int) -> float:
	if r < EIGHTH_FROM_ROUND:
		return 0.0
	return minf(EIGHTH_CHANCE_MAX, EIGHTH_CHANCE_START + EIGHTH_CHANCE_STEP * float(r - EIGHTH_FROM_ROUND))


## Returns Array of {pad: int, beat: float}; beat is the offset from phrase start.
static func make_phrase(rng: RandomNumberGenerator, r: int) -> Array:
	var out: Array = []
	var n: int = length_for_round(r)
	var beat := 0.0
	var run := 0
	var last := -1
	for i in n:
		var pad: int = rng.randi_range(0, PAD_COUNT - 1)
		if pad == last and run >= MAX_SAME_PAD_RUN:
			pad = (pad + rng.randi_range(1, PAD_COUNT - 1)) % PAD_COUNT
		run = run + 1 if pad == last else 1
		last = pad
		out.append({"pad": pad, "beat": beat})
		var step := 1.0
		if rng.randf() < eighth_chance(r):
			step = 0.5
		elif r >= REST_FROM_ROUND and rng.randf() < REST_CHANCE:
			step = 2.0
		beat += step
	return out


static func judge(err_sec: float, good_window: float) -> int:
	var a: float = absf(err_sec)
	if a <= PERFECT_WINDOW:
		return JUDGE_PERFECT
	if a <= good_window:
		return JUDGE_GOOD
	return JUDGE_MISS


static func multiplier(streak: int) -> float:
	return minf(MULT_MAX, 1.0 + MULT_STEP * float(streak))


static func note_points(j: int) -> int:
	if j == JUDGE_PERFECT:
		return PERFECT_POINTS
	return GOOD_POINTS if j == JUDGE_GOOD else 0


static func clear_bonus(length: int, flawless: bool) -> int:
	return CLEAR_BONUS_PER_NOTE * length * (FLAWLESS_MULT if flawless else 1)


## Diamond layout: 0 top, 1 right, 2 bottom, 3 left. -1 inside the hub.
static func pad_for_point(p: Vector2, center: Vector2, inner_radius: float) -> int:
	var d: Vector2 = p - center
	if d.length() < inner_radius:
		return -1
	var deg: float = rad_to_deg(atan2(d.y, d.x))
	return int(floorf(fposmod(deg + 135.0, 360.0) / 90.0)) % PAD_COUNT
